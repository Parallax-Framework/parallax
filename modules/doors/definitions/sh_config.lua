--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.config:Register("door.price", {
    Name = "Door Price",
    Description = "The price of the door.",
    Category = "Doors",
    Type = ax.types.number,
    Default = 5,
    Min = 0,
    Max = 1000,
    Decimals = 0
})

ax.config:Register("door.defaultUnownable", {
    Name = "Default Unownable",
    Description = "If enabled, all doors will be unownable by default and admins must manually set them as ownable.",
    Category = "Doors",
    Type = ax.types.bool,
    Default = false
})

ax.config:Register("door.adminMenuAccess", {
    Name = "Admin Menu Access",
    Description = "Allow admins to access the door management menu by pressing F2.",
    Category = "Doors",
    Type = ax.types.bool,
    Default = true
})