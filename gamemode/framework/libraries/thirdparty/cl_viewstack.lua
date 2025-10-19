--[[
    ax.viewstack — Stacked CalcView and CalcViewModelView dispatcher for Garry's Mod
    -------------------------------------------------------------------------------
    Purpose:
      GMod stops calling further CalcView/CalcViewModelView hooks after the first non-nil return.
      This shim captures existing hooks, removes them, then replaces them with single dispatchers
      that call everyone and merge results.

    Behavior:
      - CalcView legacy hooks: called as fn(client, origin, angles, fov, znear, zfar).
        If they return (pos, ang, fov) or a table { origin, angles, fov, znear, zfar, drawviewer },
        we merge into the current view. Missing fields are ignored.
      - CalcViewModelView legacy hooks: called as fn(weapon, viewmodel, oldPos, oldAng, pos, ang).
        If they return (pos, ang, fov) or a table { pos, ang, fov }, we merge into the current viewmodel view.
      - Modifier API: register with ax.viewstack.RegisterModifier(name, fn, priority) for CalcView.
        Your fn gets (client, view) and returns either nil (no change) or a (partial) view table.
      - ViewModelModifier API: register with ax.viewstack.RegisterViewModelModifier(name, fn, priority) for CalcViewModelView.
        Your fn gets (weapon, viewmodel) and returns either nil (no change) or a (partial) viewmodel table.

    Notes:
      - Last write wins per-field.
      - Execution order: modifiers (by priority, then name) -> legacy (by captured order,
        tweak with SetPriority/Blacklist).
      - Safe by default: each call runs in pcall; errors are printed once per hook name.

    Drop-in:
      Put this file anywhere shared (e.g., lua/autorun). It self-enables on load and on code reload.
]]

ax = ax or {}
ax.viewstack = ax.viewstack or {}

-- CalcView storage
local CAPTURED   = nil           -- array of { name, fn, prio, enabled=true }
local MODS       = {}            -- array of { name, fn, prio, enabled=true }

-- CalcViewModelView storage
local CAPTURED_VIEWMODEL = nil   -- array of { name, fn, prio, enabled=true }
local MODS_VIEWMODEL     = {}    -- array of { name, fn, prio, enabled=true }

-- Shared storage
local BLACKLIST  = {}            -- [name]=true
local PRIORITY   = {}            -- [name]=number
local WARNED     = {}            -- [name]=true (already logged error once)

-- Performance tracking and caching
local PERF_STATS = {
    lastUpdate = 0,
    frameTime = 0.016,
    skipThreshold = 0.033, -- Skip heavy operations if frame time > 33ms
    modsSorted = false,
    viewmodelModsSorted = false
}

-- Pre-allocated tables to reduce GC pressure
-- Removed TEMP_VIEW and TEMP_VIEWMODEL to avoid mutation bugs

-- Localized globals for performance
local istable_local = istable
local isstring_local = isstring
local isfunction_local = isfunction
local isnumber_local = isnumber
local isbool_local = isbool
local tonumber_local = tonumber
local tostring_local = tostring
local pcall_local = pcall
local ipairs_local = ipairs
local table_sort = table.sort
local table_insert = table.insert
local math_max = math.max
local CurTime_local = CurTime
local FrameTime_local = FrameTime

-- Optimized merge functions with performance checks
local function merge_view(base, patch)
    if not patch then return base end
    -- Only update fields that actually changed
    if patch.origin and (not base.origin or not patch.origin:IsEqualTol(base.origin, 0.0001)) then base.origin = patch.origin end
    if patch.angles and (not base.angles or not patch.angles:IsEqualTol(base.angles, 0.0001)) then base.angles = patch.angles end
    if patch.fov and patch.fov ~= base.fov then base.fov = patch.fov end
    if patch.znear and patch.znear ~= base.znear then base.znear = patch.znear end
    if patch.zfar and patch.zfar ~= base.zfar then base.zfar = patch.zfar end
    if patch.drawviewer ~= nil and patch.drawviewer ~= base.drawviewer then
        base.drawviewer = patch.drawviewer
    end
    return base
end

local function merge_viewmodel_view(base, patch)
    if not patch then return base end
    -- Only update fields that actually changed
    if patch.pos and (not base.pos or not patch.pos:IsEqualTol(base.pos, 0.0001)) then base.pos = patch.pos end
    if patch.ang and (not base.ang or not patch.ang:IsEqualTol(base.ang, 0.0001)) then base.ang = patch.ang end
    if patch.fov and patch.fov ~= base.fov then base.fov = patch.fov end
    return base
end

