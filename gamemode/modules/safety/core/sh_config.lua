--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.config:Add("weapon.raise.time", ax.type.number, 0.25, {
    description = "config.weapon.raise.time.help",
    min = 0,
    max = 2,
    decimals = 2,
    category = "gameplay",
    subCategory = "weapon_safety",
})

ax.config:Add("weapon.raise.alwaysraised", ax.type.bool, false, {
    description = "config.weapon.raise.alwaysraised.help",
    category = "gameplay",
    subCategory = "weapon_safety",
})
