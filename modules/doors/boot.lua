--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.Name = "Doors"
MODULE.Description = "Handles door entities with custom functionality and persistence."
MODULE.Author = "Riggs"

-- Permissions
CAMI.RegisterPrivilege({
    Name = "Parallax - Manage Doors",
    MinAccess = "admin"
})

function MODULE:PlayerBuyDoor(client, door)
    -- Code to handle player buying a door
end

function MODULE:PlayerSellDoor(client, door)
    -- Code to handle player selling a door
end

function MODULE:PlayerLockDoor(client, door)
    -- Code to handle player locking a door
end

function MODULE:PlayerSetOwnable(client, door, ownable)
    -- Code to handle setting a door as ownable or unownable
end