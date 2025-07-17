--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

MODULE.Name = "Spawn System"
MODULE.Description = "Faction-based spawn system with admin management tools"
MODULE.Author = "Riggs"

-- Spawn storage
MODULE.SpawnPoints = {}
MODULE.SpawnCounter = 0

-- Configuration
MODULE.Config = {
    DefaultSpawnDistance = 64,
    MaxSpawnDistance = 256,
    MinSpawnDistance = 32,
    SpawnBoxSize = Vector(32, 32, 72),
    SpawnBoxColor = Color(0, 255, 0, 100),
    InvalidSpawnColor = Color(255, 0, 0, 100),
    HologramUpdateInterval = { 3, 5 }, -- Min, Max seconds for model updates
    HologramMaxDistance = 1024 -- Maximum distance to render holograms
}

-- Register network strings
if ( SERVER ) then
    util.AddNetworkString("ax.spawn.sync")
end

-- Permissions
CAMI.RegisterPrivilege({
    Name = "Parallax - Manage Spawns",
    MinAccess = "admin"
})

-- Option for viewing spawn points
ax.option:Register("spawn.showSpawns", {
    Name = "Show Spawn Points",
    Description = "Display spawn point locations in the world",
    Category = "Debug",
    Type = ax.types.bool,
    Default = false,
    AdminOnly = true
})

-- Precache common models
local commonModels = {
    "models/player/group01/male_01.mdl",
    "models/player/group01/male_02.mdl",
    "models/player/group01/male_03.mdl",
    "models/player/group01/male_04.mdl",
    "models/player/group01/male_05.mdl",
    "models/player/group01/male_06.mdl",
    "models/player/group01/male_07.mdl",
    "models/player/group01/male_08.mdl",
    "models/player/group01/male_09.mdl",
    "models/player/group01/female_01.mdl",
    "models/player/group01/female_02.mdl",
    "models/player/group01/female_03.mdl",
    "models/player/group01/female_04.mdl",
    "models/player/group01/female_05.mdl",
    "models/player/group01/female_06.mdl"
}

for i = 1, #commonModels do
    util.PrecacheModel(commonModels[i])
end