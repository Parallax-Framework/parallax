--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

local KEY_SHOOT = IN_ATTACK + IN_ATTACK2
function MODULE:StartCommand(client, cmd)
    local weapon = client:GetActiveWeapon()
    if ( !IsValid(weapon) or !weapon:IsWeapon() ) then return end

    if ( !weapon.FireWhenLowered and !client:IsWeaponRaised() ) then
        cmd:RemoveKey(KEY_SHOOT)
    end
end