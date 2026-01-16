--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

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

ax.config:Add("bot.support", ax.type.bool, true, {
    description = "Enable automatic character creation for bots.",
    category = "general",
    subCategory = "basic"
})

-- Chat system configurations
ax.config:Add("chat.ic.distance", ax.type.number, 400, {
    description = "Maximum distance for IC (in-character) chat",
    min = 100,
    max = 2000,
    decimals = 0,
    category = "chat",
    subCategory = "distances"
})

ax.config:Add("chat.yell.distance", ax.type.number, 700, {
    description = "Maximum distance for Yell chat",
    min = 100,
    max = 2000,
    decimals = 0,
    category = "chat",
    subCategory = "distances"
})

ax.config:Add("chat.whisper.distance", ax.type.number, 200, {
    description = "Maximum distance for Whisper chat",
    min = 50,
    max = 1000,
    decimals = 0,
    category = "chat",
    subCategory = "distances"
})

ax.config:Add("chat.ooc.distance", ax.type.number, 600, {
    description = "Maximum distance for LOOC (local out-of-character) chat",
    min = 100,
    max = 2000,
    decimals = 0,
    category = "chat",
    subCategory = "distances"
})

ax.config:Add("chat.me.distance", ax.type.number, 600, {
    description = "Maximum distance for /me actions",
    min = 100,
    max = 2000,
    decimals = 0,
    category = "chat",
    subCategory = "distances"
})

-- Chat colors (networked for client consistency)
ax.config:Add("chat.ic.color", ax.type.color, Color(255, 255, 150), {
    description = "Color for IC chat",
    category = "chat",
    subCategory = "colors"
})

ax.config:Add("chat.yell.color", ax.type.color, Color(255, 255, 150), {
    description = "Color for Yell chat",
    category = "chat",
    subCategory = "colors"
})

ax.config:Add("chat.whisper.color", ax.type.color, Color(230, 230, 150), {
    description = "Color for Whisper chat",
    category = "chat",
    subCategory = "colors"
})

ax.config:Add("chat.ooc.color", ax.type.color, Color(225, 50, 50), {
    description = "Color for OOC/LOOC chat",
    category = "chat",
    subCategory = "colors"
})

ax.config:Add("chat.me.color", ax.type.color, Color(255, 255, 175), {
    description = "Color for /me actions",
    category = "chat",
    subCategory = "colors"
})

-- OOC / moderation configurations
ax.config:Add("chat.ooc.enabled", ax.type.bool, true, {
    description = "Enable or disable global OOC chat",
    category = "chat",
    subCategory = "ooc"
})

ax.config:Add("chat.ooc.delay", ax.type.number, 5, {
    description = "Minimum seconds required between consecutive OOC messages from the same player",
    min = 0,
    max = 600,
    decimals = 0,
    category = "chat",
    subCategory = "ooc"
})

ax.config:Add("chat.ooc.rate_limit", ax.type.number, 10, {
    description = "Maximum number of OOC messages a player may send per 10 minutes (0 = unlimited)",
    min = 0,
    max = 1000,
    decimals = 0,
    category = "chat",
    subCategory = "ooc"
})

-- Movement configurations
ax.config:Add("movement.bunnyhop.reduction", ax.type.number, 0.5, {
    description = "Velocity reduction on landing (0 = no reduction, 1 = full stop)",
    min = 0.0,
    max = 1.0,
    decimals = 2,
    category = "gameplay",
    subCategory = "movement"
})

-- Font system configurations
ax.config:Add("interface.font.multiplier", ax.type.number, 1.0, {
    description = "interface.font.multiplier.help",
    min = 0.5,
    max = 2.0,
    decimals = 2,
    category = "interface",
    subCategory = "display"
})

ax.config:Add("interface.font.antialias", ax.type.bool, true, {
    description = "interface.font.antialias.help",
    category = "interface",
    subCategory = "display"
})

ax.config:Add("characters.max", ax.type.number, 3, {
    description = "characters.max.help",
    min = 1,
    max = 10,
    decimals = 0,
    category = "general",
    subCategory = "characters"
})

-- Data persistence settings
ax.config:Add("autosave.interval", ax.type.number, 300, {
    description = "autosave.interval.help",
    min = 0,
    max = 3600,
    decimals = 0,
    category = "general",
    subCategory = "characters"
})

ax.config:Add("inventory.weight.max", ax.type.number, 30.0, {
    description = "inventory.weight.max",
    min = 5.0,
    max = 500.0,
    decimals = 1,
    category = "gameplay",
    subCategory = "inventory"
})

ax.config:Add("speed.walk", ax.type.number, 90, {
    description = "speed.walk.help",
    min = 50,
    max = 500,
    decimals = 0,
    category = "gameplay",
    subCategory = "movement",
    OnChanged = function(_valOld, valNew)
        for k, v in player.Iterator() do
            v:SetWalkSpeed(valNew)
        end
    end
})

ax.config:Add("speed.run", ax.type.number, 200, {
    description = "speed.run.help",
    min = 100,
    max = 600,
    decimals = 0,
    category = "gameplay",
    subCategory = "movement",
    OnChanged = function(_valOld, valNew)
        for k, v in player.Iterator() do
            v:SetRunSpeed(valNew)
        end
    end
})

ax.config:Add("speed.walk.slow", ax.type.number, 70, {
    description = "speed.walk.slow.help",
    min = 20,
    max = 300,
    decimals = 0,
    category = "gameplay",
    subCategory = "movement",
    OnChanged = function(_valOld, valNew)
        for k, v in player.Iterator() do
            v:SetSlowWalkSpeed(valNew)
        end
    end
})

ax.config:Add("speed.walk.crouched", ax.type.number, 0.7, {
    description = "speed.walk.crouched.help",
    min = 0.0,
    max = 1.0,
    decimals = 1,
    category = "gameplay",
    subCategory = "movement",
    OnChanged = function(_valOld, valNew)
        for k, v in player.Iterator() do
            v:SetCrouchedWalkSpeed(valNew)
        end
    end
})

ax.config:Add("jump.power", ax.type.number, 175, {
    description = "jump.power.help",
    min = 100,
    max = 500,
    decimals = 0,
    category = "gameplay",
    subCategory = "movement",
    OnChanged = function(_valOld, valNew)
        for k, v in player.Iterator() do
            v:SetJumpPower(valNew)
        end
    end
})

ax.config:Add("hands.force.max", ax.type.number, 16500, {
    description = "hands.force.max.help",
    min = 1000,
    max = 50000,
    decimals = 0,
    category = "gameplay",
    subCategory = "interaction"
})

ax.config:Add("hands.force.max.throw", ax.type.number, 150, {
    description = "hands.force.max.throw.help",
    min = 100,
    max = 5000,
    decimals = 0,
    category = "gameplay",
    subCategory = "interaction"
})

ax.config:Add("hands.range.max", ax.type.number, 96, {
    description = "hands.range.max.help",
    min = 50,
    max = 500,
    decimals = 0,
    category = "gameplay",
    subCategory = "interaction"
})

ax.config:Add("hands.max.carry", ax.type.number, 160, {
    description = "hands.max.carry.help",
    min = 10,
    max = 1000,
    decimals = 0,
    category = "gameplay",
    subCategory = "interaction"
})

ax.config:Add("interface.vignette.enabled", ax.type.bool, true, {
    description = "interface.vignette.enabled.help",
    category = "interface",
    subCategory = "display"
})
