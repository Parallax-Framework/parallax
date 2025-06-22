--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.config:Register("color.framework", {
    Name = "config.color.framework",
    Description = "config.color.framework.help",
    SubCategory = "category.color",
    Type = ax.types.color,
    Default = Color(142, 68, 255)
})

ax.config:Register("color.schema", {
    Name = "config.color.schema",
    Description = "config.color.schema.help",
    SubCategory = "category.color",
    Type = ax.types.color,
    Default = Color(27, 0, 150)
})

ax.config:Register("color.server.message", {
    Name = "config.color.server.message",
    Description = "config.color.server.message.help",
    SubCategory = "category.color",
    Type = ax.types.color,
    Default = Color(156, 241, 255, 200)
})

ax.config:Register("color.client.message", {
    Name = "config.color.client.message",
    Description = "config.color.client.message.help",
    SubCategory = "category.color",
    Type = ax.types.color,
    Default = Color(255, 241, 122, 200)
})

ax.config:Register("color.server.error", {
    Name = "config.color.server.error",
    Description = "config.color.server.error.help",
    SubCategory = "category.color",
    Type = ax.types.color,
    Default = Color(136, 221, 255, 255)
})

ax.config:Register("color.client.error", {
    Name = "config.color.client.error",
    Description = "config.color.client.error.help",
    SubCategory = "category.color",
    Type = ax.types.color,
    Default = Color(255, 221, 102, 255)
})

ax.config:Register("color.error", {
    Name = "config.color.error",
    Description = "config.color.error.help",
    SubCategory = "category.color",
    Type = ax.types.color,
    Default = Color(255, 120, 120)
})

ax.config:Register("color.warning", {
    Name = "config.color.warning",
    Description = "config.color.warning.help",
    SubCategory = "category.color",
    Type = ax.types.color,
    Default = Color(255, 200, 120)
})

ax.config:Register("color.success", {
    Name = "config.color.success",
    Description = "config.color.success.help",
    SubCategory = "category.color",
    Type = ax.types.color,
    Default = Color(120, 255, 120)
})

ax.config:Register("color.info", {
    Name = "config.color.info",
    Description = "config.color.info.help",
    SubCategory = "category.color",
    Type = ax.types.color,
    Default = Color(75, 165, 255)
})

ax.config:Register("voice", {
    Name = "config.voice",
    Description = "config.voice.help",
    Type = ax.types.bool,
    Default = true
})

ax.config:Register("voice.distance", {
    Name = "config.voice.distance",
    Description = "config.voice.distance.help",
    Type = ax.types.number,
    Default = 384,
    Min = 0,
    Max = 1024,
    Decimals = 0
})

ax.config:Register("mainmenu.music", {
    Name = "config.mainmenu.music",
    Description = "config.mainmenu.music.help",
    SubCategory = "category.mainmenu",
    Type = ax.types.string,
    Default = "music/hl2_song20_submix0.mp3"
})

ax.config:Register("mainmenu.pos", {
    Name = "config.mainmenu.pos",
    Description = "config.mainmenu.pos.help",
    SubCategory = "category.mainmenu",
    Type = ax.types.vector,
    Default = vector_origin
})

ax.config:Register("mainmenu.ang", {
    Name = "config.mainmenu.ang",
    Description = "config.mainmenu.ang.help",
    SubCategory = "category.mainmenu",
    Type = ax.types.angle,
    Default = angle_zero
})

ax.config:Register("mainmenu.fov", {
    Name = "config.mainmenu.fov",
    Description = "config.mainmenu.fov.help",
    SubCategory = "category.mainmenu",
    Type = ax.types.number,
    Default = 90,
    Min = 0,
    Max = 120,
    Decimals = 0
})

ax.config:Register("save.interval", {
    Name = "config.save.interval",
    Description = "config.save.interval.help",
    Type = ax.types.number,
    Default = 300,
    Min = 0,
    Max = 3600,
    Decimals = 0
})

ax.config:Register("speed.walk", {
    Name = "config.speed.walk",
    Description = "config.speed.walk.help",
    SubCategory = "category.player",
    Type = ax.types.number,
    Default = 80,
    Min = 0,
    Max = 1000,
    Decimals = 0,
    OnChange = function(_, value)
        if ( CLIENT ) then return end

        for _, client in player.Iterator() do
            client:SetWalkSpeed(value)
        end
    end
})

