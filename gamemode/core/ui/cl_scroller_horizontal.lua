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

local PANEL = {}

AccessorFunc(PANEL, "m_iOverlap", "Overlap")
AccessorFunc(PANEL, "m_bShowDropTargets", "ShowDropTargets", FORCE_BOOL)

function PANEL:Init()
    self.Panels = {}
    self.OffsetX = 0
    self.OffsetXLerp = 0
    self.FrameTime = 0

    self.pnlCanvas = vgui.Create("DDragBase", self)
    self.pnlCanvas:SetDropPos("6")
    self.pnlCanvas:SetUseLiveDrag(false)

    self.pnlCanvas.OnModified = function()
        self:OnDragModified()
    end

    self.pnlCanvas.UpdateDropTarget = function(Canvas, drop, this)
        if ( !self:GetShowDropTargets() ) then return end
        DDragBase.UpdateDropTarget(Canvas, drop, this)
    end

    self.pnlCanvas.OnChildAdded = function(Canvas, child)
        local dn = Canvas:GetDnD()
        if ( dn ) then
            child:Droppable(dn)
            child.OnDrop = function()
                local x = Canvas:LocalCursorPos()
                local closest = self.pnlCanvas:GetClosestChild(x, Canvas:GetTall() / 2)
                local id = 0

                for k, v in ipairs(self.Panels) do
                    if ( v == closest ) then
                        id = k
                        break
                    end
                end

                table.RemoveByValue(self.Panels, child)
                table.insert(self.Panels, id, child)
                self:InvalidateLayout()

                return child
            end
        end
    end

    self:SetOverlap(0)

    self.btnLeft = self:Add("ax.button.small", self)
    self.btnLeft:SetText("")

    self.btnRight = self:Add("ax.button.small", self)
    self.btnRight:SetText("")
end

function PANEL:GetCanvas()
    return self.pnlCanvas
end

function PANEL:SetScroll(x)
    self.OffsetX = x
    self:InvalidateLayout(true)
end

function PANEL:ScrollToChild(panel)
    self:InvalidateLayout(true)

    local x = select(1, self.pnlCanvas:GetChildPosition(panel))
    local w = panel:GetWide()

    x = x + w / 2
    x = x - self:GetWide() / 2

    self:SetScroll(x)
end

function PANEL:SetUseLiveDrag(state)
    self.pnlCanvas:SetUseLiveDrag(state)
end

function PANEL:MakeDroppable(name, allowCopy)
    self.pnlCanvas:MakeDroppable(name, allowCopy)
end

function PANEL:AddPanel(panel)
    table.insert(self.Panels, panel)
    panel:SetParent(self.pnlCanvas)
    self:InvalidateLayout(true)
end

function PANEL:Clear()
    self.pnlCanvas:Clear()
    self.Panels = {}
end

function PANEL:OnMouseWheeled(delta)
    self.OffsetX = self.OffsetX + delta * -175
    self:InvalidateLayout(true)
    return true
end

function PANEL:Think()
    local frameRate = VGUIFrameTime() - self.FrameTime
    self.FrameTime = VGUIFrameTime()

    if ( self.btnRight:IsDown() ) then
        self.OffsetX = self.OffsetX + 500 * frameRate
        self:InvalidateLayout(true)
    end

    if ( self.btnLeft:IsDown() ) then
        self.OffsetX = self.OffsetX - 500 * frameRate
        self:InvalidateLayout(true)
    end

    if ( dragndrop.IsDragging() ) then
        local x = self:LocalCursorPos()

        if ( x < 30 ) then
            self.OffsetX = self.OffsetX - 500 * frameRate
        elseif ( x > self:GetWide() - 30 ) then
            self.OffsetX = self.OffsetX + 500 * frameRate
        end

        self:InvalidateLayout(true)
    end

    self.OffsetXLerp = Lerp(0.1, self.OffsetXLerp, self.OffsetX)
    self:PerformLayout()
end

function PANEL:PerformLayout()
    local w, h = self:GetSize()
    self.pnlCanvas:SetTall(h)

    local x = 0

    for _, v in ipairs(self.Panels) do
        if ( !IsValid(v) or !v:IsVisible() ) then continue end

        v:SetPos(x, 0)
        v:SetTall(h)

        if ( v.ApplySchemeSettings ) then
            v:ApplySchemeSettings()
        end

        x = x + v:GetWide() - self.m_iOverlap
    end

    self.pnlCanvas:SetWide(x + self.m_iOverlap)

    if ( w < self.pnlCanvas:GetWide() ) then
        self.OffsetX = math.Clamp(self.OffsetX, 0, self.pnlCanvas:GetWide() - w)
    else
        self.OffsetX = 0
    end

    self.pnlCanvas.x = -self.OffsetXLerp

    self.btnLeft:SetSize(15, 15)
    self.btnLeft:AlignLeft(4)
    self.btnLeft:AlignBottom(5)

    self.btnRight:SetSize(15, 15)
    self.btnRight:AlignRight(4)
    self.btnRight:AlignBottom(5)

    self.btnLeft:SetVisible(self.pnlCanvas.x < 0)
    self.btnRight:SetVisible(self.pnlCanvas.x + self.pnlCanvas:GetWide() > w)
end

function PANEL:OnDragModified()
    -- Override this to handle drag reorder updates
end

function PANEL:GenerateExample(classname, sheet)
    local scroller = vgui.Create("ax.scroller.horizontal")
    scroller:Dock(TOP)
    scroller:SetHeight(64)
    scroller:DockMargin(5, 50, 5, 50)
    scroller:SetOverlap(-4)

    for _ = 0, 16 do
        local img = vgui.Create("DImage", scroller)
        img:SetImage("scripted/breen_fakemonitor_1")
        scroller:AddPanel(img)
    end

    sheet:AddSheet(classname, scroller, nil, true, true)
end

vgui.Register("ax.scroller.horizontal", PANEL, "Panel")