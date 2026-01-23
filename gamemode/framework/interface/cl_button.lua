--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("DButton")

local PANEL = {}

AccessorFunc(PANEL, "soundEnter", "SoundEnter", FORCE_STRING)
AccessorFunc(PANEL, "soundClick", "SoundClick", FORCE_STRING)
AccessorFunc(PANEL, "fontDefault", "FontDefault", FORCE_STRING)
AccessorFunc(PANEL, "fontHovered", "FontHovered", FORCE_STRING)
AccessorFunc(PANEL, "inertia", "Inertia", FORCE_NUMBER)
-- AccessorFunc(PANEL, "textColor", "TextColor") -- this is already added by DButton
AccessorFunc(PANEL, "textColorMotion", "TextColorMotion")
AccessorFunc(PANEL, "textColorHovered", "TextColorHovered")
AccessorFunc(PANEL, "easing", "Easing", FORCE_STRING)
AccessorFunc(PANEL, "updateSizeOnHover", "UpdateSizeOnHover", FORCE_BOOL)
AccessorFunc(PANEL, "wasHovered", "WasHovered", FORCE_BOOL)

function PANEL:Init()
    BaseClass.Init(self)

    self.soundEnter = "ax.gui.button.enter"
    self.soundClick = "ax.gui.button.click"
    self.fontDefault = "ax.regular"
    self.fontHovered = "ax.regular.bold"
    self.textColor = Color(255, 255, 255)
    self.textColorMotion = Color(255, 255, 255)
    self.textColorHovered = Color(200, 200, 240)
    self.inertia = 0
    self.easing = "OutQuint"
    self.updateSizeOnHover = false
    self.wasHovered = false

    self:SetFont(self.fontDefault)
    self:SetTextColor(self.textColor)
    self:SetContentAlignment(4)
end

function PANEL:SetTextInternal(text)
    BaseClass.SetText(self, text)
end

function PANEL:SetText(text, bNoTranslate, bNoSizeToContents)
    if ( !text ) then return end

    if ( !bNoTranslate and text != "" ) then
        text = ax.localization:GetPhrase(text)
    end

    self:SetTextInternal(text)

    if ( !bNoSizeToContents ) then
        self:SizeToContents()
    end
end

function PANEL:SetTextColorInternal(color)
    BaseClass.SetTextColor(self, color)
end

function PANEL:SetTextColor(color)
    self.textColor = color
    self:SetTextColorInternal(color)
end

function PANEL:SizeToContentsInternal()
    BaseClass.SizeToContents(self)
end

function PANEL:SizeToContents()
    self:SizeToContentsInternal()

    local width, height = self:GetSize()
    self:SetSize(width + ax.util:ScreenScale(16), height + ax.util:ScreenScaleH(8))
end

function PANEL:CanClick(mouseCode)
end

function PANEL:OnMousePressed(mouseCode)
    if ( !self:IsEnabled() or self:CanClick(mouseCode) == false ) then return end

    if ( mouseCode == MOUSE_LEFT ) then
        if ( self.DoClick ) then
            self:DoClick()
        end
    elseif ( mouseCode == MOUSE_RIGHT ) then
        if ( self.DoRightClick ) then
            self:DoRightClick()
        end
    end

    -- Button click delay for flicker effect
    local clickDelay = ax.option:Get("button.delay.click")
    if ( clickDelay > 0 ) then
        self:SetEnabled(false)
        timer.Simple(clickDelay, function()
            if ( IsValid(self) ) then
                self:SetEnabled(true)
            end
        end)
    end

    if ( self.soundClick ) then
        ax.client:EmitSound(self.soundClick)
    end
end

