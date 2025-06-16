----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 --- Made by a transgender queen
 -- Slay queen Riggs
 -- Stay Powerfull against the Patiarchy by a man (Alex Grist) stealing code
 -- #OverwatchFramework #CodeStealingMatters

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- ax.scroller.vertical
-- A vertical scroll panel with smooth scrolling and custom canvas.
-- @panel ax.scroller.vertical

local PANEL = {}

AccessorFunc(PANEL, "Padding", "Padding")
AccessorFunc(PANEL, "pnlCanvas", "Canvas")

function PANEL:Init()
    self.pnlCanvas = vgui.Create("Panel", self)
    self.pnlCanvas:SetMouseInputEnabled(true)
    self.pnlCanvas.OnMousePressed = function(slf, code)
        slf:GetParent():OnMousePressed(code)
    end
    self.pnlCanvas.PerformLayout = function()
        self:PerformLayoutInternal()
        self:InvalidateParent()
    end

    self.VBar = self:Add("DVScrollBar")
    self.VBar:Dock(RIGHT)

    self:SetPadding(0)
    self:SetMouseInputEnabled(true)

    self:SetPaintBackgroundEnabled(false)
    self:SetPaintBorderEnabled(false)
    self:SetPaintBackground(false)

    self.ScrollLerp = 0
    self.ScrollTarget = 0
end

function PANEL:AddItem(pnl)
    pnl:SetParent(self:GetCanvas())
end

function PANEL:OnChildAdded(child)
    self:AddItem(child)
end

function PANEL:SizeToContents()
    self:SetSize(self.pnlCanvas:GetSize())
end

function PANEL:GetVBar()
    return self.VBar
end

function PANEL:GetCanvas()
    return self.pnlCanvas
end

function PANEL:InnerWidth()
    return self.pnlCanvas:GetWide()
end

function PANEL:Rebuild()
    self.pnlCanvas:SizeToChildren(false, true)

    if ( self.m_bNoSizing and self.pnlCanvas:GetTall() < self:GetTall() ) then
        self.pnlCanvas:SetPos(0, (self:GetTall() - self.pnlCanvas:GetTall()) * 0.5)
    end
end

function PANEL:OnMouseWheeled(delta)
    self.ScrollTarget = self.ScrollTarget - delta * 120
    self.ScrollTarget = math.Clamp(self.ScrollTarget, 0, math.max(0, self.pnlCanvas:GetTall() - self:GetTall()))
    return true
end

function PANEL:OnVScroll(offset)
    self.ScrollTarget = offset
end

function PANEL:ScrollToChild(panel)
    self:InvalidateLayout(true)

    local _, y = self.pnlCanvas:GetChildPosition(panel)
    local _, h = panel:GetSize()

    y = y + h * 0.5
    y = y - self:GetTall() * 0.5

    self.ScrollTarget = y
end

function PANEL:Think()
    self.ScrollLerp = Lerp(0.1, self.ScrollLerp, self.ScrollTarget)

    if ( math.abs(self.ScrollLerp - self.ScrollTarget) > 1 ) then
        self:InvalidateLayout()
    end
end

function PANEL:PerformLayoutInternal()
    local wide = self:GetWide()

    self:Rebuild()

    self.VBar:SetUp(self:GetTall(), self.pnlCanvas:GetTall())
    local maxScroll = self.pnlCanvas:GetTall() - self:GetTall()

    self.ScrollTarget = math.Clamp(self.ScrollTarget, 0, math.max(0, maxScroll))
    self.ScrollLerp = math.Clamp(self.ScrollLerp, 0, math.max(0, maxScroll))

    if ( self.VBar.Enabled ) then
        wide = wide - self.VBar:GetWide()
    end

    self.pnlCanvas:SetPos(0, -self.ScrollLerp)
    self.pnlCanvas:SetWide(wide)

    self:Rebuild()
end

function PANEL:PerformLayout()
    self:PerformLayoutInternal()
end

function PANEL:Clear()
    return self.pnlCanvas:Clear()
end

vgui.Register("ax.scroller.vertical", PANEL, "DPanel")