--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--- Handle spawn point synchronization
net.Receive("ax.spawn.sync", function()
    MODULE.SpawnPoints = net.ReadTable()
    hook.Run("OnSpawnPointsUpdated")
    ax.util:Print("Synchronized " .. table.Count(MODULE.SpawnPoints) .. " spawn points")
end)