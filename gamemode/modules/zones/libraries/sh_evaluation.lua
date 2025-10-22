--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- @module ax.zones

--- Get all physical zones that contain a position.
-- @realm shared
-- @tparam Vector pos Position to test
-- @treturn table Array of zone specs, sorted by priority (desc) then id (asc)
function ax.zones:AtPos(pos)
    if ( !isvector(pos) ) then return {} end

    local result = {}

    for id, zone in pairs(self.stored) do
        -- Skip non-physical zones (PVS and trace)
        if ( zone.type == "pvs" or zone.type == "trace" ) then continue end

        local typeImpl = self.types[zone.type]
        if ( !typeImpl or !typeImpl.Contains ) then continue end

        if ( typeImpl.Contains(zone, pos) ) then
            table.insert(result, zone)
        end
    end

    -- Sort by priority desc, then id asc
    table.sort(result, function(a, b)
        if ( a.priority == b.priority ) then
            return a.id < b.id
        end
        return a.priority > b.priority
    end)

    return result
end

--- Get all PVS and trace zones visible to an entity.
-- @realm shared
-- @tparam Entity ent Entity to test visibility from
-- @treturn table Array of zone specs with weight field, sorted by weight desc
function ax.zones:VisibleZones(ent)
    if ( !IsValid(ent) ) then return {} end

    local pos = ent:WorldSpaceCenter()
    local result = {}

    for id, zone in pairs(self.stored) do
        -- Only check PVS and trace zones
        if ( zone.type != "pvs" and zone.type != "trace" ) then continue end

        local typeImpl = self.types[zone.type]
        if ( !typeImpl or !typeImpl.Weight ) then continue end

        local weight = typeImpl.Weight(zone, pos, ent)
        if ( weight > 0 ) then
            local entry = table.Copy(zone)
            entry._weight = weight
            table.insert(result, entry)
        end
    end

    -- Sort by weight desc, then priority desc, then id asc
    table.sort(result, function(a, b)
        if ( a._weight == b._weight ) then
            if ( a.priority == b.priority ) then
                return a.id < b.id
            end
            return a.priority > b.priority
        end
        return a._weight > b._weight
    end)

    return result
end

--- Compute zone blend for an entity.
-- Returns physical zones, visible zones, and the dominant zone.
-- @realm shared
-- @tparam Entity ent Entity to evaluate
-- @treturn table Result with fields: physical (array), visible (array), dominant (zone|nil)
function ax.zones:BlendFor(ent)
    if ( !IsValid(ent) ) then
        return { physical = {}, visible = {}, dominant = nil }
    end

    local pos = ent:WorldSpaceCenter()
    local physical = self:AtPos(pos)
    local visible = self:VisibleZones(ent)

    local dominant = nil

    -- If any physical zones exist, pick highest priority
    if ( #physical > 0 ) then
        dominant = physical[1]
    else
        -- Otherwise, pick highest weighted visible zone
        if ( #visible > 0 ) then
            dominant = visible[1]
        end
    end

    return {
        physical = physical,
        visible = visible,
        dominant = dominant,
    }
end

--- Get the dominant zone for an entity (convenience method).
-- @realm shared
-- @tparam Entity ent Entity to evaluate
-- @treturn table|nil The dominant zone or nil
function ax.zones:GetDominant(ent)
    local blend = self:BlendFor(ent)
    return blend.dominant
end