ax.config:Register("speed.run", {
    Name = "config.speed.run",
    Description = "config.speed.run.help",
    SubCategory = "category.player",
    Type = ax.types.number,
    Default = 180,
    Min = 0,
    Max = 1000,
    Decimals = 0,
    OnChange = function(_, value)
        if ( CLIENT ) then return end

        for _, client in player.Iterator() do
            client:SetRunSpeed(value)
        end
    end
})

ax.config:Register("jump.power", {
    Name = "config.jump.power",
    Description = "config.jump.power.help",
    SubCategory = "category.player",
    Type = ax.types.number,
    Default = 160,
    Min = 0,
    Max = 1000,
    Decimals = 0,
    OnChange = function(_, value)
        if ( CLIENT ) then return end

        for _, client in player.Iterator() do
            client:SetJumpPower(value)
        end
    end
})

ax.config:Register("inventory.max.weight", {
    Name = "config.inventory.max.weight",
    Description = "config.inventory.max.weight.help",
    SubCategory = "category.inventory",
    Type = ax.types.number,
    Default = 20,
    Min = 0,
    Max = 100,
    Decimals = 2,
    OnChange = function(_, value)
        for _, client in player.Iterator() do
            local character = client:GetCharacter()
            if ( character ) then
                local inventories = ax.inventory:GetByCharacterID(character:GetID())
                for i = 1, #inventories do
                    inventories[i].maxWeight = value
                end
            end
        end
    end
})

ax.config:Register("chat.radius.ic", {
    Name = "config.chat.radius.ic",
    Description = "config.chat.radius.ic.help",
    Category = "category.chat",
    Type = ax.types.number,
    Default = 384,
    Min = 0,
    Max = 1000,
    Decimals = 0
})

ax.config:Register("chat.radius.whisper", {
    Name = "config.chat.radius.whisper",
    Description = "config.chat.radius.whisper.help",
    Category = "category.chat",
    Type = ax.types.number,
    Default = 96,
    Min = 0,
    Max = 1000,
    Decimals = 0
})

ax.config:Register("chat.radius.yell", {
    Name = "config.chat.radius.yell",
    Description = "config.chat.radius.yell.help",
    Category = "category.chat",
    Type = ax.types.number,
    Default = 1024,
    Min = 0,
    Max = 1000,
    Decimals = 0
})

ax.config:Register("chat.radius.me", {
    Name = "config.chat.radius.me",
    Description = "config.chat.radius.me.help",
    Category = "category.chat",
    Type = ax.types.number,
    Default = 512,
    Min = 0,
    Max = 1000,
    Decimals = 0
})

ax.config:Register("chat.radius.it", {
    Name = "config.chat.radius.it",
    Description = "config.chat.radius.it.help",
    Category = "category.chat",
    Type = ax.types.number,
    Default = 512,
    Min = 0,
    Max = 1000,
    Decimals = 0
})

ax.config:Register("chat.radius.looc", {
    Name = "config.chat.radius.looc",
    Description = "config.chat.radius.looc.help",
    Category = "category.chat",
    Type = ax.types.number,
    Default = 512,
    Min = 0,
    Max = 1000,
    Decimals = 0
})

ax.config:Register("chat.ooc", {
    Name = "config.chat.ooc",
    Description = "config.chat.ooc.help",
    Category = "category.chat",
    Type = ax.types.bool,
    Default = true,
})

ax.config:Register("currency.singular", {
    Name = "config.currency.singular",
    Description = "config.currency.singular.help",
    Category = "category.currency",
    Type = ax.types.string,
    Default = "Dollar"
})

ax.config:Register("currency.plural", {
    Name = "config.currency.plural",
    Description = "config.currency.plural.help",
    Category = "category.currency",
    Type = ax.types.string,
    Default = "Dollars"
})
ax.config:Register("currency.symbol", {
    Name = "config.currency.symbol",
    Description = "config.currency.symbol.help",
    Category = "category.currency",
    Type = ax.types.string,
    Default = "$"
})

ax.config:Register("currency.model", {
    Name = "config.currency.model",
    Description = "config.currency.model.help",
    Category = "category.currency",
    Type = ax.types.string,
    Default = "models/props_junk/cardboard_box004a.mdl"
})

ax.config:Register("mainmenu.branchwarning", {
    Name = "config.mainmenu.branchwarning",
    Description = "config.mainmenu.branchwarning.help",
    Category = "category.mainmenu",
    Type = ax.types.bool,
    Default = true
})

