--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

AccessorFunc(PANEL, "Padding", "Padding")
AccessorFunc(PANEL, "pnlCanvas", "Canvas")
AccessorFunc(PANEL, "m_bInverted", "Inverted", FORCE_BOOL)
AccessorFunc(PANEL, "m_bStackToTop", "StackToTop", FORCE_BOOL)

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

    if ( self:GetInverted() and self:GetStackToTop() ) then
        pnl:SetZPos(-#self:GetCanvas():GetChildren()) -- put at top visually
    end
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
    if ( self:GetInverted() ) then
        delta = -delta
    end

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

    if ( self:GetInverted() ) then
        self.pnlCanvas:SetPos(0, self:GetTall() - self.pnlCanvas:GetTall() + self.ScrollLerp)
    else
        self.pnlCanvas:SetPos(0, -self.ScrollLerp)
    end

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

PANEL = {}

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

                for i = 1, #self.Panels do
                    if ( self.Panels[i] == closest ) then
                        id = i
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

    self.btnLeft = self:Add("ax.button.flat", self)
    self.btnLeft:SetText("")

    self.btnRight = self:Add("ax.button.flat", self)
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
    self.Panels[#self.Panels + 1] = panel
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

    for i = 1, #self.Panels do
        local v = self.Panels[i]
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