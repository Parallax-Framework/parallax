--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.option:Add("zones.debug.active", ax.type.bool, false, {
    category = "zones",
    subCategory = "debug",
    description = "Enable the zone debug overlay and HUD for your client."
})

ax.option:Add("zones.debug.world", ax.type.bool, true, {
    category = "zones",
    subCategory = "debug",
    description = "Draw in-world zone geometry while your zone debug session is active.",
    bNoNetworking = true
})

ax.option:Add("zones.debug.hud", ax.type.bool, true, {
    category = "zones",
    subCategory = "debug",
    description = "Show the compact zone debug HUD while your zone debug session is active.",
    bNoNetworking = true
})

ax.option:Add("zones.debug.labels", ax.type.bool, true, {
    category = "zones",
    subCategory = "debug",
    description = "Render world-space labels over zones in the debug overlay.",
    bNoNetworking = true
})

ax.option:Add("zones.debug.static", ax.type.bool, true, {
    category = "zones",
    subCategory = "debug",
    description = "Include static zones in the world debug overlay.",
    bNoNetworking = true
})

ax.option:Add("zones.debug.target", ax.type.bool, true, {
    category = "zones",
    subCategory = "debug",
    description = "Highlight the zone nearest to your current look target in the debug HUD and overlay.",
    bNoNetworking = true
})

ax.option:Add("zones.debug.distance", ax.type.number, 2500, {
    category = "zones",
    subCategory = "debug",
    description = "Preferred draw distance for the world debug overlay. The server config still caps this.",
    min = 256,
    max = 20000,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("zones.debug.entries", ax.type.number, 4, {
    category = "zones",
    subCategory = "debug",
    description = "Preferred number of zones to show per section in the debug HUD. The server config still caps this.",
    min = 1,
    max = 16,
    decimals = 0,
    bNoNetworking = true
})
