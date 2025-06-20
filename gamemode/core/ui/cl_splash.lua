--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local gradientTop = Parallax.Util:GetMaterial("vgui/gradient-u")

DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    if ( IsValid(Parallax.GUI.Splash) ) then
        Parallax.GUI.Splash:Remove()
    end

    Parallax.GUI.Splash = self

    if ( system.IsWindows() ) then
        system.FlashWindow()
    end

    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:MakePopup()

    local title = self:Add("DLabel")
    title:Dock(TOP)
    title:DockMargin(0, ScreenScaleH(32), 0, 0)
    title:SetContentAlignment(5)
    title:SetFont("Parallax.Huge.bold")
    title:SetText("PARALLAX")
    title:SetTextColor(Parallax.Config:Get("color.framework"))
    title:SizeToContents()

    local subtitle = self:Add("DLabel")
    subtitle:Dock(TOP)
    subtitle:DockMargin(0, -ScreenScaleH(4), 0, 0)
    subtitle:SetContentAlignment(5)
    subtitle:SetFont("Parallax.Large.bold")

    local schemaName = "UNKNOWN SCHEMA"
    if ( SCHEMA ) then
        schemaName = SCHEMA.Name
        if ( isfunction(SCHEMA.GetMenuTitle) ) then
            schemaName = SCHEMA:GetMenuTitle()
        end

        schemaName = Parallax.Utf8:Upper(schemaName)
    else
        Parallax.Util:PrintError("SCHEMA is not defined! Please ensure that your schema is properly set up.")
    end

    subtitle:SetText(schemaName)
    subtitle:SetTextColor(Parallax.Config:Get("color.schema"))
    subtitle:SizeToContents()

    local button = self:Add("Parallax.Button.Flat")
    button:SetText("splash.continue")
    button:Center()
    button.DoClick = function()
        self:AlphaTo(0, 0.5, 0, function()
            self:Remove()
        end)

        vgui.Create("Parallax.Mainmenu")
    end
end

function PANEL:OnRemove()
    if ( IsValid(Parallax.GUI.Splash) ) then
        Parallax.GUI.Splash = nil
    end

    if ( !IsValid(Parallax.GUI.Mainmenu) ) then
        vgui.Create("Parallax.Mainmenu")
    end
end

function PANEL:Paint(width, height)
    surface.SetDrawColor(0, 0, 0, 255)
    surface.SetMaterial(gradientTop)
    surface.DrawTexturedRect(0, 0, width, height / 2)
end

vgui.Register("Parallax.Splash", PANEL, "EditablePanel")

if ( IsValid(Parallax.GUI.Splash) ) then
    Parallax.GUI.Splash:Remove()
end

concommand.Add("ax_splash", function(client, command, arguments)
    if ( client:Team() == 0 ) then
        return
    end

    if ( IsValid(Parallax.GUI.Splash) ) then
        Parallax.GUI.Splash:Remove()
    end

    vgui.Create("Parallax.Splash")
end, nil, "Open the splash screen", FCVAR_CLIENTCMD_CAN_EXECUTE)