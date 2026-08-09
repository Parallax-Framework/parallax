--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- A frame taking no longer than this counts as smooth; sustained smooth frames mean the join freeze is over.
local STABLE_FRAME_TIME = 0.05

-- Consecutive smooth frames required before the freeze is treated as finished.
local STABLE_FRAMES_REQUIRED = 30

-- Hold the black at least this long so it never flashes on a client that loads without a real freeze.
local MIN_SHOW_TIME = 0.5

-- Hard safety cap: reveal no matter what after this long, so a stall never leaves a permanent black screen.
local MAX_WAIT_TIME = 30

-- Seconds the black takes to lift once the deferred interface has been built.
local REVEAL_TIME = 1.2

---@class ax.boot
--- The startup curtain. Black is raised as early as possible clientside so the join freeze is hidden, and whatever interface would normally open on spawn is deferred through `WhenReady` so it is not built until frame times have stabilised.
---
--- Unlike a curtain panel this is drawn by `ax.fade`, which means it never calls `MakePopup` and therefore never takes the player's mouse and keyboard hostage for the length of the freeze: escape, the console and disconnect all keep working behind it. It also shares the one black layer with every other fade, so a raise issued during a lift supersedes it instead of stacking a second sheet of black.
---@field queued table Builders waiting for the reveal.
---@field bReady boolean Whether the reveal has already happened.
ax.boot = ax.boot or {}
ax.boot.queued = ax.boot.queued or {}
ax.boot.bReady = ax.boot.bReady or false
ax.boot.elapsed = ax.boot.elapsed or 0
ax.boot.stableFrames = ax.boot.stableFrames or 0

--- Defers a builder until the join freeze is over, or runs it immediately when the curtain has already lifted; fail-open by design, so a caller never has to check whether the curtain exists.
---@realm client
---@param callback function Builder that creates the interface to reveal.
function ax.boot:WhenReady(callback)
    if ( !isfunction(callback) ) then return end

    if ( self.bReady ) then
        callback()
        return
    end

    self.queued[#self.queued + 1] = callback

    -- Queueing behind a watcher that is not running would black the screen out forever, so the deferral re-arms it rather than trusting it to be there.
    self:StartWatching()
end

--- Builds every deferred builder and lifts the black.
---@realm client
function ax.boot:Reveal()
    if ( self.bReady ) then return end

    self.bReady = true

    local queued = self.queued
    self.queued = {}

    for i = 1, #queued do
        local success, err = pcall(queued[i])
        if ( !success ) then
            -- One bad builder must not leave the screen black forever.
            ax.util:PrintError("ax.boot: deferred builder failed: " .. tostring(err))
        end
    end

    ax.fade:To(0, REVEAL_TIME)

    hook.Run("OnBootRevealed")
end

--- Arms the frame watcher; idempotent, because `hook.Add` replaces a handler of the same name rather than stacking one.
---@realm client
function ax.boot:StartWatching()
    hook.Add("Think", "ax.boot.Think", function()
        ax.boot:Think()
    end)
end

--- Watches frame timing and reveals once the freeze has ended and there is something to show, or once the safety cap is reached. The watcher is deliberately never removed: it costs one early return per frame once the curtain has lifted, and detaching it was what made a missed reveal unrecoverable, since the safety cap can only fire while something is still counting.
---@realm client
function ax.boot:Think()
    if ( self.bReady ) then return end

    local frameTime = FrameTime()
    self.elapsed = self.elapsed + frameTime

    if ( frameTime <= STABLE_FRAME_TIME ) then
        self.stableFrames = self.stableFrames + 1
    else
        self.stableFrames = 0
    end

    if ( self.elapsed >= MAX_WAIT_TIME ) then
        ax.util:PrintWarning("ax.boot: revealing on the safety cap after " .. math.Round(self.elapsed) .. "s")
        self:Reveal()
        return
    end

    -- Wait for the freeze to end AND for something to actually reveal, so the black never lifts onto an empty world.
    if ( self.elapsed >= MIN_SHOW_TIME and self.stableFrames >= STABLE_FRAMES_REQUIRED and #self.queued > 0 ) then
        self:Reveal()
    end
end

--- Draws the wordmark over the curtain; its alpha tracks the black so it fades out with it and needs no state of its own.
---@realm client
function ax.boot:Render()
    local alpha = ax.fade:GetAlpha()
    if ( alpha <= 0 ) then return end

    -- Fonts are created in GM:Initialize, which is after this directory loads, so the first frames may have nothing to draw with.
    if ( !ax.font.stored["ax.large.bold"] ) then return end

    local name = "PARALLAX"
    if ( SCHEMA and isstring(SCHEMA.name) and SCHEMA.name != "" ) then
        name = SCHEMA.name
    end

    local color = Color(ax.color.textMuted.r, ax.color.textMuted.g, ax.color.textMuted.b, alpha)

    ax.draw:TextTracked(utf8.upper(name), "ax.large.bold", ScrW() / 2, ScrH() / 2, color, ax.util:ScreenScale(6), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

ax.boot:StartWatching()

-- Raised once per session at file load, the earliest clientside moment, so the first rendered frame is solid black rather than a stuttering world. The global guard matters: autorefresh re-runs saved files, and a curtain that re-blacks the screen mid-session is unrecoverable.
if ( !AX_BOOT_RAISED ) then
    AX_BOOT_RAISED = true

    ax.fade:Set(255)
end
