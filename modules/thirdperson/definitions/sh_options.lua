--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.option:Register("thirdperson", {
    Name = "option.thirdperson",
    Type = ax.types.bool,
    Default = false,
    Description = "option.thirdperson.enable.help",
    NoNetworking = true,
    Category = "category.thirdperson"
})

ax.option:Register("thirdperson.follax.Head", {
    Name = "options.thirdperson.follax.Head",
    Type = ax.types.bool,
    Default = false,
    Description = "options.thirdperson.follax.Head.help",
    NoNetworking = true,
    Category = "category.thirdperson"
})

ax.option:Register("thirdperson.follax.Hit.angles", {
    Name = "options.thirdperson.follax.Hit.angles",
    Type = ax.types.bool,
    Default = true,
    Description = "options.thirdperson.follax.Hit.angles.help",
    NoNetworking = true,
    Category = "category.thirdperson"
})

ax.option:Register("thirdperson.follax.Hit.fov", {
    Name = "options.thirdperson.follax.Hit.fov",
    Type = ax.types.bool,
    Default = true,
    Description = "options.thirdperson.follax.Hit.fov.help",
    NoNetworking = true,
    Category = "category.thirdperson"
})

ax.option:Register("thirdperson.position.x", {
    Name = "options.thirdperson.position.x",
    Type = ax.types.number,
    Default = 50,
    Min = -100,
    Max = 100,
    Decimals = 0,
    Description = "options.thirdperson.position.x.help",
    NoNetworking = true,
    Category = "category.thirdperson"
})

ax.option:Register("thirdperson.position.y", {
    Name = "options.thirdperson.position.y",
    Type = ax.types.number,
    Default = 25,
    Min = -100,
    Max = 100,
    Decimals = 0,
    Description = "options.thirdperson.position.y.help",
    NoNetworking = true,
    Category = "category.thirdperson"
})

ax.option:Register("thirdperson.position.z", {
    Name = "options.thirdperson.position.z",
    Type = ax.types.number,
    Default = 0,
    Min = -100,
    Max = 100,
    Decimals = 0,
    Description = "options.thirdperson.position.z.help",
    NoNetworking = true,
    Category = "category.thirdperson"
})

ax.option:Register("thirdperson.toggle", {
    Name = "options.thirdperson.toggle",
    Description = "options.thirdperson.toggle.help",
    Category = "category.thirdperson",
    Type = ax.types.number,
    Default = KEY_K,
    NoNetworking = true,
    IsKeybind = true,
    OnPressed = function(self)
        RunConsoleCommand("ax_thirdperson_toggle")
    end
})