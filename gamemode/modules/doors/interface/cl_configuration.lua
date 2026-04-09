local MODULE = MODULE

local PANEL = {}
function PANEL:Init()
    if ( IsValid(ax.gui.door_config) ) then
        ax.gui.door_config:Remove()
    end

    ax.gui.door_config = self

    self:SetSize(800, 600)
    self:Center()
    self:MakePopup()

    self:SetTitle("Door Config")

    self.leftPanel = self:Add("EditablePanel")
    self.leftPanel:Dock(LEFT)
    self.leftPanel:SetWide(150)

    self.leftPanel.scrollBar = self.leftPanel:Add("ax.scroller.vertical")
    self.leftPanel.scrollBar:Dock(FILL)

    self.rightPanel = self:Add("EditablePanel")
    self.rightPanel:Dock(FILL)

    self:AddButton("door.interface.access_groups", self.PopulateDoorAccessGroups)
end

function PANEL:PopulateDoorAccessGroups()
    local groups = MODULE.AccessGroups

    self.rightPanel.scrollBar = self.rightPanel:Add("ax.scroller.vertical")
    self.rightPanel.scrollBar:Dock(FILL)

    self.rightPanel.groupPanels = {}

    for groupEnum, groupIndex in SortedPairsByValue(groups, true) do
        local groupPanel = self.rightPanel.scrollBar:Add("EditablePanel")
        groupPanel:Dock(TOP)
        groupPanel:SetTall(50)

        if ( groupIndex != MODULE.AccessGroups.OWNER and groupIndex != MODULE.AccessGroups.NONE ) then
            local arrowUp = groupPanel:Add("ax.button.icon")
            arrowUp:Dock(LEFT)
            arrowUp:SetFont("ax.small")
            arrowUp:SetFontDefault("ax.small")
            arrowUp:SetFontHovered("ax.small.italic")
            arrowUp:SetIcon("parallax/icons/chevron-up-square.png")
            arrowUp:SetContentAlignment(4)

            local arrowDown = groupPanel:Add("ax.button.icon")
            arrowDown:Dock(LEFT)
            arrowDown:SetFont("ax.small")
            arrowDown:SetFontDefault("ax.small")
            arrowDown:SetFontHovered("ax.small.italic")
            arrowDown:SetIcon("parallax/icons/chevron-down-square.png")
            arrowDown:SetContentAlignment(4)

            local groupPermissions = MODULE.AccessGroup_Permissions[groupIndex]

            local permissions = groupPanel:Add("ax.button")
            permissions:SetText("door.interface.permissions")
            permissions:Dock(RIGHT)
            permissions.DoClick = function(this)
                local menu = DermaMenu()

                local groupPermsTable, groupPermsMissingTable = MODULE:GetAccessGroupPermissions(groupIndex, true)

                local subMenu = menu:AddSubMenu("Give Permissions")
                for permIndex, permName in pairs(groupPermsMissingTable) do
                    subMenu:AddOption(permName, function()
                        ax.net:Start("ax.doors.access_group.permission_give", groupIndex, permIndex)
                    end)
                end

                subMenu = menu:AddSubMenu("Take Permissions")
                for permIndex, permName in pairs(groupPermsTable) do
                    subMenu:AddOption(permName, function()
                        ax.net:Start("ax.doors.access_group.permission_take", groupIndex, permIndex)
                    end)
                end


                menu:Open()
            end

            arrowUp.DoClick = function(this)
                ax.net:Start("ax.doors.group_moveup", groupEnum, groupIndex)
                UpdateArrowShouldDisplay(groupEnum, groupIndex, this, arrowDown)
            end

            arrowDown.DoClick = function(this)
                ax.net:Start("ax.doors.group_movedown", groupEnum, groupIndex)
                UpdateArrowShouldDisplay(groupEnum, groupIndex, arrowUp, this)
            end
        end


        local groupName = groupPanel:Add("ax.text")
        groupName:SetText(groupEnum)
        groupName:Dock(LEFT)
        groupName:SizeToContents()

        self.rightPanel.groupPanels[groupEnum] = groupPanel
    end
end

function PANEL:AddButton(name, callback)
    local button = self.leftPanel.scrollBar:Add("ax.button")
    button:SetText(name)
    button:Dock(TOP)
    button:SizeToContents()

    button.DoClick = function(this)
        self.rightPanel:Clear()
        callback(self)
        self.activePageName = name
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
