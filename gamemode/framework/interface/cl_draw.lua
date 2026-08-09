--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

---@class ax.draw
--- Drawing primitives for the Parallax interface. Everything here is square-cornered and unblurred by design, so these are plain `surface` calls rather than the `ax.render` shader path, which keeps hairlines pixel-exact and costs nothing per frame.
ax.draw = ax.draw or {}

--- Draws a filled rectangle with square corners.
---@realm client
---@param x number Left edge in screen pixels.
---@param y number Top edge in screen pixels.
---@param w number Width in pixels.
---@param h number Height in pixels.
---@param color Color Fill colour.
function ax.draw:Rect(x, y, w, h, color)
    surface.SetDrawColor(color.r, color.g, color.b, color.a or 255)
    surface.DrawRect(x, y, w, h)
end

--- Draws a hairline outline with square corners, inset so the line sits inside the given bounds rather than straddling them.
---@realm client
---@param x number Left edge in screen pixels.
---@param y number Top edge in screen pixels.
---@param w number Width in pixels.
---@param h number Height in pixels.
---@param color Color Line colour.
---@param thickness? number Line width in pixels. Defaults to the interface hairline width.
function ax.draw:Hairline(x, y, w, h, color, thickness)
    thickness = thickness or ax.ui:Hairline()

    surface.SetDrawColor(color.r, color.g, color.b, color.a or 255)
    surface.DrawOutlinedRect(x, y, w, h, thickness)
end

--- Draws a filled surface with a hairline outline: the base unit of the interface.
---@realm client
---@param x number Left edge in screen pixels.
---@param y number Top edge in screen pixels.
---@param w number Width in pixels.
---@param h number Height in pixels.
---@param fill? Color Fill colour. Defaults to the `panel` token. Pass `false` to draw the outline only.
---@param line? Color Outline colour. Defaults to the `line` token. Pass `false` to draw the fill only.
function ax.draw:Panel(x, y, w, h, fill, line)
    if ( fill != false ) then
        self:Rect(x, y, w, h, fill or ax.color.panel)
    end

    if ( line != false ) then
        self:Hairline(x, y, w, h, line or ax.color.line)
    end
end

--- Draws a horizontal hairline divider.
---@realm client
---@param x number Left edge in screen pixels.
---@param y number Vertical position in screen pixels.
---@param w number Length in pixels.
---@param color? Color Line colour. Defaults to the `line` token.
---@param thickness? number Line width in pixels. Defaults to the interface hairline width.
function ax.draw:HLine(x, y, w, color, thickness)
    self:Rect(x, y, w, thickness or ax.ui:Hairline(), color or ax.color.line)
end

--- Draws a vertical hairline divider.
---@realm client
---@param x number Horizontal position in screen pixels.
---@param y number Top edge in screen pixels.
---@param h number Length in pixels.
---@param color? Color Line colour. Defaults to the `line` token.
---@param thickness? number Line width in pixels. Defaults to the interface hairline width.
function ax.draw:VLine(x, y, h, color, thickness)
    self:Rect(x, y, thickness or ax.ui:Hairline(), h, color or ax.color.line)
end

--- Draws a rule along one edge of a rectangle, which is how selection and focus are marked without introducing a fill or a hue.
---@realm client
---@param x number Left edge in screen pixels.
---@param y number Top edge in screen pixels.
---@param w number Width in pixels.
---@param h number Height in pixels.
---@param side string Which edge to rule: `"left"`, `"right"`, `"top"` or `"bottom"`.
---@param color? Color Rule colour. Defaults to the `accent` token.
---@param thickness? number Rule width in pixels. Defaults to twice the interface hairline width so it reads as deliberate rather than incidental.
function ax.draw:Edge(x, y, w, h, side, color, thickness)
    thickness = thickness or ax.ui:Hairline() * 2
    color = color or ax.color.accent

    if ( side == "left" ) then
        self:Rect(x, y, thickness, h, color)
    elseif ( side == "right" ) then
        self:Rect(x + w - thickness, y, thickness, h, color)
    elseif ( side == "top" ) then
        self:Rect(x, y, w, thickness, color)
    elseif ( side == "bottom" ) then
        self:Rect(x, y + h - thickness, w, thickness, color)
    end
end

