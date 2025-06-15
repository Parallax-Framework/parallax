--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- ax.binder
-- A simple key binder panel for binding a single key input.
-- @panel ax.binder

local PANEL = {}

AccessorFunc(PANEL, "m_iSelectedNumber", "SelectedNumber", FORCE_NUMBER)

function PANEL:Init()
    self:SetText("")
    self:SetFont("parallax")
    self:SetContentAlignment(5)
    self:SetDrawBackground(true)
    self:SetDrawBorder(true)
    self:SetPaintBackgroundEnabled(true)
    self:SetPaintBorderEnabled(true)
    self:SetSelectedNumber(0)
    self:SetMouseInputEnabled(true)
    self:SetKeyBoardInputEnabled(false)

    self.Changed = false
end

function PANEL:DoClick()
    self:GetParent():RequestFocus()
    self:SetText("...")
    self.Changed = true
    self:SetKeyboardInputEnabled(true)
end

function PANEL:OnKeyCodeTyped(code)
    if ( code == KEY_ESCAPE ) then
        self:SetText(input.GetKeyName(self:GetSelectedNumber()))
        self:SetKeyboardInputEnabled(false)
        self.Changed = false
        return
    end

    self:SetSelectedNumber(code)
    self:SetText(input.GetKeyName(code))
    self:SetKeyboardInputEnabled(false)
    self.Changed = true

    if ( self.OnChange ) then
        self:OnChange(code)
    end
end

function PANEL:OnChange(code)
    -- Optional override
end

function PANEL:UpdateText()
    self:SetText(input.GetKeyName(self:GetSelectedNumber()))
end

function PANEL:AllowEnter(bAllow)
    self.AllowEnter = bAllow
end

function PANEL:Think()
    if ( self.Changed and !self:HasKeyboardInputEnabled() ) then
        self.Changed = false
        self:UpdateText()
    end
end

vgui.Register("ax.binder", PANEL, "ax.button")