--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--- Add a spawn point for a faction
ax.command:Register("SpawnAdd", {
    Description = "Add a spawn point for a faction at your current position",
    Arguments = {
        {
            Type = ax.types.string,
            ErrorMsg = "You must provide a valid faction ID or name!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Spawns", nil) ) then
            client:Notify("You don't have permission to manage spawn points!")
            return
        end

        local factionInput = arguments[1]
        local faction = ax.faction:Get(factionInput)

        if ( !faction ) then
            client:Notify("Invalid faction: " .. factionInput)
            return
        end

        local pos = client:GetPos()
        local ang = client:GetAngles()

        MODULE.spawn:Add(faction:GetID(), pos, ang, function(success, result)
            if ( success ) then
                client:Notify("Added spawn point #" .. result .. " for faction " .. faction:GetName())
            else
                client:Notify("Failed to add spawn point: " .. result)
            end
        end)
    end
})

--- Remove a spawn point
ax.command:Register("SpawnRemove", {
    Description = "Remove a spawn point by ID",
    Arguments = {
        {
            Type = ax.types.number,
            ErrorMsg = "You must provide a valid spawn point ID!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Spawns", nil) ) then
            client:Notify("You don't have permission to manage spawn points!")
            return
        end

        local id = arguments[1]

        if ( !MODULE.SpawnPoints[id] ) then
            client:Notify("Spawn point #" .. id .. " does not exist!")
            return
        end

        MODULE.spawn:Remove(id, function(success, result)
            if ( success ) then
                client:Notify("Removed spawn point #" .. id)
            else
                client:Notify("Failed to remove spawn point: " .. result)
            end
        end)
    end
})

--- Remove nearby spawn points
ax.command:Register("SpawnRemoveNear", {
    Description = "Remove all spawn points within a certain distance",
    Arguments = {
        {
            Type = ax.types.number,
            Optional = true,
            ErrorMsg = "Invalid distance value!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Spawns", nil) ) then
            client:Notify("You don't have permission to manage spawn points!")
            return
        end

        local distance = arguments[1] or MODULE.Config.DefaultSpawnDistance
        local pos = client:GetPos()
        local nearby = MODULE.spawn:GetNearby(pos, distance)

        if ( #nearby == 0 ) then
            client:Notify("No spawn points found within " .. distance .. " units!")
            return
        end

        local removed = 0
        for i = 1, #nearby do
            local spawn = nearby[i]
            MODULE.spawn:Remove(spawn.id, function(success)
                if ( success ) then
                    removed = removed + 1
                    if ( removed == #nearby ) then
                        client:Notify("Removed " .. removed .. " spawn points")
                    end
                end
            end)
        end
    end
})

--- List spawn points for a faction
ax.command:Register("SpawnList", {
    Description = "List all spawn points for a faction",
    Arguments = {
        {
            Type = ax.types.string,
            Optional = true,
            ErrorMsg = "Invalid faction!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Spawns", nil) ) then
            client:Notify("You don't have permission to manage spawn points!")
            return
        end

        local factionInput = arguments[1]
        local spawns = {}

        if ( factionInput ) then
            local faction = ax.faction:Get(factionInput)
            if ( !faction ) then
                client:Notify("Invalid faction: " .. factionInput)
                return
            end
            spawns = MODULE.spawn:GetForFaction(faction:GetID())
        else
            spawns = MODULE.SpawnPoints
        end

        if ( table.Count(spawns) == 0 ) then
            client:Notify("No spawn points found!")
            return
        end

        client:ChatText("Spawn Points:")
        for id, spawn in pairs(spawns) do
            local faction = ax.faction:Get(spawn.faction)
            local factionName = faction and faction:GetName() or "Unknown"
            local pos = spawn.pos
            client:ChatText("  #" .. id .. " - " .. factionName .. " at " .. math.Round(pos.x) .. ", " .. math.Round(pos.y) .. ", " .. math.Round(pos.z))
        end
    end
})

--- Teleport to a spawn point
ax.command:Register("SpawnGoto", {
    Description = "Teleport to a spawn point by ID",
    Arguments = {
        {
            Type = ax.types.number,
            ErrorMsg = "You must provide a valid spawn point ID!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Spawns", nil) ) then
            client:Notify("You don't have permission to manage spawn points!")
            return
        end

        local id = arguments[1]
        local spawn = MODULE.SpawnPoints[id]

        if ( !spawn ) then
            client:Notify("Spawn point #" .. id .. " does not exist!")
            return
        end

        client:SetPos(spawn.pos)
        client:SetAngles(spawn.ang)
        client:Notify("Teleported to spawn point #" .. id)
    end
})

--- Show nearby spawn points
ax.command:Register("SpawnNear", {
    Description = "Show nearby spawn points",
    Arguments = {
        {
            Type = ax.types.number,
            Optional = true,
            ErrorMsg = "Invalid distance value!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Spawns", nil) ) then
            client:Notify("You don't have permission to manage spawn points!")
            return
        end

        local distance = arguments[1] or MODULE.Config.DefaultSpawnDistance
        local pos = client:GetPos()
        local nearby = MODULE.spawn:GetNearby(pos, distance)

        if ( #nearby == 0 ) then
            client:Notify("No spawn points found within " .. distance .. " units!")
            return
        end

        client:ChatText("Nearby spawn points:")
        for i = 1, #nearby do
            local spawn = nearby[i]
            local faction = ax.faction:Get(spawn.faction)
            local factionName = faction and faction:GetName() or "Unknown"
            local dist = math.Round(pos:Distance(spawn.pos))
            client:ChatText("  #" .. spawn.id .. " - " .. factionName .. " (" .. dist .. " units away)")
        end
    end
})