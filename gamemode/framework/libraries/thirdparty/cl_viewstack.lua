--[[
    ax.viewstack — Stacked CalcView dispatcher for Garry's Mod
    ----------------------------------------------------------
    Purpose:
      GMod stops calling further CalcView hooks after the first non-nil return.
      This shim captures existing CalcView hooks, removes them, then replaces
      CalcView with a single dispatcher that calls everyone and merges results.

    Behavior:
      - Legacy hooks: called as fn(ply, origin, angles, fov, znear, zfar).
        If they return (pos, ang, fov) or a table { origin, angles, fov, znear, zfar, drawviewer },
        we merge into the current view. Missing fields are ignored.
      - Modifier API: register with ax.viewstack.RegisterModifier(name, fn, priority).
        Your fn gets (ply, view) and returns either nil (no change) or a (partial) view table.

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

local CAPTURED   = nil           -- array of { name, fn, prio, enabled=true }
local MODS       = {}            -- array of { name, fn, prio, enabled=true }
local BLACKLIST  = {}            -- [name]=true
local PRIORITY   = {}            -- [name]=number
local WARNED     = {}            -- [name]=true (already logged error once)

-- Utility: shallow merge, last write wins
local function merge_view(base, patch)
    if not patch then return base end
    base.origin      = patch.origin      or base.origin
    base.angles      = patch.angles      or base.angles
    base.fov         = patch.fov         or base.fov
    base.znear       = patch.znear       or base.znear
    base.zfar        = patch.zfar        or base.zfar
    base.drawviewer  = (patch.drawviewer ~= nil) and patch.drawviewer or base.drawviewer
    return base
end

-- Normalize any CalcView-style returns into a table or nil
local function normalize_returns(a, b, c, d, e, f)
    -- Table return
    if istable(a) then return a end
    -- Tuple return: pos, ang, fov (ignore extra returns; GMod doesn’t use them here)
    if a ~= nil or b ~= nil or c ~= nil then
        return {
            origin = a,
            angles = b,
            fov    = c,
            -- d/e/f could be znear/zfar/drawviewer in some custom hooks; keep if typed right
            znear  = isnumber(d) and d or nil,
            zfar   = isnumber(e) and e or nil,
            drawviewer = isbool(f) and f or nil
        }
    end
    return nil
end

local function safe_call(name, fn, ...)
    local ok, a, b, c, d, e, f = pcall(fn, ...)
    if not ok then
        if not WARNED[name] then
            WARNED[name] = true
            MsgC(Color(255,80,80), "[viewstack] Hook error in ", name, ": ", tostring(a), "\n")
        end
        return nil
    end
    return normalize_returns(a, b, c, d, e, f)
end

local function sort_by_prio_then_name(list)
    table.sort(list, function(x, y)
        local px = x.prio or 0
        local py = y.prio or 0
        if px ~= py then return px < py end
        return tostring(x.name) < tostring(y.name)
    end)
end

-- Capture existing CalcView hooks and remove them from the hook system.
local function capture_legacy()
    CAPTURED = {}
    local t = hook.GetTable() or {}
    local cv = t["CalcView"] or {}

    -- Preserve capture order: iterate then record insertion index as implicit order
    for name, fn in pairs(cv) do
        if isfunction(fn) and name ~= "__ax_viewstack_dispatcher" then
            table.insert(CAPTURED, {
                name    = name,
                fn      = fn,
                prio    = PRIORITY[name] or 0,
                enabled = not BLACKLIST[name]
            })
            hook.Remove("CalcView", name)
        end
    end
end

-- Public API

--- Register a modifier that gets (ply, view) and returns a (partial) view table or nil.
function ax.viewstack:RegisterModifier(name, fn, priority)
    assert(isstring(name) and name ~= "", "Modifier needs a name")
    assert(isfunction(fn), "Modifier needs a function")
    table.insert(MODS, { name = name, fn = fn, prio = tonumber(priority) or 0, enabled = true })
    sort_by_prio_then_name(MODS)
end

--- Blacklist a legacy hook (or modifier) by name.
function ax.viewstack:Blacklist(name, state)
    BLACKLIST[name] = state ~= false
    -- Apply to captured + mods immediately
    if CAPTURED then
        for _, h in ipairs(CAPTURED) do
            if h.name == name then h.enabled = not BLACKLIST[name] end
        end
    end
    for _, m in ipairs(MODS) do
        if m.name == name then m.enabled = not BLACKLIST[name] end
    end
end

--- Set priority for a legacy hook (captured) or modifier. Lower number runs earlier.
function ax.viewstack:SetPriority(name, prio)
    PRIORITY[name] = tonumber(prio) or 0
    if CAPTURED then
        for _, h in ipairs(CAPTURED) do
            if h.name == name then h.prio = PRIORITY[name] end
        end
        sort_by_prio_then_name(CAPTURED)
    end
    for _, m in ipairs(MODS) do
        if m.name == name then m.prio = PRIORITY[name] end
    end
    sort_by_prio_then_name(MODS)
end

--- Rebuild capture and (re)install dispatcher.
function ax.viewstack:Enable()
    capture_legacy()

    hook.Add("CalcView", "__ax_viewstack_dispatcher", function(ply, origin, angles, fov, znear, zfar)
        -- Base view seeded from engine params
        local view = {
            origin = origin,
            angles = angles,
            fov    = fov,
            znear  = znear,
            zfar   = zfar,
            drawviewer = false
        }

        -- 1) run modern modifiers
        for _, m in ipairs(MODS) do
            if m.enabled and not BLACKLIST[m.name] then
                local ok, patch = pcall(m.fn, ply, view)
                if not ok then
                    if not WARNED[m.name] then
                        WARNED[m.name] = true
                        MsgC(Color(255,80,80), "[viewstack] Modifier error in ", m.name, ": ", tostring(patch), "\n")
                    end
                else
                    if istable(patch) then
                        merge_view(view, patch)
                    end
                end
            end
        end

        -- 2) run captured legacy hooks
        if CAPTURED and #CAPTURED > 0 then
            sort_by_prio_then_name(CAPTURED) -- stable + applies priority changes
            for _, h in ipairs(CAPTURED) do
                if h.enabled and not BLACKLIST[h.name] then
                    local patch = safe_call(h.name, h.fn, ply, view.origin, view.angles, view.fov, view.znear, view.zfar)
                    if istable(patch) then
                        merge_view(view, patch)
                    end
                end
            end
        end

        return view
    end)
end

--- Remove dispatcher and restore captured hooks (if needed).
function ax.viewstack:Disable()
    hook.Remove("CalcView", "__ax_viewstack_dispatcher")
    if CAPTURED then
        for _, h in ipairs(CAPTURED) do
            if h.fn and isfunction(h.fn) then
                hook.Add("CalcView", h.name, h.fn)
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

-- Auto-enable after all scripts have had a chance to add their hooks
-- (timer 0 yields one frame; also re-run on code reload)
local function boot()
    timer.Simple(0, function()
        if ax.viewstack.__booted then return end
        ax.viewstack.__booted = true
        ax.viewstack:Enable()
        MsgC(Color(120,200,255), "[viewstack] Enabled. Captured and stacked CalcView hooks.\n")
    end)
end

boot()

hook.Add("OnReloaded", "ax.viewstack.reload", function()
    ax.viewstack.__booted = false
    boot()
end)
