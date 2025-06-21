--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    if ( IsValid(Parallax.GUI.tooltip) ) then
        Parallax.GUI.tooltip:Remove()
    end

    Parallax.GUI.tooltip = self

    self:SetSize(ScreenScale(128), ScreenScale(24))
    self:SetMouseInputEnabled(false)
    self:SetPos(gui.MouseX(), gui.MouseY())
    self:SetAlpha(0)
    self:SetDrawOnTop(true)

    self.title = ""
    self.description = ""
    self.next = 0
    self.fading = false
    self.alpha = 0
    self.panel = nil
end

function PANEL:SetTitle(title)
    self.title = title
end

function PANEL:SetDescription(description)
    self.description = description
end

function PANEL:SetText(title, description)
    self.title = title
    self.description = description
end

function PANEL:SetPanel(panel)
    self.panel = panel
end

function PANEL:SizeToContents()
    local title = Parallax.Localization:GetPhrase(self.title) or self.title
    local desc = Parallax.Localization:GetPhrase(self.description) or self.description
    local descWrapped = Parallax.Util:GetWrappedText(desc, "parallax", ScreenScale(128))

    local width = 0
    local titleWidth = Parallax.Util:GetTextWidth("Parallax.large.bold", title)
    width = math.max(width, titleWidth)
    for i = 1, #descWrapped do
        local descWidth = Parallax.Util:GetTextWidth("parallax", descWrapped[i])
        width = math.max(width, descWidth)
    end

    local height = Parallax.Util:GetTextHeight("Parallax.large.bold")
    for i = 1, #descWrapped do
        height = height + Parallax.Util:GetTextHeight("parallax")
    end

    self:SetSize(width + 32, height + 8)
end

function PANEL:Think()
    if ( !system.HasFocus() ) then
        self:Remove()
    end

    self:SetPos(gui.MouseX() + 16, gui.MouseY())

    local mouseX, mouseY = gui.MouseX(), gui.MouseY()
    local screenWidth = ScrW()
    local tooltipWidth = self:GetWide()

    self:SetPos(math.Clamp(mouseX + 16, 0, screenWidth - tooltipWidth), mouseY)
    self:SetAlpha(self.alpha)

    if ( IsValid(self.panel) ) then
        self.next = nil
        self.fading = false
        return
    elseif ( !self.next ) then
        self.next = CurTime() + 0.2
    end

    if ( self.next < CurTime() and !self.fading ) then
        self.fading = true
    end

    if ( self:GetAlpha() <= 1 and self.fading ) then
        self:Remove()
    end
end

function PANEL:Paint(width, height)
    self.alpha = Lerp(FrameTime() * 5, self.alpha, self.fading and 0 or 255)

    Parallax.Util:DrawBlur(self)
    draw.RoundedBox(0, 0, 0, width, height, Color(0, 0, 0, 200))
    local title = Parallax.Localization:GetPhrase(self.title) or self.title
    draw.SimpleText(title, "Parallax.large.bold", 8, 0, Parallax.Color:Get("text.light"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local desc = Parallax.Localization:GetPhrase(self.description) or self.description
    local descWrapped = Parallax.Util:GetWrappedText(desc, "parallax", width - 32)
    for i = 1, #descWrapped do
        draw.SimpleText(descWrapped[i], "parallax", 16, 48 + (i - 1) * Parallax.Util:GetTextHeight("parallax"), Parallax.Color:Get("text"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
end

vgui.Register("Parallax.Tooltip", PANEL, "EditablePanel")

if ( IsValid(Parallax.GUI.tooltip) ) then
    Parallax.GUI.tooltip:Remove()
end