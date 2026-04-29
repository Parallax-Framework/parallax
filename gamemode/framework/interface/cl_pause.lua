--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.gui = ax.gui or {}

local PANEL = {}

function PANEL:Init()
    hook.Run("PrePauseMenuContentCreated", self)

    local parent = self:GetParent()
    if ( !IsValid(parent) ) then return end

    -- Shrink the transition to the left third of the screen.
    self:SetWidthOffset(-math.floor(parent:GetWide() * 2 / 3))
    self:SetHeightOffset(0)

    self.title = self:Add("ax.text")
    self.title:Dock(TOP)
    self.title:DockMargin(ax.util:ScreenScale(32), ax.util:ScreenScaleH(32), ax.util:ScreenScale(32), ax.util:ScreenScaleH(16))
    self.title:SetFont("ax.huge.bold")
    self.title:SetContentAlignment(4)
    self.title:SetText(SCHEMA and SCHEMA.menuTranslate and "pause.title" or ( SCHEMA and SCHEMA.name or "Parallax Framework" ), !( SCHEMA and SCHEMA.menuTranslate ))
    self.title:SetTextColor(ax.theme:GetGlass().text)

    self.buttons = self:Add("EditablePanel")
    self.buttons:Dock(FILL)
    self.buttons:DockPadding(ax.util:ScreenScale(32), ax.util:ScreenScaleH(16), ax.util:ScreenScale(32), ax.util:ScreenScaleH(48))

    local extra = {}
    hook.Run("CreatePauseMenuButtons", self, extra)
    for i = 1, #extra do
        if ( IsValid(extra[i]) ) then
            self.buttons:AddItem(extra[i])
        end
    end

    self:AddButton("pause.resume", function()
        self:CloseMenu()
    end)

    if ( ax.client:GetCharacter() ) then
        self:AddButton("pause.characters", function()
            self:CloseMenu()

            timer.Simple(0.1, function()
                if ( IsValid(ax.gui.main) ) then
                    ax.gui.main:Remove()
                end

                vgui.Create("ax.main")
            end)
        end)
    end

    self:AddButton("pause.options", function()
        self:CloseMenu()

        timer.Simple(0.1, function()
            if ( IsValid(ax.gui.main) ) then
                ax.gui.main:Remove()
            end

            local main = vgui.Create("ax.main")
            if ( !IsValid(main) ) then return end

            timer.Simple(0, function()
                if ( !IsValid(main) or !IsValid(main.splash) or !IsValid(main.options) ) then return end

                main.splash:SlideLeft(0.25)
                main.options:SlideToFront(0.25)
            end)
        end)
    end)

    self:AddButton("pause.disconnect", function()
        if ( hook.Run("ShouldAllowDisconnect", self) == false ) then return end

        Derma_Query("Are you sure you want to disconnect?", "Disconnect",
            "Yes", function()
                RunConsoleCommand("disconnect")
            end,
            "No",
            nil
        )
    end)

    self:AddButton("pause.legacy", function()
        ax.gui.bPauseLegacy = true
        self:CloseMenu(function()
            gui.ActivateGameUI()
        end)
    end)

    hook.Run("PostPauseMenuContentCreated", self)
end

function PANEL:AddButton(text, doClick)
    local button = self.buttons:Add("ax.button")
    button:Dock(TOP)
    button:DockMargin(0, 0, 0, ax.util:ScreenScaleH(2))
    button:SetText(text)
    button.DoClick = function()
        if ( isfunction(doClick) ) then
            doClick()
        end
    end

    return button
end

function PANEL:CloseMenu(callback)
    local parent = self:GetParent()
    if ( !IsValid(parent) ) then return end

    parent:SetMouseInputEnabled(false)

    self:SlideLeft(nil, function()
        if ( isfunction(callback) ) then
            callback()
        end

        local parent = self:GetParent()
        if ( IsValid(parent) ) then
            parent:Remove()
        end
    end)
end

function PANEL:Paint(width, height)
    local glass = ax.theme:GetGlass()
    local metrics = ax.theme:GetMetrics()
    ax.theme:DrawGlassBackdrop(0, 0, width, height, {
        radius = 0,
        blur = 1.0,
        flags = ax.render.SHAPE_IOS,
        fill = ax.theme:ScaleAlpha(glass.overlayStrong, metrics.opacity)
    })
end

vgui.Register("ax.pause.content", PANEL, "ax.transition")

PANEL = {}

function PANEL:Init()
    if ( IsValid(ax.gui.pause) ) then
        ax.gui.pause:Remove()
    end

    ax.gui.pause = self

    hook.Run("PrePauseMenuCreated", self)

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())
    self:MakePopup()
    self:SetKeyboardInputEnabled(false) -- let ESC reach OnPauseMenuShow for toggling

    self.content = self:Add("ax.pause.content")
    self.content:StartAtLeft()
    self.content:SlideToFront()

    hook.Run("PostPauseMenuCreated", self)
end

function PANEL:Close()
    if ( IsValid(self.content) ) then
        self.content:CloseMenu()
    else
        self:Remove()
    end
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.pause", PANEL, "EditablePanel")

if ( IsValid(ax.gui.pause) ) then
    ax.gui.pause:Remove()
end
