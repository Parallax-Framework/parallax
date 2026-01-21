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

-- Hysteresis parameters (same as server)
local HYSTERESIS_TIME = 0.5
local HYSTERESIS_MARGIN = 5
local hysteresis = {
    candidate = nil,
    since = 0,
}

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
    for _, zone in ipairs(state.physical) do
        oldPhysicalSet[zone.id] = zone
    end

    local newPhysicalSet = {}
    for _, zone in ipairs(newPhysical) do
        newPhysicalSet[zone.id] = zone
    end

    -- Fire enter events
    for zoneId, zone in pairs(newPhysicalSet) do
        if ( !oldPhysicalSet[zoneId] ) then
            hook.Run("ax.ZoneEntered", client, zone)
        end
    end

    -- Fire exit events
    for zoneId, zone in pairs(oldPhysicalSet) do
        if ( !newPhysicalSet[zoneId] ) then
            hook.Run("ax.ZoneExited", client, zone)
        end
    end

    -- Check visible zone changes
    local oldVisibleSet = {}
    for _, zone in ipairs(state.visible) do
        oldVisibleSet[zone.id] = zone
    end

    local newVisibleSet = {}
    for _, zone in ipairs(newVisible) do
        newVisibleSet[zone.id] = zone
    end

    -- Fire seen events
    for zoneId, zone in pairs(newVisibleSet) do
        if ( !oldVisibleSet[zoneId] ) then
            hook.Run("ax.ZoneSeen", client, zone)
        end
    end

    -- Fire unseen events
    for zoneId, zone in pairs(oldVisibleSet) do
        if ( !newVisibleSet[zoneId] ) then
            hook.Run("ax.ZoneUnseen", client, zone)
        end
    end

    -- Handle dominant zone with hysteresis
    local oldDominant = state.dominant

    if ( newDominant != oldDominant ) then
        -- If no candidate or candidate changed, start timer
        if ( !hysteresis.candidate or (newDominant and hysteresis.candidate.id != newDominant.id) ) then
            hysteresis.candidate = newDominant
            hysteresis.since = now
        end

        -- Check if hysteresis time elapsed or priority difference is large
        local elapsed = now - hysteresis.since
        local priorityDiff = 0

        if ( newDominant and oldDominant ) then
            priorityDiff = math.abs(newDominant.priority - oldDominant.priority)
        end

        if ( elapsed >= HYSTERESIS_TIME or priorityDiff >= HYSTERESIS_MARGIN ) then
            -- Switch dominant
            state.dominant = newDominant
            hysteresis.candidate = nil
            hysteresis.since = 0

            hook.Run("ax.ZoneChanged", client, oldDominant, newDominant)
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
    if ( CurTime() - state.lastCheck < 0.1 ) then return end

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
