--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("DLabel")

local PANEL = {}

function PANEL:Init()
    self:SetFont("ax.regular")
    self:SetTextColor(color_white)
end

function PANEL:SetText(text, bNoTranslate, bNoSizeToContents)
    if ( !text ) then return end

    if ( !bNoTranslate ) then
        text = ax.localization:GetPhrase(text)
    end

    BaseClass.SetText(self, text)

    if ( !bNoSizeToContents ) then
        self:SizeToContents()
    end
end

function PANEL:SizeToContents()
    BaseClass.SizeToContents(self)

    local width, height = self:GetSize()
    self:SetSize(width + 8, height + 4)
end

vgui.Register("ax.text", PANEL, "DLabel")

DEFINE_BASECLASS("DLabel")

PANEL = {}

AccessorFunc(PANEL, "bTypingEnabled", "TypingEnabled", FORCE_BOOL)
AccessorFunc(PANEL, "fTypingSpeed", "TypingSpeed", FORCE_NUMBER)

function PANEL:Init()
    self:SetFont("ax.regular")
    self:SetTextColor(color_white)

    self.fullText = ""
    self.displayedText = ""
    self.charIndex = 0
    self.nextCharTime = 0

    self:SetTypingEnabled(true)
    self:SetTypingSpeed(0.03)
end

function PANEL:SetText(text, bNoTranslate, bNoSizeToContents)
    if ( !text ) then return end

    if ( !bNoTranslate ) then
        text = ax.localization:GetPhrase(text)
    end

    if ( self:GetTypingEnabled() ) then
        self.fullText = text
        self:RestartTyping()
    else
        BaseClass.SetText(self, text)
    end

    if ( !bNoSizeToContents ) then
        surface.SetFont(self:GetFont())
        local w, h = surface.GetTextSize(text)
        self:SetSize(w + 8, h + 4)
    end
end

function PANEL:RestartTyping()
    self.displayedText = ""
    self.charIndex = 0
    self.nextCharTime = CurTime() + self:GetTypingSpeed()
end

function PANEL:Think()
    if ( self:GetTypingEnabled() and self.charIndex < #self.fullText and CurTime() >= self.nextCharTime ) then
        self.charIndex = self.charIndex + 1
        self.displayedText = string.sub(self.fullText, 1, self.charIndex)

        BaseClass.SetText(self, self.displayedText)
        self.nextCharTime = CurTime() + self:GetTypingSpeed()
    end

    if ( isfunction(self.PostThink) ) then
        self:PostThink()
    end
end

function PANEL:SizeToContents()
    BaseClass.SizeToContents(self)

    local width, height = self:GetSize()
    self:SetSize(width + 8, height + 4)
end

vgui.Register("ax.text.typewriter", PANEL, "DLabel")

DEFINE_BASECLASS("DTextEntry")

PANEL = {}

function PANEL:Init()
    self:SetFont("ax.regular")
    self:SetTextColor(color_white)
    self:SetPaintBackground(false)
    self:SetUpdateOnType(true)
    self:SetCursorColor(color_white)
    self:SetHighlightColor(color_white)

    self:SetTall(ScreenScale(12))
end

function PANEL:SizeToContents()
    BaseClass.SizeToContents(self)

    local width, height = self:GetSize()
    self:SetSize(width + 8, height + 4)
end

function PANEL:Paint(width, height)
    surface.SetDrawColor(0, 0, 0, 100)
    surface.DrawRect(0, 0, width, height)

    BaseClass.Paint(self, width, height)
end

function PANEL:ShouldPlayTypeSound()
    return true
end

function PANEL:OnTextChanged(...)
    BaseClass.OnTextChanged(self, ...)

    if ( self:ShouldPlayTypeSound() ) then
        surface.PlaySound("common/talk.wav")
    end
end

vgui.Register("ax.text.entry", PANEL, "DTextEntry")