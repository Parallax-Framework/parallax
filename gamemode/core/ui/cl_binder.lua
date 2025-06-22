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

ax.binds = ax.binds or {}
local release = {}
hook.Add("Think", "ax.Keybinds.logic", function()
    if ( !system.HasFocus() or gui.IsConsoleVisible() or gui.IsGameUIVisible() or vgui.CursorVisible() ) then
        -- If the game doesn't have focus, we don't want to process keybinds.
        for keyCode in pairs(release) do
            release[keyCode] = false
        end

        return
    end

    for keyCode, optionName in pairs(ax.binds) do
        local optionData = ax.option.stored[optionName]
        if ( !istable(optionData) or optionData.Type != ax.types.number or !optionData.IsKeybind ) then continue end
        if ( !isnumber(keyCode) ) then continue end

        if ( input.IsKeyDown(keyCode) or input.IsMouseDown(keyCode) ) then
            if ( !release[keyCode] ) then
                release[keyCode] = true

                local prevent = hook.Run("PreKeybindPressed", optionName, keyCode)
                if ( prevent == true ) then continue end

                if ( isfunction(optionData.OnPressed) ) then
                    optionData:OnPressed()
                end

                hook.Run("PostKeybindPressed", optionName, keyCode)
            end
        else
            if ( release[keyCode] ) then
                local prevent = hook.Run("PreKeybindReleased", optionName, keyCode)
                if ( prevent == true ) then continue end

                if ( isfunction(optionData.OnReleased) ) then
                    optionData:OnReleased()
                end

                release[keyCode] = false
                hook.Run("PostKeybindReleased", optionName, keyCode)
            end
        end
    end
end)

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
    self:SetKeyboardInputEnabled(false)

    self.Trapping = false
end

function PANEL:OnMouseReleased(mouseCode)
    if ( mouseCode != MOUSE_LEFT ) then
        self.Trapping = false
        self:SetKeyboardInputEnabled(false)

        local bind = ax.binds[self:GetSelectedNumber()]
        if ( isstring(bind) ) then
            ax.option:Set(bind, KEY_NONE)
            ax.binds[self:GetSelectedNumber()] = nil
        end

        self:SetSelectedNumber(0)
        self:UpdateText()
        return
    end

    self:GetParent():RequestFocus()
    self:SetText("...")

    input.StartKeyTrapping()
    self.Trapping = true
    self:SetKeyboardInputEnabled(true)
end

function PANEL:OnKeyCodePressed(code)

end

function PANEL:OnChange(code)
    -- Optional override
end

function PANEL:UpdateText()
    self:SetText(input.GetKeyName(self:GetSelectedNumber()) or "None")
end

function PANEL:AllowEnter(bAllow)
    self.AllowEnter = bAllow
end

function PANEL:SetValue(value)
    self:SetSelectedNumber(value)
    self:UpdateText()
end

function PANEL:Think()
    if ( self.Trapping and !self:IsKeyboardInputEnabled() ) then
        self.Trapping = false

        return
    end

    if ( input.IsKeyTrapping() and self.Trapping ) then
        local code = input.CheckKeyTrapping()
        if ( !isnumber(code) ) then return end

        if ( code == KEY_ESCAPE ) then
            self:SetKeyboardInputEnabled(false)
            self.Trapping = false
            self:UpdateText()
            return
        end

        self:SetValue(code)
        self:SetKeyboardInputEnabled(false)

        if ( isfunction(self.OnChange) ) then
            self:OnChange(code)
        end

        self.Trapping = false
    end
end

vgui.Register("ax.binder", PANEL, "ax.button")