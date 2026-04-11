--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- @module ax.zones

ax.zones = ax.zones or {}

-- Client-side tracking state for local player
ax.zones.clientTracking = ax.zones.clientTracking or {
    physical = {},
    visible = {},
    dominant = nil,
    lastCheck = 0,
}

local hysteresis = {
    candidate = nil,
    since = 0,
}

local function GetTrackingNumber(key, fallback, minValue, maxValue)
    local value = tonumber(fallback) or 0

    if ( ax and ax.config and ax.config.Get ) then
        value = tonumber(ax.config:Get(key, fallback)) or value
    end

    if ( minValue != nil ) then
        value = math.max(value, minValue)
    end

    if ( maxValue != nil ) then
        value = math.min(value, maxValue)
    end

    return value
end

--- Get the client's zone tracking state.
-- @realm client
-- @treturn table Tracking state with physical, visible, and dominant fields
function ax.zones:GetClientTracking()
    return self.clientTracking
end

--- Update client-side tracking for local player.
-- @realm client
local function UpdateClientTracking()
    local client = ax.client
    if ( !ax.util:IsValidPlayer(client) ) then return end

    local state = ax.zones.clientTracking
    local now = CurTime()
    state.lastCheck = now

    -- Get current zones
    local blend = ax.zones:BlendFor(client)
    local newPhysical = blend.physical
    local newVisible = blend.visible
    local newDominant = blend.dominant

    -- Check physical zone changes
    local oldPhysicalSet = {}
    for _ = 1, #state.physical do
        local zone = state.physical[_]
        oldPhysicalSet[zone.id] = zone
    end

    local newPhysicalSet = {}
    for _ = 1, #newPhysical do
        local zone = newPhysical[_]
        newPhysicalSet[zone.id] = zone
    end

    -- Fire enter events
    for zoneId, zone in pairs(newPhysicalSet) do
        if ( !oldPhysicalSet[zoneId] ) then
            hook.Run("OnZoneEntered", client, zone)
        end
    end

    -- Fire exit events
    for zoneId, zone in pairs(oldPhysicalSet) do
        if ( !newPhysicalSet[zoneId] ) then
            hook.Run("OnZoneExited", client, zone)
        end
    end

    -- Check visible zone changes
    local oldVisibleSet = {}
    for _ = 1, #state.visible do
        local zone = state.visible[_]
        oldVisibleSet[zone.id] = zone
    end

    local newVisibleSet = {}
    for _ = 1, #newVisible do
        local zone = newVisible[_]
        newVisibleSet[zone.id] = zone
    end

    -- Fire seen events
    for zoneId, zone in pairs(newVisibleSet) do
        if ( !oldVisibleSet[zoneId] ) then
            hook.Run("OnZoneSeen", client, zone)
        end
    end

    -- Fire unseen events
    for zoneId, zone in pairs(oldVisibleSet) do
        if ( !newVisibleSet[zoneId] ) then
            hook.Run("OnZoneUnseen", client, zone)
        end
    end

    -- Handle dominant zone with hysteresis
    local oldDominant = state.dominant
    local hysteresisTime = GetTrackingNumber("zones.tracking.hysteresis_time", 0.5, 0, 5)
    local hysteresisMargin = GetTrackingNumber("zones.tracking.hysteresis_margin", 5, 0, 100)
    local useLastDominant = ax.config:Get("zones.tracking.use_last_dominant", true) != false
    local nextDominant = newDominant

    if ( useLastDominant and !nextDominant and oldDominant ) then
        nextDominant = oldDominant
    end

    if ( nextDominant != oldDominant ) then
        -- If no candidate or candidate changed, start timer
        local candidateId = hysteresis.candidate and hysteresis.candidate.id or false
        local nextDominantId = nextDominant and nextDominant.id or false

        if ( candidateId != nextDominantId ) then
            hysteresis.candidate = nextDominant
            hysteresis.since = now
        end

        -- Check if hysteresis time elapsed or priority difference is large
        local elapsed = now - hysteresis.since
        local priorityDiff = 0

        if ( nextDominant and oldDominant ) then
            priorityDiff = math.abs(nextDominant.priority - oldDominant.priority)
        end

        if ( elapsed >= hysteresisTime or priorityDiff >= hysteresisMargin ) then
            -- Switch dominant
            state.dominant = nextDominant
            hysteresis.candidate = nil
            hysteresis.since = 0

            hook.Run("OnZoneChanged", client, oldDominant, nextDominant)
        end
    else
        -- Same dominant, reset hysteresis
        hysteresis.candidate = nil
        hysteresis.since = 0
    end

    -- Update state
    state.physical = newPhysical
    state.visible = newVisible
end

--- Tick hook to update client tracking.
hook.Add("Think", "ax.zones.clientTracking", function()
    if ( !ax.zones.clientTracking ) then return end

    -- Update at a reasonable rate (not every frame)
    local state = ax.zones.clientTracking
    local interval = GetTrackingNumber("zones.tracking.client_interval", 0.1, 0, 1)
    if ( CurTime() - state.lastCheck < interval ) then return end

    UpdateClientTracking()
end)

--- Reset client tracking when spawning.
hook.Add("OnReloaded", "ax.zones.clientTracking", function()
    ax.zones.clientTracking = {
        physical = {},
        visible = {},
        dominant = nil,
        lastCheck = 0,
    }

    hysteresis = {
        candidate = nil,
        since = 0,
    }
end)

ax.util:PrintDebug("Client zone tracking loaded")
