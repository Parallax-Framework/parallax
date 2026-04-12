local MODULE = MODULE

function ax.player.meta:HasDoorAccess(door, actions)
    if ( !door:IsDoor() ) then return false end

    local doorTable = door:GetTable()
    local playerAccess = doorTable.axPlayerAccess and doorTable.axPlayerAccess[self] or MODULE.AccessGroups.NONE

    local try = hook.Run("CanPlayerAccessDoor", self, door, playerAccess)
    if ( try != nil ) then return try end

    if ( playerAccess == MODULE.AccessGroups.NONE ) then return false end

    if ( !actions ) then
        return true
    end

    local permissions = MODULE.AccessGroup_Permissions[playerAccess]
    return permissions and bit.band(permissions, actions) == actions
end
