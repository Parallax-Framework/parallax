--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.config:Add("language", ax.type.string, "en", {
    description = "Server language",
    category = "general",
    subCategory = "basic"
})

ax.config:Add("botSupport", ax.type.bool, true, {
    description = "Enable automatic character creation for bots.",
    bNetworked = false,
    category = "general",
    subCategory = "basic"
})

-- Chat system configurations
ax.config:Add("chatICDistance", ax.type.number, 400, {
    description = "Maximum distance for IC (in-character) chat",
    min = 100,
    max = 2000,
    decimals = 0,
    category = "chat",
    subCategory = "distances"
})

ax.config:Add("chatYellDistance", ax.type.number, 700, {
    description = "Maximum distance for Yell chat",
    min = 100,
    max = 2000,
    decimals = 0,
    category = "chat",
    subCategory = "distances"
})

ax.config:Add("chatOOCDistance", ax.type.number, 600, {
    description = "Maximum distance for LOOC (local out-of-character) chat",
    min = 100,
    max = 2000,
    decimals = 0,
    category = "chat",
    subCategory = "distances"
})

ax.config:Add("chatMeDistance", ax.type.number, 600, {
    description = "Maximum distance for /me actions",
    min = 100,
    max = 2000,
    decimals = 0,
    category = "chat",
    subCategory = "distances"
})

-- Chat colors (networked for client consistency)
ax.config:Add("chatColorIC", ax.type.color, Color(230, 230, 110), {
    description = "Color for IC chat",
    bNetworked = true,
    category = "chat",
    subCategory = "colors"
})

ax.config:Add("chatColorYell", ax.type.color, Color(255, 0, 0), {
    description = "Color for Yell chat",
    bNetworked = true,
    category = "chat",
    subCategory = "colors"
})

ax.config:Add("chatColorOOC", ax.type.color, Color(110, 10, 10), {
    description = "Color for OOC/LOOC chat",
    bNetworked = true,
    category = "chat",
    subCategory = "colors"
})

-- Movement configurations
ax.config:Add("movementBunnyhopReduction", ax.type.number, 0.5, {
    description = "Velocity reduction on landing (0 = no reduction, 1 = full stop)",
    min = 0.0,
    max = 1.0,
    decimals = 2,
    category = "gameplay",
    subCategory = "movement"
})

-- Console color configurations (networked for consistency)
ax.config:Add("consoleColorPrint", ax.type.color, Color(100, 150, 255), {
    description = "Color for framework print messages",
    bNetworked = true,
    category = "interface",
    subCategory = "console"
})

ax.config:Add("consoleColorWarning", ax.type.color, Color(255, 200, 100), {
    description = "Color for framework warning messages",
    bNetworked = true,
    category = "interface",
    subCategory = "console"
})

ax.config:Add("consoleColorSuccess", ax.type.color, Color(100, 255, 100), {
    description = "Color for framework success messages",
    bNetworked = true,
    category = "interface",
    subCategory = "console"
})

ax.config:Add("consoleColorDebug", ax.type.color, Color(150, 150, 150), {
    description = "Color for framework debug messages",
    bNetworked = true,
    category = "interface",
    subCategory = "console"
})

-- Font system configurations
ax.config:Add("fontScaleMultiplier", ax.type.number, 1.0, {
    description = "Global font scale multiplier",
    min = 0.5,
    max = 2.0,
    decimals = 2,
    bNetworked = true,
    category = "interface",
    subCategory = "display"
})

ax.config:Add("fontAntialiasEnabled", ax.type.bool, true, {
    description = "Enable font antialiasing",
    bNetworked = true,
    category = "interface",
    subCategory = "display"
})

ax.config:Add("maxCharactersPerPlayer", ax.type.number, 3, {
    description = "Maximum characters each player can create",
    min = 1,
    max = 10,
    decimals = 0,
    category = "general",
    subCategory = "characters"
})

-- Data persistence settings
ax.config:Add("autoSaveInterval", ax.type.number, 300, {
    description = "Auto-save interval in seconds (0 to disable)",
    min = 0,
    max = 3600,
    decimals = 0,
    category = "general",
    subCategory = "characters"
})

ax.config:Add("maxInventoryWeight", ax.type.number, 30.0, {
    description = "Default maximum inventory weight",
    min = 5.0,
    max = 500.0,
    decimals = 1,
    category = "gameplay",
    subCategory = "inventory"
})
