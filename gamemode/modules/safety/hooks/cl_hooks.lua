--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local LOWERED_POS = Vector(0, 0, 0)
local LOWERED_ANGLES = Angle(10, 10, 0)
local LOWERED_LERP = {pos = Vector(0, 0, 0), angles = Angle(0, 0, 0)}

ax.viewstack:RegisterViewModelModifier("safety", function(weapon, patch)
    local client = ax.client
    if ( !IsValid(client) ) then return end

    local targetPos = LOWERED_POS
    local targetAngles = LOWERED_ANGLES
    if ( IsValid(weapon) and weapon:IsWeapon() ) then
        if ( weapon.LoweredPos ) then
            targetPos = weapon.LoweredPos
        end

        if ( weapon.LoweredAngles ) then
            targetAngles = weapon.LoweredAngles
        end
    end

    if ( IsValid(weapon) and !client:IsWeaponRaised() ) then
        LOWERED_LERP.pos = Lerp(FrameTime() * 4, LOWERED_LERP.pos, targetPos)
        LOWERED_LERP.angles = LerpAngle(FrameTime() * 4, LOWERED_LERP.angles, targetAngles)
    else
        LOWERED_LERP.pos = Lerp(FrameTime() * 4, LOWERED_LERP.pos, vector_origin)
        LOWERED_LERP.angles = LerpAngle(FrameTime() * 4, LOWERED_LERP.angles, angle_zero)
    end

    if ( !LOWERED_LERP.pos or !LOWERED_LERP.angles ) then return end

    local pos = patch.pos + LOWERED_LERP.pos
    local ang = patch.ang + LOWERED_LERP.angles

    return {
        pos = pos,
        ang = ang
    }
end, 1)
