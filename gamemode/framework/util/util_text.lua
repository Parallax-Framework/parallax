--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Utility helpers used across the Parallax framework (printing, file handling, text utilities, etc.).
-- @module ax.util

--- Text utilities.
-- @section text_utilities

--- Truncates text to a maximum character count, appending `"..."` when cut.
-- If the text is already within `maxLength` characters it is returned unchanged. When truncation is needed, the text is cut to `maxLength - 3` characters and `"..."` is appended, so the returned string is always at most `maxLength` characters long in total. Returns `""` and prints an error when either argument is invalid.
-- @realm shared
-- @param text string The text to truncate.
-- @param maxLength number The maximum number of characters allowed (inclusive of the `"..."` suffix).
-- @return string The original text, or a truncated version ending with `"..."`.
-- @usage ax.util:CapText("Hello, World!", 8)  -- "Hello..."
-- ax.util:CapText("Hi", 10)                   -- "Hi" (unchanged)
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

--- Truncates text at a word boundary to avoid splitting words mid-character.
-- Splits the text by spaces and accumulates words until the next word would exceed `maxLength`. The result always has `"..."` appended, even when the boundary falls exactly at `maxLength`. As a result the returned string may be shorter than `maxLength` if the last fitting word ends well before it.
-- Returns `""` and prints an error when either argument is invalid.
-- @realm shared
-- @param text string The text to truncate.
-- @param maxLength number The maximum number of characters to aim for.
-- @return string Words that fit within `maxLength`, followed by `"..."`.
-- @usage ax.util:CapTextWord("the quick brown fox", 12)  -- "the quick..."
-- ax.util:CapTextWord("hi", 50)                          -- "hi" (unchanged)
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
    --- Splits text into lines that each fit within a pixel width limit.
    -- Measures text using `surface.GetTextSize` with `font` to determine where line breaks should occur. Words are added to the current line until adding the next word would exceed `maxWidth`, at which point a new line is started. When a single word is wider than `maxWidth`, it is split character-by-character so it always fits. If the entire text fits on one line, a single-element table is returned immediately.
    -- Returns false (with a printed error) when any argument is invalid.
    -- @realm client
    -- @param text string The text to wrap.
    -- @param font string The font name used for pixel-width measurement.
    --   Must be a font registered with `surface.CreateFont` or a GMod built-in.
    -- @param maxWidth number The maximum line width in pixels.
    -- @return table|false An ordered array of line strings, or false on invalid input.
    -- @usage local lines = ax.util:GetWrappedText("Hello world, how are you?", "DermaDefault", 100)
    -- for _, line in ipairs(lines) do draw.SimpleText(line, ...) end
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

    --- Returns the rendered pixel width of a string in a given font.
    -- Calls `surface.SetFont(font)` as a side effect, changing the active surface font state. Use `GetTextSize` if you need both dimensions at once.
    -- @realm client
    -- @param font string The font name to measure with.
    -- @param text string The string to measure.
    -- @return number The width of `text` in pixels when rendered in `font`.
    -- @usage local w = ax.util:GetTextWidth("DermaDefault", "Hello World")
    function ax.util:GetTextWidth(font, text)
        surface.SetFont(font)
        return select(1, surface.GetTextSize(text))
    end

    --- Returns the line height of a font in pixels.
    -- Measures the height of the capital letter `"W"` as a representative character that occupies the full ascender height of the font. The result is the number of vertical pixels a single line of text in this font occupies. Calls `surface.SetFont(font)` as a side effect.
    -- @realm client
    -- @param font string The font name to measure.
    -- @return number The line height in pixels.
    -- @usage local lineH = ax.util:GetTextHeight("DermaDefault")
    function ax.util:GetTextHeight(font)
        surface.SetFont(font)
        return select(2, surface.GetTextSize("W"))
    end

    --- Returns the rendered pixel dimensions of a string in a given font.
    -- Convenience wrapper that calls `surface.SetFont(font)` then returns both values from `surface.GetTextSize(text)` in one call. Use this when you need both width and height to avoid two separate font sets.
    -- @realm client
    -- @param font string The font name to measure with.
    -- @param text string The string to measure.
    -- @return number Width of `text` in pixels.
    -- @return number Height of `text` in pixels.
    -- @usage local w, h = ax.util:GetTextSize("DermaDefault", "Hello World")
    function ax.util:GetTextSize(font, text)
        surface.SetFont(font)
        return surface.GetTextSize(text)
    end
end