function PANEL:Think()
    local hovering = self:IsHovered() and self:IsEnabled()
    if ( hovering and !self:GetWasHovered() ) then
        ax.client:EmitSound(self.soundEnter)
        self:SetFont(self.fontHovered)

        if ( self.updateSizeOnHover ) then
            self:SizeToContents()
        end

        self:SetWasHovered(true)

        self:Motion(0.25, {
            Target = {inertia = 1},
            Easing = self.easing,
            Think = function(this)
                self:SetInertia(this.inertia)
            end
        })

        self:Motion(0.25, {
            Target = {textColorMotion = self.textColorHovered},
            Easing = self.easing,
            Think = function(this)
                self:SetTextColorInternal(this.textColorMotion)
            end
        })

        if ( self.OnHovered ) then
            self:OnHovered()
        end
    elseif ( !hovering and self:GetWasHovered() ) then
        self:SetFont(self.fontDefault)

        if ( self.updateSizeOnHover ) then
            self:SizeToContents()
        end

        self:SetWasHovered(false)

        self:Motion(0.25, {
            Target = {inertia = 0},
            Easing = self.easing,
            Think = function(this)
                self:SetInertia(this.inertia)
            end
        })

        self:Motion(0.25, {
            Target = {textColorMotion = self.textColor},
            Easing = self.easing,
            Think = function(this)
                self:SetTextColorInternal(this.textColorMotion)
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

function PANEL:OnHovered()
    -- Override this method to add custom behavior
end

function PANEL:OnUnHovered()
    -- Override this method to add custom behavior
end

function PANEL:OnThink()
    -- Override this method to add custom behavior
end

function PANEL:Paint()
end

vgui.Register("ax.button.core", PANEL, "DButton")

DEFINE_BASECLASS("ax.button.core")

PANEL = {}

function PANEL:Init()
    BaseClass.Init(self)

    self:SetContentAlignment(5)
end

function PANEL:Paint(width, height)
    local border = height / 4
    ax.render.DrawShadows(border, 0, 0, width, height, Color(200, 200, 200, 10 + 40 * self.inertia), 0, border / 4, ax.render.BLUR)

    -- underline shadow
    ax.render.DrawShadows(border / 2, 0, 0, width, height, Color(0, 0, 0, 50 * self.inertia), border / 2, border)

    if ( self.PaintAdditional ) then
        self:PaintAdditional(width, height)
    end
end

vgui.Register("ax.button", PANEL, "ax.button.core")

DEFINE_BASECLASS("ax.button.core")

PANEL = {}

AccessorFunc(PANEL, "backgroundColor", "BackgroundColor")
AccessorFunc(PANEL, "backgroundAlpha", "BackgroundAlpha", FORCE_NUMBER)
AccessorFunc(PANEL, "backgroundAlphaHovered", "BackgroundAlphaHovered", FORCE_NUMBER)
AccessorFunc(PANEL, "backgroundAlphaUnHovered", "BackgroundAlphaUnHovered", FORCE_NUMBER)
AccessorFunc(PANEL, "sizeToContentsMotion", "SizeToContentsMotion", FORCE_BOOL)

function PANEL:Init()
    BaseClass.Init(self)

    self.backgroundColor = Color(255, 255, 255)
    self.backgroundAlphaHovered = 255
    self.backgroundAlphaUnHovered = 0
    self.sizeToContentsMotion = false

    self:SetTextColorHovered(Color(0, 0, 0))
    self:SetContentAlignment(5)
end

function PANEL:SetText(text)
    if ( !text ) then return end

    BaseClass.SetText(self, text)

    text = self:GetText()
    text = utf8.upper(text)

    self:SetTextInternal(text)
end

function PANEL:SizeToContents()
    if ( !self.sizeToContentsMotion ) then
        BaseClass.SizeToContents(self)

        local width, height = self:GetSize()
        self:SetSize(width + ax.util:ScreenScale(8), height + ax.util:ScreenScaleH(8))

        return
    end

    local oldWidth, oldHeight = self:GetSize()

    BaseClass.SizeToContents(self)

    local width, height = self:GetSize()
    self:SetSize(oldWidth, oldHeight)

    self.width = oldWidth
    self.height = oldHeight

    if ( !self.wasHovered ) then
        width = width + ax.util:ScreenScale(8)
        height = height + ax.util:ScreenScaleH(8)
    end

    self:Motion(0.25, {
        Target = {width = width, height = height},
        Easing = self.easing,
        Think = function(this)
            self:SetSize(this.width, this.height)
        end
    })
end

function PANEL:Paint(width, height)
    ax.render.Draw(0, 0, 0, width, height, ColorAlpha(self.backgroundColor, self.backgroundAlphaHovered * self.inertia))

    if ( self.PaintAdditional ) then
        self:PaintAdditional(width, height)
    end
end

vgui.Register("ax.button.flat", PANEL, "ax.button.core")

-- Flat button variant with icon support
DEFINE_BASECLASS("ax.button.flat")

PANEL = {}

AccessorFunc(PANEL, "icon", "Icon")
AccessorFunc(PANEL, "iconSize", "IconSize", FORCE_NUMBER)
AccessorFunc(PANEL, "iconColor", "IconColor")
AccessorFunc(PANEL, "iconSpacing", "IconSpacing", FORCE_NUMBER)
AccessorFunc(PANEL, "iconAlign", "IconAlign", FORCE_STRING)

function PANEL:Init()
    BaseClass.Init(self)

    self:SetText("")

    self.icon = nil
    self.iconSize = ax.util:ScreenScale(16)
    self.iconColor = Color(255, 255, 255)
    self.iconSpacing = ax.util:ScreenScale(4)
    self.iconAlign = "left" -- left, right, or center

    self:SetContentAlignment(5)
end

function PANEL:SetIcon(iconPath)
    if ( !isstring(iconPath) ) then return end

    self.icon = ax.util:GetMaterial(iconPath)
end

function PANEL:Paint(width, height)
    ax.render.Draw(0, 0, 0, width, height, ColorAlpha(self.backgroundColor, self.backgroundAlphaHovered * self.inertia))

    if ( self.icon ) then
        local iconY = (height - self.iconSize) / 2
        local iconInertia = 1 - self.inertia
        local iconColor = Color(self.iconColor.r * iconInertia, self.iconColor.g * iconInertia, self.iconColor.b * iconInertia, 255)

        surface.SetDrawColor(iconColor)
        if ( self.iconAlign == "left" ) then
            surface.SetMaterial(self.icon)
            surface.DrawTexturedRect(self.iconSpacing, iconY, self.iconSize, self.iconSize)
        elseif ( self.iconAlign == "right" ) then
            surface.SetMaterial(self.icon)
            surface.DrawTexturedRect(width - self.iconSpacing - self.iconSize, iconY, self.iconSize, self.iconSize)
        elseif ( self.iconAlign == "center" ) then
            surface.SetMaterial(self.icon)
            surface.DrawTexturedRect((width - self.iconSize) / 2, iconY, self.iconSize, self.iconSize)
        end
    end

    if ( self.PaintAdditional ) then
        self:PaintAdditional(width, height)
    end
end

function PANEL:GetTextInset()
    if ( !self.icon ) then return BaseClass.GetTextInset(self) end

    local insetLeft, insetTop = BaseClass.GetTextInset(self)

    if ( self.iconAlign == "left" ) then
        return insetLeft + self.iconSize + self.iconSpacing, insetTop
    elseif ( self.iconAlign == "right" ) then
        return insetLeft, insetTop
    end

    return insetLeft, insetTop
end

vgui.Register("ax.button.flat.icon", PANEL, "ax.button.flat")
