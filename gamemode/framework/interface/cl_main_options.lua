--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

function PANEL:Init()
    hook.Run("PreMainMenuOptionsCreated", self)

    local parent = self:GetParent()

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())

    self:CreateNavigation(self, "back", function()
        self:SlideDown()
        parent.splash:SlideToFront()
    end)

    local settings = self:Add("ax.store")
    settings:SetType("option")
    settings:DockMargin(ax.util:ScreenScale(32), ax.util:ScreenScaleH(32), ax.util:ScreenScale(32), ax.util:ScreenScaleH(32))

    for _, tab in ipairs(settings:GetPages()) do
        tab:DockPadding(0, 0, ax.util:ScreenScale(64), 0)
    end

    hook.Run("PostMainMenuOptionsCreated", self)
end

function PANEL:Paint(width, height)
    ax.util:DrawGradient("down", 0, 0, width, height, Color(0, 0, 0, 200))
end

vgui.Register("ax.main.options", PANEL, "ax.transition")
