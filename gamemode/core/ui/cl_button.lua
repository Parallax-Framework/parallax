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

DEFINE_BASECLASS("DButton")

local PANEL = {}

AccessorFunc(PANEL, "inertia", "Inertia", FORCE_NUMBER)

function PANEL:Init()
    self:SetFont("parallax.button")
    self:SetTextColorProperty(ax.color:Get("white"))
    self:SetContentAlignment(4)
    self:SetTall(ScreenScaleH(18))
    self:SetTextInset(ScreenScale(2), 0)

    self.inertia = 0
    self.inertiaTarget = 0

    self.baseHeight = self:GetTall()
    self.baseTextColor = self:GetTextColor()

    self.height = self.baseHeight
    self.heightTarget = self.baseHeight

    self.textColor = Color(255, 255, 255, 255)
    self.textColorTarget = ax.color:Get("white")

    self.textInset = {ScreenScale(2), 0}
    self.textInsetTarget = {ScreenScale(2), 0}
end

function PANEL:SetText(text, bNoTranslate, bNoSizeToContents, bNoUppercase)
    if ( !text ) then return end

    if ( !bNoTranslate ) then
        text = ax.localization:GetPhrase(text)
    end

    if ( !bNoUppercase ) then
        text = ax.utf8:Upper(text)
    end

    BaseClass.SetText(self, text)

    if ( !bNoSizeToContents ) then
        self:SizeToContents()
    end
end

function PANEL:SetTextColorProperty(color)
    self.baseTextColor = color
    self:SetTextColor(color)
end

function PANEL:SizeToContents()
    BaseClass.SizeToContents(self)
end

function PANEL:Paint(width, height)
    local ft = FrameTime()
    local time = ft * 10

    local performanceAnimations = ax.option:Get("performance.animations", true)
    if ( !performanceAnimations ) then
        time = 1
    end

    self.inertia = Lerp(time, self.inertia, self.inertiaTarget)
    self.height = Lerp(time, self.height, self.heightTarget)
    self.textColor = self.textColor:Lerp(self.textColorTarget, time)

    self.textInset[1] = Lerp(time, self.textInset[1], self.textInsetTarget[1])
    self.textInset[2] = Lerp(time, self.textInset[2], self.textInsetTarget[2])

    local backgroundColor = Color(self.textColor.r / 8, self.textColor.g / 8, self.textColor.b / 8)
    draw.RoundedBox(0, 0, 0, width, height, ColorAlpha(backgroundColor, 100 * self.inertia))

    surface.SetDrawColor(self.textColor.r, self.textColor.g, self.textColor.b, 200 * self.inertia)
    surface.DrawRect(0, 0, ScreenScale(4) * self.inertia, height)

    return false
end

function PANEL:Think()
    if ( !self:IsHovered() and ( self.textColorTarget != self.baseTextColor or self.heightTarget != self.baseHeight) ) then
        self:SetFont("parallax.button")

        self.heightTarget = self.baseHeight
        self.textColorTarget = self.baseTextColor or ax.color:Get("white")
        self.textInsetTarget = {ScreenScale(2), 0}

        self.inertiaTarget = 0

        if ( self.OnUnHovered ) then
            self:OnUnHovered()
        end
    end

    self:SetTall(self.height)
    self:SetTextColor(self.textColor)
    self:SetTextInset(self.textInset[1], self.textInset[2])

    if ( self.OnThink ) then
        self:OnThink()
    end
end

function PANEL:OnCursorEntered()
    surface.PlaySound("ax.button.enter")

    self:SetFont("parallax.button.hover")

    self.heightTarget = self.baseHeight * 1.25
    self.textColorTarget = ax.config:Get("color.schema")
    self.textInsetTarget = {ScreenScale(8), 0}

    self.inertiaTarget = 1

    if ( self.OnHovered ) then
        self:OnHovered()
    end
end

function PANEL:OnMousePressed(key)
    surface.PlaySound("ax.button.click")

    if ( key == MOUSE_LEFT ) then
        self:DoClick()
    else
        self:DoRightClick()
    end
end

vgui.Register("ax.button", PANEL, "DButton")

DEFINE_BASECLASS("ax.button")

PANEL = {}

AccessorFunc(PANEL, "backgroundAlphaHovered", "BackgroundAlphaHovered", FORCE_NUMBER)
AccessorFunc(PANEL, "backgroundAlphaUnHovered", "BackgroundAlphaUnHovered", FORCE_NUMBER)
AccessorFunc(PANEL, "backgroundColor", "BackgroundColor")

function PANEL:Init()
    self:SetFont("parallax.button.small")
    self:SetTextColorProperty(ax.color:Get("white"))
    self:SetContentAlignment(5)
    self:SetTall(ScreenScaleH(12))
    self:SetTextInset(0, 0)

    self:SetWide(ScreenScale(64))

    self.backgroundAlphaHovered = 1
    self.backgroundAlphaUnHovered = 0

    self.inertia = 0
    self.inertiaTarget = 0

    self.baseHeight = self:GetTall()
    self.baseTextColor = self:GetTextColor()

    self.baseTextColorTarget = ax.color:Get("black")
    self.textColorTarget = ax.color:Get("black")

    self.backgroundColor = ax.color:Get("white")
end

function PANEL:SizeToContents()
    BaseClass.SizeToContents(self)

    self:SetSize(self:GetWide() + ScreenScale(16), self:GetTall() + ScreenScale(16))
end

function PANEL:Paint(width, height)
    local ft = FrameTime()
    local time = ft * 10

    local performanceAnimations = ax.option:Get("performance.animations", true)
    if ( !performanceAnimations ) then
        time = 1
    end

    self.inertia = Lerp(time, self.inertia, self.inertiaTarget)
    self.textColor = self.textColor:Lerp(self.textColorTarget, time)

    draw.RoundedBox(0, 0, 0, width, height, ColorAlpha(self.backgroundColor, 255 * self.inertia))

    return false
end

function PANEL:Think()
    if ( !self:IsHovered() and ( self.textColorTarget != self.baseTextColor ) ) then
        self:SetFont("parallax.button.small")

        self.textColorTarget = self.baseTextColor or ax.color:Get("white")

        self.inertiaTarget = self.backgroundAlphaUnHovered or 0

        if ( self.OnUnHovered ) then
            self:OnUnHovered()
        end
    end

    self:SetTextColor(self.textColor)

    if ( self.OnThink ) then
        self:OnThink()
    end
end

function PANEL:OnCursorEntered()
    surface.PlaySound("ax.button.enter")

    self:SetFont("parallax.button.small.hover")

    self.textColorTarget = self.baseTextColorTarget or ax.color:Get("black")

    self.inertiaTarget = self.backgroundAlphaHovered or 1

    if ( self.OnHovered ) then
        self:OnHovered()
    end
end

vgui.Register("ax.button.small", PANEL, "ax.button")

sound.Add({
    name = "ax.button.click",
    channel = CHAN_STATIC,
    volume = 0.2,
    level = 80,
    pitch = 120,
    sound = "ui/buttonclickrelease.wav"
})

sound.Add({
    name = "ax.button.enter",
    channel = CHAN_STATIC,
    volume = 0.1,
    level = 80,
    pitch = 120,
    sound = "ui/buttonrollover.wav"
})