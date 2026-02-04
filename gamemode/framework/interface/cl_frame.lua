--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- ax.frame
-- Base window panel with blur, fade-in, draggable, sizable, and close/maximize/minimize support.
-- Children may be docked; operates modally.
-- @panel ax.frame

local PANEL = {}

AccessorFunc(PANEL, "m_bIsMenuComponent", "IsMenu",         FORCE_BOOL)
AccessorFunc(PANEL, "m_bDraggable",       "Draggable",     FORCE_BOOL)
AccessorFunc(PANEL, "m_bSizable",         "Sizable",       FORCE_BOOL)
AccessorFunc(PANEL, "m_bScreenLock",      "ScreenLock",    FORCE_BOOL)
AccessorFunc(PANEL, "m_bDeleteOnClose",   "DeleteOnClose", FORCE_BOOL)
AccessorFunc(PANEL, "m_bPaintShadow",     "PaintShadow",   FORCE_BOOL)
AccessorFunc(PANEL, "m_iMinWidth",        "MinWidth",      FORCE_NUMBER)
AccessorFunc(PANEL, "m_iMinHeight",       "MinHeight",     FORCE_NUMBER)
AccessorFunc(PANEL, "m_bBackgroundBlur",  "BackgroundBlur",FORCE_BOOL)

local GLASS_FLAGS = ax.render.SHAPE_IOS
local GLASS_BORDER = Color(255, 255, 255, 40)
local GLASS_BG = Color(245, 250, 255, 70)
local GLASS_HEADER = Color(255, 255, 255, 110)
local GLASS_HEADER_FLAGS = bit.bor(GLASS_FLAGS, ax.render.NO_BL, ax.render.NO_BR)

local function DrawGlassPanel(x, y, w, h, radius, color, blurIntensity, flags)
    flags = flags or GLASS_FLAGS

    ax.render().Rect(x, y, w, h)
        :Rad(radius)
        :Flags(flags)
        :Blur(blurIntensity or 1.2)
        :Draw()

    ax.render.Draw(radius, x, y, w, h, color, flags)
    ax.render.DrawOutlined(radius, x, y, w, h, GLASS_BORDER, 1, flags)
end

function PANEL:Init()
    self:SetFocusTopLevel(true)
    self:SetPaintShadow(true)

    self.btnClose = self:Add("ax.button")
    self.btnClose:SetText("X", true, true)
    self.btnClose.DoClick = function() self:Close() end

    self.lblTitle = self:Add("ax.text")
    self.lblTitle:SetFont("ax.large")

    self:SetDraggable(true)
    self:SetSizable(false)
    self:SetScreenLock(false)
    self:SetDeleteOnClose(true)
    self:SetTitle("Window")

    self:SetMinWidth(50)
    self:SetMinHeight(50)

    self:SetPaintBackgroundEnabled(false)
    self:SetPaintBorderEnabled(false)

    self.m_fCreateTime = SysTime()

    self:DockPadding(12, 64, 12, 12)
end

function PANEL:ShowCloseButton(bShow)
    self.btnClose:SetVisible(bShow)
end

function PANEL:GetTitle()
    return self.lblTitle:GetText()
end

function PANEL:SetTitle(strTitle)
    self.lblTitle:SetText(strTitle or "", true)
end

function PANEL:Close()
    self:SetVisible(false)

    if ( self:GetDeleteOnClose() ) then
        self:Remove()
    end

    self:OnClose()
end

function PANEL:OnClose()
end

function PANEL:Center()
    self:InvalidateLayout(true)
    self:CenterVertical()
    self:CenterHorizontal()
end

function PANEL:IsActive()
    if ( self:HasFocus() ) then return true end
    if ( vgui.FocusedHasParent(self) ) then return true end
    return false
end

function PANEL:Think()
    local mousex = math.Clamp(gui.MouseX(), 1, ScrW() - 1)
    local mousey = math.Clamp(gui.MouseY(), 1, ScrH() - 1)

    if ( self.Dragging ) then
        local x = mousex - self.Dragging[1]
        local y = mousey - self.Dragging[2]

        if ( self:GetScreenLock() ) then
            x = math.Clamp(x, 0, ScrW() - self:GetWide())
            y = math.Clamp(y, 0, ScrH() - self:GetTall())
        end

        self:SetPos(x, y)
    end

    if ( self.Sizing ) then
        local x = mousex - self.Sizing[1]
        local y = mousey - self.Sizing[2]
        local px, py = self:GetPos()

        if ( x < self.m_iMinWidth ) then
            x = self.m_iMinWidth
        elseif ( x > ScrW() - px and self:GetScreenLock() ) then
            x = ScrW() - px
        end

        if ( y < self.m_iMinHeight ) then
            y = self.m_iMinHeight
        elseif ( y > ScrH() - py and self:GetScreenLock() ) then
            y = ScrH() - py
        end

        self:SetSize(x, y)
        self:SetCursor("sizenwse")
        return
    end

    local screenX, screenY = self:LocalToScreen(0, 0)

    if ( self.Hovered and self.m_bSizable and
        mousex > (screenX + self:GetWide() - 20) and
        mousey > (screenY + self:GetTall() - 20) ) then
        self:SetCursor("sizenwse")
        return
    end

    if ( self.Hovered and self:GetDraggable() and
        mousey < (screenY + 48) ) then
        self:SetCursor("sizeall")
        return
    end

    self:SetCursor("arrow")

    if ( self.y < 0 ) then
        self:SetPos(self.x, 0)
    end
end

function PANEL:OnMousePressed(code)
    local screenX, screenY = self:LocalToScreen(0, 0)

    if ( self.m_bSizable and
        gui.MouseX() > (screenX + self:GetWide() - 20) and
        gui.MouseY() > (screenY + self:GetTall() - 20) ) then
        self.Sizing = { gui.MouseX() - self:GetWide(), gui.MouseY() - self:GetTall() }
        self:MouseCapture(true)
        return
    end

    if ( self:GetDraggable() and gui.MouseY() < (screenY + 48) ) then
        self.Dragging = { gui.MouseX() - self.x, gui.MouseY() - self.y }
        self:MouseCapture(true)
        return
    end
end

function PANEL:OnMouseReleased()
    self.Dragging = nil
    self.Sizing   = nil
    self:MouseCapture(false)
end

function PANEL:PerformLayout()
    self.btnClose:SetPos(self:GetWide() - 48 - 12, 12)
    self.btnClose:SetSize(48, 48)

    self.lblTitle:SetPos(16, 10)
    self.lblTitle:SetSize(self:GetWide() - 32, 40)
end

function PANEL:Paint(width, height)
    if ( self:GetBackgroundBlur() ) then
        Derma_DrawBackgroundBlur(self, self.m_fCreateTime)
    end

    DrawGlassPanel(0, 0, width, height, 12, GLASS_BG, 1.1)
    DrawGlassPanel(0, 0, width, 58, 12, GLASS_HEADER, 1.4, GLASS_HEADER_FLAGS)

    return true
end

vgui.Register("ax.frame", PANEL, "EditablePanel")
