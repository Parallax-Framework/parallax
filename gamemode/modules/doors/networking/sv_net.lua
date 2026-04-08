local MODULE = MODULE

ax.net:Hook("ax.doors.group_moveup", function(ply, groupEnum, groupIndex)
    if ( !CAMI.PlayerHasAccess(ply, "Parallax - Doors - Manage Access Groups", nil) ) then return end
    if ( groupEnum == "OWNER" ) then return end

    local groups = MODULE.AccessGroups

    print("moving", groupIndex, groupIndex - 1, groupEnum)

    groups[groupEnum] = groupIndex - 1

    PrintTable(groups)
end, false)

ax.net:Hook("ax.doors.group_movedown", function(ply, groupEnum, groupIndex)
    if ( !CAMI.PlayerHasAccess(ply, "Parallax - Doors - Manage Access Groups", nil) ) then return end
    if ( groupEnum == "OWNER" ) then return end

    local groups = MODULE.AccessGroups

    groups[groupEnum] = groupIndex + 1

    PrintTable(groups)
end, false)
