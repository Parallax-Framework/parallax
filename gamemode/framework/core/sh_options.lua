--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.option:Add("performance.animations", ax.type.bool, true, {
    category = "interface",
    subCategory = "display",
    description = "performance.animations.help",
    bNoNetworking = true
})

ax.option:Add("inventory.categories.italic", ax.type.bool, true, {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.categories.italic.help",
    bNoNetworking = true
})

ax.option:Add("interface.theme", ax.type.array, "dark", {
    category = "interface",
    subCategory = "display",
    description = "interface.theme.help",
    choices = {
        ["dark"] = "theme.dark",
        ["light"] = "theme.light",
        ["blue"] = "theme.blue",
        ["purple"] = "theme.purple",
        ["green"] = "theme.green",
        ["red"] = "theme.red"
    },
    bNoNetworking = true,
    OnChanged = function(self, oldValue, value)
        if ( IsValid(ax.gui.main) ) then
            ax.gui.main:Remove()
            vgui.Create("ax.main")

            -- just notify the user that the main menu has been rebuilt to apply the new theme
            Derma_Message("The main menu has been rebuilt to apply the new theme.", "Theme Changed", "OK")
        end
    end
})

ax.option:Add("interface.glass.roundness", ax.type.number, 8, {
    category = "interface",
    subCategory = "display",
    description = "interface.glass.roundness.help",
    min = 0,
    max = 24,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("interface.glass.blur", ax.type.number, 1.0, {
    category = "interface",
    subCategory = "display",
    description = "interface.glass.blur.help",
    min = 0,
    max = 2.0,
    decimals = 2,
    bNoNetworking = true
})

ax.option:Add("interface.glass.opacity", ax.type.number, 1.0, {
    category = "interface",
    subCategory = "display",
    description = "interface.glass.opacity.help",
    min = 0.2,
    max = 1.5,
    decimals = 2,
    bNoNetworking = true
})

ax.option:Add("interface.glass.borderOpacity", ax.type.number, 1.0, {
    category = "interface",
    subCategory = "display",
    description = "interface.glass.borderOpacity.help",
    min = 0.2,
    max = 1.5,
    decimals = 2,
    bNoNetworking = true
})

ax.option:Add("interface.glass.gradientOpacity", ax.type.number, 1.0, {
    category = "interface",
    subCategory = "display",
    description = "interface.glass.gradientOpacity.help",
    min = 0.0,
    max = 1.5,
    decimals = 2,
    bNoNetworking = true
})

-- UI scaling and layout options
ax.option:Add("interface.scale", ax.type.number, 1.0, {
    min = 0.5,
    max = 2.0,
    decimals = 1,
    category = "interface",
    subCategory = "display",
    description = "UI element scaling factor (affects notifications, panels, etc.)",
    bNoNetworking = true
})

ax.option:Add("inventory.columns", ax.type.number, 4, {
    category = "interface",
    subCategory = "inventory",
    description = "inventories.columns.help",
    min = 2,
    max = 8,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("button.delay.click", ax.type.number, 0.1, {
    category = "interface",
    subCategory = "buttons",
    description = "button.delay.click.help",
    min = 0,
    max = 1,
    decimals = 2,
    bNoNetworking = true
})

-- Visual preference options

ax.option:Add("hud.bar.health.show", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "hud.bar.health.show.help",
    bNoNetworking = true
})

ax.option:Add("hud.bar.armor.show", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "hud.bar.armor.show.help",
    bNoNetworking = true
})

-- Chat preferences
ax.option:Add("chat.timestamps", ax.type.bool, false, {
    category = "chat",
    subCategory = "basic",
    description = "chat.timestamps.help",
    bNoNetworking = true
})

ax.option:Add("chat.sounds", ax.type.bool, true, {
    category = "chat",
    subCategory = "basic",
    description = "chat.sounds.help",
    bNoNetworking = true
})

ax.option:Add("chat.randomized.verbs", ax.type.bool, true, {
    category = "chat",
    subCategory = "basic",
    description = "chat.randomized.verbs.help",
    bNoNetworking = true
})

-- Notification customization
ax.option:Add("notification.enabled", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "notification.enabled.help",
    bNoNetworking = true
})

ax.option:Add("notification.length.default", ax.type.number, 5, {
    min = 1,
    max = 20,
    decimals = 0,
    category = "interface",
    subCategory = "hud",
    description = "notification.length.default.help",
    bNoNetworking = true
})

ax.option:Add("notification.sounds", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "notification.sounds.help",
    bNoNetworking = true
})

ax.option:Add("notification.position", ax.type.array, "bottomcenter", {
    category = "interface",
    subCategory = "hud",
    description = "notification.position.help",
    choices = {
        ["topright"] = "Top Right", ["topleft"] = "Top Left", ["topcenter"] = "Top Center",
        ["bottomright"] = "Bottom Right", ["bottomleft"] = "Bottom Left", ["bottomcenter"] = "Bottom Center"
    },
    bNoNetworking = true
})

ax.option:Add("notification.scale", ax.type.number, 1.0, {
    min = 0.5,
    max = 2.0,
    decimals = 1,
    category = "interface",
    subCategory = "hud",
    description = "notification.scale.help",
    bNoNetworking = true
})

ax.option:Add("fontScaleGeneral", ax.type.number, 1, {
    category = "interface",
    subCategory = "fonts",
    description = "fontScaleGeneral.help",
    min = 0.5,
    max = 2,
    decimals = 2,
    deferredUpdate = true,
    bNoNetworking = true,
    OnChanged = function(self, oldValue, value)
        ax.font:Load()

        Derma_Message("Font scale changed. You may need to rejoin the server for all changes to take effect.", "Font Scale Changed", "OK")
    end
})

ax.option:Add("fontScaleSmall", ax.type.number, 1, {
    category = "interface",
    subCategory = "fonts",
    description = "fontScaleSmall.help",
    min = 0.5,
    max = 2,
    decimals = 2,
    deferredUpdate = true,
    bNoNetworking = true,
    OnChanged = function(self, oldValue, value)
        ax.font:Load()

        Derma_Message("Font scale changed. You may need to rejoin the server for all changes to take effect.", "Font Scale Changed", "OK")
    end
})

ax.option:Add("fontScaleBig", ax.type.number, 1, {
    category = "interface",
    subCategory = "fonts",
    description = "fontScaleBig.help",
    min = 0.5,
    max = 2,
    decimals = 2,
    deferredUpdate = true,
    bNoNetworking = true,
    OnChanged = function(self, oldValue, value)
        ax.font:Load()

        Derma_Message("Font scale changed. You may need to rejoin the server for all changes to take effect.", "Font Scale Changed", "OK")
    end
})
