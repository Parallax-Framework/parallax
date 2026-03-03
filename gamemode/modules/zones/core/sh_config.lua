--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.config:Add("zones.tracking.server_interval", ax.type.number, 0.05, {
    description = "Minimum time in seconds between server-side dominant zone recalculations for tracked entities.",
    category = "zones",
    subCategory = "tracking",
    min = 0,
    max = 1,
    decimals = 2
})

ax.config:Add("zones.tracking.client_interval", ax.type.number, 0.10, {
    description = "Minimum time in seconds between local client zone tracking refreshes.",
    category = "zones",
    subCategory = "tracking",
    min = 0,
    max = 1,
    decimals = 2
})

ax.config:Add("zones.tracking.hysteresis_time", ax.type.number, 0.50, {
    description = "Delay in seconds before switching dominant zones when priorities are close.",
    category = "zones",
    subCategory = "tracking",
    min = 0,
    max = 5,
    decimals = 2
})

ax.config:Add("zones.tracking.hysteresis_margin", ax.type.number, 5, {
    description = "Priority gap that bypasses hysteresis and switches dominant zones immediately.",
    category = "zones",
    subCategory = "tracking",
    min = 0,
    max = 100,
    decimals = 0
})

ax.config:Add("zones.tracking.use_last_dominant", ax.type.bool, true, {
    description = "Keep using the last dominant zone when the player is not currently inside or seeing any zone.",
    category = "zones",
    subCategory = "tracking"
})

ax.config:Add("zones.editor.default_priority", ax.type.number, 0, {
    description = "Default priority used for newly created zone drafts.",
    category = "zones",
    subCategory = "editor",
    min = -999999,
    max = 999999,
    decimals = 0
})

ax.config:Add("zones.editor.default_box_extent", ax.type.number, 64, {
    description = "Half-size in Hammer units for new box zone drafts.",
    category = "zones",
    subCategory = "editor",
    min = 1,
    max = 4096,
    decimals = 0
})

ax.config:Add("zones.editor.default_radius", ax.type.number, 128, {
    description = "Default radius in Hammer units for sphere, PVS, and trace drafts.",
    category = "zones",
    subCategory = "editor",
    min = 1,
    max = 32768,
    decimals = 0
})

ax.config:Add("zones.editor.max_radius", ax.type.number, 32768, {
    description = "Maximum radius the zone editor will accept for radial zone types.",
    category = "zones",
    subCategory = "editor",
    min = 1,
    max = 131072,
    decimals = 0
})

ax.config:Add("zones.debug.enabled", ax.type.bool, true, {
    description = "Master switch for the admin zone debug overlay and HUD.",
    category = "zones",
    subCategory = "debug",
    OnChanged = function(self, oldValue, value)
        if ( SERVER and value == false and ax.zones and isfunction(ax.zones.StopAllDebugSessions) ) then
            ax.zones:StopAllDebugSessions()
        end
    end
})

ax.config:Add("zones.debug.draw_distance", ax.type.number, 3500, {
    description = "Maximum world distance in Hammer units that zone debug overlays may render.",
    category = "zones",
    subCategory = "debug",
    min = 256,
    max = 20000,
    decimals = 0
})

ax.config:Add("zones.debug.max_entries", ax.type.number, 6, {
    description = "Maximum number of physical and visible zones shown per section in the debug HUD.",
    category = "zones",
    subCategory = "debug",
    min = 1,
    max = 16,
    decimals = 0
})

ax.config:Add("zones.debug.target_tolerance", ax.type.number, 192, {
    description = "How close a looked-at position must be to a zone before it is treated as the current debug target.",
    category = "zones",
    subCategory = "debug",
    min = 16,
    max = 1024,
    decimals = 0
})
