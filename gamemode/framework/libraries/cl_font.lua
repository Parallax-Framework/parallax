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
-- Supports: bold, italic, shadow, and all their combinations.
--
-- @usage
-- -- Use any combination of styles:
-- draw.SimpleText("Hello", "ax.regular.bold.italic", x, y)
-- draw.SimpleText("World", "ax.large.shadow", x, y + 20)
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

local styleModifiers = { "bold", "italic", "shadow" }

--- Generate all permutations of a table
-- @realm client
-- @param arr table The array to permute
-- @return table Array of all permutations
local function GeneratePermutations(arr)
    if ( #arr == 0 ) then return { {} } end
    if ( #arr == 1 ) then return { arr } end

    local result = {}
    for i = 1, #arr do
        local elem = arr[i]
        local remaining = {}
        for j = 1, #arr do
            if ( j != i ) then
                table.insert(remaining, arr[j])
            end
        end

        local perms = GeneratePermutations(remaining)
        for _, perm in ipairs(perms) do
            local new = { elem }
            for _, v in ipairs(perm) do
                table.insert(new, v)
            end
            table.insert(result, new)
        end
    end

    return result
end

--- Generate all style combinations with all orderings (cached)
-- @realm client
-- @return table Array of all style combinations
function ax.font:GenerateStyleCombinations()
    if ( self.styleCombinations ) then
        return self.styleCombinations
    end

    self.styleCombinations = { "" }

    local seen = { [""] = true }
    for i = 1, bit.lshift(1, #styleModifiers) - 1 do
        local combo = {}
        for j = 1, #styleModifiers do
            if ( bit.band(i, bit.lshift(1, j - 1)) != 0 ) then
                table.insert(combo, styleModifiers[j])
            end
        end

        -- Generate all permutations of this combination
        local perms = GeneratePermutations(combo)
        for _, perm in ipairs(perms) do
            local str = table.concat(perm, ".")
            if ( !seen[str] ) then
                seen[str] = true
                table.insert(self.styleCombinations, str)
            end
        end
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
            shadow = string.find(combo, "shadow", 1, true) and true or false,
            antialias = true,
            extended = true
        }

        table.Merge(data, fontData or {})
        surface.CreateFont(fontName, data)
    end

    ax.util:Print("Font family '" .. name .. "' created with " .. #combinations .. " variations.")
end

function ax.font:Load()
    local generalScale = ax.option:Get("fontScaleGeneral", 1)
    local smallScale = ax.option:Get("fontScaleSmall", 1)
    local bigScale = ax.option:Get("fontScaleBig", 1)

    local baseSizes = {
        tiny = 6,
        small = 8,
        regular = 10,
        medium = 12,
        large = 16,
        massive = 24,
        huge = 32
    }

    local smallFamilies = { "tiny", "small", "regular" }
    local bigFamilies = { "medium", "large", "massive", "huge" }

    for name, base in pairs(baseSizes) do
        local scale = generalScale
        if ( table.HasValue(smallFamilies, name) ) then
            scale = scale / smallScale
        elseif ( table.HasValue(bigFamilies, name) ) then
            scale = scale / bigScale
        end
        local size = ax.util:ScreenScaleH(base) * scale
        ax.font:CreateFamily(name, "GorDIN Regular", size)
    end

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
