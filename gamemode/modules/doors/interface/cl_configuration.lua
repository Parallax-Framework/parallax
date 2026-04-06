local MODULE = MODULE

local PANEL = {}
function PANEL:Init()
    if ( IsValid(ax.gui.door_config) ) then
        ax.gui.door_config:Remove()
    end

    ax.gui.door_config = self

    self:SetSize(800, 600)
    self:Center()

    self:SetTitle("Door Config")

    self.leftPanel = self:Add("EditablePanel")
    self.leftPanel:Dock(LEFT)
    self.leftPanel:SetWide(150)

    self.leftPanel.scrollBar = self.leftPanel:Add("ax.scroller.vertical")
    self.leftPanel.scrollBar:Dock(FILL)

    self.rightPanel = self:Add("EditablePanel")
    self.rightPanel:Dock(FILL)

    self:AddButton("Door Access Groups", self.PopulateDoorAccessGroups)
end

function PANEL:PopulateDoorAccessGroups()
end

function PANEL:AddButton(name, callback)
    local button = self.leftPanel.scrollBar:Add("ax.button")
    button:SetText(name)
    button:Dock(TOP)
    button:SizeToContents()

    button.DoClick = function()
        self.rightPanel:Clear()
        callback()
    end

    self.leftPanel.scrollBar:SizeToChildren(true, false)
    self.leftPanel.scrollBar:InvalidateChildren()

    return button
end

vgui.Register("ax.doors.config", PANEL, "ax.frame")

concommand.Add("ax_open_door_config", function()
    if ( !IsValid(ax.gui.door_config) ) then
        vgui.Create("ax.doors.config")
    else
        ax.gui.door_config:Remove()
    end
end)
