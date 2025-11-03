--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.Name = "Third Person"
MODULE.Description = "Adds third-person camera functionality to the gamemode."
MODULE.Author = "Riggs"

ax.config:Add("thirdperson", ax.type.bool, true, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Enable third-person camera functionality in the gamemode.",
    bNoNetworking = true
})

ax.option:Add("thirdperson", ax.type.bool, false, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Toggle third-person camera.",
    bNoNetworking = true
})

ax.option:Add("thirdpersonX", ax.type.number, 25, {
    category = "camera",
    subCategory = "thirdperson",
    description = "X offset for third-person camera.",
    bNoNetworking = true,
    min = -100,
    max = 100,
    decimals = 0
})

ax.option:Add("thirdpersonY", ax.type.number, 0, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Y offset for third-person camera.",
    bNoNetworking = true,
    min = -100,
    max = 100,
    decimals = 0
})

ax.option:Add("thirdpersonZ", ax.type.number, -50, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Z offset for third-person camera.",
    bNoNetworking = true,
    min = -100,
    max = 100,
    decimals = 0
})

ax.option:Add("thirdpersonFollowHead", ax.type.bool, true, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Make the third-person camera follow the player's model head movements.",
    bNoNetworking = true
})

ax.option:Add("thirdpersonFollowTraceAngles", ax.type.bool, true, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Make the third-person camera follow the player's aim direction instead of view angles.",
    bNoNetworking = true
})

ax.option:Add("thirdpersonFollowTraceFieldOfView", ax.type.bool, true, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Make the third-person camera FOV calculated based on the distance from the trace end point to the player.",
    bNoNetworking = true
})

ax.option:Add("thirdpersonDesiredPositionInterpolation", ax.type.number, 5, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Interpolation speed for the third-person camera desired position. Lower values will be more smooth but also more slower to respond. Set to 0 to disable interpolation.",
    bNoNetworking = true,
    min = 0,
    max = 20,
    decimals = 0
})

ax.option:Add("thirdpersonDesiredAngleInterpolation", ax.type.number, 5, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Interpolation speed for the third-person camera desired angle. Lower values will be more smooth but also more slower to respond. Set to 0 to disable interpolation.",
    bNoNetworking = true,
    min = 0,
    max = 20,
    decimals = 0
})

ax.option:Add("thirdpersonDesiredFieldOfViewInterpolation", ax.type.number, 5, {
    category = "camera",
    subCategory = "thirdperson",
    description = "Interpolation speed for the third-person camera desired FOV. Lower values will be more smooth but also more slower to respond. Set to 0 to disable interpolation.",
    bNoNetworking = true,
    min = 0,
    max = 20,
    decimals = 0
})

ax.localisation:Register("en", {
    thirdperson = "Third Person",
    thirdpersonX = "Third Person X Offset",
    thirdpersonY = "Third Person Y Offset",
    thirdpersonZ = "Third Person Z Offset",
    thirdpersonFollowHead = "Third Person Follow Head",
    thirdpersonFollowTraceAngles = "Third Person Follow Trace Angles",
    thirdpersonFollowTraceFieldOfView = "Third Person Follow Trace Field Of View",
    thirdpersonDesiredPositionInterpolation = "Third Person Desired Position Interpolation",
    thirdpersonDesiredAngleInterpolation = "Third Person Desired Angle Interpolation",
    thirdpersonDesiredFieldOfViewInterpolation = "Third Person Desired Field Of View Interpolation"
})

ax.localisation:Register("bg", {
    thirdperson = "Трето лице",
    thirdpersonX = "X изместване на камерата от трето лице",
    thirdpersonY = "Y изместване на камерата от трето лице",
    thirdpersonZ = "Z изместване на камерата от трето лице",
    thirdpersonFollowHead = "Камерата от трето лице следва главата",
    thirdpersonFollowTraceAngles = "Камерата от трето лице следва ъглите на траса",
    thirdpersonFollowTraceFieldOfView = "Полето на виждане на камерата от трето лице следва траса",
    thirdpersonDesiredPositionInterpolation = "Интерполация на желаната позиция на камерата от трето лице",
    thirdpersonDesiredAngleInterpolation = "Интерполация на желания ъгъл на камерата от трето лице",
    thirdpersonDesiredFieldOfViewInterpolation = "Интерполация на желаното поле на виждане на камерата от трето лице"
})

