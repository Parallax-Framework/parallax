local MODULE = MODULE

ax.net:Hook("ax.doors.door_access.give", function(door, client, accessGroup)
    local doorTable = door:GetTable()

    doorTable.axPlayerAccess = doorTable.axPlayerAccess or {}
    doorTable.axPlayerAccess[client] = accessGroup
end)

ax.net:Hook("ax.doors.door_access.take", function(door, client)
    local doorTable = door:GetTable()
    doorTable.axPlayerAccess = doorTable.axPlayerAccess or {}
    doorTable.axPlayerAccess[client] = nil
end)

ax.net:Hook("ax.doors.access_groups_update", function(accessGroups)
    MODULE.AccessGroups = accessGroups

    if ( IsValid(ax.gui.door_config) and ax.gui.door_config.activePageName == "door.interface.access_groups" ) then
        ax.gui.door_config.rightPanel:Clear()
        ax.gui.door_config:PopulateDoorAccessGroups()
    end
end)

ax.net:Hook("ax.doors.access_group_permissions_update", function(groupIndex, permissions)
    MODULE.AccessGroup_Permissions[groupIndex] = permissions
end)

ax.net:Hook("ax.doors.permissions_sync", function(permissions)
    MODULE.AccessGroup_Permissions = permissions
end)
