--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

---@class ax.entry : DTextEntry
--- A text field on a sunken surface with a hairline that brightens on focus. Derived from `DTextEntry` so `SetPlaceholderText`, `SetAllowNonAsciiCharacters`, `SetMultiline`, `OnValueChange` and the `AllowInput` override all come for free; only the paint and the disabled state are ours.
---
--- Note that `SetText` is deliberately left as the engine's, which assigns the text WITHOUT firing `OnValueChange`. That is what makes `entry:SetText(value, true)` the safe way to seed a default. Do not reroute it through `SetValue`: `SetValue` calls `SetText` internally, so an override that called it back would recurse forever.
local PANEL = {}

--- Initialises the field and strips the stock derma paint.
---@realm client
function PANEL:Init()
    self:SetPaintBackground(false)
    self:SetFont("ax.regular")
    self:SetTextColor(ax.color.text)
    self:SetCursorColor(ax.color.textBright)
    self:SetHighlightColor(ax.color.accentMuted)
    self:SetPlaceholderColor(ax.color.textFaint)

    -- `OnValueChange` otherwise only fires on Enter, which would let a player submit the form with text the payload never saw.
    self:SetUpdateOnType(true)

    self.bDisabled = false
end

--- Disables the field, blocking editing and dropping the text to the muted ramp.
---@realm client
---@param bDisabled boolean Whether the field is disabled.
function PANEL:SetDisabled(bDisabled)
    self.bDisabled = bDisabled and true or false

    self:SetEditable(!self.bDisabled)
    self:SetMouseInputEnabled(!self.bDisabled)
    self:SetKeyboardInputEnabled(!self.bDisabled)
    self:SetTextColor(self.bDisabled and ax.color.textDisabled or ax.color.text)
end

--- Returns whether the field is disabled.
---@realm client
---@return boolean bDisabled Whether the field is disabled.
function PANEL:GetDisabled()
    return self.bDisabled
end

--- Draws the sunken surface, its hairline, and then the stock text pass on top.
---@realm client
---@param width number Panel width in pixels.
---@param height number Panel height in pixels.
function PANEL:Paint(width, height)
    ax.draw:Rect(0, 0, width, height, ax.color.inset)

    local line = ax.color.line
    if ( !self.bDisabled ) then
        if ( self:HasFocus() ) then
            line = ax.color.lineFocus
        elseif ( self:IsHovered() ) then
            line = ax.color.lineStrong
        end
    end

    ax.draw:Hairline(0, 0, width, height, line)

    -- Runs after our surface, or the caret and the selection highlight would draw underneath it.
    self:DrawTextEntryText(self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor())
end

vgui.Register("ax.entry", PANEL, "DTextEntry")