ax.config:Register("hands.max.Carry", {
    Name = "config.hands.max.Carry",
    Description = "config.hands.max.Carry.help",
    Category = "category.hands",
    Type = ax.types.number,
    Default = 160,
    Min = 0,
    Max = 500,
    Decimals = 0
})

ax.config:Register("hands.max.Force", {
    Name = "config.hands.max.Force",
    Description = "config.hands.max.Force.help",
    Category = "category.hands",
    Type = ax.types.number,
    Default = 16500,
    Min = 0,
    Max = 50000,
    Decimals = 0
})

ax.config:Register("hands.max.throw", {
    Name = "config.hands.max.throw",
    Description = "config.hands.max.throw.help",
    Category = "category.hands",
    Type = ax.types.number,
    Default = 150,
    Min = 0,
    Max = 256,
    Decimals = 0
})

ax.config:Register("hands.range", {
    Name = "config.hands.range",
    Description = "config.hands.range.help",
    Category = "category.hands",
    Type = ax.types.number,
    Default = 96,
    Min = 0,
    Max = 256,
    Decimals = 0
})

ax.config:Register("weapon.raise.time", {
    Name = "config.weapon.raise.time",
    Description = "config.weapon.raise.time.help",
    SubCategory = "category.weapon",
    Type = ax.types.number,
    Default = 1,
    Min = 0,
    Max = 5,
    Decimals = 1
})

ax.config:Register("weapon.raise.alwaysraised", {
    Name = "config.weapon.raise.alwaysraised",
    Description = "config.weapon.raise.alwaysraised.help",
    SubCategory = "category.weapon",
    Type = ax.types.bool,
    Default = false
})

ax.config:Register("debug.networking", {
    Name = "config.debug.networking",
    Description = "config.debug.networking.help",
    SubCategory = "category.debug",
    Type = ax.types.bool,
    Default = false
})

ax.config:Register("networking.cooldown", {
    Name = "config.networking.cooldown",
    Description = "config.networking.cooldown.help",
    SubCategory = "category.networking",
    Type = ax.types.number,
    Default = 0.1,
    Min = 0,
    Max = 60,
    Decimals = 1
})

ax.config:Register("debug.developer", {
    Name = "config.debug.developer",
    Description = "config.debug.developer.help",
    SubCategory = "category.debug",
    Type = ax.types.bool,
    Default = false
})

ax.config:Register("debug.preview", {
    Name = "config.debug.preview",
    Description = "config.debug.preview.help",
    SubCategory = "category.debug",
    Type = ax.types.bool,
    Default = false
})

ax.config:Register("time.respawn", {
    Name = "config.time.respawn",
    Description = "config.time.respawn.help",
    Type = ax.types.number,
    Default = 60,
    Min = 0,
    Max = 300,
})

ax.config:Register("characters.restorepos", {
    Name = "config.characters.restorepos",
    Description = "config.characters.restorepos.help",
    Category = "category.characters",
    Type = ax.types.bool,
    Default = true,
})

ax.config:Register("characters.maxCount", {
    Name = "config.characters.maxCount",
    Description = "config.characters.maxCount.help",
    Category = "category.characters",
    Type = ax.types.number,
    Default = 5,
    Min = 1,
    Max = 20,
})

ax.config:Register("characters.minNameLength", {
    Name = "config.characters.minNameLength",
    Description = "config.characters.minNameLength.help",
    Category = "category.characters",
    Type = ax.types.number,
    Default = 3,
    Min = 1,
    Max = 32,
})

ax.config:Register("characters.maxNameLength", {
    Name = "config.characters.maxNameLength",
    Description = "config.characters.maxNameLength.help",
    Category = "category.characters",
    Type = ax.types.number,
    Default = 32,
    Min = 1,
    Max = 64,
})

ax.config:Register("characters.minDescriptionLength", {
    Name = "config.characters.minDescriptionLength",
    Description = "config.characters.minDescriptionLength.help",
    Category = "category.characters",
    Type = ax.types.number,
    Default = 1,
    Min = 1,
    Max = 1024,
})

ax.config:Register("characters.maxDescriptionLength", {
    Name = "config.characters.maxDescriptionLength",
    Description = "config.characters.maxDescriptionLength.help",
    Category = "category.characters",
    Type = ax.types.number,
    Default = 256,
    Min = 1,
    Max = 1024,
})