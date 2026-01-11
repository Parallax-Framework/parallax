ax.command:Add("SpawnAdd", {
    description = "Adds a spawn point at your current location. Optionally specify a faction and/or class to restrict the spawn point.",
    adminOnly = true,
    arguments = {
        { name = "faction", type = ax.type.string, optional = true },
        { name = "class", type = ax.type.string, optional = true }
    },
    OnRun = function(def, client, factionIdentifier, classIdentifier)
        local spawnPos = client:GetPos()
        local spawnAng = client:EyeAngles()

        local spawnData = {
            position = spawnPos,
            angles = Angle(0, spawnAng.y, 0):SnapTo("y", 15) -- Snap to nearest 15 degrees on Yaw
        }

        ax.spawns:Add(spawnData, factionIdentifier, classIdentifier)

        return "Spawn point added at your current location."
    end
})

ax.command:Add("SpawnRemove", {
    description = "Removes spawn points within the specified radius of your current location.",
    adminOnly = true,
    arguments = {
        { name = "radius", type = ax.type.number }
    },
    OnRun = function(def, client, radius)
        local success, count = ax.spawns:Remove(client:GetPos(), radius)
        if ( success ) then
            return string.format("Removed %d spawn point(s) within %.0f units.", count, radius)
        else
            return "No spawn points found within that radius."
        end
    end
})

ax.command:Add("SpawnClear", {
    description = "Clears all spawn points from the system.",
    superAdminOnly = true,
    OnRun = function(def, client)
        ax.spawns:Clear()

        return "All spawn points have been cleared."
    end
})
