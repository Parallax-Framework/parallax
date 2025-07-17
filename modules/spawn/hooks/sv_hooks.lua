--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--- Initialize the spawn system
function MODULE:Initialize()
    -- Initialize the spawns table using the proper database API
    ax.database:InitializeTable("ax_spawns", {
        id = "INTEGER PRIMARY KEY AUTOINCREMENT",
        faction = "INTEGER NOT NULL",
        pos_x = "REAL NOT NULL",
        pos_y = "REAL NOT NULL",
        pos_z = "REAL NOT NULL",
        ang_p = "REAL NOT NULL",
        ang_y = "REAL NOT NULL",
        ang_r = "REAL NOT NULL",
        schema = "TEXT NOT NULL"
    })

    -- Load all spawn points after table is initialized
    self.spawn:LoadAll()
end

--- Called when a player spawns
function MODULE:PostPlayerLoadout(client)
    local factionID = client:GetCharacter():GetFaction()
    local spawn = self.spawn:GetRandom(factionID)
    if ( spawn ) then
        client:SetPos(spawn.pos)
        client:SetAngles(spawn.ang)
        client:SetVelocity(Vector(0, 0, 0))
    else
        -- Fallback to default spawn behavior
        ax.util:PrintWarning("No spawn points found for faction " .. factionID .. "!")
    end
end

--- Sync spawn points to newly connected players
function MODULE:PlayerReady(client)
    self.spawn:Sync(client)
end

function MODULE:OnReloaded()
    self.spawn:LoadAll()
end