--- Draws four L-shaped corner brackets instead of a closed outline, framing a region without boxing it in.
---@realm client
---@param x number Left edge in screen pixels.
---@param y number Top edge in screen pixels.
---@param w number Width in pixels.
---@param h number Height in pixels.
---@param length number Length of each bracket arm in pixels.
---@param color? Color Bracket colour. Defaults to the `lineStrong` token.
---@param thickness? number Bracket width in pixels. Defaults to the interface hairline width.
function ax.draw:Corners(x, y, w, h, length, color, thickness)
    thickness = thickness or ax.ui:Hairline()
    color = color or ax.color.lineStrong

    -- Clamp so brackets on a small region cannot overlap into a full outline.
    length = math.min(length, w / 2, h / 2)

    surface.SetDrawColor(color.r, color.g, color.b, color.a or 255)

    -- Top left
    surface.DrawRect(x, y, length, thickness)
    surface.DrawRect(x, y, thickness, length)

    -- Top right
    surface.DrawRect(x + w - length, y, length, thickness)
    surface.DrawRect(x + w - thickness, y, thickness, length)

    -- Bottom left
    surface.DrawRect(x, y + h - thickness, length, thickness)
    surface.DrawRect(x, y + h - length, thickness, length)

    -- Bottom right
    surface.DrawRect(x + w - length, y + h - thickness, length, thickness)
    surface.DrawRect(x + w - thickness, y + h - length, thickness, length)
end

--- Draws the full-screen dim laid behind modal surfaces; there is no blur pass, the dim alone carries the separation.
---@realm client
---@param fraction? number Opacity multiplier in 0-1, for fading the scrim in. Defaults to 1.
function ax.draw:Scrim(fraction)
    local scrim = ax.color.scrim
    local alpha = (scrim.a or 255) * math.Clamp(fraction or 1, 0, 1)

    surface.SetDrawColor(scrim.r, scrim.g, scrim.b, alpha)
    surface.DrawRect(0, 0, ScrW(), ScrH())
end

local function IterateCharacters(text)
    local characters = {}

    if ( utf8 and utf8.codes ) then
        for _, code in utf8.codes(text) do
            characters[#characters + 1] = utf8.char(code)
        end

        return characters
    end

    for i = 1, #text do
        characters[#characters + 1] = string.sub(text, i, i)
    end

    return characters
end

--- Measures letter-spaced text, since `surface.GetTextSize` cannot account for tracking.
---@realm client
---@param text string The string to measure.
---@param font string Font name.
---@param tracking number Extra pixels inserted between characters.
---@return number width Total width in pixels.
---@return number height Line height in pixels.
function ax.draw:GetTrackedTextSize(text, font, tracking)
    surface.SetFont(font)

    local characters = IterateCharacters(text)
    local _, height = surface.GetTextSize(text)
    local width = 0

    for i = 1, #characters do
        local charWidth = surface.GetTextSize(characters[i])
        width = width + charWidth
    end

    if ( #characters > 1 ) then
        width = width + tracking * (#characters - 1)
    end

    return width, height
end

--- Draws letter-spaced text, the wide-tracked label treatment the interface leans on for headers and section titles.
---@realm client
---@param text string The string to draw.
---@param font string Font name.
---@param x number Anchor X in screen pixels.
---@param y number Anchor Y in screen pixels.
---@param color Color Text colour.
---@param tracking? number Extra pixels inserted between characters. Defaults to 2.
---@param alignX? number Horizontal alignment: `TEXT_ALIGN_LEFT`, `TEXT_ALIGN_CENTER` or `TEXT_ALIGN_RIGHT`. Defaults to left.
---@param alignY? number Vertical alignment: `TEXT_ALIGN_TOP`, `TEXT_ALIGN_CENTER` or `TEXT_ALIGN_BOTTOM`. Defaults to top.
---@return number width The width the text occupied, so callers can advance a layout cursor.
function ax.draw:TextTracked(text, font, x, y, color, tracking, alignX, alignY)
    tracking = tracking or 2

    local width, height = self:GetTrackedTextSize(text, font, tracking)

    if ( alignX == TEXT_ALIGN_CENTER ) then
        x = x - width / 2
    elseif ( alignX == TEXT_ALIGN_RIGHT ) then
        x = x - width
    end

    if ( alignY == TEXT_ALIGN_CENTER ) then
        y = y - height / 2
    elseif ( alignY == TEXT_ALIGN_BOTTOM ) then
        y = y - height
    end

    surface.SetFont(font)
    surface.SetTextColor(color.r, color.g, color.b, color.a or 255)

    local characters = IterateCharacters(text)
    local cursor = x

    for i = 1, #characters do
        local character = characters[i]

        surface.SetTextPos(cursor, y)
        surface.DrawText(character)

        cursor = cursor + surface.GetTextSize(character) + tracking
    end

    return width
end
