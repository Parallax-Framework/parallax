--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("DScrollPanel")

--- Pixels travelled per wheel notch.
local SCROLL_STEP = 90

--- How quickly the interpolated scroll closes on its target; multiplied by frame time so the feel does not change with framerate the way a fixed per-frame fraction would.
local SCROLL_SPEED = 14

---@class ax.scroller : DScrollPanel
--- A vertical scroll panel whose bar is a hairline rather than a stock derma slab. The legacy interface skin is gone, so every derived derma control has to repaint itself or it renders in default grey.
---
--- Optionally centres content that is shorter than the panel, which is the vertical counterpart of what `ax.scroller.horizontal` does for a short row. Off by default: a form wants to start at the top, and only a panel holding one block of content wants it.
local PANEL = {}

--- Initialises the scroller and restyles its scrollbar.
---@realm client
function PANEL:Init()
    self.bCenterVertically = false

    local bar = self:GetVBar()
    bar:SetHideButtons(true)
    bar:SetWide(ax.ui:Hairline() * 3)

    bar.Paint = function(_, width, height)
        ax.draw:Rect(0, 0, width, height, ax.color.inset)
    end

    bar.btnGrip.Paint = function(this, width, height)
        local color = this.Depressed and ax.color.lineFocus or (this:IsHovered() and ax.color.lineStrong or ax.color.line)
        ax.draw:Rect(0, 0, width, height, color)
    end
end

--- Moves the scroll target by a wheel notch instead of jumping the bar, leaving `Think` to close the distance.
---@realm client
---@param delta number Wheel delta; positive scrolls up.
---@return boolean bHandled Whether the wheel was consumed.
function PANEL:OnMouseWheeled(delta)
    local bar = self:GetVBar()
    if ( !IsValid(bar) or !bar.Enabled ) then return false end

    local maximum = math.max(tonumber(bar.CanvasSize) or 0, 0)
    local target = self.scrollTarget or bar:GetScroll()

    self.scrollTarget = math.Clamp(target - delta * SCROLL_STEP, 0, maximum)

    return true
end

--- Eases the scroll bar toward its target. Dragging the grip drops the target outright, so a drag is never fought by an interpolation still closing on somewhere else.
---@realm client
function PANEL:Think()
    if ( !self.scrollTarget ) then return end

    local bar = self:GetVBar()
    if ( !IsValid(bar) or !bar.Enabled ) then
        self.scrollTarget = nil
        return
    end

    if ( bar.Dragging ) then
        self.scrollTarget = nil
        return
    end

    local current = bar:GetScroll()
    if ( math.abs(current - self.scrollTarget) <= 1 ) then
        bar:SetScroll(self.scrollTarget)
        self.scrollTarget = nil
        return
    end

    bar:SetScroll(ax.ease:Lerp("Linear", math.Clamp(FrameTime() * SCROLL_SPEED, 0, 1), current, self.scrollTarget))
end

--- Centres content vertically when it is shorter than the panel; once it overflows the setting stops applying and normal scrolling takes over.
---@realm client
---@param bCenter boolean Whether short content should be centred.
function PANEL:SetCenterVertically(bCenter)
    self.bCenterVertically = bCenter and true or false
    self:InvalidateLayout()
end

--- Returns whether short content is centred vertically.
---@realm client
---@return boolean bCenter Whether centring is enabled.
function PANEL:GetCenterVertically()
    return self.bCenterVertically
end

--- Lays the scroller out, then re-centres the canvas when the content does not fill it.
---@realm client
---@param width number Panel width in pixels.
---@param height number Panel height in pixels.
function PANEL:PerformLayout(width, height)
    if ( isfunction(BaseClass.PerformLayout) ) then
        BaseClass.PerformLayout(self, width, height)
    end

    if ( !self.bCenterVertically ) then return end

    local canvas = self:GetCanvas()
    if ( !IsValid(canvas) ) then return end

    local content = canvas:GetTall()

    -- Overflowing content belongs to the scroll position, so leave it where the base put it.
    if ( content <= 0 or content >= height ) then return end

    canvas:SetPos(canvas:GetX(), (height - content) / 2)
end

--- Draws nothing; the scroller is a container and its background belongs to whatever holds it.
---@realm client
function PANEL:Paint()
end

vgui.Register("ax.scroller", PANEL, "DScrollPanel")
