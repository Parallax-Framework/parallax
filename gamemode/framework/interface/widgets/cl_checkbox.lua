--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

---@class ax.checkbox : DButton
--- A boolean toggle drawn as a hairline square that fills when checked. Included so the create screen's field-type switch is total: a schema registering a `bool` character var gets a control rather than nothing.
local PANEL = {}

--- Initialises the toggle.
---@realm client
function PANEL:Init()
    self:SetText("")
    self:SetPaintBackground(false)

    self.label = ""
    self.bChecked = false
end

--- Sets the text shown beside the box.
---@realm client
---@param text string The label.
function PANEL:SetLabel(text)
    self.label = tostring(text or "")
end

--- Sets the checked state without firing the change callback.
---@realm client
---@param bChecked boolean Whether the box is checked.
function PANEL:SetChecked(bChecked)
    self.bChecked = bChecked and true or false
end

--- Returns the checked state.
---@realm client
---@return boolean bChecked Whether the box is checked.
function PANEL:GetChecked()
    return self.bChecked
end

--- Toggles the box and reports the new state.
---@realm client
function PANEL:DoClick()
    self.bChecked = !self.bChecked

    self:OnChanged(self.bChecked)
end

--- Override point fired when the player toggles the box.
---@realm client
---@param bChecked boolean The new state.
function PANEL:OnChanged(bChecked)
end

--- Draws the box and its label.
---@realm client
---@param width number Panel width in pixels.
---@param height number Panel height in pixels.
function PANEL:Paint(width, height)
    local boxSize = math.min(height, ax.util:ScreenScale(10))
    local boxY = height / 2 - boxSize / 2
    local bHovered = self:IsHovered()

    ax.draw:Rect(0, boxY, boxSize, boxSize, ax.color.inset)
    ax.draw:Hairline(0, boxY, boxSize, boxSize, bHovered and ax.color.lineStrong or ax.color.line)

    if ( self.bChecked ) then
        local inset = math.max(ax.ui:Hairline() * 2, 2)
        ax.draw:Rect(inset, boxY + inset, boxSize - inset * 2, boxSize - inset * 2, ax.color.accent)
    end

    if ( self.label == "" ) then return end

    draw.SimpleText(self.label, "ax.regular", boxSize + ax.ui:Space("md"), height / 2, bHovered and ax.color.textBright or ax.color.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

vgui.Register("ax.checkbox", PANEL, "DButton")
