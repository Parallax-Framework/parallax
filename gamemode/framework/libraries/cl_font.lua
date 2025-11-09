--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Font management system for creating and storing fonts used throughout the Parallax Framework.
-- Supports font families with various styles and weights.
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

local families = {
    ["bold"] = "GorDIN Black",
    ["italic"] = "GorDIN Regular",
    ["italic.bold"] = "GorDIN Black"
}

--- Create a font family with various styles and weights.
-- Generates multiple font variations (bold, italic, etc.) from a base font definition.
-- @realm client
-- @param name string The base name for the font family
-- @param font string The font face name to use
-- @param size number The base font size
-- @param familiesOverride table Optional override for font family definitions
-- @param fontData table Optional additional font data to merge
-- @usage ax.font:CreateFamily("header", "Arial", 24)
function ax.font:CreateFamily(name, font, size, familiesOverride, fontData)
    if ( !font or font == "" ) then
        ax.util:PrintError("Failed to create font family '" .. name .. "': Font is not defined.")
        return
    end

    if ( !size or size <= 0 ) then
        ax.util:PrintError("Failed to create font family '" .. name .. "': Size is not defined or invalid.")
        return
    end

    -- Create the base font
    local createFontData = {
        font = font,
        size = size,
        weight = 700,
        antialias = true
    }

    table.Merge(createFontData, fontData or {})

    -- Multiply depending on size
    if ( createFontData.blursize ) then
        createFontData.blursize = math.floor(size / 4) + createFontData.blursize
    end

    surface.CreateFont("ax." .. name, createFontData)

    if ( familiesOverride ) then
        families = familiesOverride
    end

    for family, fontName in pairs(families) do
        if ( isstring(family) and isstring(fontName) ) then
            createFontData = {
                font = fontName,
                size = size,
                weight = ax.util:FindString(family, "bold") and 900 or 700,
                italic = ax.util:FindString(family, "italic"),
                antialias = true
            }

            table.Merge(createFontData, fontData or {})

            if ( createFontData.blursize ) then
                createFontData.blursize = math.floor(size / 4) + createFontData.blursize
            end

            surface.CreateFont("ax." .. name .. "." .. family, createFontData)
        else
            createFontData = {
                font = font,
                size = size,
                weight = ax.util:FindString(family, "bold") and 900 or 700,
                italic = ax.util:FindString(family, "italic"),
                antialias = true
            }

            table.Merge(createFontData, fontData or {})

            if ( createFontData.blursize ) then
                createFontData.blursize = math.floor(size / 4) + createFontData.blursize
            end

            surface.CreateFont("ax." .. name .. "." .. family, createFontData)
        end
    end

    ax.util:Print("Font family '" .. name .. "' created successfully.")
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

concommand.Add("ax_font_list", function(client, cmd, args)
    ax.util:Print("Available fonts:")

    for name, data in args[1] and SortedPairsByMemberValue(ax.font.stored, "size", true) or SortedPairs(ax.font.stored) do
        ax.util:Print(" - " .. name)
    end
end, nil, "List all available fonts in the Parallax Framework", FCVAR_HIDDEN)

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
AX_FONTS = {
    "ax.tiny",
    "ax.tiny.bold",
    "ax.tiny.italic",
    "ax.tiny.italic.bold",
    "ax.small",
    "ax.small.bold",
    "ax.small.italic",
    "ax.small.italic.bold",
    "ax.regular",
    "ax.regular.bold",
    "ax.regular.italic",
    "ax.regular.italic.bold",
    "ax.large",
    "ax.large.bold",
    "ax.large.italic",
    "ax.large.italic.bold",
    "ax.massive",
    "ax.massive.bold",
    "ax.massive.italic",
    "ax.massive.italic.bold",
    "ax.huge",
    "ax.huge.bold",
    "ax.huge.italic",
    "ax.huge.italic.bold"
}
