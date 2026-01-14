--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

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

local function FormatTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    local miliseconds = math.floor((seconds - math.floor(seconds)) * 100)

    return string.format("%02d:%02d:%02d", minutes, secs, miliseconds)
end

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

    net.Start("ax.player.actionbar.stop")
        net.WriteBool(cancelled == true)
    net.SendToServer()

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
    if ( hook.Run("ShouldDrawActionBar", activeBar) == false ) then self:Stop(true) return end

    local client = ax.client
    if ( !IsValid(client) or !client:Alive() ) then
        self:Stop(true)
        return
    end

    local elapsed = CurTime() - self.startTime
    local progress = math.Clamp(elapsed / self.duration, 0, 1)
    local remaining = self.endTime - CurTime()

    if ( remaining <= 0 ) then
        self:Stop(false)
        return
    end

    local scrW, scrH = ScrW(), ScrH()
    local centerX = scrW / 2
    local centerY = scrH - ScreenScaleH(120)
    local circleRadius = ScreenScale(16)

    ax.render.DrawCircle(centerX, centerY, circleRadius * 2 - 2, ax.actionBar.progressColor)

    local progressAngle = 360 * (1 - progress)
    ax.util:DrawSlice(centerX, centerY, circleRadius, 0, progressAngle, ax.actionBar.bgColor)

    local timeText = FormatTime(remaining)
    draw.SimpleText(timeText, "ax.small.bold", centerX, centerY, ax.actionBar.textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local labelY = centerY + circleRadius + ScreenScaleH(8)
    draw.SimpleText(self.label, "ax.medium.italic", centerX, labelY, ax.actionBar.labelColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- Hook into HUD paint
hook.Add("HUDPaint", "ax.actionBar.Render", function()
    ax.actionBar:Render()
end)
