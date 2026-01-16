--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

AX_ALWAYS_RAISED = {}
AX_ALWAYS_RAISED["gmod_tool"] = true
AX_ALWAYS_RAISED["gmod_camera"] = true
AX_ALWAYS_RAISED["weapon_physgun"] = true
AX_ALWAYS_RAISED["swep_construction_kit"] = true

function ax.player.meta:IsWeaponRaised()
    if ( ax.config:Get("weapon.raise.alwaysraised", false) ) then return true end

    local weapon = self:GetActiveWeapon()
    if ( IsValid(weapon) and ( AX_ALWAYS_RAISED[weapon:GetClass()] or weapon.AlwaysRaised ) ) then return true end

    return self:GetRelay("ax.weapon.raised", false)
end