-- Optimized normalization with reduced allocations
local function normalize_returns(a, b, c, d, e, f)
    -- Fast path: table return
    if istable_local(a) then return a end
    -- Early bailout: no meaningful data
    if a == nil and b == nil and c == nil then return nil end

    -- Use local table to avoid mutation/race bugs
    return {
        origin = a,
        angles = b,
        fov = c,
        znear = isnumber_local(d) and d or nil,
        zfar = isnumber_local(e) and e or nil,
        drawviewer = isbool_local(f) and f or nil
    }
end

local function normalize_viewmodel_returns(a, b, c)
    -- Fast path: table return
    if istable_local(a) then return a end
    -- Early bailout: no meaningful data
    if a == nil and b == nil and c == nil then return nil end

    -- Use local table to avoid mutation/race bugs
    return {
        pos = a,
        ang = b,
        fov = c
    }
end

-- Optimized safe call with performance tracking
local function safe_call(name, fn, ...)
    local ok, a, b, c, d, e, f = pcall_local(fn, ...)
    if not ok then
        if not WARNED[name] then
            WARNED[name] = true
            MsgC(Color(255,80,80), "[viewstack] Hook error in ", name, ": ", tostring_local(a), "\n")
        end
        return nil
    end
    -- Skip normalization if no returns
    if a == nil and b == nil and c == nil then return nil end
    return normalize_returns(a, b, c, d, e, f)
end

local function safe_call_viewmodel(name, fn, ...)
    local ok, a, b, c = pcall_local(fn, ...)
    if not ok then
        if not WARNED[name] then
            WARNED[name] = true
            MsgC(Color(255,80,80), "[viewstack] ViewModelView hook error in ", name, ": ", tostring_local(a), "\n")
        end
        return nil
    end
    -- Skip normalization if no returns
    if a == nil and b == nil and c == nil then return nil end
    return normalize_viewmodel_returns(a, b, c)
end

-- Performance monitoring
local function update_perf_stats()
    local now = CurTime_local()
    if now - PERF_STATS.lastUpdate > 0.1 then -- Update every 100ms
        PERF_STATS.frameTime = FrameTime_local() or 0.016
        PERF_STATS.lastUpdate = now
    end
end

-- Optimized sorting with caching
local function sort_by_prio_then_name(list, sortedFlag)
    -- Skip sorting if already sorted and no changes
    if sortedFlag and PERF_STATS[sortedFlag] then return end

    table_sort(list, function(x, y)
        local px = x.prio or 0
        local py = y.prio or 0
        if px ~= py then return px < py end
        return tostring_local(x.name) < tostring_local(y.name)
    end)

    if sortedFlag then
        PERF_STATS[sortedFlag] = true
    end
end

-- Public API

--- Register a modifier that gets (client, view) and returns a (partial) view table or nil.
function ax.viewstack:RegisterModifier(name, fn, priority)
    assert(isstring_local(name) and name ~= "", "Modifier needs a name")
    assert(isfunction_local(fn), "Modifier needs a function")
    table_insert(MODS, { name = name, fn = fn, prio = tonumber_local(priority) or 0, enabled = true })
    PERF_STATS.modsSorted = false -- Mark for re-sort
end

--- Register a viewmodel modifier that gets (weapon, viewmodel) and returns a (partial) viewmodel table or nil.
function ax.viewstack:RegisterViewModelModifier(name, fn, priority)
    assert(isstring_local(name) and name ~= "", "ViewModelModifier needs a name")
    assert(isfunction_local(fn), "ViewModelModifier needs a function")
    table_insert(MODS_VIEWMODEL, { name = name, fn = fn, prio = tonumber_local(priority) or 0, enabled = true })
    PERF_STATS.viewmodelModsSorted = false -- Mark for re-sort
end

--- Blacklist a legacy hook (or modifier) by name.
function ax.viewstack:Blacklist(name, state)
    local newState = state ~= false
    if BLACKLIST[name] == newState then return end -- No change needed

    BLACKLIST[name] = newState
    local enabled = not newState

    -- Apply to captured hooks
    if CAPTURED then
        for _, h in ipairs_local(CAPTURED) do
            if h.name == name then h.enabled = enabled end
        end
    end
    if CAPTURED_VIEWMODEL then
        for _, h in ipairs_local(CAPTURED_VIEWMODEL) do
            if h.name == name then h.enabled = enabled end
        end
    end

    -- Apply to modifiers
    for _, m in ipairs_local(MODS) do
        if m.name == name then m.enabled = enabled end
    end
    for _, m in ipairs_local(MODS_VIEWMODEL) do
        if m.name == name then m.enabled = enabled end
    end
