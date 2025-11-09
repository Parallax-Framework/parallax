--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.option:Add("performance.animations", ax.type.bool, true, {
    category = "interface",
    subCategory = "display",
    description = "performance.animations.help"
})

ax.option:Add("inventory.categories.italic", ax.type.bool, true, {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.categories.italic.help"
})

-- UI scaling and layout options
ax.option:Add("interface.scale", ax.type.number, 1.0, {
    min = 0.5,
    max = 2.0,
    decimals = 1,
    category = "interface",
    subCategory = "display",
    description = "UI element scaling factor (affects notifications, panels, etc.)"
})

ax.option:Add("inventory.columns", ax.type.number, 4, {
    category = "interface",
    subCategory = "inventory",
    description = "inventories.columns.help",
    min = 2,
    max = 8,
    decimals = 0
})

ax.option:Add("button.delay.click", ax.type.number, 0.1, {
    category = "interface",
    subCategory = "buttons",
    description = "button.delay.click.help",
    min = 0,
    max = 1,
    decimals = 2
})

-- Visual preference options

ax.option:Add("hud.bar.health.show", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "hud.bar.health.show.help"
})

ax.option:Add("hud.bar.armor.show", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "hud.bar.armor.show.help"
})

-- Chat preferences
ax.option:Add("chat.timestamps", ax.type.bool, false, {
    category = "chat",
    subCategory = "basic",
    description = "chat.timestamps.help"
})

ax.option:Add("chat.sounds", ax.type.bool, true, {
    category = "chat",
    subCategory = "basic",
    description = "chat.sounds.help"
})

ax.option:Add("chat.randomized.verbs", ax.type.bool, true, {
    category = "chat",
    subCategory = "basic",
    description = "chat.randomized.verbs.help"
})

-- Notification customization
ax.option:Add("notification.enabled", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "notification.enabled.help"
})

ax.option:Add("notification.length.default", ax.type.number, 5, {
    min = 1,
    max = 20,
    decimals = 0,
    category = "interface",
    subCategory = "hud",
    description = "notification.length.default.help"
})

ax.option:Add("notification.sounds", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "notification.sounds.help"
})

ax.option:Add("notification.position", ax.type.array, "bottomcenter", {
    category = "interface",
    subCategory = "hud",
    description = "notification.position.help",
    choices = {
        ["topright"] = "Top Right", ["topleft"] = "Top Left", ["topcenter"] = "Top Center",
        ["bottomright"] = "Bottom Right", ["bottomleft"] = "Bottom Left", ["bottomcenter"] = "Bottom Center"
    }
})

ax.option:Add("notification.scale", ax.type.number, 1.0, {
    min = 0.5,
    max = 2.0,
    decimals = 1,
    category = "interface",
    subCategory = "hud",
    description = "notification.scale.help"
})
