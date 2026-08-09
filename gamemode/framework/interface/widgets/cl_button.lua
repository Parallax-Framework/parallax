--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("DButton")

--- Seconds a hover transition takes to settle.
local HOVER_TIME = 0.18

--- Played as the cursor lands on a button.
local SOUND_ROLLOVER = "parallax/ui/widgets/button/rollover.wav"

--- Played as a button is pressed.
local SOUND_PRESS = "parallax/ui/widgets/button/press.wav"

---@class ax.button : DButton
--- A flat, square-cornered button. State is carried by surface brightness and a left accent rule rather than by a colour change, which is what keeps the interface monochrome.
local PANEL = {}

--- Initialises the button with the interface's default treatment: tracked caps, left-aligned, no stock derma paint.
---@realm client
function PANEL:Init()
    self:SetText("")
    self:SetPaintBackground(false)

    self.label = ""
    self.font = "ax.regular.bold"
    self.tracking = ax.util:ScreenScale(2)
    self.alignX = TEXT_ALIGN_LEFT
    self.hoverFrac = 0
    self.bAccent = true
    self.bDanger = false
    self.textColorOverride = nil
end

--- Sets the button label; the text is uppercased at draw time, so pass it in natural case.
---@realm client
---@param text string The label.
function PANEL:SetLabel(text)
    self.label = tostring(text or "")
end

--- Returns the button label.
---@realm client
---@return string label The current label.
function PANEL:GetLabel()
    return self.label
end

--- Sets the label font.
---@realm client
---@param font string A registered font name.
function PANEL:SetFont(font)
    self.font = font
end

--- Sets the letter spacing of the label in pixels.
---@realm client
---@param tracking number Extra pixels inserted between characters.
function PANEL:SetTracking(tracking)
    self.tracking = tracking or 0
end

--- Sets the horizontal alignment of the label.
---@realm client
---@param alignX number `TEXT_ALIGN_LEFT`, `TEXT_ALIGN_CENTER` or `TEXT_ALIGN_RIGHT`.
function PANEL:SetAlign(alignX)
    self.alignX = alignX or TEXT_ALIGN_LEFT
end

--- Toggles the left accent rule that marks hover and selection.
---@realm client
---@param bAccent boolean Whether to draw the rule.
function PANEL:SetAccent(bAccent)
    self.bAccent = bAccent and true or false
end

--- Marks the button as destructive, which is the one case where the interface spends a hue.
---@realm client
---@param bDanger boolean Whether this button destroys something.
function PANEL:SetDanger(bDanger)
    self.bDanger = bDanger and true or false
end

--- Overrides the label colour, bypassing the state ramp.
---@realm client
---@param color Color|nil The colour to draw the label with, or nil to restore the default.
function PANEL:SetTextColor(color)
    self.textColorOverride = color
end

--- Plays the rollover cue and eases the hover state in.
---@realm client
function PANEL:OnCursorEntered()
    if ( self:GetDisabled() ) then return end

    surface.PlaySound(SOUND_ROLLOVER)

    self:Motion(HOVER_TIME, {
        Target = { hoverFrac = 1 },
        Easing = "OutQuad"
    })
end

--- Eases the hover state back out.
---@realm client
function PANEL:OnCursorExited()
    self:Motion(HOVER_TIME, {
        Target = { hoverFrac = 0 },
        Easing = "OutQuad"
    })
end

--- Plays the press cue, then hands off to the stock button so `DoClick` still fires.
---@realm client
---@param code number The mouse code pressed.
function PANEL:OnMousePressed(code)
    if ( !self:GetDisabled() and code == MOUSE_LEFT ) then
        surface.PlaySound(SOUND_PRESS)
    end

    BaseClass.OnMousePressed(self, code)
end

--- The eased hover position, driven by `ax.motion` from the cursor callbacks rather than stepped per frame. A disabled button always reads 0, so disabling one mid-hover does not leave it stuck lit.
---@realm client
---@return number fraction Hover position in 0-1.
function PANEL:GetHoverFraction()
    if ( self:GetDisabled() ) then return 0 end

    return self.hoverFrac or 0
end

--- Draws the button surface, its hairline, the accent rule and the label.
---@realm client
---@param width number Panel width in pixels.
---@param height number Panel height in pixels.
function PANEL:Paint(width, height)
    local fraction = self:GetHoverFraction()
    local bDisabled = self:GetDisabled()

    local fill = ax.ui:Mix(ax.color.fill, self:IsDown() and ax.color.fillActive or ax.color.fillHover, fraction)
    local line = ax.ui:Mix(ax.color.line, ax.color.lineStrong, fraction)

    ax.draw:Rect(0, 0, width, height, fill)
    ax.draw:Hairline(0, 0, width, height, line)

    if ( self.bAccent and fraction > 0 ) then
        local accent = self.bDanger and ax.color.danger or ax.color.accent
        ax.draw:Edge(0, 0, width, height, "left", ColorAlpha(accent, 255 * fraction))
    end

    if ( self.label == "" ) then return end

    local textColor = self.textColorOverride
    if ( !textColor ) then
        if ( bDisabled ) then
            textColor = ax.color.textDisabled
        elseif ( self.bDanger ) then
            textColor = ax.ui:Mix(ax.color.textMuted, ax.color.danger, fraction)
        else
            textColor = ax.ui:Mix(ax.color.text, ax.color.textBright, fraction)
        end
    end

    local padding = ax.ui:Space("lg")
    local x = padding

    if ( self.alignX == TEXT_ALIGN_CENTER ) then
        x = width / 2
    elseif ( self.alignX == TEXT_ALIGN_RIGHT ) then
        x = width - padding
    end

    ax.draw:TextTracked(utf8.upper(self.label), self.font, x, height / 2, textColor, self.tracking, self.alignX, TEXT_ALIGN_CENTER)
end

--- Suppresses the stock derma depressed-state paint.
---@realm client
function PANEL:PaintOver()
end

vgui.Register("ax.button", PANEL, "DButton")
