--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

---@class ax.slider : EditablePanel
--- A numeric slider drawn as a hairline track with a square handle and a value readout. Written from scratch rather than wrapping `DNumSlider` because the interface skin is gone and `DNumSlider` is a composite of three stock controls that would each need repainting.
---
--- The API deliberately matches the `DNumSlider` subset the character vars use -- `SetMin`, `SetMax`, `SetDecimals`, `SetValue`, `GetValue` and the `OnValueChanged` callback -- so a var written against the old slider keeps working.
local PANEL = {}

--- Initialises the slider with a 0-100 integer range.
---@realm client
function PANEL:Init()
    self.min = 0
    self.max = 100
    self.decimals = 0
    self.value = 0
    self.bDragging = false

    self:SetCursor("hand")
end

--- Sets the lowest selectable value.
---@realm client
---@param min number Lower bound.
function PANEL:SetMin(min)
    self.min = tonumber(min) or 0
    self:SetValue(self.value)
end

--- Sets the highest selectable value.
---@realm client
---@param max number Upper bound.
function PANEL:SetMax(max)
    self.max = tonumber(max) or 0
    self:SetValue(self.value)
end

--- Sets how many decimal places the value keeps.
---@realm client
---@param decimals number Decimal places; 0 for integers.
function PANEL:SetDecimals(decimals)
    self.decimals = math.max(math.floor(tonumber(decimals) or 0), 0)
    self:SetValue(self.value)
end

--- Returns the current value.
---@realm client
---@return number value The current value.
function PANEL:GetValue()
    return self.value
end

--- Sets the value, clamped and rounded to the configured range and precision; fires `OnValueChanged` only when the value actually moves.
---@realm client
---@param value number The value to set.
function PANEL:SetValue(value)
    local resolved = ax.util:ClampRound(tonumber(value) or 0, self.min, self.max, self.decimals)
    if ( resolved == self.value ) then return end

    self.value = resolved

    self:OnValueChanged(resolved)
end

--- Override point fired when the value changes.
---@realm client
---@param value number The new value.
function PANEL:OnValueChanged(value)
end

--- Converts a cursor X position into a value and applies it.
---@realm client
---@param x number Cursor X in panel space.
function PANEL:SetValueFromCursor(x)
    local width = self:GetWide()
    if ( width <= 0 ) then return end

    local fraction = math.Clamp(x / width, 0, 1)

    self:SetValue(self.min + (self.max - self.min) * fraction)
end

--- Begins a drag.
---@realm client
---@param code number The mouse code pressed.
function PANEL:OnMousePressed(code)
    if ( code != MOUSE_LEFT ) then return end

    self.bDragging = true
    self:MouseCapture(true)
    self:SetValueFromCursor(self:CursorPos())
end

--- Ends a drag.
---@realm client
---@param code number The mouse code released.
function PANEL:OnMouseReleased(code)
    self.bDragging = false
    self:MouseCapture(false)
end

--- Tracks the cursor while dragging.
---@realm client
---@param x number Cursor X in panel space.
function PANEL:OnCursorMoved(x)
    if ( !self.bDragging ) then return end

    self:SetValueFromCursor(x)
end

--- Draws the track, the filled portion, the handle and the readout.
---@realm client
---@param width number Panel width in pixels.
---@param height number Panel height in pixels.
function PANEL:Paint(width, height)
    local range = self.max - self.min
    local fraction = range > 0 and math.Clamp((self.value - self.min) / range, 0, 1) or 0

    local hairline = ax.ui:Hairline()
    local trackY = height / 2 - hairline / 2
    local readoutWidth = ax.util:ScreenScale(28)
    local trackWidth = width - readoutWidth

    ax.draw:Rect(0, trackY, trackWidth, hairline, ax.color.line)
    ax.draw:Rect(0, trackY, trackWidth * fraction, hairline, self.bDragging and ax.color.accent or ax.color.lineFocus)

    local handleWidth = hairline * 2
    local handleHeight = height * 0.5
    local handleX = math.Clamp(trackWidth * fraction - handleWidth / 2, 0, trackWidth - handleWidth)

    ax.draw:Rect(handleX, height / 2 - handleHeight / 2, handleWidth, handleHeight, (self.bDragging or self:IsHovered()) and ax.color.textBright or ax.color.text)

    draw.SimpleText(string.format("%." .. self.decimals .. "f", self.value), "ax.small", width, height / 2, ax.color.textMuted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

vgui.Register("ax.slider", PANEL, "EditablePanel")
