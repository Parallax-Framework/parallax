--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.config:Register("admin.logging", {
    Name = "Admin Logging",
    Description = "Enable admin action logging",
    Type = ax.types.bool,
    Default = true
})

ax.config:Register("admin.immunity", {
    Name = "Admin Immunity",
    Description = "Enable admin immunity system",
    Type = ax.types.bool,
    Default = true
})

ax.config:Register("admin.hierarchy", {
    Name = "Admin Hierarchy",
    Description = "Enable admin hierarchy system",
    Type = ax.types.bool,
    Default = true
})

ax.config:Register("admin.tickets.enabled", {
    Name = "Ticket System",
    Description = "Enable the ticket system",
    Type = ax.types.bool,
    Default = true
})

ax.config:Register("admin.tickets.maxPerPlayer", {
    Name = "Max Tickets Per Player",
    Description = "Maximum number of active tickets per player",
    Type = ax.types.number,
    Default = 3,
    Min = 1,
    Max = 10
})

ax.config:Register("admin.tickets.autoClose", {
    Name = "Auto Close Tickets",
    Description = "Automatically close tickets after X hours of inactivity",
    Type = ax.types.number,
    Default = 24,
    Min = 1,
    Max = 168
})