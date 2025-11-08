--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

function ax.player.meta:SetWeaponRaised(bRaised)
    if ( bRaised == nil ) then bRaised = true end

    self:SetRelay("ax.weapon.raised", bRaised)

    local weapon = self:GetActiveWeapon()
    if ( IsValid(weapon) and weapon:IsWeapon() and isfunction(weapon.SetWeaponRaised) ) then
        weapon:SetWeaponRaised(bRaised)
    end

    hook.Run("UpdateClientAnimations", self) -- Ensure animations are updated when weapon raise state changes

    hook.Run("PlayerWeaponRaised", self, bRaised)
end

function ax.player.meta:ToggleWeaponRaise()
    local bRaised = self:GetRelay("ax.weapon.raised", false)
    self:SetWeaponRaised(!bRaised)
end
