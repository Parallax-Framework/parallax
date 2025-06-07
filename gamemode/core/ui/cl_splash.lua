local gradientTop = ax.util:GetMaterial("vgui/gradient-u")

DEFINE_BASECLASS("EditablePanel")

local PANEL = {}

function PANEL:Init()
    if ( IsValid(ax.gui.splash) ) then
        ax.gui.splash:Remove()
    end

    ax.gui.splash = self

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
    title:SetFont("parallax.title")
    title:SetText("PARALLAX")
    title:SetTextColor(ax.config:Get("color.framework"))
    title:SizeToContents()

    local subtitle = self:Add("DLabel")
    subtitle:Dock(TOP)
    subtitle:DockMargin(0, -ScreenScaleH(4), 0, 0)
    subtitle:SetContentAlignment(5)
    subtitle:SetFont("parallax.subtitle")

    local schemaName = "UNKNOWN SCHEMA"
    if ( SCHEMA ) then
        schemaName = SCHEMA.Name
        if ( isfunction(SCHEMA.GetMenuTitle) ) then
            schemaName = SCHEMA:GetMenuTitle()
        end

        schemaName = string.upper(schemaName)
    else
        ax.util:PrintError("SCHEMA is not defined! Please ensure that your schema is properly set up.")
    end

    subtitle:SetText(schemaName)
    subtitle:SetTextColor(ax.config:Get("color.schema"))
    subtitle:SizeToContents()

    local button = self:Add("ax.button.small")
    button:SetText("Click to continue")
    button:Center()
    button.DoClick = function()
        self:AlphaTo(0, 0.5, 0, function()
            self:Remove()
        end)

        vgui.Create("ax.mainmenu")
    end
end

function PANEL:OnRemove()
    if ( IsValid(ax.gui.splash) ) then
        ax.gui.splash = nil
    end

    if ( !IsValid(ax.gui.mainmenu) ) then
        vgui.Create("ax.mainmenu")
    end
end

function PANEL:Paint(width, height)
    surface.SetDrawColor(0, 0, 0, 255)
    surface.SetMaterial(gradientTop)
    surface.DrawTexturedRect(0, 0, width, height / 2)
end

vgui.Register("ax.splash", PANEL, "EditablePanel")

if ( IsValid(ax.gui.splash) ) then
    ax.gui.splash:Remove()
end

concommand.Add("ax_splash", function(client, command, arguments)
    if ( client:Team() == 0 ) then
        return
    end

    if ( IsValid(ax.gui.splash) ) then
        ax.gui.splash:Remove()
    end

    vgui.Create("ax.splash")
end, nil, "Open the splash screen", FCVAR_CLIENTCMD_CAN_EXECUTE)