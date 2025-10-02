--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.config:Add( "language", ax.type.string, "en", { description = "Server language", category = "general" } )

ax.config:Add("notificationEnabled", ax.type.bool, true, { description = "Enable client notifications", bNetworked = true, category = "notifications" })
ax.config:Add("notificationDefaultLength", ax.type.number, 5, { min = 1, max = 20, decimals = 0, bNetworked = true, category = "notifications" })
ax.config:Add("notificationMaxWidthFraction", ax.type.number, 0.42, { min = 0.2, max = 0.9, decimals = 2, bNetworked = true, category = "notifications" })
ax.config:Add("notificationInTime", ax.type.number, 0.22, { min = 0.05, max = 1.0, decimals = 2, bNetworked = true, category = "notifications" })
ax.config:Add("notificationOutTime", ax.type.number, 0.20, { min = 0.05, max = 1.0, decimals = 2, bNetworked = true, category = "notifications" })
ax.config:Add("notificationEasing", ax.type.string, "OutCubic", { description = "Easing for notification animations", bNetworked = true, category = "notifications" })
ax.config:Add("notificationSound", ax.type.string, "ui/hint.wav", { description = "Sound to play when a notification appears (path relative to sound/)", bNetworked = true, category = "notifications" })
