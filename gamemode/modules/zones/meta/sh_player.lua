--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- @module ax.player.meta

--- Get all physical zones the player is currently in.
-- @realm shared
-- @treturn table Array of zone specs, sorted by priority
-- @usage local zones = client:GetZones()
function ax.player.meta:GetZones()
    return ax.zones:AtPos(self:WorldSpaceCenter())
end

--- Get all visible (PVS/trace) zones for the player.
-- @realm shared
-- @treturn table Array of zone specs with weight field
-- @usage local visible = client:GetVisibleZones()
function ax.player.meta:GetVisibleZones()
    return ax.zones:VisibleZones(self)
end

--- Get the full zone blend state for the player.
-- @realm shared
-- @treturn table Blend state with physical, visible, and dominant fields
-- @usage local blend = client:GetZoneBlend()
function ax.player.meta:GetZoneBlend()
    return ax.zones:BlendFor(self)
end

--- Get the dominant zone for the player.
-- @realm shared
-- @treturn table|nil The dominant zone spec or nil
-- @usage local zone = client:GetDominantZone()
function ax.player.meta:GetDominantZone()
    return ax.zones:GetDominant(self)
end

--- Check if the player is in a specific zone.
-- @realm shared
-- @tparam number|string identifier Zone ID or name
-- @treturn boolean True if player is in the zone
-- @usage if client:IsInZone("Safe Zone") then
function ax.player.meta:IsInZone(identifier)
    local zone = ax.zones:Get(identifier)
    if ( !zone ) then return false end

    local zones = self:GetZones()
    for _, z in ipairs(zones) do
        if ( z.id == zone.id ) then
            return true
        end
    end

    return false
end

--- Check if the player can see a specific zone (PVS/trace).
-- @realm shared
-- @tparam number|string identifier Zone ID or name
-- @treturn boolean True if player can see the zone
-- @usage if client:CanSeeZone("Tower Overlook") then
function ax.player.meta:CanSeeZone(identifier)
    local zone = ax.zones:Get(identifier)
    if ( !zone ) then return false end
    if ( zone.type != "pvs" and zone.type != "trace" ) then return false end

    local visible = self:GetVisibleZones()
    for _, z in ipairs(visible) do
        if ( z.id == zone.id ) then
            return true
        end
    end

    return false
end

--- Check if the player is in a zone with a specific flag.
-- @realm shared
-- @tparam string flagName Flag name to check
-- @tparam any flagValue Optional value to match (if nil, checks for existence)
-- @treturn boolean True if in a zone with the flag
-- @usage if client:IsInZoneWithFlag("pvp", true) then
function ax.player.meta:IsInZoneWithFlag(flagName, flagValue)
    local zones = self:GetZones()
    for _, zone in ipairs(zones) do
        if ( zone.flags and zone.flags[flagName] != nil and (flagValue == nil or zone.flags[flagName] == flagValue) ) then
            return true
        end
    end

    return false
end

--- Get all zones the player is in that have a specific flag.
-- @realm shared
-- @tparam string flagName Flag name to check
-- @tparam any flagValue Optional value to match (if nil, checks for existence)
-- @treturn table Array of zone specs
-- @usage local pvpZones = client:GetZonesWithFlag("pvp", true)
function ax.player.meta:GetZonesWithFlag(flagName, flagValue)
    local zones = self:GetZones()
    local result = {}

    for _, zone in ipairs(zones) do
        if ( zone.flags and zone.flags[flagName] != nil and (flagValue == nil or zone.flags[flagName] == flagValue) ) then
            table.insert(result, zone)
        end
    end

    return result
end

--- Check if the player's dominant zone has a specific flag.
-- @realm shared
-- @tparam string flagName Flag name to check
-- @tparam any flagValue Optional value to match (if nil, checks for existence)
-- @treturn boolean True if dominant zone has the flag
-- @usage if client:DominantZoneHasFlag("safe", true) then
function ax.player.meta:DominantZoneHasFlag(flagName, flagValue)
    local dominant = self:GetDominantZone()
    if ( !dominant or !dominant.flags ) then return false end

    if ( dominant.flags[flagName] != nil and (flagValue == nil or dominant.flags[flagName] == flagValue) ) then
        return true
    end

    return false
end

