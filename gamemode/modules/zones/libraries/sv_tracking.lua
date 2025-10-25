--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- @module ax.zones

ax.zones = ax.zones or {}
ax.zones.tracked = ax.zones.tracked or {}

-- Hysteresis parameters for dominant zone switching
local HYSTERESIS_TIME = 0.5 -- Seconds to wait before switching dominant
local HYSTERESIS_MARGIN = 5 -- Priority margin to ignore flicker

--- Start tracking an entity for zone events.
-- @realm server
-- @tparam Entity ent Entity to track
function ax.zones:TrackEntity(ent)
    if ( !IsValid(ent) ) then return end

    local id = ent:EntIndex()
    if ( self.tracked[id] ) then return end

    self.tracked[id] = {
        entity = ent,
        physical = {},      -- Current physical zones
        visible = {},       -- Current visible zones
        dominant = nil,     -- Current dominant zone
        lastCheck = 0,
        hysteresis = {
            candidate = nil,
            since = 0,
        },
    }

    ax.util:PrintDebug("Now tracking entity " .. tostring(ent) .. " for zones")
end

--- Stop tracking an entity.
-- @realm server
-- @tparam Entity ent Entity to stop tracking
function ax.zones:UntrackEntity(ent)
    if ( !IsValid(ent) ) then return end

    local id = ent:EntIndex()
    self.tracked[id] = nil

    ax.util:PrintDebug("Stopped tracking entity " .. tostring(ent) .. " for zones")
end

--- Get tracking state for an entity.
-- @realm server
-- @tparam Entity ent Entity
-- @treturn table|nil Tracking state or nil
function ax.zones:GetTracking(ent)
    if ( !IsValid(ent) ) then return nil end
    return self.tracked[ent:EntIndex()]
end

--- Update tracking for a single entity.
-- @realm server
-- @tparam Entity ent Entity to update
local function UpdateTracking(ent)
    if ( !IsValid(ent) ) then return end

    local id = ent:EntIndex()
    local state = ax.zones.tracked[id]
    if ( !state ) then return end

    local now = CurTime()
    state.lastCheck = now

    -- Get current zones
    local blend = ax.zones:BlendFor(ent)
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
            hook.Run("ax.ZoneEntered", ent, zone)
        end
    end

    -- Fire exit events
    for zoneId, zone in pairs(oldPhysicalSet) do
        if ( !newPhysicalSet[zoneId] ) then
            hook.Run("ax.ZoneExited", ent, zone)
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
            hook.Run("ax.ZoneSeen", ent, zone)
        end
    end

    -- Fire unseen events
    for zoneId, zone in pairs(oldVisibleSet) do
        if ( !newVisibleSet[zoneId] ) then
            hook.Run("ax.ZoneUnseen", ent, zone)
        end
    end

    -- Handle dominant zone with hysteresis
    local oldDominant = state.dominant

    if ( newDominant != oldDominant ) then
        -- If no candidate or candidate changed, start timer
        if ( !state.hysteresis.candidate or (newDominant and state.hysteresis.candidate.id != newDominant.id) ) then
            state.hysteresis.candidate = newDominant
            state.hysteresis.since = now
        end

        -- Check if hysteresis time elapsed or priority difference is large
        local elapsed = now - state.hysteresis.since
        local priorityDiff = 0

        if ( newDominant and oldDominant ) then
            priorityDiff = math.abs(newDominant.priority - oldDominant.priority)
        end

        if ( elapsed >= HYSTERESIS_TIME or priorityDiff >= HYSTERESIS_MARGIN ) then
            -- Switch dominant
            state.dominant = newDominant
            state.hysteresis.candidate = nil
            state.hysteresis.since = 0

            hook.Run("ax.ZoneChanged", ent, oldDominant, newDominant)
        end
    else
        -- Same dominant, reset hysteresis
        state.hysteresis.candidate = nil
        state.hysteresis.since = 0
    end

    -- Update state
    state.physical = newPhysical
    state.visible = newVisible
end

--- Tick hook to update all tracked entities.
--[[
local nextTick = 0
hook.Add("Tick", "ax.zones.tracking", function()
    if ( CurTime() < nextTick ) then return end
    nextTick = CurTime() + 1

    for id, state in pairs(ax.zones.tracked) do
        if ( !IsValid(state.entity) ) then
            ax.zones.tracked[id] = nil
            continue
        end

        UpdateTracking(state.entity)
    end
end)
]]

hook.Add("FinishMove", "ax.zones.tracking", function(ply, mv)
    local state = ax.zones:GetTracking(ply)
    if ( !state ) then return end

    UpdateTracking(ply)
end)

--- Auto-track all players on join.
hook.Add("PlayerInitialSpawn", "ax.zones.tracking", function(ply)
    ax.zones:TrackEntity(ply)
end)

--- Stop tracking players on disconnect.
hook.Add("PlayerDisconnected", "ax.zones.tracking", function(ply)
    ax.zones:UntrackEntity(ply)
end)

--- Re-track all players on reload.
hook.Add("OnReloaded", "ax.zones.tracking", function()
    ax.zones.tracked = {}

    for _, client in player.Iterator() do
        ax.zones:TrackEntity(client)
    end
end)
