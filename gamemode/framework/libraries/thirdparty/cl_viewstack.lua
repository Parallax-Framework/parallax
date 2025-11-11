--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Viewstack library for managing camera and viewmodel modifications.
-- Provides a system to register, order, and apply multiple view modifiers.
-- Commonly used for effects like weapon sway, bobbing, and custom camera effects.
-- @module ax.viewstack

ax.viewstack = ax.viewstack or {}

local _seq = 0

local function seq()
    _seq = _seq + 1
    return _seq
end

local function safe_call(fn, ...)
    local ok, a, b, c, d = pcall(fn, ...)
    if ( !ok ) then return nil end

    return a, b, c, d
end

ax.viewstack.enabled = true
ax.viewstack.inCalc = false
ax.viewstack.inVM = false
ax.viewstack.camDirty = false
ax.viewstack.vmDirty = false
ax.viewstack.mods = ax.viewstack.mods or {}
ax.viewstack.modsVM = ax.viewstack.modsVM or {}

local function sort_mods(list)
    table.sort(list, function(a, b)
        if ( a.priority == b.priority ) then
            return a.order < b.order
        end

        return a.priority < b.priority
    end)
end

--- Enable the viewstack.
-- @treturn boolean true if enabled
function ax.viewstack:Enable()
    self.enabled = true
    return true
end

--- Disable the viewstack.
-- @treturn boolean false if disabled
function ax.viewstack:Disable()
    self.enabled = false
    return false
end

--- Register a camera modifier.
-- @tparam string name Unique key
-- @tparam function fn Signature: fn(client, view) -> patch or nil
-- @tparam[opt=50] number priority Lower runs first
-- @treturn boolean true if added
function ax.viewstack:RegisterModifier(name, fn, priority)
    self.mods[name] = {
        name = name,
        fn = fn,
        priority = tonumber(priority) or 50,
        enabled = true,
        order = seq()
    }

    self.camDirty = true

    return true
end

--- Unregister a camera modifier.
-- @tparam string name Unique key
-- @treturn boolean true if removed
function ax.viewstack:UnregisterModifier(name)
    local had = self.mods[name] != nil
    self.mods[name] = nil
    self.camDirty = true

    return had
end

--- Enable or disable a camera modifier.
-- @tparam string name Unique key
-- @tparam boolean enabled New state
-- @treturn boolean enabled state
function ax.viewstack:SetModifierEnabled(name, enabled)
    local m = self.mods[name]
    if ( !m ) then return false end
    m.enabled = !!enabled

    return m.enabled
end

--- Register a viewmodel modifier.
-- @tparam string name Unique key
-- @tparam function fn Signature: fn(weapon, patch) -> patch or nil
-- @tparam[opt=50] number priority Lower runs first
-- @treturn boolean true if added
function ax.viewstack:RegisterViewModelModifier(name, fn, priority)
    self.modsVM[name] = {
        name = name,
        fn = fn,
        priority = tonumber(priority) or 50,
        enabled = true,
        order = seq()
    }

    self.vmDirty = true

    return true
end

--- Unregister a viewmodel modifier.
-- @tparam string name Unique key
-- @treturn boolean true if removed
function ax.viewstack:UnregisterViewModelModifier(name)
    local had = self.modsVM[name] != nil
    self.modsVM[name] = nil
    self.vmDirty = true

    return had
end

--- Enable or disable a viewmodel modifier.
-- @tparam string name Unique key
-- @tparam boolean enabled New state
-- @treturn boolean enabled state
function ax.viewstack:SetViewModelModifierEnabled(name, enabled)
    local m = self.modsVM[name]
    if ( !m ) then return false end

    m.enabled = !!enabled

    return m.enabled
end

