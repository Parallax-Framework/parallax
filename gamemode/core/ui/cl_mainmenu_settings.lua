--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local padding = ScreenScale(32)

DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:SetVisible(false)
end

function PANEL:Populate()
    local parent = self:GetParent()
    parent:SetGradientLeftTarget(0)
    parent:SetGradientRightTarget(0)
    parent:SetGradientTopTarget(1)
    parent:SetGradientBottomTarget(1)
    parent:SetDimTarget(0.25)
    parent.container:Clear()
    parent.container:SetVisible(false)

    self:SetVisible(true)

    local title = self:Add("ax.text")
    title:Dock(TOP)
    title:DockMargin(padding, padding, 0, 0)
    title:SetFont("ax.large.bold")
    title:SetText("options")

    local navigation = self:Add("EditablePanel")
    navigation:Dock(BOTTOM)
    navigation:DockMargin(padding, 0, padding, padding)
    navigation:SetTall(ScreenScale(24))

    local backButton = navigation:Add("ax.button.flat")
    backButton:Dock(LEFT)
    backButton:SetText("back")
    backButton.DoClick = function()
        self.currentCreatePage = 0
        self.currentCreatePayload = {}
        parent:Populate()

        self:Clear()
        self:SetVisible(false)
    end

    local options = self:Add("ax.options")
    options:Dock(FILL)
    options:DockMargin(padding, 0, padding, 0)
end

vgui.Register("ax.mainmenu.options", PANEL, "EditablePanel")

ax.gui.OptionsLast = nil