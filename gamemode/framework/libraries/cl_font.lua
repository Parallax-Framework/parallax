--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

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
        createFontData.blursize = math.max(2, math.floor(size / 8))
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

            if ( createFontData.blursize ) then
                createFontData.blursize = math.max(2, math.floor(size / 8))
            end

            table.Merge(createFontData, fontData or {})

            surface.CreateFont("ax." .. name .. "." .. family, createFontData)
        else
            createFontData = {
                font = font,
                size = size,
                weight = ax.util:FindString(family, "bold") and 900 or 700,
                italic = ax.util:FindString(family, "italic"),
                antialias = true
            }

            if ( createFontData.blursize ) then
                createFontData.blursize = math.max(2, math.floor(size / 8))
            end

            table.Merge(createFontData, fontData or {})

            surface.CreateFont("ax." .. name .. "." .. family, createFontData)
        end
    end

    ax.util:Print("Font family '" .. name .. "' created successfully.")
end

function ax.font:Load()
    ax.font:CreateFamily("tiny", "GorDIN Regular", ScreenScaleH(6))
    ax.font:CreateFamily("small", "GorDIN Regular", ScreenScaleH(8))
    ax.font:CreateFamily("regular", "GorDIN Regular", ScreenScaleH(10))
    ax.font:CreateFamily("large", "GorDIN Regular", ScreenScaleH(16))
    ax.font:CreateFamily("massive", "GorDIN Regular", ScreenScaleH(24))
    ax.font:CreateFamily("huge", "GorDIN Regular", ScreenScaleH(32))

    hook.Run("LoadFonts")
end

concommand.Add("ax_font_list", function(client, cmd, args)
    ax.util:Print("Available fonts:")

    for name, data in (args[1] and SortedPairsByMemberValue(ax.font.stored, "size", true) or SortedPairs(ax.font.stored)) do
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