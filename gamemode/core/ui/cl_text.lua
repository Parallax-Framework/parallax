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
    self:SetFont("parallax")
    self:SetTextColor(Parallax.Color:Get("text.light"))
end

function PANEL:SetText(text, bNoTranslate, bNoSizeToContents)
    if ( !bNoTranslate ) then
        -- we need to check if the text is upper case, because the localization function will convert it to lower case
        -- after that we can convert it back to upper case if needed
        local isUpper = false
        if ( string.upper(text) == text ) then
            isUpper = true
        end

        text = Parallax.Localization:GetPhrase(string.lower(text))

        if ( isUpper ) then
            text = Parallax.Utf8:Upper(text)
        end
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

vgui.Register("Parallax.Text", PANEL, "DLabel")

DEFINE_BASECLASS("DLabel")

PANEL = {}

AccessorFunc(PANEL, "bTypingEnabled", "TypingEnabled", FORCE_BOOL)
AccessorFunc(PANEL, "fTypingSpeed", "TypingSpeed", FORCE_NUMBER)

function PANEL:Init()
    self:SetFont("parallax")
    self:SetTextColor(Parallax.Color:Get("text.light"))

    self.fullText = ""
    self.displayedText = ""
    self.charIndex = 0
    self.nextCharTime = 0

    self:SetTypingEnabled(true)
    self:SetTypingSpeed(0.03)
end

function PANEL:SetText(text, bNoTranslate, bNoSizeToContents)
    if ( !bNoTranslate ) then
        local isUpper = (string.upper(text) == text)

        text = Parallax.Localization:GetPhrase(string.lower(text))

        if ( isUpper ) then
            text = string.upper(text)
        end
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

vgui.Register("Parallax.Text.Typewriter", PANEL, "DLabel")

concommand.Add("parallax_showtypewriter", function()
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Typewriter Example")
    frame:SetSize(600, 200)
    frame:Center()
    frame:MakePopup()

    local label = frame:Add("Parallax.Text.Typewriter")
    label:Dock(FILL)
    label:SetTypingSpeed(0.05)
    label:SetText("WELCOME TO SANTEGO BASE", true, true)

    local reset = frame:Add("DButton")
    reset:SetText("Reset Text")
    reset:Dock(BOTTOM)
    reset.DoClick = function()
        label:RestartTyping()
    end
end)