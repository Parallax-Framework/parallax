--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--[[
-- Don't know if there is are more efficient way to do this or to retrieve the languages from gmod itself.
local languages = {
    ["bg"] = "Bulgarian",
    ["cs"] = "Czech",
    ["da"] = "Danish",
    ["de"] = "German",
    ["el"] = "Greek",
    ["en"] = "English",
    ["en-PT"] = "English (Pirate)",
    ["es"] = "Spanish (Spain)",
    ["fi"] = "Finnish",
    ["fr"] = "French",
    ["he"] = "Hebrew",
    ["hr"] = "Croatian",
    ["hu"] = "Hungarian",
    ["it"] = "Italian",
    ["ja"] = "Japanese",
    ["ko"] = "Korean",
    ["nl"] = "Dutch",
    ["no"] = "Norwegian",
    ["pl"] = "Polish",
    ["pt"] = "Portuguese (Portugal)",
    ["pt-br"] = "Portuguese (Brazil)",
    ["ro"] = "Romanian",
    ["ru"] = "Russian",
    ["sk"] = "Slovak",
    ["sr"] = "Serbian",
    ["sv"] = "Swedish",
    ["th"] = "Thai",
    ["tr"] = "Turkish",
    ["uk"] = "Ukrainian",
    ["vi"] = "Vietnamese",
    ["zh-cn"] = "Chinese (Simplified)",
    ["zh-tw"] = "Chinese (Traditional)",
}

ax.option:Register("language", {
    Name = "options.language",
    Description = "options.language.help",
    Type = ax.types.array,
    Default = "en",
    OnChange = function(self, value)
        -- GMOD blocks the console command gmod_language from being run in the console
        RunConsoleCommand("gmod_language", value)
    end,
    Populate = function()
        return languages
    end
})
]]

ax.option:Register("inventory.sort", {
    Name = "options.inventory.sort",
    Description = "options.inventory.sort.help",
    Type = ax.types.array,
    Default = "name",
    NoNetworking = true,
    Populate = function()
        return {
            ["name"] = "Name",
            ["weight"] = "Weight",
            ["category"] = "Category",
        }
    end
})

ax.option:Register("hud.crosshair", {
    Name = "options.hud.crosshair",
    Description = "options.hud.crosshair.help",
    Category = "category.hud",
    SubCategory = "category.crosshair",
    Type = ax.types.bool,
    Default = true,
    NoNetworking = true
})

ax.option:Register("hud.crosshair.color", {
    Name = "options.hud.crosshair.color",
    Description = "options.hud.crosshair.color.help",
    Category = "category.hud",
    SubCategory = "category.crosshair",
    Type = ax.types.color,
    Default = color_white,
    NoNetworking = true
})

ax.option:Register("hud.crosshair.size", {
    Name = "options.hud.crosshair.size",
    Description = "options.hud.crosshair.size.help",
    Category = "category.hud",
    SubCategory = "category.crosshair",
    Type = ax.types.number,
    Default = 1,
    NoNetworking = true,
    Min = 0.1,
    Max = 5,
    Decimals = 1
})

ax.option:Register("hud.crosshair.thickness", {
    Name = "options.hud.crosshair.thickness",
    Description = "options.hud.crosshair.thickness.help",
    Category = "category.hud",
    SubCategory = "category.crosshair",
    Type = ax.types.number,
    Default = 1,
    NoNetworking = true,
    Min = 1,
    Max = 5,
    Decimals = 1
})

ax.option:Register("hud.crosshair.type", {
    Name = "options.hud.crosshair.type",
    Description = "options.hud.crosshair.type.help",
    Category = "category.hud",
    SubCategory = "category.crosshair",
    Type = ax.types.array,
    Default = "cross",
    NoNetworking = true,
    Populate = function()
        return {
            ["cross"] = "Cross",
            ["rectangle"] = "Rectangle",
            ["circle"] = "Circle"
        }
    end
})

ax.option:Register("hud.health.bar", {
    Name = "options.hud.health.bar",
    Description = "options.hud.health.bar.help",
    Category = "category.hud",
    SubCategory = "category.hud.health",
    Type = ax.types.bool,
    Default = true,
    NoNetworking = true
})

ax.option:Register("hud.health.bar.always", {
    Name = "options.hud.health.bar.always",
    Description = "options.hud.health.bar.always.help",
    Category = "category.hud",
    SubCategory = "category.hud.health",
    Type = ax.types.bool,
    Default = false,
    NoNetworking = true
})

ax.option:Register("hud.vignette", {
    Name = "options.hud.vignette",
    Description = "options.hud.vignette.help",
    Category = "category.hud",
    Type = ax.types.bool,
    Default = true,
    NoNetworking = true
})

ax.option:Register("tab.fade.time", {
    Name = "options.tab.fade.time",
    Description = "options.tab.fade.time.help",
    Type = ax.types.number,
    NoNetworking = true,
    Default = 0.4,
    Min = 0,
    Max = 1,
    Decimals = 2
})

ax.option:Register("tab.anchor.time", {
    Name = "options.tab.anchor.time",
    Description = "options.tab.anchor.time.help",
    Type = ax.types.number,
    Default = 0.4,
    NoNetworking = true,
    Min = 0,
    Max = 1,
    Decimals = 2
})

ax.option:Register("mainmenu.music", {
    Name = "options.mainmenu.music",
    Description = "options.mainmenu.music.help",
    SubCategory = "category.mainmenu",
    Type = ax.types.bool,
    Default = true,
    NoNetworking = true
})

ax.option:Register("mainmenu.music.volume", {
    Name = "options.mainmenu.music.volume",
    Description = "options.mainmenu.music.volume.help",
    SubCategory = "category.mainmenu",
    Type = ax.types.number,
    Default = 50,
    NoNetworking = true,
    Min = 0,
    Max = 100,
    Decimals = 0
})

ax.option:Register("mainmenu.music.loop", {
    Name = "options.mainmenu.music.loop",
    Description = "options.mainmenu.music.loop.help",
    SubCategory = "category.mainmenu",
    Type = ax.types.bool,
    Default = true,
    NoNetworking = true
})

ax.option:Register("performance.blur", {
    Name = "options.performance.blur",
    Description = "options.performance.blur.help",
    Category = "category.performance",
    Type = ax.types.bool,
    Default = true,
    NoNetworking = true
})

ax.option:Register("performance.animations", {
    Name = "options.performance.animations",
    Description = "options.performance.animations.help",
    Category = "category.performance",
    Type = ax.types.bool,
    Default = true,
    NoNetworking = true
})

ax.option:Register("chat.size.font", {
    Name = "options.chat.size.font",
    Description = "options.chat.size.font.help",
    Category = "category.chat",
    Type = ax.types.number,
    Default = 1,
    NoNetworking = true,
    Min = 0,
    Max = 2,
    Decimals = 2,
    OnChange = function(self, value)
        hook.Run("LoadFonts")

        for i = 1, #ax.chat.messages do
            local v = ax.chat.messages[i]
            if ( !IsValid(v) ) then continue end

            v:SizeToContents()
        end
    end
})