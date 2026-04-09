local MODULE = MODULE

ax.net:Hook("ax.doors.group_moveup", function(client, groupEnum, groupIndex)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Doors - Manage Access Groups", nil) ) then return end
    if ( groupEnum == "OWNER" or groupEnum == "NONE" ) then return end

    local groups = MODULE.AccessGroups
    if ( groupIndex + 1 >= groups.OWNER ) then
        client:Notify("You can't move above the 'OWNER' group", ax.notification.enums.WARNING)
        return
    end

    for k, v in pairs(groups) do
        if ( v == groupIndex + 1 ) then
            groups[k] = groupIndex
            break
        end
    end

    groups[groupEnum] = groupIndex + 1

    ax.net:Start(nil, "ax.doors.access_groups_update", groups)
end, false)

ax.net:Hook("ax.doors.group_movedown", function(client, groupEnum, groupIndex)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Doors - Manage Access Groups", nil) ) then return end
    if ( groupEnum == "OWNER" or groupEnum == "NONE" ) then return end

    local groups = MODULE.AccessGroups
    if ( groupIndex - 1 <= groups.NONE ) then
        client:Notify("You can't move below the 'NONE' group", ax.notification.enums.WARNING)
        return
    end

    for k, v in pairs(groups) do
        if ( v == groupIndex - 1 ) then
            groups[k] = groupIndex
            break
        end
    end

    groups[groupEnum] = groupIndex - 1

    ax.net:Start(nil, "ax.doors.access_groups_update", groups)
end, false)

ax.net:Hook("ax.doors.access_group.permission_give", function(client, groupIndex, permIndex)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Doors - Manage Access Groups", nil) ) then return end

    local permissions = MODULE.AccessGroup_Permissions[groupIndex]
    if ( !permissions ) then return end

    if ( MODULE:CanAccessGroupPerformAction(groupIndex, permIndex) ) then
        client:Notify("This access group can already perform this action", ax.notification.enums.WARNING)
        return
    end

    MODULE.AccessGroup_Permissions[groupIndex] = bit.bor(permissions, permIndex)
    ax.net:Start(nil, "ax.doors.access_group_permissions_update", groupIndex, MODULE.AccessGroup_Permissions[groupIndex])

    client:Notify("You have given permission to this access group", ax.notification.enums.SUCCESS)

    ax.data:Set("door.groupPermissions", MODULE.AccessGroup_Permissions, {
        scope = "schema",
        noCache = true
    })
end, false)

ax.net:Hook("ax.doors.access_group.permission_take", function(client, groupIndex, permIndex)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Doors - Manage Access Groups", nil) ) then return end

    local permissions = MODULE.AccessGroup_Permissions[groupIndex]
    if ( !permissions ) then return end

    if ( !MODULE:CanAccessGroupPerformAction(groupIndex, permIndex) ) then
        client:Notify("This access group cannot perform this action", ax.notification.enums.WARNING)
        return
    end

    MODULE.AccessGroup_Permissions[groupIndex] = bit.band(permissions, bit.bnot(permIndex))
    ax.net:Start(nil, "ax.doors.access_group_permissions_update", groupIndex, MODULE.AccessGroup_Permissions[groupIndex])

    client:Notify("You have taken permission from this access group", ax.notification.enums.SUCCESS)

    ax.data:Set("door.groupPermissions", MODULE.AccessGroup_Permissions, {
        scope = "schema",
        noCache = true
    })
end, false)
