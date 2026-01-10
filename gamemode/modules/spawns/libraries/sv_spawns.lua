--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.spawns = ax.spawns or {}
ax.spawns.list = ax.spawns.list or {}

function ax.spawns:Save()
    ax.data:Set("spawns", ax.spawns.list, {
        scope = "map",
        human = true
    })
end

function ax.spawns:Load()
    local storedSpawns = ax.data:Get("spawns", {}, {
        scope = "map"
    })

    if ( istable(storedSpawns) ) then
        ax.spawns.list = storedSpawns
    else
        ax.spawns.list = {}
    end
end

function ax.spawns:Add(spawnData, factionIdentifier, classIdentifier)
    local factionUniqueID = nil
    if ( factionIdentifier ) then
        local factionData = ax.faction:Get(factionIdentifier)
        if ( factionData ) then
            factionUniqueID = factionData.id
        end
    end

    local classUniqueID = nil
    if ( classIdentifier ) then
        local classData = ax.class:Get(classIdentifier)
        if ( classData ) then
            classUniqueID = classData.id
        end
    end

    spawnData.faction = factionUniqueID
    spawnData.class = classUniqueID

    if ( !spawnData.position or !spawnData.angles ) then
        return
    end

    table.insert(ax.spawns.list, spawnData)

    self:Save()
end

function ax.spawns:Remove(position, radius)
    local removedCount = 0
    local radiusSqr = radius * radius

    for i = #ax.spawns.list, 1, -1 do
        local spawnData = ax.spawns.list[i]
        if ( spawnData.position:DistToSqr(position) <= radiusSqr ) then
            table.remove(ax.spawns.list, i)
            removedCount = removedCount + 1
        end
    end

    self:Save()

    return removedCount > 0, removedCount
end

function ax.spawns:GetValidSpawns(factionIdentifier, classIdentifier)
    local validSpawns = {}
    -- first, scan for class specific spawns
    if ( classIdentifier ) then
        local classData = ax.class:Get(classIdentifier)
        if ( classData ) then
            for _, spawnData in ipairs(ax.spawns.list) do
                if ( spawnData.class == classData.id ) then
                    table.insert(validSpawns, spawnData)
                end
            end
        end
    end

    -- next, scan for faction specific spawns if none found yet
    if ( #validSpawns == 0 and factionIdentifier ) then
        local factionData = ax.faction:Get(factionIdentifier)
        if ( factionData ) then
            for _, spawnData in ipairs(ax.spawns.list) do
                if ( spawnData.faction == factionData.id ) then
                    table.insert(validSpawns, spawnData)
                end
            end
        end
    end

    -- fallback to spawns without faction/class restrictions
    if ( #validSpawns == 0 ) then
        for _, spawnData in ipairs(ax.spawns.list) do
            if ( !spawnData.faction and !spawnData.class ) then
                table.insert(validSpawns, spawnData)
            end
        end
    end

    return validSpawns
end

function ax.spawns:GetRandomSpawn(factionIdentifier, classIdentifier)
    local validSpawns = self:GetValidSpawns(factionIdentifier, classIdentifier)
    if ( #validSpawns == 0 ) then return nil end

    return validSpawns[math.random(#validSpawns)]
end

function ax.spawns:Clear()
    ax.spawns.list = {}
    self:Save()
end
