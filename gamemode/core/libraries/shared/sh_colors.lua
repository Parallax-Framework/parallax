----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 --- Made by a transgender queen
 -- Slay queen Riggs
 -- Stay Powerfull against the Patiarchy by a man (Alex Grist) stealing code
 -- #OverwatchFramework #CodeStealingMatters

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Colors library
-- @module ax.color

ax.color = {}
ax.color.stored = {}

--- Registers a new color.
-- @realm shared
-- @param info A table containing information about the color.
function ax.color:Register(name, color)
    if ( !isstring(name) or #name == 0 ) then
        ax.util:PrintError("Attempted to register a color without a name!")
        return false
    end

    if ( !ax.util:CoerceType(ax.types.color, color) ) then
        ax.util:PrintError("Attempted to register a color without a color!")
        return false
    end

    local bResult = hook.Run("PreColorRegistered", name, color)
    if ( bResult == false ) then return false end

    self.stored[name] = color
    hook.Run("OnColorRegistered", name, color)
end

--- Gets a color by its name.
-- @realm shared
-- @param name The name of the color.
-- @return The color.
function ax.color:Get(name)
    local storedColor = self.stored[name]
    if ( ax.util:CoerceType(ax.types.color, storedColor) ) then
        return Color(storedColor.r, storedColor.g, storedColor.b, storedColor.a or 255)
    end

    ax.util:PrintError("Attempted to get a color that does not exist: " .. tostring(name))
    return Color(255, 255, 255, 255)
end

--- Dims a color by a specified fraction.
-- @realm shared
-- @param col Color The color to dim.
-- @param frac number The fraction to dim the color by.
-- @return Color The dimmed color.
function ax.color:Dim(col, frac)
    return Color(col.r * frac, col.g * frac, col.b * frac, col.a)
end

--- Returns whether or not a color is dark.
-- @realm shared
-- @param col Color The color to check.
-- @return boolean True if the color is dark, false otherwise.
-- @note A color is considered dark if its luminance is less than 0.5.
function ax.color:IsDark(col)
    if ( !ax.util:CoerceType(ax.types.color, col) ) then
        ax.util:PrintError("Attempted to check if a color is dark without a valid color!")
        return false
    end

    local r, g, b = col.r / 255, col.g / 255, col.b / 255

    local luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
    return luminance < 0.5
end

local string = string

local hex_to_dec = {}
for code = 48, 57 do hex_to_dec[code] = code - 48 end
for code = 65, 70 do hex_to_dec[code] = code - 55 end
for code = 97, 102 do hex_to_dec[code] = code - 87 end

function HexToColor(hex)
    local idx = string.byte(hex, 1) == 35 and 2 or 1 -- '#' check without allocation
    local len = #hex - (idx - 1)

    if len == 3 or len == 4 then
        local r, g, b, a = string.byte(hex, idx, idx + len - 1)
        r = hex_to_dec[r]
        g = hex_to_dec[g]
        b = hex_to_dec[b]
        a = a and hex_to_dec[a] or 15

        if ( !r and !g and !b and !a ) then
            return ax.util:PrintError("invalid hex input: " .. hex)
        end

        return Color(r * 16 + r, g * 16 + g, b * 16 + b, a * 16 + a)
    elseif ( len == 6 or len == 8 ) then
        local r1, r2, g1, g2, b1, b2, a1, a2 = string.byte(hex, idx, idx + len - 1)
        r1, r2 = hex_to_dec[r1], hex_to_dec[r2]
        g1, g2 = hex_to_dec[g1], hex_to_dec[g2]
        b1, b2 = hex_to_dec[b1], hex_to_dec[b2]

        a1, a2 = a1 and hex_to_dec[a1] or 15, a2 and hex_to_dec[a2] or 15

        if ( !r1 and !r2 and !g1 and !g2 and !b1 and !b2 and !a1 and !a2 ) then
            return ax.util:PrintError("invalid hex input: " .. hex)
        end

        return Color(r1 * 16 + r2, g1 * 16 + g2, b1 * 16 + b2, a1 * 16 + a2)
    end

    return ax.util:PrintError("invalid hex input: " .. hex)
end

function ax.color:ToHex(color)
    if ( !ax.util:CoerceType(ax.types.color, color) ) then
        ax.util:PrintError("Attempted to convert a color to hex without a valid color!")
        return "#FFFFFF"
    end

    if ( color.a == 255 ) then
        return string.format("#%02x%02x%02x", color.r, color.g, color.b)
    end

    return string.format("#%02x%02x%02x%02x", color.r, color.g, color.b, color.a)
end

if ( CLIENT ) then
    concommand.Add("ax_list_colors", function(client, cmd, arguments)
        for k, v in pairs(ax.color.stored) do
            ax.util:Print("Color: " .. k .. " >> ", ax.color:Get("cyan"), v, " Sample")
        end
    end)
end