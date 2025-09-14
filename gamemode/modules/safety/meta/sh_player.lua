--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local ALWAYS_RAISED = {}
ALWAYS_RAISED["gmod_tool"] = true
ALWAYS_RAISED["gmod_camera"] = true
ALWAYS_RAISED["weapon_physgun"] = true

function ax.player.meta:IsWeaponRaised()
    if ( ax.config:Get("weapon.raise.alwaysraised", false) ) then return true end

    local weapon = self:GetActiveWeapon()
    if ( IsValid(weapon) and ( ALWAYS_RAISED[weapon:GetClass()] or weapon.AlwaysRaised ) ) then return true end

    return self:GetRelay("ax.weapon.raised", false)
end
