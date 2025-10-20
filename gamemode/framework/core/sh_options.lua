--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.option:Add("performanceAnimations", ax.type.bool, true, { category = "interface", subCategory = "display", description = "Enable or disable interface animations." })
ax.option:Add("inventoryCategoriesItalic", ax.type.bool, true, { category = "interface", subCategory = "inventory", description = "Display inventory categories in italic style." })
ax.option:Add("keybindTest", ax.type.number, 0, { keybind = true, category = "general", subCategory = "basic", description = "Test keybind option." })

-- UI scaling and layout options
ax.option:Add("uiScale", ax.type.number, 1.0, {
    min = 0.5,
    max = 2.0,
    decimals = 1,
    category = "interface",
    subCategory = "display",
    description = "UI element scaling factor (affects notifications, panels, etc.)"
})

ax.option:Add("buttonDisableFlicker", ax.type.bool, false, {
    category = "interface",
    subCategory = "display",
    description = "Disable button flicker effect on click"
})

ax.option:Add("inventoryColumns", ax.type.number, 4, {
    category = "interface",
    subCategory = "inventory",
    description = "Number of columns in inventory grid layout",
    min = 2,
    max = 8,
    decimals = 0
})

ax.option:Add("buttonClickDelay", ax.type.number, 0.1, {
    category = "interface",
    subCategory = "buttons",
    description = "Delay in seconds before a button can be clicked again (creates a flicker effect).",
    min = 0,
    max = 1,
    decimals = 2
})

-- Visual preference options
ax.option:Add("consolePrintColors", ax.type.bool, true, {
    category = "interface",
    subCategory = "console",
    description = "Enable colored console output for framework messages"
})

ax.option:Add("hudShowHealthBar", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "Show health bar when looking at other players"
})

ax.option:Add("hudShowArmorBar", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "Show armor bar when looking at other players"
})

-- Chat preferences
ax.option:Add("chatTimestamps", ax.type.bool, false, {
    category = "chat",
    subCategory = "basic",
    description = "Show timestamps in chat messages"
})

ax.option:Add("chatSounds", ax.type.bool, true, {
    category = "chat",
    subCategory = "basic",
    description = "Play sound when receiving chat messages"
})

-- Notification customization
ax.option:Add("notificationEnabled", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "Enable client notifications"
})

ax.option:Add("notificationDefaultLength", ax.type.number, 5, {
    min = 1,
    max = 20,
    decimals = 0,
    category = "interface",
    subCategory = "hud",
    description = "Default notification display duration in seconds"
})

ax.option:Add("notificationSounds", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "Play sounds when notifications appear and disappear"
})

ax.option:Add("notificationPosition", ax.type.array, "bottomcenter", {
    category = "interface",
    subCategory = "hud",
    description = "Position for notification display",
    choices = {"topright", "topleft", "topcenter", "bottomright", "bottomleft", "bottomcenter"}
})

ax.option:Add("notificationScale", ax.type.number, 1.0, {
    min = 0.5,
    max = 2.0,
    decimals = 1,
    category = "interface",
    subCategory = "hud",
    description = "Scale factor for notification size"
})