end

--- Set priority for a legacy hook (captured) or modifier. Lower number runs earlier.
function ax.viewstack:SetPriority(name, prio)
    local newPrio = tonumber_local(prio) or 0
    if PRIORITY[name] == newPrio then return end -- No change needed

    PRIORITY[name] = newPrio
    local needsSort = false

    -- Update captured hooks
    if CAPTURED then
        for _, h in ipairs_local(CAPTURED) do
            if h.name == name then
                h.prio = newPrio
                needsSort = true
            end
        end
        if needsSort then sort_by_prio_then_name(CAPTURED) end
    end

    needsSort = false
    if CAPTURED_VIEWMODEL then
        for _, h in ipairs_local(CAPTURED_VIEWMODEL) do
            if h.name == name then
                h.prio = newPrio
                needsSort = true
            end
        end
        if needsSort then sort_by_prio_then_name(CAPTURED_VIEWMODEL) end
    end

    -- Update modifiers and mark for re-sort
    for _, m in ipairs_local(MODS) do
        if m.name == name then
            m.prio = newPrio
            PERF_STATS.modsSorted = false
        end
    end
    for _, m in ipairs_local(MODS_VIEWMODEL) do
        if m.name == name then
            m.prio = newPrio
            PERF_STATS.viewmodelModsSorted = false
        end
    end
end

--- Rebuild capture and (re)install dispatcher.
function ax.viewstack:Enable()
    hook.Add("CalcView", "__ax_viewstack_dispatcher", function(client, origin, angles, fov, znear, zfar)
        update_perf_stats()

        -- Base view seeded from engine params
        local view = {
            origin = origin,
            angles = angles,
            fov    = fov,
            znear  = znear,
            zfar   = zfar,
            drawviewer = false
        }

        -- Early bailout for performance: skip if no modifiers and no captured hooks
        local hasWork = #MODS > 0 or (CAPTURED and #CAPTURED > 0)
        if not hasWork then return view end

        -- 1) run modern modifiers (sort only when needed)
        if #MODS > 0 then
            sort_by_prio_then_name(MODS, "modsSorted")

            for _, m in ipairs_local(MODS) do
                if m.enabled and not BLACKLIST[m.name] then
                    local ok, patch = pcall_local(m.fn, client, view)
                    if not ok then
                        if not WARNED[m.name] then
                            WARNED[m.name] = true
                            MsgC(Color(255,80,80), "[viewstack] Modifier error in ", m.name, ": ", tostring_local(patch), "\n")
                        end
                    elseif istable_local(patch) then
                        merge_view(view, patch)
                    end
                end
            end
        end

        -- 2) run captured legacy hooks (only if they exist)
        if CAPTURED and #CAPTURED > 0 then
            sort_by_prio_then_name(CAPTURED) -- Legacy hooks always get sorted
            for _, h in ipairs_local(CAPTURED) do
                if h.enabled and not BLACKLIST[h.name] then
                    local patch = safe_call(h.name, h.fn, client, view.origin, view.angles, view.fov, view.znear, view.zfar)
                    if istable_local(patch) then
                        merge_view(view, patch)
                    end
                end
            end
        end

        return view
    end)

    hook.Add("CalcViewModelView", "__ax_viewstack_viewmodel_dispatcher", function(weapon, viewmodel, oldPos, oldAng, pos, ang)
        update_perf_stats()

        -- Base viewmodel view seeded from engine params
        local viewmodelView = {
            pos = pos,
            ang = ang,
        }

        -- Early bailout: skip if no modifiers and no captured hooks
        local hasWork = #MODS_VIEWMODEL > 0 or (CAPTURED_VIEWMODEL and #CAPTURED_VIEWMODEL > 0)
        if not hasWork then return pos, ang end

        -- 1) run modern viewmodel modifiers (sort only when needed)
        if #MODS_VIEWMODEL > 0 then
            sort_by_prio_then_name(MODS_VIEWMODEL, "viewmodelModsSorted")

            for _, m in ipairs_local(MODS_VIEWMODEL) do
                if m.enabled and not BLACKLIST[m.name] then
                    local ok, patch = pcall_local(m.fn, weapon, viewmodelView)
                    if not ok then
                        if not WARNED[m.name] then
                            WARNED[m.name] = true
                            MsgC(Color(255,80,80), "[viewstack] ViewModelModifier error in ", m.name, ": ", tostring_local(patch), "\n")
                        end
                    elseif istable_local(patch) then
                        merge_viewmodel_view(viewmodelView, patch)
                    end
                end
            end
        end

        -- 2) run captured legacy viewmodel hooks (only if they exist)
        if CAPTURED_VIEWMODEL and #CAPTURED_VIEWMODEL > 0 then
            sort_by_prio_then_name(CAPTURED_VIEWMODEL) -- Legacy hooks always get sorted
            for _, h in ipairs_local(CAPTURED_VIEWMODEL) do
                if h.enabled and not BLACKLIST[h.name] then
                    local patch = safe_call_viewmodel(h.name, h.fn, weapon, viewmodel, oldPos, oldAng, viewmodelView.pos, viewmodelView.ang)
                    if istable_local(patch) then
                        merge_viewmodel_view(viewmodelView, patch)
                    end
                end
            end
        end

        return viewmodelView.pos, viewmodelView.ang
    end)
