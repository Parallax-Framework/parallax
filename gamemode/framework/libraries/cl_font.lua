--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Font management system for creating and storing fonts used throughout the Parallax Framework.
-- Automatically generates all possible combinations of font styles for each font family.
-- Supports: bold, italic, underline, strikeout, and all their combinations.
--
-- @usage
-- -- Use any combination of styles:
-- draw.SimpleText("Hello", "ax.regular.bold.italic", x, y)
-- draw.SimpleText("World", "ax.large.underline.strikeout", x, y)
-- draw.SimpleText("!", "ax.huge.bold.italic.underline.strikeout", x, y)
--
-- @module ax.font

ax.font = ax.font or {}
ax.font.stored = ax.font.stored or {}

surface.axCreateFont = surface.axCreateFont or surface.CreateFont

function surface.CreateFont(name, data)
    if ( !isstring(name) or !istable(data) ) then
        ax.util:PrintError("Invalid parameters for surface.CreateFont: " .. tostring(name) .. ", " .. tostring(data))
        return
    end

    if ( string.StartsWith(name, "ax.") or string.StartsWith(name, "Parallax") ) then
        ax.font.stored[name] = data
    end

    surface.axCreateFont(name, data)
end

local styleModifiers = { "bold", "italic", "strikeout", "underline" }

--- Generate all style combinations (cached)
-- @realm client
-- @return table Array of all style combinations
function ax.font:GenerateStyleCombinations()
    if ( self.styleCombinations ) then return self.styleCombinations end

    self.styleCombinations = { "" }
    for i = 1, 15 do -- 2^4 - 1
        local combo = {}
        for j = 1, 4 do
            if ( bit.band(i, bit.lshift(1, j - 1)) != 0 ) then
                table.insert(combo, styleModifiers[j])
            end
        end
        table.sort(combo)
        table.insert(self.styleCombinations, table.concat(combo, "."))
    end

    return self.styleCombinations
end

--- Create a font family with all style variations
-- @realm client
-- @param name string The base name for the font family
-- @param font string The font face name
-- @param size number The font size
-- @param fontData table Optional additional font data
function ax.font:CreateFamily(name, font, size, fontData)
    if ( !font or !size or size <= 0 ) then
        ax.util:PrintError("Invalid font family '" .. name .. "'")
        return
    end

    local combinations = self:GenerateStyleCombinations()

    for _, combo in ipairs(combinations) do
        local fontName = "ax." .. name .. (combo != "" and ("." .. combo) or "")
        local data = {
            font = string.find(combo, "bold", 1, true) and "GorDIN Black" or font,
            size = size,
            weight = string.find(combo, "bold", 1, true) and 900 or 700,
            italic = string.find(combo, "italic", 1, true) and true or false,
            underline = string.find(combo, "underline", 1, true) and true or false,
            strikeout = string.find(combo, "strikeout", 1, true) and true or false,
            antialias = true,
            extended = true
        }

        table.Merge(data, fontData or {})
        surface.CreateFont(fontName, data)
    end

    ax.util:Print("Font family '" .. name .. "' created with " .. #combinations .. " variations.")
end

function ax.font:Load()
    ax.font:CreateFamily("tiny", "GorDIN Regular", ax.util:ScreenScaleH(6))
    ax.font:CreateFamily("small", "GorDIN Regular", ax.util:ScreenScaleH(8))
    ax.font:CreateFamily("regular", "GorDIN Regular", ax.util:ScreenScaleH(10))
    ax.font:CreateFamily("medium", "GorDIN Regular", ax.util:ScreenScaleH(12))
    ax.font:CreateFamily("large", "GorDIN Regular", ax.util:ScreenScaleH(16))
    ax.font:CreateFamily("massive", "GorDIN Regular", ax.util:ScreenScaleH(24))
    ax.font:CreateFamily("huge", "GorDIN Regular", ax.util:ScreenScaleH(32))

    hook.Run("LoadFonts")
end

--- Generate list of all available fonts
-- @realm client
-- @return table Array of all font names
function ax.font:GenerateAvailableFonts()
    local fonts = {}
    local baseFonts = { "tiny", "small", "regular", "medium", "large", "massive", "huge" }

    for _, baseName in ipairs(baseFonts) do
        for _, combo in ipairs(self:GenerateStyleCombinations()) do
            fonts[#fonts + 1] = "ax." .. baseName .. (combo != "" and ("." .. combo) or "")
        end
    end

    return fonts
end

concommand.Add("ax_font_list", function(client, cmd, args)
    if ( args[1] == "combinations" ) then
        local combinations = ax.font:GenerateStyleCombinations()
        ax.util:Print("Available style combinations (" .. #combinations .. " total):")
        for _, combo in ipairs(combinations) do
            ax.util:Print(" - " .. (combo == "" and "(base)" or combo))
        end
        return
    end

    ax.util:Print("Available fonts:")
    for name, data in args[1] and SortedPairsByMemberValue(ax.font.stored, "size", true) or SortedPairs(ax.font.stored) do
        ax.util:Print(" - " .. name)
    end
end, nil, "List all available fonts in the Parallax Framework. Use 'ax_font_list combinations' to see all style combinations.", FCVAR_HIDDEN)

concommand.Add("ax_font_reload", function(client, cmd, args)
    ax.font:Load()
end, nil, "Reload all fonts in the Parallax Framework", FCVAR_HIDDEN)

concommand.Add("ax_font_wipe", function(client, cmd, args)
    for name, data in pairs(ax.font.stored) do
        if ( string.StartsWith(name, "ax.") or string.StartsWith(name, "Parallax") ) then
            surface.CreateFont(name, data)
        end
    end
    ax.util:Print("Wiped and reloaded all Parallax Framework fonts.")
end, nil, "Wipe and reload all Parallax Framework fonts", FCVAR_HIDDEN)

--- Available fonts registered in the Parallax Framework
-- @table AX_FONTS
AX_FONTS = ax.font:GenerateAvailableFonts()
