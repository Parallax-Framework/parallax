--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("DHorizontalScroller")

--- How quickly the interpolated offset closes on the real one; multiplied by frame time so the feel does not change with framerate.
local SCROLL_SPEED = 14

---@class ax.scroller.horizontal : DHorizontalScroller
--- A horizontal rail of cards, used where the content is a row of banners rather than a list of rows. The stock arrow buttons are hidden: the rail is driven by the mouse wheel and by dragging, and a pair of chrome arrows would read as a second visual system against hairline monochrome.
---
--- Content that does not fill the rail is centred rather than left-aligned, so a short row reads as deliberate instead of as a row that ran out. Once the content overflows, the centring stops applying and normal scrolling takes over.
local PANEL = {}

--- Initialises the rail and strips the stock arrow buttons.
---@realm client
function PANEL:Init()
    self:SetOverlap(0)

    -- Kept alive rather than removed: DHorizontalScroller lays them out and reads their width every frame.
    if ( IsValid(self.btnLeft) ) then
        self.btnLeft:SetAlpha(0)
        self.btnLeft:SetMouseInputEnabled(false)
    end

    if ( IsValid(self.btnRight) ) then
        self.btnRight:SetAlpha(0)
        self.btnRight:SetMouseInputEnabled(false)
    end
end

--- Measures how far the laid-out cards actually reach, which is the content width the base scroller works from.
---@realm client
---@return number width Rightmost edge of the content in pixels, or 0 when empty.
function PANEL:GetContentWidth()
    local canvas = self:GetCanvas()
    if ( !IsValid(canvas) ) then return 0 end

    local widest = 0
    local children = canvas:GetChildren()

    for i = 1, #children do
        local child = children[i]
        if ( !IsValid(child) or !child:IsVisible() ) then continue end

        widest = math.max(widest, child:GetX() + child:GetWide())
    end

    return widest
end

--- Lays the rail out, then re-centres the canvas when the cards do not fill it.
---@realm client
---@param width number Panel width in pixels.
---@param height number Panel height in pixels.
function PANEL:PerformLayout(width, height)
    if ( isfunction(BaseClass.PerformLayout) ) then
        BaseClass.PerformLayout(self, width, height)
    end

    local canvas = self:GetCanvas()
    if ( !IsValid(canvas) ) then return end

    local content = self:GetContentWidth()
    if ( content <= 0 ) then return end

    if ( content < width ) then
        canvas:SetPos((width - content) / 2, canvas:GetY())
        return
    end

    -- Overflowing: drive the canvas from the interpolated offset rather than the raw one the base scroller just applied.
    canvas:SetPos(-(self.offsetLerp or self.OffsetX or 0), canvas:GetY())
end

--- Eases the rendered offset toward the real scroll offset, which the base scroller moves in whole notches.
---@realm client
function PANEL:Think()
    local target = tonumber(self.OffsetX) or 0

    if ( !self.offsetLerp ) then
        self.offsetLerp = target
        return
    end

    if ( math.abs(self.offsetLerp - target) <= 1 ) then
        if ( self.offsetLerp == target ) then return end

        self.offsetLerp = target
        self:InvalidateLayout()

        return
    end

    self.offsetLerp = ax.ease:Lerp("Linear", math.Clamp(FrameTime() * SCROLL_SPEED, 0, 1), self.offsetLerp, target)
    self:InvalidateLayout()
end

--- Draws nothing; the rail is a container and its ground belongs to whatever holds it.
---@realm client
function PANEL:Paint()
end

vgui.Register("ax.scroller.horizontal", PANEL, "DHorizontalScroller")
