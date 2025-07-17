--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--- Spawn library for server-side spawn management
-- @module MODULE.spawn

MODULE.spawn = MODULE.spawn or {}

--- Loads all spawn points from the database
function MODULE.spawn:LoadAll()
    ax.database:Select("ax_spawns", nil, nil, function(data)
        MODULE.SpawnPoints = {}
        MODULE.SpawnCounter = 0

        if ( data and istable(data) ) then
            for i = 1, #data do
                local spawn = data[i]
                local id = tonumber(spawn.id)

                MODULE.SpawnPoints[id] = {
                    id = id,
                    faction = tonumber(spawn.faction),
                    pos = Vector(tonumber(spawn.pos_x), tonumber(spawn.pos_y), tonumber(spawn.pos_z)),
                    ang = Angle(tonumber(spawn.ang_p), tonumber(spawn.ang_y), tonumber(spawn.ang_r)),
                    schema = spawn.schema
                }

                if ( id > MODULE.SpawnCounter ) then
                    MODULE.SpawnCounter = id
                end
            end
        end

        ax.util:Print("Loaded " .. table.Count(MODULE.SpawnPoints) .. " spawn points")

        -- Sync to all clients
        self:SyncAll()
    end)
end

--- Adds a new spawn point
-- @param factionID The faction ID for this spawn
-- @param pos The position vector
-- @param ang The angle
-- @param callback Optional callback function
function MODULE.spawn:Add(factionID, pos, ang, callback)
    if ( !isnumber(factionID) or !isvector(pos) or !isangle(ang) ) then
        if ( callback ) then callback(false, "Invalid parameters") end
        return
    end

    local schema = engine.ActiveGamemode()

    ax.database:Insert("ax_spawns", {
        faction = factionID,
        pos_x = pos.x,
        pos_y = pos.y,
        pos_z = pos.z,
        ang_p = ang.p,
        ang_y = ang.y,
        ang_r = ang.r,
        schema = schema
    }, function(insertID)
        if ( insertID ) then
            MODULE.SpawnCounter = math.max(MODULE.SpawnCounter, insertID)

            MODULE.SpawnPoints[insertID] = {
                id = insertID,
                faction = factionID,
                pos = pos,
                ang = ang,
                schema = schema
            }

            -- Sync to all clients
            self:SyncAll()

            if ( callback ) then callback(true, insertID) end
        else
            if ( callback ) then callback(false, "Database error") end
        end
    end)
end

--- Removes a spawn point
-- @param id The spawn point ID
-- @param callback Optional callback function
function MODULE.spawn:Remove(id, callback)
    if ( !MODULE.SpawnPoints[id] ) then
        if ( callback ) then callback(false, "Spawn point not found") end
        return
    end

    ax.database:Delete("ax_spawns", "id = " .. id, function(success)
        if ( success ) then
            MODULE.SpawnPoints[id] = nil

            -- Sync to all clients
            self:SyncAll()

            if ( callback ) then callback(true) end
        else
            if ( callback ) then callback(false, "Database error") end
        end
    end)
end

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

    return !trace.Hit and !trace.StartSolid and util.IsInWorld(spawn.pos)
end

--- Gets a random valid spawn point for a faction
-- @param factionID The faction ID
-- @return Spawn point data or nil
function MODULE.spawn:GetRandom(factionID)
    local spawns = self:GetForFaction(factionID)
    if ( #spawns == 0 ) then return nil end

    -- Try to find a valid spawn
    local attempts = 0
    while ( attempts < 10 ) do
        local spawn = spawns[math.random(#spawns)]
        if ( self:IsValid(spawn) ) then
            return spawn
        end
        attempts = attempts + 1
    end

    -- If no valid spawn found, return any spawn
    return spawns[math.random(#spawns)]
end

--- Syncs spawn points to all clients
function MODULE.spawn:SyncAll()
    net.Start("ax.spawn.sync")
    net.WriteTable(MODULE.SpawnPoints)
    net.Broadcast()

    hook.Run("OnSpawnPointsUpdated")
end

--- Syncs spawn points to a specific client
-- @param client The client to sync to
function MODULE.spawn:Sync(client)
    net.Start("ax.spawn.sync")
    net.WriteTable(MODULE.SpawnPoints)
    net.Send(client)

    hook.Run("OnSpawnPointsUpdated")
end