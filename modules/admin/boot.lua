--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.Name = "Admin"
MODULE.Description = "Comprehensive admin system with features similar to other variants of admin systems, including user groups, permissions, logging, and hierarchy management."
MODULE.Author = "Riggs"

MODULE.Groups = {}
MODULE.Permissions = {}
MODULE.BannedPlayers = MODULE.BannedPlayers or {}
MODULE.AdminLogs = MODULE.AdminLogs or {}

-- Default admin groups with hierarchy levels
MODULE.DefaultGroups = {
    {name = "user", level = 0, color = Color(255, 255, 255), immunity = 0},
    {name = "vip", level = 1, color = Color(255, 215, 0), immunity = 10},
    {name = "moderator", level = 2, color = Color(0, 255, 0), immunity = 50},
    {name = "admin", level = 3, color = Color(0, 100, 255), immunity = 75},
    {name = "superadmin", level = 4, color = Color(255, 0, 0), immunity = 100},
}

-- Register default CAMI permissions
MODULE.DefaultPermissions = {
    -- Basic admin permissions
    {name = "Parallax - Admin Menu", level = 2},
    {name = "Parallax - Kick Players", level = 2},
    {name = "Parallax - Ban Players", level = 2},
    {name = "Parallax - Mute Players", level = 2},
    {name = "Parallax - Teleport", level = 2},
    {name = "Parallax - Spectate", level = 2},
    {name = "Parallax - Noclip", level = 2},
    {name = "Parallax - Godmode", level = 2},
    {name = "Parallax - Freeze Players", level = 2},
    {name = "Parallax - Slay Players", level = 2},
    {name = "Parallax - Bring Players", level = 2},
    {name = "Parallax - Goto Players", level = 2},
    {name = "Parallax - Send Players", level = 2},
    {name = "Parallax - Jail Players", level = 2},
    {name = "Parallax - Strip Weapons", level = 2},
    {name = "Parallax - Give Weapons", level = 2},
    {name = "Parallax - Respawn Players", level = 2},
    {name = "Parallax - Force Roleplay", level = 2},
    {name = "Parallax - Warn Players", level = 2},
    {name = "Parallax - View Logs", level = 2},

    -- Advanced admin permissions
    {name = "Parallax - Manage Usergroups", level = 3},
    {name = "Parallax - Manage Permissions", level = 3},
    {name = "Parallax - Unban Players", level = 3},
    {name = "Parallax - Permanent Ban", level = 3},
    {name = "Parallax - Access Data", level = 3},
    {name = "Parallax - Map Control", level = 3},
    {name = "Parallax - Server Commands", level = 3},
    {name = "Parallax - Cleanup", level = 3},
    {name = "Parallax - Ban Offline", level = 3},

    -- Super admin permissions
    {name = "Parallax - Root Access", level = 4},
    {name = "Parallax - Console Access", level = 4},
    {name = "Parallax - Lua Run", level = 4},
    {name = "Parallax - RCON", level = 4}
}