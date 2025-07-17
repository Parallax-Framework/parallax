--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--- Client-side spawn library
-- @module MODULE.spawn

MODULE.spawn = MODULE.spawn or {}

--- Gets spawn points for a faction
-- @param factionID The faction ID
-- @return Table of spawn points
function MODULE.spawn:GetForFaction(factionID)
    local spawns = {}
    local schema = engine.ActiveGamemode()

    for id, spawn in pairs(MODULE.SpawnPoints) do
        if ( spawn.faction == factionID and spawn.schema == schema ) then
            spawns[#spawns + 1] = spawn
        end
    end

    return spawns
end

--- Gets all spawn points near a position
-- @param pos The position to check
-- @param distance The maximum distance
-- @return Table of nearby spawn points
function MODULE.spawn:GetNearby(pos, distance)
    local nearby = {}
    distance = distance or MODULE.Config.DefaultSpawnDistance

    for id, spawn in pairs(MODULE.SpawnPoints) do
        if ( spawn.pos:Distance(pos) <= distance ) then
            nearby[#nearby + 1] = spawn
        end
    end

    return nearby
end

local function IsInWorld(pos)
    if ( SERVER ) then
        return util.IsInWorld(pos)
    else
        local trace = util.TraceLine({
            start = pos,
            endpos = pos + Vector(0, 0, -1000),
            filter = function(ent)
                return ent:IsWorld()
            end
        })

        return trace.Hit and trace.Entity:IsWorld()
    end
end

--- Checks if a spawn point is valid (not blocked)
-- @param spawn The spawn point data
-- @return Boolean if spawn is valid
function MODULE.spawn:IsValid(spawn)
    local mins = Vector(-16, -16, 0)
    local maxs = Vector(16, 16, 72)

    local trace = util.TraceHull({
        start = spawn.pos,
        endpos = spawn.pos,
        mins = mins,
        maxs = maxs,
        filter = function(ent)
            return ent:IsPlayer()
        end
    })

    return !trace.Hit and !trace.StartSolid and IsInWorld(spawn.pos)
end