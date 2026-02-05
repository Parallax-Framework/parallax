--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Action bar system for displaying circular progress indicators with timers.
-- Displays a centered circular progress bar with countdown timer and customizable label.
--
-- @module ax.actionBar

ax.actionBar = ax.actionBar or {}
ax.actionBar.active = ax.actionBar.active or false
ax.actionBar.label = ax.actionBar.label or ""
ax.actionBar.startTime = ax.actionBar.startTime or 0
ax.actionBar.duration = ax.actionBar.duration or 0
ax.actionBar.endTime = ax.actionBar.endTime or 0
ax.actionBar.onComplete = ax.actionBar.onComplete or nil
ax.actionBar.onCancel = ax.actionBar.onCancel or nil

--- Start displaying an action bar
-- @realm client
-- @param label string Label text to display (default: "Processing...")
-- @param duration number Duration in seconds
-- @param onComplete function Optional callback when action completes
-- @param onCancel function Optional callback when action is cancelled
function ax.actionBar:Start(label, duration, onComplete, onCancel)
    if ( label == nil ) then return end

    self.active = true
    self.startTime = CurTime()
    self.duration = duration
    self.endTime = CurTime() + duration
    self.label = label
    self.onComplete = onComplete
    self.onCancel = onCancel
end

--- Stop the current action bar
-- @realm client
-- @param cancelled bool Whether the action was cancelled (triggers onCancel callback)
function ax.actionBar:Stop(cancelled)
    if ( !self:IsActive() ) then return end

    if ( cancelled == true and isfunction(self.onCancel) ) then
        self.onCancel()
    elseif ( !cancelled and isfunction(self.onComplete) ) then
        self.onComplete()
    end

    ax.net:Start("player.actionbar.stop", cancelled == true)

    self.active = false
end

--- Check if an action bar is currently active
-- @realm client
-- @return bool Whether an action bar is active
function ax.actionBar:IsActive()
    return self.active
end

--- Get remaining time for the active action bar
-- @realm client
-- @return number Remaining time in seconds (0 if no active bar)
function ax.actionBar:GetRemainingTime()
    if ( !self:IsActive() ) then return 0 end

    return math.max(0, self.endTime - CurTime())
end

ax.actionBar.bgColor = Color(145, 100, 255)
ax.actionBar.progressColor = Color(30, 30, 35, 150)
ax.actionBar.textColor = Color(255, 255, 255, 255)
ax.actionBar.labelColor = Color(200, 200, 200, 255)

function ax.actionBar:Render()
    if ( !self:IsActive() ) then return end
    if ( hook.Run("ShouldDrawActionBar", self) == false ) then self:Stop(true) return end

    local client = ax.client
    if ( !ax.util:IsValidPlayer(client) ) then
        self:Stop(true)
        return
    end

    local glass = ax.theme and ax.theme:GetGlass()
    local ringColor = glass and (glass.highlight or glass.progress) or self.bgColor
    local progressColor = glass and (glass.panel or glass.button) or self.progressColor
    local outlineColor = glass and (glass.panelBorder or glass.buttonBorder) or Color(255, 255, 255, 90)
    local innerFillColor = glass and (glass.overlayStrong or glass.overlay) or Color(0, 0, 0, 160)
    local ringGlowColor = ColorAlpha(ringColor, math.Clamp((ringColor.a or 255) + 80, 0, 255))
    local textColor = glass and (glass.text or self.textColor) or self.textColor
    local labelColor = glass and (glass.textMuted or self.labelColor) or self.labelColor

    local elapsed = CurTime() - self.startTime
    local progress = math.Clamp(elapsed / self.duration, 0, 1)
    local remaining = self.endTime - CurTime()

    if ( remaining <= 0 ) then
        self:Stop(false)
        return
    end

    local scrW, scrH = ScrW(), ScrH()
    local centerX = scrW / 2
    local centerY = scrH - ScreenScaleH(128)
    local circleRadius = ScreenScale(24)

    local outerDiameter = circleRadius * 2
    local ringThickness = math.max(3, circleRadius * 0.45)
    local innerDiameter = math.max(outerDiameter - (ringThickness * 2), circleRadius)

    ax.render().Circle(centerX, centerY, outerDiameter)
        :Blur(0.8)
        :Draw()
    ax.render.DrawCircle(centerX, centerY, outerDiameter, progressColor)
    ax.render.DrawCircleOutlined(centerX, centerY, outerDiameter, outlineColor, 1.5)

    local remainingProgress = math.Clamp(1 - progress, 0, 1)
    local progressAngle = 360 * remainingProgress

    ax.render().Circle(centerX, centerY, outerDiameter)
        :Rotation(90)
        :Outline(ringThickness)
        :StartAngle(0)
        :EndAngle(progressAngle)
        :Blur(0.4)
        :Color(ringGlowColor)
        :Draw()
    ax.render().Circle(centerX, centerY, outerDiameter - 2)
        :Rotation(90)
        :Outline(ringThickness)
        :StartAngle(0)
        :EndAngle(progressAngle)
        :Color(ringColor)
        :Draw()

    ax.render().Circle(centerX, centerY, innerDiameter)
        :Blur(0.9)
        :Draw()
    ax.render.DrawCircle(centerX, centerY, innerDiameter, innerFillColor)
    ax.render.DrawCircleOutlined(centerX, centerY, innerDiameter, outlineColor, 1)

    local timeText = string.ToMinutesSecondsMilliseconds(remaining)
    draw.SimpleText(timeText, "ax.small.bold", centerX, centerY, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local labelY = centerY + circleRadius + ScreenScaleH(8)
    draw.SimpleText(self.label, "ax.regular.italic", centerX, labelY, labelColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Hook into HUD paint
hook.Add("PostRenderVGUI", "ax.actionBar.Render", function()
    ax.actionBar:Render()
end)
