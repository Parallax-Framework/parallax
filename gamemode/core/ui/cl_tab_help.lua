--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)
    self:InvalidateParent(true)

    local title = self:Add("Parallax.text")
    title:Dock(TOP)
    title:SetFont("Parallax.huge.bold")
    title:SetText("HELP")

    self.buttons = self:Add("Parallax.scroller.horizontal")
    self.buttons:Dock(TOP)
    self.buttons:DockMargin(0, ScreenScaleH(4), 0, 0)
    self.buttons:SetTall(ScreenScaleH(24))
    self.buttons.Paint = nil

    self.buttons.btnLeft:SetAlpha(0)
    self.buttons.btnRight:SetAlpha(0)

    self.container = self:Add("EditablePanel")
    self.container:Dock(FILL)
    self.container:InvalidateParent(true)
    self.container.Paint = nil

    local categories = {}
    hook.Run("PopulateHelpCategories", categories)
    for k, v in SortedPairs(categories) do
        local button = self.buttons:Add("Parallax.button.flat")
        button:Dock(LEFT)
        button:SetText(k)
        button:SizeToContents()

        button.DoClick = function()
            Parallax.GUI.helpLast = k

            self:Populate(v)
        end

        self.buttons:AddPanel(button)
    end

    for k, v in SortedPairs(categories) do
        if ( Parallax.GUI.helpLast ) then
            if ( Parallax.GUI.helpLast == k ) then
                self:Populate(v)
                break
            end
        else
            self:Populate(v)
            break
        end
    end
end

function PANEL:Populate(data)
    if ( !data ) then return end

    self.container:Clear()

    if ( istable(data) ) then
        if ( isfunction(data.Populate) ) then
            data:Populate(self.container)
        end

        if ( data.OnClose ) then
            self:CallOnRemove("Parallax.tab.help." .. data.name, function()
                data.OnClose()
            end)
        end
    elseif ( isfunction(data) ) then
        data(self.container)
    end
end

vgui.Register("Parallax.tab.help", PANEL, "EditablePanel")

Parallax.GUI.helpLast = nil