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
    if ( IsValid(ax.gui.main) ) then
        ax.gui.main:Remove()
    end

    ax.gui.main = self

    self.startTime = SysTime()

    hook.Run("PreMainMenuCreated", self)

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())
    self:MakePopup()

    self.splash = self:Add("ax.main.splash")
    self.splash:StartAtBottom()

    self.create = self:Add("ax.main.create")
    self.create:StartAtBottom()

    self.load = self:Add("ax.main.load")
    self.load:StartAtBottom()

    self.options = self:Add("ax.main.options")
    self.options:StartAtBottom()

    self.splash:StartAtTop()
    self.splash:SlideToFront()

    hook.Run("PostMainMenuCreated", self)
end

function PANEL:Paint(width, height)
    ax.render().Rect(0, 0, width, height)
        :Rad(0)
        :Flags(ax.render.SHAPE_IOS)
        :Blur(1.25)
        :Draw()
    ax.render.Draw(0, 0, 0, width, height, Color(245, 250, 255, 20))
end

vgui.Register("ax.main", PANEL, "EditablePanel")

if ( IsValid(ax.gui.main) ) then
    ax.gui.main:Remove()

    timer.Simple(0, function()
        vgui.Create("ax.main")
    end)
end

concommand.Add("ax_menu", function()
    if ( IsValid(ax.gui.main) ) then
        ax.gui.main:Remove()
        return
    end

    vgui.Create("ax.main")
end)