--- Get the player's zone tracking state.
-- @realm shared
-- @treturn table|nil Tracking state or nil
-- @usage local state = client:GetZoneTracking()
function ax.player.meta:GetZoneTracking()
    if ( SERVER ) then
        return ax.zones:GetTracking(self)
    else
        -- Client can only get their own tracking
        if ( self == ax.client ) then
            return ax.zones:GetClientTracking()
        end
        return nil
    end
end

--- Get a specific data value from the player's dominant zone.
-- @realm shared
-- @tparam string key Data key to retrieve
-- @treturn any The data value or nil
-- @usage local music = client:GetDominantZoneData("music_track")
function ax.player.meta:GetDominantZoneData(key)
    local dominant = self:GetDominantZone()
    if ( !dominant or !dominant.data ) then return nil end

    return dominant.data[key]
end

--- Get a specific data value from any zone the player is in (highest priority).
-- @realm shared
-- @tparam string key Data key to retrieve
-- @treturn any The data value or nil
-- @usage local spawn = client:GetZoneData("spawn_point")
function ax.player.meta:GetZoneData(key)
    local zones = self:GetZones()
    for _, zone in ipairs(zones) do
        if ( zone.data and zone.data[key] != nil ) then
            return zone.data[key]
        end
    end

    return nil
end

--- Check if the player is in any zone of a specific type.
-- @realm shared
-- @tparam string zoneType Zone type ("box", "sphere", "pvs", "trace")
-- @treturn boolean True if in a zone of that type
-- @usage if client:IsInZoneType("box") then
function ax.player.meta:IsInZoneType(zoneType)
    local zones = self:GetZones()
    for _, zone in ipairs(zones) do
        if ( zone.type == zoneType ) then
            return true
        end
    end

    return false
end

--- Get all zones of a specific type the player is in.
-- @realm shared
-- @tparam string zoneType Zone type ("box", "sphere", "pvs", "trace")
-- @treturn table Array of zone specs
-- @usage local boxes = client:GetZonesByType("box")
function ax.player.meta:GetZonesByType(zoneType)
    local zones = self:GetZones()
    local result = {}

    for _, zone in ipairs(zones) do
        if ( zone.type == zoneType ) then
            table.insert(result, zone)
        end
    end

    return result
end

--- Get the highest priority zone the player is in.
-- This is the first zone returned by GetZones() since they're sorted by priority.
-- @realm shared
-- @treturn table|nil The highest priority zone or nil
-- @usage local topZone = client:GetHighestPriorityZone()
function ax.player.meta:GetHighestPriorityZone()
    local zones = self:GetZones()
    return zones[1]
end

--- Check if the player is in multiple zones.
-- @realm shared
-- @treturn boolean True if in more than one zone
-- @usage if client:IsInMultipleZones() then
function ax.player.meta:IsInMultipleZones()
    local zones = self:GetZones()
    return #zones > 1
end

--- Get the number of zones the player is currently in.
-- @realm shared
-- @treturn number Number of zones
-- @usage local count = client:GetZoneCount()
function ax.player.meta:GetZoneCount()
    local zones = self:GetZones()
    return #zones
end

--- Get all zone names the player is currently in.
-- @realm shared
-- @treturn table Array of zone names
-- @usage local names = client:GetZoneNames()
function ax.player.meta:GetZoneNames()
    local zones = self:GetZones()
    local names = {}

    for _, zone in ipairs(zones) do
        table.insert(names, zone.name)
    end

    return names
end

--- Get distance to a specific zone's center/origin.
-- @realm shared
-- @tparam number|string identifier Zone ID or name
-- @treturn number|nil Distance or nil if zone not found
-- @usage local dist = client:GetDistanceToZone("Safe Zone")
function ax.player.meta:GetDistanceToZone(identifier)
    local zone = ax.zones:Get(identifier)
    if ( !zone ) then return nil end

    local pos = self:WorldSpaceCenter()
    local zonePos

    if ( zone.type == "box" ) then
        zonePos = (zone.mins + zone.maxs) / 2
    elseif ( zone.type == "sphere" ) then
        zonePos = zone.center
    elseif ( zone.type == "pvs" or zone.type == "trace" ) then
        zonePos = zone.origin
    end

    if ( !zonePos ) then return nil end

    return pos:Distance(zonePos)
end
