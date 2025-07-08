--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("DTextEntry")

local PANEL = {}

function PANEL:Init()
    self:SetFont("parallax")
    self:SetTextColor(ax.color:Get("text.light"))
    self:SetPaintBackground(false)
    self:SetUpdateOnType(true)
    self:SetCursorColor(ax.color:Get("text.light"))
    self:SetHighlightColor(ax.color:Get("text.light"))
    self._bSndEffectOptional = false

    self:SetTall(ScreenScale(12))
end

function PANEL:SizeToContents()
    BaseClass.SizeToContents(self)

    local width, height = self:GetSize()
    self:SetSize(width + 8, height + 4)
end

function PANEL:Paint(width, height)
    surface.SetDrawColor(ax.color:Get("background.transparent"))
    surface.DrawRect(0, 0, width, height)

    BaseClass.Paint(self, width, height)
end

function PANEL:ShouldPlayTypeSound()
    if ( self._bSndEffectOptional ) then
        return ax.option:Get("chat.typesound")
    end

    return BaseClass.ShouldPlayTypeSound(self)
end

function PANEL:OnTextChanged(...)
    BaseClass.OnTextChanged(self, ...)

    if ( self:ShouldPlayTypeSound() ) then
        surface.PlaySound("common/talk.wav")
    end
end

vgui.Register("ax.text.entry", PANEL, "DTextEntry")