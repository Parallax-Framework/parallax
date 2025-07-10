--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.config:Register("stamina.drain", {
    Name = "config.stamina.drain",
    Description = "config.stamina.drain.help",
    Category = "config.stamina",
    Type = ax.types.number,
    Default = 5,
    Min = 0,
    Max = 100,
    Decimals = 1
})

ax.config:Register("stamina", {
    Name = "config.stamina",
    Description = "config.stamina.help",
    Category = "config.stamina",
    Type = ax.types.bool,
    Default = true
})

ax.config:Register("stamina.max", {
    Name = "config.stamina.max",
    Description = "config.stamina.max.Help",
    Category = "config.stamina",
    Type = ax.types.number,
    Default = 100,
    Min = 0,
    Max = 1000,
    Decimals = 0
})

ax.config:Register("stamina.regen", {
    Name = "config.stamina.regen",
    Description = "config.stamina.regen.help",
    Category = "config.stamina",
    Type = ax.types.number,
    Default = 2,
    Min = 0,
    Max = 100,
    Decimals = 1
})

ax.config:Register("stamina.tick", {
    Name = "config.stamina.tick",
    Description = "config.stamina.tick.help",
    Category = "config.stamina",
    Type = ax.types.number,
    Default = 0.1,
    Min = 0,
    Max = 1,
    Decimals = 2
})
