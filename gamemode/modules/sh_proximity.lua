--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "Proximity"
MODULE.description = "A proximity styled voice chat modifier."
MODULE.author = "Riggs"

ax.config:Add("proximity", ax.type.bool, true, { category = "audio", subCategory = "proximity", description = "Whether or not the proximity system is enabled." })
ax.config:Add("proximityMuteVolume", ax.type.number, 10, { category = "audio", subCategory = "proximity", description = "The volume to set when a player is muted.", min = 0, max = 100, decimals = 0 })
ax.config:Add("proximityUnMutedDistance", ax.type.number, 10, { category = "audio", subCategory = "proximity", description = "The distance at which a player is unmuted.", min = 0, max = 100, decimals = 0 })
ax.config:Add("proximityMaxTraces", ax.type.number, 5, { category = "audio", subCategory = "proximity", description = "The maximum number of traces to perform when calculating voice volume.", min = 1, max = 20, decimals = 0 })
ax.config:Add("proximityMaxDistance", ax.type.number, 1000, { category = "audio", subCategory = "proximity", description = "The maximum distance for full volume reduction.", min = 0, max = 10000, decimals = 0 })
ax.config:Add("proximityMaxVolume", ax.type.number, 1, { category = "audio", subCategory = "proximity", description = "The maximum voice volume allowed.", min = 0, max = 1, decimals = 2 })

if ( SERVER ) then return end

-- Cache for voice volumes to smooth transitions and reduce recalculation
local voiceVolumeCache = {}
local volumeTargets = {}

-- Cached config values to avoid repeated lookups
local cachedConfig = {
    maxTraces = 5,
    maxDistance = 1000,
    maxVolume = 1,
    nextConfigUpdate = 0
}

-- Update config cache periodically (every 5 seconds)
local function UpdateConfigCache()
    if ( CurTime() < cachedConfig.nextConfigUpdate ) then return end
    cachedConfig.nextConfigUpdate = CurTime() + 5

    cachedConfig.maxTraces = ax.config:Get("proximityMaxTraces")
    cachedConfig.maxDistance = ax.config:Get("proximityMaxDistance")
    cachedConfig.maxVolume = ax.config:Get("proximityMaxVolume")
end

-- Pre-allocate trace structure to avoid table creation overhead
local traceData = {
    start = Vector(0, 0, 0),
    endpos = Vector(0, 0, 0),
    filter = {},
    mask = MASK_SOLID_BRUSHONLY -- Only check world geometry, ignore entities
}

local function CalculateVoiceVolume(listener, speaker, listenerEyePos, speakerEyePos, distSqr)
    -- Early distance check - skip expensive traces if too far
    local maxDistSqr = cachedConfig.maxDistance * cachedConfig.maxDistance
    if ( distSqr > maxDistSqr ) then
        return 0
    end

    -- Calculate distance factor first (cheap operation)
    local distance = math.sqrt(distSqr)
    local distanceFactor = 1 - ( distance / cachedConfig.maxDistance )
    distanceFactor = math.Clamp(distanceFactor, 0, 1)

    -- If very far away, skip traces entirely
    if ( distanceFactor < 0.05 ) then
        return 0
    end

    -- Perform occlusion traces (expensive operation)
    local totalVolume = 0
    local maxTraces = cachedConfig.maxTraces

    -- Reuse trace structure
    traceData.start = listenerEyePos
    traceData.filter[1] = listener
    traceData.filter[2] = speaker

    for i = 1, maxTraces do
        -- Use random offsets for better occlusion detection
        local offset = VectorRand() * 16
        traceData.endpos = speakerEyePos + offset

        local trace = util.TraceLine(traceData)

        if ( trace.Hit and trace.HitWorld ) then
            -- Apply occlusion penalty based on how early the trace hit
            local volume = 1 - ( trace.Fraction * 0.5 )
            totalVolume = totalVolume + volume
        else
            totalVolume = totalVolume + 1
        end
    end

    -- Calculate final volume
    local averageVolume = ( totalVolume / maxTraces ) * distanceFactor

    -- Apply vehicle modifiers
    if ( speaker:InVehicle() ) then
        averageVolume = averageVolume * 0.9
    end

    if ( listener:InVehicle() and listener:GetVehicle() != speaker:GetVehicle() ) then
        averageVolume = averageVolume * 0.8
    end

    return math.Clamp(averageVolume, 0, cachedConfig.maxVolume)
end

local nextThink = 0
local THINK_INTERVAL = 0.33 -- Think interval in seconds
local VOLUME_LERP_SPEED = 8 -- Smooth volume transitions

function MODULE:Think()
    if ( CurTime() < nextThink ) then return end
    nextThink = CurTime() + THINK_INTERVAL

    if ( !ax.config:Get("proximity") ) then return end

    local listener = ax.client
    if ( !IsValid(listener) ) then return end

    -- Update config cache
    UpdateConfigCache()

    -- Cache listener position (avoid multiple calls)
    local listenerEyePos = listener:EyePos()
    local ft = FrameTime()

    -- Process each speaker
    for _, speaker in ipairs(player.GetAll()) do
        if ( !IsValid(speaker) or speaker == listener or !speaker:IsSpeaking() ) then
            continue
        end

        if ( hook.Run("ShouldModifyVoiceVolume", listener, speaker) == false ) then
            local speakerID = speaker:EntIndex()
            volumeTargets[speakerID] = cachedConfig.maxVolume
            voiceVolumeCache[speakerID] = cachedConfig.maxVolume
            speaker:SetVoiceVolumeScale(cachedConfig.maxVolume)
            continue
        end

        local speakerID = speaker:EntIndex()

        -- Early distance check using squared distance (avoids sqrt)
        local speakerEyePos = speaker:EyePos()
        local distSqr = listenerEyePos:DistToSqr(speakerEyePos)

        -- Skip very distant players entirely (beyond max distance)
        if ( distSqr > cachedConfig.maxDistance * cachedConfig.maxDistance * 1.1 ) then
            volumeTargets[speakerID] = 0
            speaker:SetVoiceVolumeScale(0)
            continue
        end

        -- Calculate target volume
        local targetVolume = CalculateVoiceVolume(listener, speaker, listenerEyePos, speakerEyePos, distSqr)

        -- Initialize cache if needed
        if ( !voiceVolumeCache[speakerID] ) then
            voiceVolumeCache[speakerID] = targetVolume
        end

        -- Smooth volume transitions using lerp
        volumeTargets[speakerID] = targetVolume
        local currentVolume = voiceVolumeCache[speakerID]
        local smoothedVolume = Lerp(math.Clamp(ft * VOLUME_LERP_SPEED, 0, 1), currentVolume, targetVolume)

        voiceVolumeCache[speakerID] = smoothedVolume
        speaker:SetVoiceVolumeScale(smoothedVolume)
    end
end

-- Cleanup cache when players leave
hook.Add("EntityRemoved", "ax.proximity.cleanup", function(ent)
    if ( !ax.util:IsValidPlayer(ent) ) then return end

    local entIndex = ent:EntIndex()
    voiceVolumeCache[entIndex] = nil
    volumeTargets[entIndex] = nil
end)
