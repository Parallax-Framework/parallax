ax.config:Register("color.framework", {
    Name = "config.color.framework",
    Description = "config.color.framework.help",
    Type = ax.types.color,
    Default = Color(142, 68, 255)
})

ax.config:Register("color.schema", {
    Name = "config.color.schema",
    Description = "config.color.schema.help",
    Type = ax.types.color,
    Default = Color(27, 0, 150)
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
    SubCategory = "config.mainmenu",
    Type = ax.types.string,
    Default = "music/hl2_song20_submix0.mp3"
})

ax.config:Register("mainmenu.pos", {
    Name = "config.mainmenu.pos",
    Description = "config.mainmenu.pos.help",
    SubCategory = "config.mainmenu",
    Type = ax.types.vector,
    Default = vector_origin
})

ax.config:Register("mainmenu.ang", {
    Name = "config.mainmenu.ang",
    Description = "config.mainmenu.ang.help",
    SubCategory = "config.mainmenu",
    Type = ax.types.angle,
    Default = angle_zero
})

ax.config:Register("mainmenu.fov", {
    Name = "config.mainmenu.fov",
    Description = "config.mainmenu.fov.help",
    SubCategory = "config.mainmenu",
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
    SubCategory = "config.player",
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
    SubCategory = "config.player",
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
    SubCategory = "config.player",
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
    SubCategory = "config.inventory",
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
                for _, inventory in ipairs(inventories) do
                    inventory.maxWeight = value
                end
            end
        end
    end
})

ax.config:Register("chat.radius.ic", {
    Name = "config.chat.radius.ic",
    Description = "config.chat.radius.ic.help",
    Category = "config.chat",
    Type = ax.types.number,
    Default = 384,
    Min = 0,
    Max = 1000,
    Decimals = 0
})

ax.config:Register("chat.radius.whisper", {
    Name = "config.chat.radius.whisper",
    Description = "config.chat.radius.whisper.help",
    Category = "config.chat",
    Type = ax.types.number,
    Default = 96,
    Min = 0,
    Max = 1000,
    Decimals = 0
})

ax.config:Register("chat.radius.yell", {
    Name = "config.chat.radius.yell",
    Description = "config.chat.radius.yell.help",
    Category = "config.chat",
    Type = ax.types.number,
    Default = 1024,
    Min = 0,
    Max = 1000,
    Decimals = 0
})

ax.config:Register("chat.radius.me", {
    Name = "config.chat.radius.me",
    Description = "config.chat.radius.me.help",
    Category = "config.chat",
    Type = ax.types.number,
    Default = 512,
    Min = 0,
    Max = 1000,
    Decimals = 0
})

ax.config:Register("chat.radius.it", {
    Name = "config.chat.radius.it",
    Description = "config.chat.radius.it.help",
    Category = "config.chat",
    Type = ax.types.number,
    Default = 512,
    Min = 0,
    Max = 1000,
    Decimals = 0
})

ax.config:Register("chat.radius.looc", {
    Name = "config.chat.radius.looc",
    Description = "config.chat.radius.looc.help",
    Category = "config.chat",
    Type = ax.types.number,
    Default = 512,
    Min = 0,
    Max = 1000,
    Decimals = 0
})

ax.config:Register("chat.ooc", {
    Name = "config.chat.ooc",
    Description = "config.chat.ooc.help",
    Category = "config.chat",
    Type = ax.types.bool,
    Default = true,
})

ax.config:Register("currency.singular", {
    Name = "config.currency.singular",
    Description = "config.currency.singular.help",
    Category = "config.currency",
    Type = ax.types.string,
    Default = "Dollar"
})

ax.config:Register("currency.plural", {
    Name = "config.currency.plural",
    Description = "config.currency.plural.help",
    Category = "config.currency",
    Type = ax.types.string,
    Default = "Dollars"
})
ax.config:Register("currency.symbol", {
    Name = "config.currency.symbol",
    Description = "config.currency.symbol.help",
    Category = "config.currency",
    Type = ax.types.string,
    Default = "$"
})

ax.config:Register("currency.model", {
    Name = "config.currency.model",
    Description = "config.currency.model.help",
    Category = "config.currency",
    Type = ax.types.string,
    Default = "models/props_junk/cardboard_box004a.mdl"
})

ax.config:Register("mainmenu.branchwarning", {
    Name = "config.mainmenu.branchwarning",
    Description = "config.mainmenu.branchwarning.help",
    Category = "config.mainmenu",
    Type = ax.types.bool,
    Default = true
})

ax.config:Register("hands.max.carry", {
    Name = "config.hands.max.carry",
    Description = "config.hands.max.carry.help",
    Category = "config.hands",
    Type = ax.types.number,
    Default = 160,
    Min = 0,
    Max = 500,
    Decimals = 0
})

ax.config:Register("hands.max.force", {
    Name = "config.hands.max.force",
    Description = "config.hands.max.force.help",
    Category = "config.hands",
    Type = ax.types.number,
    Default = 16500,
    Min = 0,
    Max = 50000,
    Decimals = 0
})

ax.config:Register("hands.max.throw", {
    Name = "config.hands.max.throw",
    Description = "config.hands.max.throw.help",
    Category = "config.hands",
    Type = ax.types.number,
    Default = 150,
    Min = 0,
    Max = 256,
    Decimals = 0
})

ax.config:Register("hands.range", {
    Name = "config.hands.range",
    Description = "config.hands.range.help",
    Category = "config.hands",
    Type = ax.types.number,
    Default = 96,
    Min = 0,
    Max = 256,
    Decimals = 0
})

ax.config:Register("weapon.raise.time", {
    Name = "config.weapon.raise.time",
    Description = "config.weapon.raise.time.help",
    SubCategory = "config.weapon",
    Type = ax.types.number,
    Default = 1,
    Min = 0,
    Max = 5,
    Decimals = 1
})

ax.config:Register("weapon.raise.alwaysraised", {
    Name = "config.weapon.raise.alwaysraised",
    Description = "config.weapon.raise.alwaysraised.help",
    SubCategory = "config.weapon",
    Type = ax.types.bool,
    Default = false
})

ax.config:Register("debug.networking", {
    Name = "config.debug.networking",
    Description = "config.debug.networking.help",
    SubCategory = "config.debug",
    Type = ax.types.bool,
    Default = false
})

ax.config:Register("debug.developer", {
    Name = "config.debug.developer",
    Description = "config.debug.developer.help",
    SubCategory = "config.debug",
    Type = ax.types.bool,
    Default = false
})

ax.config:Register("debug.preview", {
    Name = "config.debug.preview",
    Description = "config.debug.preview.help",
    SubCategory = "config.debug",
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