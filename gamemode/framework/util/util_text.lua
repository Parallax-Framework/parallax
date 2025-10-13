--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Utility helpers used across the Parallax framework (printing, file handling, text utilities, etc.).
-- @module ax.util

--- Text utilities.
-- @section text_utilities

--- Cap text to a maximum number of characters, adding ellipsis when trimmed.
-- @param text string Text to cap
-- @param maxLength number Maximum number of characters
-- @return string The truncated text (with ellipsis when trimmed)
-- @usage local short = ax.util:CapText(longText, 32)
function ax.util:CapText(text, maxLength)
    if ( !isstring(text) or !isnumber(maxLength) or maxLength <= 0 ) then
        ax.util:PrintError("Attempted to cap text with invalid parameters", text, maxLength)
        return ""
    end

    if ( #text <= maxLength ) then
        return text
    end

    return string.sub(text, 1, maxLength - 3) .. "..."
end

--- Cap text at a word boundary to avoid breaking words when truncating.
-- @param text string Text to cap
-- @param maxLength number Maximum number of characters
-- @return string The truncated text at a word boundary
-- @usage local short = ax.util:CapTextWord(longText, 50)
function ax.util:CapTextWord(text, maxLength)
    if ( !isstring(text) or !isnumber(maxLength) or maxLength <= 0 ) then
        ax.util:PrintError("Attempted to cap text with invalid parameters", text, maxLength)
        return ""
    end

    if ( #text <= maxLength ) then
        return text
    end

    local words = string.Explode(" ", text)
    local cappedText = ""

    for i = 1, #words do
        local word = words[i]
        if ( #cappedText + #word + 1 > maxLength ) then
            break
        end

        if ( cappedText != "" ) then
            cappedText = cappedText .. " "
        end

        cappedText = cappedText .. word
    end

    return cappedText .. "..."
end

if ( CLIENT ) then
    --- Wraps text into multiple lines based on a maximum width (client-only).
    -- @param text string Text to wrap
    -- @param font string Font name used to measure text
    -- @param maxWidth number Maximum width in pixels
    -- @return table An array of line strings
    -- @usage local lines = ax.util:GetWrappedText("Hello world", "Default", 200)
    function ax.util:GetWrappedText(text, font, maxWidth)
        if ( !isstring(text) or !isstring(font) or !isnumber(maxWidth) ) then
            ax.util:PrintError("Attempted to wrap text with no value", text, font, maxWidth)
            return false
        end

        local lines = {}
        local line = ""

        if ( self:GetTextWidth(font, text) <= maxWidth ) then
            return {text}
        end

        local words = string.Explode(" ", text)

        for i = 1, #words do
            local word = words[i]
            local wordWidth = self:GetTextWidth(font, word)

            if ( wordWidth > maxWidth ) then
                for j = 1, string.len(word) do
                    local char = string.sub(word, j, j)
                    local next = line .. char

                    if ( self:GetTextWidth(font, next) > maxWidth ) then
                        lines[#lines + 1] = line
                        line = ""
                    end

                    line = line .. char
                end

                continue
            end

            local space = (line == "") and "" or " "
            local next = line .. space .. word

            if ( self:GetTextWidth(font, next) > maxWidth ) then
                lines[#lines + 1] = line
                line = word
            else
                line = next
            end
        end

        if ( line != "" ) then
            lines[#lines + 1] = line
        end

        return lines
    end

    --- Returns the given text's width (client-only).
    -- @param font string Font name
    -- @param text string Text to measure
    -- @return number Width in pixels
    -- @usage local w = ax.util:GetTextWidth("Default", "Hello")
    function ax.util:GetTextWidth(font, text)
        surface.SetFont(font)
        return select(1, surface.GetTextSize(text))
    end

    --- Returns the given text's height (client-only).
    -- @param font string Font name
    -- @return number Height in pixels
    -- @usage local h = ax.util:GetTextHeight("Default")
    function ax.util:GetTextHeight(font)
        surface.SetFont(font)
        return select(2, surface.GetTextSize("W"))
    end

    --- Returns the given text's size (client-only).
    -- @param font string Font name
    -- @param text string Text to measure
    -- @return number w, number h Width and height in pixels
    -- @usage local w,h = ax.util:GetTextSize("Default", "Hello")
    function ax.util:GetTextSize(font, text)
        surface.SetFont(font)
        return surface.GetTextSize(text)
    end
end
