--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

ax.config:Register("voicechat.modes.enabled", {
    Name = "config.voicechat.modes.enabled",
    Description = "config.voicechat.modes.enabled.help",
    SubCategory = "category.color",
    Type = ax.types.bool,
    Default = true,
})