if ( SERVER ) then return end

local FIXED_RADIUS = 6
local curPos
local curAng
local curFOV

-- LVS is gay and already used the ShouldDrawThirdPerson hook, so we have to use a different name
function MODULE:ShouldUseThirdPerson(client)
    if ( !client:Alive() or client:InVehicle() or client:GetObserverMode() != OBS_MODE_NONE or !client:Alive() or client:GetMoveType() == MOVETYPE_NOCLIP ) then
        return false
    end

    if ( !ax.config:Get("thirdperson") ) then
        return false
    end

    return ax.option:Get("thirdperson")
end

ax.viewstack:RegisterModifier("thirdperson", function(client, view)
    if ( hook.Run("ShouldUseThirdPerson", client) == false ) then return end

    if ( !curPos ) then
        curPos = view.origin
    end

    if ( !curAng ) then
        curAng = view.angles
    end

    if ( !curFOV ) then
        curFOV = 0
    end

    -- start from the player's eye position
    local startPos = client:EyePos()
    local head = client:LookupBone("ValveBiped.Bip01_Head1")
    if ( ax.option:Get("thirdpersonFollowHead") and head ) then
        local headPos, _ = client:GetBonePosition(head)
        if ( headPos ) then
            startPos = headPos
        end
    end

    local ang = view.angles

    -- desired camera offset relative to view angles
    local desiredPos = startPos + ang:Forward() * ax.option:Get("thirdpersonZ") + ang:Right() * ax.option:Get("thirdpersonX") + ang:Up() * ax.option:Get("thirdpersonY")

    local traceCamera = util.TraceHull({
        start = startPos,
        endpos = desiredPos,
        mins = Vector(-FIXED_RADIUS, -FIXED_RADIUS, -FIXED_RADIUS),
        maxs = Vector(FIXED_RADIUS, FIXED_RADIUS, FIXED_RADIUS),
        filter = client,
        mask = MASK_SOLID
    })

    if ( traceCamera.Hit ) then
        desiredPos = traceCamera.HitPos - ang:Forward() * FIXED_RADIUS
    end

    local trace = util.TraceLine({
        start = client:GetShootPos(),
        endpos = client:GetShootPos() + client:GetAimVector() * 2048,
        filter = client,
        mask = MASK_SOLID
    })

    local desiredAng = ang
    if ( ax.option:Get("thirdpersonFollowTraceAngles") ) then
        local traceAng = (trace.HitPos - desiredPos):Angle()
        desiredAng = traceAng
    end

    local desiredFOV = 0

    local posInterpSpeed = ax.option:Get("thirdpersonDesiredPositionInterpolation")
    local angInterpSpeed = ax.option:Get("thirdpersonDesiredAngleInterpolation")
    local fovInterpSpeed = ax.option:Get("thirdpersonDesiredFieldOfViewInterpolation")

    local ft = math.Clamp(FrameTime(), 0, 0.1)
    if ( posInterpSpeed > 0 ) then
        curPos = LerpVector(ft * posInterpSpeed, curPos, desiredPos)
    else
        curPos = desiredPos
    end

    if ( angInterpSpeed > 0 ) then
        curAng = LerpAngle(ft * angInterpSpeed, curAng, desiredAng)
    else
        curAng = desiredAng
    end

    if ( ax.option:Get("thirdpersonFollowTraceFieldOfView") ) then
        local distance = trace.StartPos:Distance(trace.HitPos)
        desiredFOV = math.Remap(distance / 4, 0, 2048, 0, 75)
    end

    if ( fovInterpSpeed > 0 ) then
        curFOV = Lerp(ft * fovInterpSpeed, curFOV, desiredFOV)
    else
        curFOV = desiredFOV
    end

    return {
        origin = curPos,
        angles = curAng,
        fov = view.fov - curFOV,
        drawviewer = true
    }
end, 1)

concommand.Add("ax_thirdperson_toggle", function(client, cmd, args)
    ax.option:Set("thirdperson", !ax.option:Get("thirdperson"))
end)
