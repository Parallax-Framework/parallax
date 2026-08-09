--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

---@class ax.text : Panel
--- A self-sizing text label. Supports the interface's tracked-caps treatment for headers and section titles, and wraps to the panel width when told to.
local PANEL = {}

--- Initialises the label with the interface's default body font and colour.
---@realm client
function PANEL:Init()
    self.font = "ax.regular"
    self.text = ""
    self.textColor = ax.color.text
    self.tracking = 0
    self.alignX = TEXT_ALIGN_LEFT
    self.alignY = TEXT_ALIGN_TOP
    self.bWrap = false

    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)
end

--- Sets the label text, optionally resizing the panel to fit it.
---@realm client
---@param text string The text to display.
---@param bSizeToContents? boolean Resize the panel to the measured text. Defaults to true.
function PANEL:SetText(text, bSizeToContents)
    self.text = tostring(text or "")

    if ( bSizeToContents != false ) then
        self:SizeToContents()
    end
end

--- Returns the label text.
---@realm client
---@return string text The current text.
function PANEL:GetText()
    return self.text
end

--- Sets the font, resizing to fit.
---@realm client
---@param font string A registered font name, e.g. `"ax.large.bold"`.
function PANEL:SetFont(font)
    self.font = font
    self:SizeToContents()
end

--- Sets the text colour.
---@realm client
---@param color Color The colour to draw with.
function PANEL:SetTextColor(color)
    self.textColor = color
end

--- Sets the letter spacing in pixels; anything above zero switches the label to the tracked-caps treatment.
---@realm client
---@param tracking number Extra pixels inserted between characters.
function PANEL:SetTracking(tracking)
    self.tracking = tracking or 0
    self:SizeToContents()
end

--- Sets the text alignment within the panel bounds.
---@realm client
---@param alignX number `TEXT_ALIGN_LEFT`, `TEXT_ALIGN_CENTER` or `TEXT_ALIGN_RIGHT`.
---@param alignY number `TEXT_ALIGN_TOP`, `TEXT_ALIGN_CENTER` or `TEXT_ALIGN_BOTTOM`.
function PANEL:SetAlign(alignX, alignY)
    self.alignX = alignX or TEXT_ALIGN_LEFT
    self.alignY = alignY or TEXT_ALIGN_TOP
end

--- Enables word wrapping at the current panel width; wrapped labels are never tracked, because tracking and wrapping disagree about where a line ends.
---@realm client
---@param bWrap boolean Whether to wrap.
function PANEL:SetWrap(bWrap)
    self.bWrap = bWrap and true or false
    self:SizeToContents()
end

--- Resizes the panel to the measured text, honouring wrapping and tracking.
---@realm client
function PANEL:SizeToContents()
    if ( self.text == "" ) then
        self:SetSize(0, 0)
        return
    end

    if ( self.bWrap ) then
        local width = self:GetWide()
        if ( width <= 0 ) then return end

        local lines = ax.util:GetWrappedText(self.text, self.font, width) or {}
        surface.SetFont(self.font)

        local _, lineHeight = surface.GetTextSize("W")
        self:SetTall(math.max(#lines, 1) * lineHeight)

        return
    end

    if ( self.tracking > 0 ) then
        local width, height = ax.draw:GetTrackedTextSize(self.text, self.font, self.tracking)
        self:SetSize(width, height)

        return
    end

    surface.SetFont(self.font)

    local width, height = surface.GetTextSize(self.text)
    self:SetSize(width, height)
end

--- Draws the label.
---@realm client
---@param width number Panel width in pixels.
---@param height number Panel height in pixels.
function PANEL:Paint(width, height)
    if ( self.text == "" ) then return end

    local x = 0
    if ( self.alignX == TEXT_ALIGN_CENTER ) then
        x = width / 2
    elseif ( self.alignX == TEXT_ALIGN_RIGHT ) then
        x = width
    end

    local y = 0
    if ( self.alignY == TEXT_ALIGN_CENTER ) then
        y = height / 2
    elseif ( self.alignY == TEXT_ALIGN_BOTTOM ) then
        y = height
    end

    if ( self.bWrap ) then
        local lines = ax.util:GetWrappedText(self.text, self.font, width) or { self.text }

        surface.SetFont(self.font)
        local _, lineHeight = surface.GetTextSize("W")

        for i = 1, #lines do
            draw.SimpleText(lines[i], self.font, x, (i - 1) * lineHeight, self.textColor, self.alignX, TEXT_ALIGN_TOP)
        end

        return
    end

    if ( self.tracking > 0 ) then
        ax.draw:TextTracked(self.text, self.font, x, y, self.textColor, self.tracking, self.alignX, self.alignY)
        return
    end

    draw.SimpleText(self.text, self.font, x, y, self.textColor, self.alignX, self.alignY)
end

vgui.Register("ax.text", PANEL, "EditablePanel")
