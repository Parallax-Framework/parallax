--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Seconds before the card dismisses itself when the player does nothing.
local AUTO_DISMISS_TIME = 12

--- Seconds the card ignores input, so a click that was already travelling when the curtain lifted does not skip it.
local INPUT_GRACE_TIME = 0.6

---@class ax.main.splash : EditablePanel
--- The title card: a branded first impression with no controls on it. It holds until the player presses anything, or until it times out, then hands over to the menu proper.
local PANEL = {}

--- Initialises the card and takes keyboard focus so any key dismisses it.
---@realm client
function PANEL:Init()
    hook.Run("PreMainMenuSplashCreated", self)

    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(true)
    self:RequestFocus()

    self.startTime = RealTime()
    self.bDismissing = false

    hook.Run("PostMainMenuSplashCreated", self)
end

--- Hands over to the menu proper; safe to call repeatedly.
---@realm client
function PANEL:Dismiss()
    if ( self.bDismissing ) then return end

    -- Input arriving in the first moments belongs to whatever the player was doing before the curtain lifted, not to this card.
    if ( RealTime() - self.startTime < INPUT_GRACE_TIME ) then return end

    self.bDismissing = true

    local parent = self:GetParent()
    if ( !IsValid(parent) ) then return end

    parent:ShowAfterSplash()
end

--- Dismisses on any mouse press.
---@realm client
function PANEL:OnMousePressed()
    self:Dismiss()
end

--- Dismisses on any key press.
---@realm client
---@param key number The key code pressed.
function PANEL:OnKeyCodePressed(key)
    self:Dismiss()
end

--- Dismisses once the card has been up long enough on its own.
---@realm client
function PANEL:Think()
    if ( self.bDismissing ) then return end

    if ( RealTime() - self.startTime >= AUTO_DISMISS_TIME ) then
        self:Dismiss()
    end
end

--- Resolves the title, letting a schema brand the card without forking it.
---@realm client
---@return string title The title text.
function PANEL:GetTitle()
    local override = hook.Run("GetMainMenuTitle")
    if ( isstring(override) and override != "" ) then
        return override
    end

    if ( SCHEMA and isstring(SCHEMA.name) and SCHEMA.name != "" ) then
        return SCHEMA.name
    end

    return "Parallax"
end

--- Resolves the subtitle.
---@realm client
---@return string subtitle The subtitle text.
function PANEL:GetSubtitle()
    local override = hook.Run("GetMainMenuSubtitle")
    if ( isstring(override) and override != "" ) then
        return override
    end

    if ( SCHEMA and isstring(SCHEMA.description) and SCHEMA.description != "" ) then
        return SCHEMA.description
    end

    return "A new dimension of roleplay, built for you."
end

--- Draws the card: wordmark, hairline rule, subtitle, and a pulsing prompt.
---@realm client
---@param width number Panel width in pixels.
---@param height number Panel height in pixels.
function PANEL:Paint(width, height)
    local centerX = width / 2
    local titleY = height * 0.42

    local titleTracking = ax.util:ScreenScale(8)
    local titleWidth = ax.draw:TextTracked(utf8.upper(self:GetTitle()), "ax.giant.bold", centerX, titleY, ax.color.textBright, titleTracking, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- The rule is measured from the wordmark so it always frames it rather than floating at a fixed width.
    local ruleWidth = math.max(titleWidth, ax.util:ScreenScale(120))
    local ruleY = titleY + ax.util:ScreenScale(18)

    ax.draw:HLine(centerX - ruleWidth / 2, ruleY, ruleWidth, ax.color.line)

    ax.draw:TextTracked(self:GetSubtitle(), "ax.regular", centerX, ruleY + ax.util:ScreenScale(12), ax.color.textMuted, ax.util:ScreenScale(1), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    ax.draw:Corners(width * 0.5 - ruleWidth * 0.75, titleY - ax.util:ScreenScale(33), ruleWidth * 1.5, ax.util:ScreenScale(84), ax.util:ScreenScale(12), ax.color.lineStrong)

    if ( self.bDismissing ) then return end

    local pulse = 0.55 + math.sin(RealTime() * 2.2) * 0.35
    local prompt = ColorAlpha(ax.color.textFaint, 255 * pulse)

    ax.draw:TextTracked("PRESS ANY KEY", "ax.small.bold", centerX, height * 0.86, prompt, ax.util:ScreenScale(4), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

vgui.Register("ax.main.splash", PANEL, "EditablePanel")
