--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

-- Configuration options for weapon selection using ax.option
if ( CLIENT ) then
    -- Basic settings
    ax.option:Register("weaponselect.enabled", {
        Name = "Enable Weapon Selection",
        Description = "Enable or disable the weapon selection system.",
        Category = "category.weaponselect",
        Type = ax.types.bool,
        Default = true,
        NoNetworking = true
    })

    ax.option:Register("weaponselect.fadetime", {
        Name = "Fade Time",
        Description = "How long the weapon selection stays visible in seconds.",
        Category = "category.weaponselect",
        Type = ax.types.number,
        Default = 5,
        Min = 1,
        Max = 15,
        NoNetworking = true
    })

    ax.option:Register("weaponselect.animspeed", {
        Name = "Animation Speed",
        Description = "Speed of weapon selection animations.",
        Category = "category.weaponselect",
        Type = ax.types.number,
        Default = 8,
        Min = 1,
        Max = 20,
        NoNetworking = true
    })

    ax.option:Register("weaponselect.alpha", {
        Name = "Background Alpha",
        Description = "Background opacity of weapon selection.",
        Category = "category.weaponselect",
        Type = ax.types.number,
        Default = 150,
        Min = 0,
        Max = 255,
        NoNetworking = true
    })

    -- Visual settings
    ax.option:Register("weaponselect.position.x", {
        Name = "Position X",
        Description = "Horizontal position of the weapon selection panel (0-1).",
        Category = "category.weaponselect",
        SubCategory = "category.weaponselect.position",
        Type = ax.types.number,
        Default = 0.05,
        Min = 0,
        Max = 1,
        Decimals = 2,
        NoNetworking = true
    })

    ax.option:Register("weaponselect.position.y", {
        Name = "Position Y",
        Description = "Vertical position of the weapon selection panel (0-1).",
        Category = "category.weaponselect",
        SubCategory = "category.weaponselect.position",
        Type = ax.types.number,
        Default = 0.5,
        Min = 0,
        Max = 1,
        Decimals = 2,
        NoNetworking = true
    })

    ax.option:Register("weaponselect.size.width", {
        Name = "Panel Width",
        Description = "Width of the weapon selection panel in pixels.",
        Category = "category.weaponselect",
        SubCategory = "category.weaponselect.size",
        Type = ax.types.number,
        Default = 400,
        Min = 300,
        Max = 800,
        NoNetworking = true
    })

    ax.option:Register("weaponselect.size.height", {
        Name = "Panel Height",
        Description = "Height of the weapon selection panel in pixels.",
        Category = "category.weaponselect",
        SubCategory = "category.weaponselect.size",
        Type = ax.types.number,
        Default = 600,
        Min = 400,
        Max = 1000,
        NoNetworking = true
    })

    -- Effects
    ax.option:Register("weaponselect.blur.enabled", {
        Name = "Enable Blur",
        Description = "Enable background blur effect when weapon selection is open.",
        Category = "category.weaponselect",
        SubCategory = "category.weaponselect.effects",
        Type = ax.types.bool,
        Default = true,
        NoNetworking = true
    })

    ax.option:Register("weaponselect.blur.intensity", {
        Name = "Blur Intensity",
        Description = "Intensity of the background blur effect.",
        Category = "category.weaponselect",
        SubCategory = "category.weaponselect.effects",
        Type = ax.types.number,
        Default = 3,
        Min = 1,
        Max = 10,
        NoNetworking = true
    })

    ax.option:Register("weaponselect.glow.enabled", {
        Name = "Enable Glow",
        Description = "Enable glow effect around the weapon selection panel.",
        Category = "category.weaponselect",
        SubCategory = "category.weaponselect.effects",
        Type = ax.types.bool,
        Default = true,
        NoNetworking = true
    })

    ax.option:Register("weaponselect.particles.enabled", {
        Name = "Enable Particles",
        Description = "Enable particle effects for weapon selection.",
        Category = "category.weaponselect",
        SubCategory = "category.weaponselect.effects",
        Type = ax.types.bool,
        Default = true,
        NoNetworking = true
    })

    -- Audio
    ax.option:Register("weaponselect.sounds.enabled", {
        Name = "Enable Sounds",
        Description = "Enable sound effects for weapon selection.",
        Category = "category.weaponselect",
        SubCategory = "category.weaponselect.audio",
        Type = ax.types.bool,
        Default = true,
        NoNetworking = true
    })

    ax.option:Register("weaponselect.sounds.volume", {
        Name = "Sound Volume",
        Description = "Volume of weapon selection sound effects.",
        Category = "category.weaponselect",
        SubCategory = "category.weaponselect.audio",
        Type = ax.types.number,
        Default = 0.5,
        Min = 0,
        Max = 1,
        Decimals = 1,
        NoNetworking = true
    })

    -- Content
    ax.option:Register("weaponselect.categories.enabled", {
        Name = "Show Categories",
        Description = "Group weapons by categories in the selection menu.",
        Category = "category.weaponselect",
        SubCategory = "category.weaponselect.content",
        Type = ax.types.bool,
        Default = false,
        NoNetworking = true
    })

    ax.option:Register("weaponselect.descriptions.enabled", {
        Name = "Show Descriptions",
        Description = "Show weapon descriptions in the selection menu.",
        Category = "category.weaponselect",
        SubCategory = "category.weaponselect.content",
        Type = ax.types.bool,
        Default = true,
        NoNetworking = true
    })

    ax.option:Register("weaponselect.keybind.enabled", {
        Name = "Enable Keybinds",
        Description = "Allow custom keybinds for weapon selection.",
        Category = "category.weaponselect",
        SubCategory = "category.weaponselect.content",
        Type = ax.types.bool,
        Default = true,
        NoNetworking = true
    })

    -- Advanced
    ax.option:Register("weaponselect.animations.easing", {
        Name = "Animation Easing",
        Description = "Type of easing function for animations.",
        Category = "category.weaponselect",
        SubCategory = "category.weaponselect.advanced",
        Type = ax.types.array,
        Default = "OutQuad",
        NoNetworking = true,
        Populate = function()
            return {
                ["Linear"] = "Linear",
                ["InQuad"] = "In Quad", ["OutQuad"] = "Out Quad", ["InOutQuad"] = "In Out Quad",
                ["InCubic"] = "In Cubic", ["OutCubic"] = "Out Cubic", ["InOutCubic"] = "In Out Cubic",
                ["InQuart"] = "In Quart", ["OutQuart"] = "Out Quart", ["InOutQuart"] = "In Out Quart",
                ["InBack"] = "In Back", ["OutBack"] = "Out Back", ["InOutBack"] = "In Out Back",
                ["InBounce"] = "In Bounce", ["OutBounce"] = "Out Bounce", ["InOutBounce"] = "In Out Bounce"
            }
        end
    })

    ax.option:Register("weaponselect.theme", {
        Name = "Theme",
        Description = "Visual theme for the weapon selection interface.",
        Category = "category.weaponselect",
        SubCategory = "category.weaponselect.advanced",
        Type = ax.types.array,
        Default = "Dark",
        NoNetworking = true,
        Populate = function()
            return {
                ["Dark"] = "Dark",
                ["Light"] = "Light",
                ["Blue"] = "Blue",
                ["Green"] = "Green",
                ["Red"] = "Red",
                ["Purple"] = "Purple",
                ["Orange"] = "Orange"
            }
        end
    })

    -- Color themes
    MODULE.Themes = {
        Dark = {
            background = Color(20, 20, 30),
            item = Color(40, 40, 50),
            selected = Color(100, 150, 255),
            text = Color(255, 255, 255),
            textDim = Color(160, 160, 180, 255),
            accent = Color(100, 150, 255)
        },
        Light = {
            background = Color(240, 240, 250),
            item = Color(220, 220, 230),
            selected = Color(100, 150, 255),
            text = Color(20, 20, 30),
            textDim = Color(50, 50, 60),
            accent = Color(100, 150, 255)
        },
        Blue = {
            background = Color(15, 25, 40),
            item = Color(25, 35, 55),
            selected = Color(70, 130, 255),
            text = Color(200, 220, 255),
            textDim = Color(160, 160, 180, 255),
            accent = Color(70, 130, 255)
        },
        Green = {
            background = Color(15, 30, 20),
            item = Color(25, 45, 30),
            selected = Color(100, 255, 150),
            text = Color(200, 255, 220),
            textDim = Color(160, 160, 180, 255),
            accent = Color(100, 255, 150)
        },
        Red = {
            background = Color(30, 15, 15),
            item = Color(45, 25, 25),
            selected = Color(255, 100, 100),
            text = Color(255, 200, 200),
            textDim = Color(160, 160, 180, 255),
            accent = Color(255, 100, 100)
        },
        Purple = {
            background = Color(25, 15, 30),
            item = Color(40, 25, 45),
            selected = Color(200, 100, 255),
            text = Color(230, 200, 255),
            textDim = Color(160, 160, 180, 255),
            accent = Color(200, 100, 255)
        },
        Orange = {
            background = Color(30, 20, 10),
            item = Color(45, 35, 20),
            selected = Color(255, 150, 50),
            text = Color(255, 230, 200),
            textDim = Color(160, 160, 180, 255),
            accent = Color(255, 150, 50)
        }
    }

    -- Get current theme colors
    function MODULE:GetThemeColors()
        local themeName = ax.option:Get("weaponselect.theme", "Dark")
        return self.Themes[themeName] or self.Themes.Dark
    end

    -- Get theme-appropriate alpha values
    function MODULE:GetThemeAlpha(baseAlpha)
        local theme = ax.option:Get("weaponselect.theme", "Dark")
        local multiplier = 1.0

        if ( theme == "Light" ) then
            multiplier = 0.9
        end

        return baseAlpha * multiplier
    end
end