--- Get ordered camera modifiers.
-- @treturn table ordered list
function ax.viewstack:GetCameraPipeline()
    if ( self.camDirty ) then
        local list = {}
        for _, v in pairs(self.mods) do
            if v.enabled then list[#list + 1] = v end
        end

        sort_mods(list)

        self.cacheCam = list
        self.camDirty = false
    end

    return self.cacheCam or {}
end

--- Get ordered viewmodel modifiers.
-- @treturn table ordered list
function ax.viewstack:GetViewModelPipeline()
    if ( self.vmDirty ) then
        local list = {}
        for _, v in pairs(self.modsVM) do
            if v.enabled then list[#list + 1] = v end
        end

        sort_mods(list)

        self.cacheVM = list
        self.vmDirty = false
    end

    return self.cacheVM or {}
end

--- Run the camera pipeline.
-- @tparam Player client
-- @tparam table view {origin, angles, fov}
-- @treturn[opt] table final view or nil to fall back
function ax.viewstack:RunCamera(client, view)
    local changed = false
    local cur = { origin = view.origin, angles = view.angles, fov = view.fov, znear = view.znear, zfar = view.zfar, drawviewer = view.drawviewer }

    for _, m in ipairs(self:GetCameraPipeline()) do
        local patch = safe_call(m.fn, client, cur)
        if ( patch ) then
            if ( patch.origin ) then cur.origin = patch.origin end
            if ( patch.angles ) then cur.angles = patch.angles end
            if ( patch.fov ) then cur.fov = patch.fov end
            if ( patch.znear ) then cur.znear = patch.znear end
            if ( patch.zfar ) then cur.zfar = patch.zfar end
            if ( patch.drawviewer != nil ) then cur.drawviewer = patch.drawviewer end
            changed = true
        end
    end

    if ( changed ) then
        return {
            origin = cur.origin,
            angles = cur.angles,
            fov = cur.fov,
            znear = cur.znear,
            zfar = cur.zfar,
            drawviewer = cur.drawviewer
        }
    end
end

--- Run the viewmodel pipeline.
-- @tparam Weapon weapon
-- @tparam table patch {pos, ang, fov}
-- @treturn[opt] table final patch or nil to fall back
function ax.viewstack:RunViewModel(weapon, patch)
    local changed = false
    local cur = { pos = patch.pos, ang = patch.ang, fov = patch.fov }

    for _, m in ipairs(self:GetViewModelPipeline()) do
        local nextPatch = safe_call(m.fn, weapon, cur)
        if ( nextPatch ) then
            if ( nextPatch.pos ) then cur.pos = nextPatch.pos end
            if ( nextPatch.ang ) then cur.ang = nextPatch.ang end
            if ( nextPatch.fov ) then cur.fov = nextPatch.fov end
            changed = true
        end
    end

    if ( changed ) then
        return { pos = cur.pos, ang = cur.ang, fov = cur.fov }
    end
end

--- Internal: calc base camera view from hook args.
-- @tparam Player client
-- @tparam Vector origin
-- @tparam Angle angles
-- @tparam number fov
-- @treturn table base view
function ax.viewstack:BaseView(client, origin, angles, fov)
    return {
        origin = origin or client:EyePos(),
        angles = angles or client:EyeAngles(),
        fov = fov or client:GetFOV(),
        drawviewer = nil
    }
end

hook.Add("CalcView", "ax.viewstack.CalcView", function(client, origin, angles, fov, znear, zfar)
    if ( !ax.viewstack.enabled ) then return end
    if ( ax.viewstack.inCalc ) then return end
    ax.viewstack.inCalc = true

    -- Support for LVS, because they love breaking everything
    local pod = client:GetVehicle()
    local vehicle = client.lvsGetVehicle and client:lvsGetVehicle() or nil
    if ( IsValid(pod) and IsValid(vehicle) ) then
        ax.viewstack.inCalc = false
        return
    end

    local base = GAMEMODE.BaseClass:CalcView(client, origin, angles, fov, znear, zfar)
    base.znear = znear
    base.zfar = zfar

    local out = ax.viewstack:RunCamera(client, base)
    ax.viewstack.inCalc = false
    if ( out ) then
        return {
            origin = out.origin,
            angles = out.angles,
            fov = out.fov,
            znear = out.znear,
            zfar = out.zfar,
            drawviewer = out.drawviewer
        }
    end
end)

hook.Add("CalcViewModelView", "ax.viewstack.CalcViewModelView", function(weapon, viewmodel, oldPos, oldAng, newPos, newAng)
    if ( !ax.viewstack.enabled ) then return end

    if ( !IsValid(weapon) or !IsValid(viewmodel) ) then return end

    local client = weapon:GetOwner()
    if ( !IsValid(client) or !client:IsPlayer() or client != LocalPlayer() or client:InVehicle() or !client:Alive() ) then return end
    if ( hook.Run("ShouldDrawLocalPlayer", client) == true ) then return end

    if ( ax.viewstack.inVM ) then return end
    ax.viewstack.inVM = true

    local base = { pos = newPos, ang = newAng, fov = nil }
    local out = ax.viewstack:RunViewModel(weapon, base)
    ax.viewstack.inVM = false
    if ( out ) then
        return out.pos or newPos, out.ang or newAng, out.fov
    end
end)
