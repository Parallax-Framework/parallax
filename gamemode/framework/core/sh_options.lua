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
    subCategory = "performance",
    description = "performance.animations.help",
    bNoNetworking = true
})

ax.option:Add("performance.blur", ax.type.bool, true, {
    category = "interface",
    subCategory = "performance",
    description = "performance.blur.help",
    bNoNetworking = true
})

ax.option:Add("performance.vignette.trace", ax.type.bool, true, {
    category = "interface",
    subCategory = "performance",
    description = "performance.vignette.trace.help",
    bNoNetworking = true
})

ax.option:Add("performance.voice.indicators", ax.type.bool, true, {
    category = "interface",
    subCategory = "performance",
    description = "performance.voice.indicators.help",
    bNoNetworking = true
})

ax.option:Add("inventory.categories.italic", ax.type.bool, true, {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.categories.italic.help",
    bNoNetworking = true
})

-- UI scaling and layout options
ax.option:Add("interface.scale", ax.type.number, 1.0, {
    min = 0.5,
    max = 2.0,
    decimals = 1,
    category = "interface",
    subCategory = "layout",
    description = "UI element scaling factor (affects notifications, panels, etc.)",
    bNoNetworking = true
})

ax.option:Add("inventory.columns", ax.type.number, 3, {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.columns.help",
    min = 2,
    max = 8,
    decimals = 0,
    bNoNetworking = true,
    OnChanged = function(self, oldValue, value)
        if ( CLIENT and IsValid(ax.gui.inventory) ) then
            ax.gui.inventory:PopulateItems()
        end
    end
})

ax.option:Add("store.columns", ax.type.number, 3, {
    category = "interface",
    subCategory = "inventory",
    description = "store.columns.help",
    min = 1,
    max = 8,
    decimals = 0,
    bNoNetworking = true,
    OnChanged = function(self, oldValue, value)
        if ( CLIENT and IsValid(ax.gui.settings) ) then
            ax.gui.settings:Remove()
            ax.command:Run("settings")
        end
    end
})

ax.option:Add("inventory.sort.categories", ax.type.array, "alphabetical", {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.sort.categories.help",
    choices = {
        ["alphabetical"] = "inventory.sort.alphabetical",
        ["manual"] = "inventory.sort.manual"
    },
    bNoNetworking = true
})

ax.option:Add("inventory.sort.items", ax.type.array, "alphabetical", {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.sort.items.help",
    choices = {
        ["alphabetical"] = "inventory.sort.alphabetical",
        ["weight"] = "inventory.sort.weight",
        ["class"] = "inventory.sort.class"
    },
    bNoNetworking = true
})

ax.option:Add("inventory.search.live", ax.type.bool, true, {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.search.live.help",
    bNoNetworking = true
})

ax.option:Add("inventory.categories.collapsible", ax.type.bool, false, {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.categories.collapsible.help",
    bNoNetworking = true
})

ax.option:Add("inventory.pagination.page_size", ax.type.number, 24, {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.pagination.page_size.help",
    min = 1,
    max = 128,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("inventory.actions.confirm_bulk_drop", ax.type.bool, true, {
    category = "interface",
    subCategory = "inventory",
    description = "inventory.actions.confirm_bulk_drop.help",
    bNoNetworking = true
})

ax.option:Add("button.delay.click", ax.type.number, 0.1, {
    category = "interface",
    subCategory = "interaction",
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

ax.option:Add("hud.elements.enabled", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "hud.elements.enabled.help",
    bNoNetworking = true
})

ax.option:Add("hud.targetid.enabled", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.enabled.help",
    bNoNetworking = true
})

ax.option:Add("hud.targetid.distance", ax.type.number, 96, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.distance.help",
    min = 32,
    max = 512,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.fade_speed_in", ax.type.number, 10, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.fade_speed_in.help",
    min = 1,
    max = 30,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.fade_speed_out", ax.type.number, 10, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.fade_speed_out.help",
    min = 1,
    max = 30,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.position_speed", ax.type.number, 20, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.position_speed.help",
    min = 1,
    max = 40,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.max_width", ax.type.number, 128, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.max_width.help",
    min = 64,
    max = 384,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.line_spacing", ax.type.number, 6, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.line_spacing.help",
    min = 4,
    max = 16,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.visible_delay", ax.type.number, 0.1, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.visible_delay.help",
    min = 0,
    max = 1,
    decimals = 2,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.player_offset", ax.type.number, 16, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.player_offset.help",
    min = 0,
    max = 64,
    decimals = 0,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.flash_speed", ax.type.number, 0.75, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.flash_speed.help",
    min = 0.1,
    max = 5,
    decimals = 2,
    bNoNetworking = true
})

ax.option:Add("hud.targetid.show_descriptions", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.show_descriptions.help",
    bNoNetworking = true
})

ax.option:Add("hud.targetid.show_extras", ax.type.bool, true, {
    category = "interface",
    subCategory = "hud",
    description = "hud.targetid.show_extras.help",
    bNoNetworking = true
})

-- Chat preferences
ax.option:Add("chat.timestamps", ax.type.bool, false, {
    category = "chat",
    subCategory = "formatting",
    description = "chat.timestamps.help",
    bNoNetworking = true
})

-- whether or not to use 0-24 hours or the PM/AM system
ax.option:Add("chat.timestamps.24hour", ax.type.bool, false, {
    category = "chat",
    subCategory = "formatting",
    description = "chat.timestamps.24hour.help",
    bNoNetworking = true
})

ax.option:Add("chat.sounds", ax.type.bool, true, {
    category = "chat",
    subCategory = "behavior",
    description = "chat.sounds.help",
    bNoNetworking = true
})

ax.option:Add("chat.randomized.verbs", ax.type.bool, true, {
    category = "chat",
    subCategory = "behavior",
    description = "chat.randomized.verbs.help",
    bNoNetworking = true
})

-- Notification customization
ax.option:Add("notification.enabled", ax.type.bool, true, {
    category = "interface",
    subCategory = "notifications",
    description = "notification.enabled.help",
    bNoNetworking = true
})

ax.option:Add("notification.length.default", ax.type.number, 5, {
    min = 1,
    max = 20,
    decimals = 0,
    category = "interface",
    subCategory = "notifications",
    description = "notification.length.default.help",
    bNoNetworking = true
})

ax.option:Add("notification.sounds", ax.type.bool, true, {
    category = "interface",
    subCategory = "notifications",
    description = "notification.sounds.help",
    bNoNetworking = true
})

ax.option:Add("notification.position", ax.type.array, "bottomcenter", {
    category = "interface",
    subCategory = "notifications",
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
    subCategory = "notifications",
    description = "notification.scale.help",
    bNoNetworking = true
})

ax.option:Add("fontScaleGeneral", ax.type.number, 1, {
    category = "interface",
    subCategory = "typography",
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
    subCategory = "typography",
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
    subCategory = "typography",
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
