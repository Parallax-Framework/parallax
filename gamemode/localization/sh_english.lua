ax.localization:Register("en", {
    -- General
    ["yes"] = "Yes",
    ["no"] = "No",
    ["ok"] = "OK",
    ["cancel"] = "Cancel",
    ["apply"] = "Apply",
    ["close"] = "Close",
    ["back"] = "Back",
    ["next"] = "Next",

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
    ["tab.help.modules"] = "Modules",
    ["tab.inventory"] = "Inventory",
    ["tab.scoreboard"] = "Scoreboard",
    ["tab.settings"] = "Settings",
    ["tab.characters"] = "Characters",

    -- Category Translations
    ["category.chat"] = "Chat",
    ["category.gameplay"] = "Gameplay",
    ["category.general"] = "General",
    ["category.audio"] = "Audio",
    ["category.interface"] = "Interface",
    ["category.modules"] = "Modules",
    ["category.schema"] = "Schema",

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
    ["config.hands.force.max"] = "Maximum Hand Force",
    ["config.hands.force.max.throw"] = "Maximum Throw Force",
    ["config.hands.max.carry"] = "Maximum Carry Weight",
    ["config.hands.range.max"] = "Maximum Reach Distance",

    ---- Inventory
    ["config.inventory.weight.max"] = "Inventory Max Weight",
    ["config.inventory.sync.delta"] = "Inventory Delta Sync",
    ["config.inventory.sync.debounce"] = "Inventory Sync Debounce",
    ["config.inventory.sync.full_refresh_interval"] = "Inventory Full Refresh Interval",
    ["config.inventory.action.rate_limit"] = "Inventory Action Rate Limit",
    ["config.inventory.transfer.rate_limit"] = "Inventory Transfer Rate Limit",
    ["config.inventory.pagination.default_page_size"] = "Inventory Default Page Size",
    ["config.inventory.pagination.max_page_size"] = "Inventory Max Page Size",
    ["config.inventory.restore.batch_size"] = "Inventory Restore Batch Size",
    ["config.inventory.sync.delta.help"] = "Enable delta inventory syncing to send only changed items.",
    ["config.inventory.sync.debounce.help"] = "Delay in seconds before sending inventory sync updates.",
    ["config.inventory.sync.full_refresh_interval.help"] = "Minimum seconds between full sync refreshes when delta sync is enabled.",
    ["config.inventory.action.rate_limit.help"] = "Minimum delay in seconds between item actions per player.",
    ["config.inventory.transfer.rate_limit.help"] = "Minimum delay in seconds between inventory transfer requests per player.",
    ["config.inventory.pagination.default_page_size.help"] = "Default number of item stacks per inventory page.",
    ["config.inventory.pagination.max_page_size.help"] = "Maximum number of item stacks allowed per page.",
    ["config.inventory.restore.batch_size.help"] = "Number of world inventory items restored per sync batch.",

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
    ["command.executionfailed"] = "That command failed to run. Try again.",
    ["command.unknownerror"] = "Something went wrong. Please try again.",

    --- General
    ---- Basic
    ["config.bot.support"] = "Bot Support",
    ["config.language"] = "Language",

    ---- Characters
    ["config.autosave.interval"] = "Character Autosave Interval",
    ["config.characters.max"] = "Max Characters",

    -- Audio
    ["config.proximity"] = "Enable Proximity Voice",
    ["config.proximityMaxDistance"] = "Proximity Max Distance",
    ["config.proximityMaxTraces"] = "Proximity Max Traces",
    ["config.proximityMaxVolume"] = "Proximity Max Volume",
    ["config.proximityMuteVolume"] = "Proximity Mute Volume",
    ["config.proximityUnMutedDistance"] = "Proximity Unmute Distance",

    -- Options Translations
    --- Chat
    ---- Basic
    ["option.chat.sounds"] = "Enable Chat Sounds",
    ["option.chat.timestamps"] = "Show Timestamps in Chat",
    ["option.chat.randomized.verbs"] = "Use Randomized Chat Verbs",
    ["option.chat.randomized.verbs.help"] = "When enabled, chat messages use varied verbs (exclaims, mutters, shouts). When disabled, they use the default verbs (says, whispers, yells).",

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
    ["option.interface.theme"] = "Interface Theme",
    ["option.interface.theme.help"] = "Choose the color theme for the interface.",
    ["option.interface.glass.roundness"] = "Glass Roundness",
    ["option.interface.glass.roundness.help"] = "Adjust the corner radius of glass UI elements.",
    ["option.interface.glass.blur"] = "Glass Blur Intensity",
    ["option.interface.glass.blur.help"] = "Control the blur strength behind glass UI elements.",
    ["option.interface.glass.opacity"] = "Glass Opacity",
    ["option.interface.glass.opacity.help"] = "Adjust the opacity of glass UI panels.",
    ["option.interface.glass.borderOpacity"] = "Glass Border Opacity",
    ["option.interface.glass.borderOpacity.help"] = "Control the visibility of glass UI borders.",
    ["option.interface.glass.gradientOpacity"] = "Glass Gradient Opacity",
    ["option.interface.glass.gradientOpacity.help"] = "Adjust the strength of gradient overlays on glass panels.",
    ["option.performance.animations"] = "Enable Interface Animations",

    -- Theme Names
    ["theme.dark"] = "Dark",
    ["theme.light"] = "Light",
    ["theme.blue"] = "Blue",
    ["theme.purple"] = "Purple",
    ["theme.green"] = "Green",
    ["theme.red"] = "Red",

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
    ["option.inventory.sort.categories"] = "Inventory Category Sort Mode",
    ["option.inventory.sort.items"] = "Inventory Item Sort Mode",
    ["option.inventory.search.live"] = "Live Inventory Search",
    ["option.inventory.categories.collapsible"] = "Collapsible Inventory Categories",
    ["option.inventory.pagination.page_size"] = "Inventory Page Size",
    ["option.inventory.actions.confirm_bulk_drop"] = "Confirm Bulk Drop Actions",
    ["option.inventory.sort.categories.help"] = "Choose how inventory categories are ordered.",
    ["option.inventory.sort.items.help"] = "Choose how items are ordered inside each category.",
    ["option.inventory.search.live.help"] = "Update search results while typing.",
    ["option.inventory.categories.collapsible.help"] = "Allow inventory categories to be collapsed and expanded.",
    ["option.inventory.pagination.page_size.help"] = "Number of inventory stacks shown per page.",
    ["option.inventory.actions.confirm_bulk_drop.help"] = "Ask for confirmation before dropping multiple items from a stack.",
    ["inventory.sort.alphabetical"] = "Alphabetical",
    ["inventory.sort.manual"] = "Manual",
    ["inventory.sort.weight"] = "Weight",
    ["inventory.sort.class"] = "Class",

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

    -- Chatbox
    ["chatbox.entry.placeholder"] = "Say something...",
    ["chatbox.recommendations.no_description"] = "No description provided.",
    ["chatbox.recommendations.truncated"] = "Showing first %d results.",
    ["chatbox.menu.close"] = "Close Chat",
    ["chatbox.menu.clear_history"] = "Clear Chat History",
    ["chatbox.menu.reset_position"] = "Reset Position",
    ["chatbox.menu.reset_size"] = "Reset Size",
    ["chatbox.menu.confirm_clear_title"] = "Clear Chat History",
    ["chatbox.menu.confirm_clear_message"] = "Clear all chat history?",

    ["config.chatbox.max_message_length"] = "Chatbox Max Message Length",
    ["config.chatbox.history_size"] = "Chatbox Input History Size",
    ["config.chatbox.chat_type_history"] = "Chatbox Chat Type History Size",
    ["config.chatbox.looc_prefix"] = "Chatbox LOOC Prefix",
    ["config.chatbox.recommendations.debounce"] = "Chatbox Recommendation Debounce",
    ["config.chatbox.recommendations.animation_duration"] = "Chatbox Recommendation Animation Duration",
    ["config.chatbox.recommendations.command_limit"] = "Chatbox Command Recommendation Limit",
    ["config.chatbox.recommendations.voice_limit"] = "Chatbox Voice Recommendation Limit",
    ["config.chatbox.recommendations.wrap_cycle"] = "Chatbox Recommendation Cycle Wrap",
})