end

--- Remove dispatcher and restore captured hooks (if needed).
function ax.viewstack:Disable()
    hook.Remove("CalcView", "__ax_viewstack_dispatcher")
    hook.Remove("CalcViewModelView", "__ax_viewstack_viewmodel_dispatcher")
    if CAPTURED then
        for _, h in ipairs(CAPTURED) do
            if h.fn and isfunction(h.fn) then
                hook.Add("CalcView", h.name, h.fn)
            end
        end
    end
    if CAPTURED_VIEWMODEL then
        for _, h in ipairs(CAPTURED_VIEWMODEL) do
            if h.fn and isfunction(h.fn) then
                hook.Add("CalcViewModelView", h.name, h.fn)
            end
        end
    end
end

-- Convenience: simple offset/lerp helpers you can use in modifiers.
function ax.viewstack:Offset(vec, ang, fovDelta)
    return function(_, view)
        local patch = {}
        if vec then patch.origin = view.origin + vec end
        if ang then patch.angles = Angle(view.angles.p + ang.p, view.angles.y + ang.y, view.angles.r + ang.r) end
        if fovDelta then patch.fov = (view.fov or 90) + fovDelta end
        return patch
    end
end

function ax.viewstack:Lerp(alpha, target)
    alpha = math.Clamp(alpha or 0, 0, 1)
    return function(_, view)
        local p = {}
        if target.origin then p.origin = LerpVector(alpha, view.origin, target.origin) end
        if target.angles then p.angles = LerpAngle(alpha, view.angles, target.angles) end
        if target.fov    then p.fov    = Lerp(alpha, view.fov or 90, target.fov) end
        if target.znear  then p.znear  = Lerp(alpha, view.znear or 0, target.znear) end
        if target.zfar   then p.zfar   = Lerp(alpha, view.zfar  or 0, target.zfar) end
        if target.drawviewer ~= nil then p.drawviewer = (alpha >= 1) and target.drawviewer or view.drawviewer end
        return p
    end
end

-- Convenience: simple offset/lerp helpers you can use in viewmodel modifiers.
function ax.viewstack:ViewModelOffset(vec, ang, fovDelta)
    return function(_, viewmodel)
        local patch = {}
        if vec then patch.pos = viewmodel.pos + vec end
        if ang then patch.ang = Angle(viewmodel.ang.p + ang.p, viewmodel.ang.y + ang.y, viewmodel.ang.r + ang.r) end
        if fovDelta then patch.fov = (viewmodel.fov or 90) + fovDelta end
        return patch
    end
end

function ax.viewstack:ViewModelLerp(alpha, target)
    alpha = math.Clamp(alpha or 0, 0, 1)
    return function(_, viewmodel)
        local p = {}
        if target.pos then p.pos = LerpVector(alpha, viewmodel.pos, target.pos) end
        if target.ang then p.ang = LerpAngle(alpha, viewmodel.ang, target.ang) end
        if target.fov then p.fov = Lerp(alpha, viewmodel.fov or 90, target.fov) end
        return p
    end
end

-- Auto-enable after all scripts have had a chance to add their hooks
-- (timer 0 yields one frame; also re-run on code reload)
local function boot()
    timer.Simple(0, function()
        if ax.viewstack.__booted then return end
        ax.viewstack.__booted = true
        ax.viewstack:Enable()
        MsgC(Color(120,200,255), "[viewstack] Enabled. Captured and stacked CalcView and CalcViewModelView hooks.\n")
    end)
end

boot()

-- Clean up existing hook to prevent duplicates on reload
hook.Remove("OnReloaded", "ax.viewstack.reload")

hook.Add("OnReloaded", "ax.viewstack.reload", function()
    ax.viewstack:Disable()
    ax.viewstack.__booted = false
    boot()
end)
