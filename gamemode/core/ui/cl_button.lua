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

AccessorFunc(PANEL, "baseHeight", "BaseHeight", FORCE_NUMBER)
AccessorFunc(PANEL, "baseTextColor", "BaseTextColor")
AccessorFunc(PANEL, "baseTextColorTarget", "BaseTextColorTarget")
AccessorFunc(PANEL, "fontDefault", "FontDefault")
AccessorFunc(PANEL, "fontHovered", "FontHovered")
AccessorFunc(PANEL, "height", "Height", FORCE_NUMBER)
AccessorFunc(PANEL, "inertia", "Inertia", FORCE_NUMBER)
AccessorFunc(PANEL, "soundClick", "SoundClick")
AccessorFunc(PANEL, "soundEnter", "SoundEnter")
AccessorFunc(PANEL, "textInsetX", "TextInsetX", FORCE_NUMBER)
AccessorFunc(PANEL, "textInsetY", "TextInsetY", FORCE_NUMBER)
AccessorFunc(PANEL, "wasHovered", "WasHovered", FORCE_BOOL)

function PANEL:Init()
    self.baseHeight = self:GetTall()
    self.baseTextColor = self:GetTextColor()
    self.baseTextColorTarget = ax.config:Get("color.schema")
    self.fontDefault = "ax.large"
    self.fontHovered = "ax.large.bold"
    self.height = self.baseHeight
    self.inertia = 0
    self.soundClick = "ax.button.click"
    self.soundEnter = "ax.button.enter"
    self.textColor = Color(255, 255, 255, 255)
    self.textInsetX = ScreenScale(2)
    self.textInsetY = 0
    self.wasHovered = false

    self:SetFont(self.fontDefault)
    self:SetTextColorProperty(ax.color:Get("white"))
    self:SetContentAlignment(4)
    self:SetTextInset(ScreenScale(2), 0)
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

    self.baseHeight = self:GetTall()
    self.height = self.baseHeight
end

function PANEL:Paint(width, height)
    local textColor = self.textColor
    local inertia = self.inertia

    local backgroundColor = Color(textColor.r / 8, textColor.g / 8, textColor.b / 8)
    draw.RoundedBox(0, 0, 0, width, height, ColorAlpha(backgroundColor, 100 * inertia))

    surface.SetDrawColor(textColor.r, textColor.g, textColor.b, 200 * inertia)
    surface.DrawRect(0, 0, ScreenScale(4) * inertia, height)

    return false
end

function PANEL:Think()
    local hovering = self:IsHovered()
    if ( hovering and !self.wasHovered ) then
        surface.PlaySound(self.soundEnter)
        self:SetFont(self.fontHovered)
        self.wasHovered = true

        self:Motion(0.2, {
            Target = {height = self.baseHeight * 1.25},
            Easing = "OutQuad",
            Think = function(this)
                self:SetTall(self.height)
            end
        })

        self:Motion(0.2, {
            Target = {textColor = self.baseTextColorTarget},
            Easing = "OutQuad",
            Think = function(this)
                self:SetTextColor(self.textColor)
            end
        })

        self:Motion(0.2, {
            Target = {textInsetX = ScreenScale(8), textInsetY = 0},
            Easing = "OutQuad",
            Think = function(this)
                self:SetTextInset(self.textInsetX, self.textInsetY)
            end
        })

        self:Motion(0.2, {
            Target = {inertia = 1},
            Easing = "OutQuad",
            Think = function(this)
                self:SetInertia(self.inertia)
            end
        })

        if ( self.OnHovered ) then
            self:OnHovered()
        end
    elseif ( !hovering and self.wasHovered ) then
        self:SetFont(self.fontDefault)
        self.wasHovered = false

        self:Motion(0.2, {
            Target = {height = self.baseHeight},
            Easing = "OutQuad",
            Think = function(this)
                self:SetTall(self.height)
            end
        })

        self:Motion(0.2, {
            Target = {textColor = self.baseTextColor or ax.color:Get("white")},
            Easing = "OutQuad",
            Think = function(this)
                self:SetTextColor(self.textColor)
            end
        })

        self:Motion(0.2, {
            Target = {textInsetX = ScreenScale(2), textInsetY = 0},
            Easing = "OutQuad",
            Think = function(this)
                self:SetTextInset(self.textInsetX, self.textInsetY)
            end
        })

        self:Motion(0.2, {
            Target = {inertia = 0},
            Easing = "OutQuad",
            Think = function(this)
                self:SetInertia(self.inertia)
            end
        })

        if ( self.OnUnHovered ) then
            self:OnUnHovered()
        end
    end

    if ( self.OnThink ) then
        self:OnThink()
    end
end

function PANEL:OnMousePressed(key)
    surface.PlaySound(self.soundClick)

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
    self.backgroundAlphaHovered = 1
    self.backgroundAlphaUnHovered = 0
    self.backgroundColor = ax.color:Get("white")
    self.baseHeight = self:GetTall()
    self.baseTextColor = self:GetTextColor()
    self.baseTextColorTarget = ax.color:Get("black")
    self.fontDefault = "ax.large"
    self.fontHovered = "ax.large.bold"
    self.inertia = 0
    self.wasHovered = false

    self:SetFont(self.fontDefault)
    self:SetTextColorProperty(ax.color:Get("white"))
    self:SetContentAlignment(5)
    self:SetTall(ScreenScaleH(12))
    self:SetTextInset(0, 0)

    self:SetWide(ScreenScale(64))
end

function PANEL:SizeToContents()
    BaseClass.SizeToContents(self)

    self:SetSize(self:GetWide() + ScreenScale(16), self:GetTall() + ScreenScaleH(16))
end

function PANEL:Paint(width, height)
    draw.RoundedBox(0, 0, 0, width, height, ColorAlpha(self.backgroundColor, 255 * self.inertia))
    return false
end

function PANEL:Think()
    local hovering = self:IsHovered()
    if ( hovering and !self.wasHovered ) then
        surface.PlaySound(self.soundEnter)
        self:SetFont(self.fontHovered)
        self.wasHovered = true

        self:Motion(0.2, {
            Target = {textColor = self.baseTextColorTarget},
            Easing = "OutQuad",
            Think = function(this)
                self:SetTextColor(self.textColor)
            end
        })

        self:Motion(0.2, {
            Target = {inertia = self.backgroundAlphaHovered or 1},
            Easing = "OutQuad",
            Think = function(this)
                self:SetInertia(self.inertia)
            end
        })

        if ( self.OnHovered ) then
            self:OnHovered()
        end
    elseif ( !hovering and self.wasHovered ) then
        self:SetFont(self.fontDefault)
        self.wasHovered = false

        self:Motion(0.2, {
            Target = {textColor = self.baseTextColor or ax.color:Get("white")},
            Easing = "OutQuad",
            Think = function(this)
                self:SetTextColor(self.textColor)
            end
        })

        self:Motion(0.2, {
            Target = {inertia = self.backgroundAlphaUnHovered or 0},
            Easing = "OutQuad",
            Think = function(this)
                self:SetInertia(self.inertia)
            end
        })

        if ( self.OnUnHovered ) then
            self:OnUnHovered()
        end
    end

    if ( self.OnThink ) then
        self:OnThink()
    end
end

vgui.Register("ax.button.flat", PANEL, "ax.button")

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