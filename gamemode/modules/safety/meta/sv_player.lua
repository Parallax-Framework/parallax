--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local player = ax.player.meta or FindMetaTable("Player")

--- Sets whether this player's active weapon is raised. Updates the `ax.weapon.raised` relay state, forwards the state to the active weapon when it implements `SetWeaponRaised`, and fires `PlayerWeaponRaised`. Passing nil defaults to true.
---@realm server
---@param bRaised boolean|nil True to raise the weapon, false to lower it. Defaults to true.
---@usage client:SetWeaponRaised(false)
function player:SetWeaponRaised(bRaised)
    if ( bRaised == nil ) then bRaised = true end

    self:SetRelay("ax.weapon.raised", bRaised)

    local weapon = self:GetActiveWeapon()
    if ( type(weapon) == "Weapon" and weapon:IsWeapon() and isfunction(weapon.SetWeaponRaised) ) then
        weapon:SetWeaponRaised(bRaised)
    end

    hook.Run("PlayerWeaponRaised", self, bRaised)
end

--- Toggles this player's weapon raised state. Reads the current `ax.weapon.raised` relay value and applies the inverse via `SetWeaponRaised`.
---@realm server
---@usage client:ToggleWeaponRaise()
function player:ToggleWeaponRaise()
    local bRaised = self:GetRelay("ax.weapon.raised", false)
    self:SetWeaponRaised(!bRaised)
end
