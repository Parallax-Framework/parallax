ax.localization:Register("en", {
    -- Main Menu Translations
    ["mainmenu.category.00_faction"] = "Factions",
    ["mainmenu.category.01_identity"] = "Identity",
    ["mainmenu.category.02_appearance"] = "Appearance",
    ["mainmenu.category.03_other"] = "Other",
    ["mainmenu.create"] = "Create Character",
    ["mainmenu.disconnect"] = "Disconnect",
    ["mainmenu.load"] = "Load Character",
    ["mainmenu.options"] = "Options",
    ["mainmenu.play"] = "Play",

    -- Tab Menu Translations
    ["tab.config"] = "Config",
    ["tab.help"] = "Help",
    ["tab.inventory"] = "Inventory",
    ["tab.scoreboard"] = "Scoreboard",
    ["tab.settings"] = "Settings",

    -- Category Translations
    ["category.chat"] = "Chat",
    ["category.gameplay"] = "Gameplay",
    ["category.general"] = "General",
    ["category.interface"] = "Interface",
    ["category.modules"] = "Modules",

    -- Subcategory Translations
    ["subcategory.basic"] = "Basic",
    ["subcategory.buttons"] = "Buttons",
    ["subcategory.characters"] = "Characters",
    ["subcategory.colors"] = "Colors",
    ["subcategory.display"] = "Display",
    ["subcategory.distances"] = "Distances",
    ["subcategory.fonts"] = "Fonts",
    ["subcategory.hud"] = "HUD",
    ["subcategory.interaction"] = "Interaction",
    ["subcategory.inventory"] = "Inventory",
    ["subcategory.movement"] = "Movement",
    ["subcategory.position"] = "Position",
    ["subcategory.size"] = "Size",
    ["subcategory.general"] = "General",
    ["subcategory.ooc"] = "OOC",

    -- Store Translations
    ["store.enabled"] = "Enabled",
    ["store.disabled"] = "Disabled",

    -- Config Translations
    --- Chat
    ---- Distances
    ["config.chat.ic.distance"] = "IC Chat Distance",
    ["config.chat.me.distance"] = "ME Chat Distance",
    ["config.chat.ooc.distance"] = "OOC Chat Distance",
    ["config.chat.yell.distance"] = "YELL Chat Distance",
    ["config.chat.ooc.enabled"] = "Enable OOC Chat",
    ["config.chat.ooc.delay"] = "OOC Message Delay (seconds)",
    ["config.chat.ooc.rate_limit"] = "OOC Messages per 10 minutes",

    --- Gameplay
    ---- Interaction
    ["config.hands.force.max"] = "Hands Max Hand Force",
    ["config.hands.force.max.throw"] = "Hands Max Throw Force",
    ["config.hands.max.carry"] = "Hands Max Carry Weight",
    ["config.hands.range.max"] = "Hands Max Reach Distance",

    ---- Inventory
    ["config.inventory.weight.max"] = "Inventory Max Weight",

    ---- Movement
    ["config.jump.power"] = "Jump Power",
    ["config.movement.bunnyhop.reduction"] = "Bunnyhop Speed Reduction",
    ["config.speed.run"] = "Run Speed",
    ["config.speed.walk"] = "Walk Speed",
    ["config.speed.walk.crouched"] = "Crouched Walk Speed",
    ["config.speed.walk.slow"] = "Slow Walk Speed",

    ---- Misc
    ["respawning"] = "Respawning...",
    ["command.notvalid"] = "That doesn't look like a real command.",
    ["command.notfound"] = "No command by that name. Check the spelling.",
    ["command.executionfailed"] = "That command tripped on the way out. Try again.",
    ["command.unknownerror"] = "Something went sideways. Please try again.",

    --- General
    ---- Basic
    ["config.bot.support"] = "Bot Support",
    ["config.language"] = "Language",

    ---- Characters
    ["config.autosave.interval"] = "Character Autosave Interval",
    ["config.characters.max"] = "Max Characters",

    -- Options Translations
    --- Chat
    ---- Basic
    ["option.chat.sounds"] = "Enable Chat Sounds",
    ["option.chat.timestamps"] = "Show Timestamps in Chat",
    ["option.chat.randomized.verbs"] = "Use Randomized Chat Verbs",
    ["option.chat.randomized.verbs.help"] = "When enabled, chat messages will use varied verbs (exclaims, mutters, shouts). When disabled, uses default verbs (says, whispers, yells).",

    ---- Position
    ["option.chat.x"] = "Chatbox X Position",
    ["option.chat.y"] = "Chatbox Y Position",

    ---- Size
    ["option.chat.width"] = "Chatbox Width",
    ["option.chat.height"] = "Chatbox Height",

    --- Interface
    ---- Chat
    ["config.chat.ic.color"] = "IC Chat Color",
    ["config.chat.me.color"] = "ME Chat Color",
    ["config.chat.ooc.color"] = "OOC Chat Color",
    ["config.chat.yell.color"] = "YELL Chat Color",
    ["config.chat.whisper.color"] = "WHISPER Chat Color",

    ---- Buttons
    ["option.button.delay.click"] = "Button Click Delay",

    ---- Display
    ["option.interface.scale"] = "Interface Scale",
    ["option.performance.animations"] = "Enable Interface Animations",

    ---- Fonts
    ["option.fontScaleGeneral"] = "General Font Scale",
    ["option.fontScaleGeneral.help"] = "General font scale multiplier.",
    ["option.fontScaleSmall"] = "Small Font Scale",
    ["option.fontScaleSmall.help"] = "Small font scale modifier. Lower values make small fonts bigger.",
    ["option.fontScaleBig"] = "Big Font Scale",
    ["option.fontScaleBig.help"] = "Big font scale modifier. Higher values make big fonts smaller.",

    ---- HUD
    ["option.hud.bar.armor.show"] = "Show Armor Bar",
    ["option.hud.bar.health.show"] = "Show Health Bar",
    ["option.notification.enabled"] = "Enable Notifications",
    ["option.notification.length.default"] = "Default Notification Length",
    ["option.notification.scale"] = "Notification Scale",
    ["option.notification.sounds"] = "Enable Notification Sounds",
    ["option.notification.position"] = "Notification Position",

    ---- Inventory
    ["option.inventory.categories.italic"] = "Italicize Category Names",
    ["option.inventory.columns"] = "Number of Inventory Columns",

    -- Inventory Translations
    ["inventory.weight.abbreviation"] = "kg",

    -- OOC / Notification Translations
    ["notify.chat.ooc.disabled"] = "OOC chat is currently disabled on this server.",
    ["notify.chat.ooc.wait"] = "Please wait %d second(s) before sending another OOC message.",
    ["notify.chat.ooc.rate_limited"] = "You have reached the OOC message limit (%d) for the last %d minutes.",

    ---- Flags
    ["flag.p.name"] = "Physgun Permission",
    ["flag.p.description"] = "Allows the use of the physgun.",

    ["flag.t.name"] = "Toolgun Permission",
    ["flag.t.description"] = "Allows the use of the toolgun.",

    ["config.interface.font.antialias"] = "Font Antialiasing",
    ["config.interface.font.multiplier"] = "Font Scale",

    ["config.interface.vignette.enabled"] = "Enable Vignette Effect",
    ["config.interface.vignette.enabled.help"] = "Toggle the vignette effect around the edges of the screen.",
})
