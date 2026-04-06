local MODULE = MODULE

function ax.player.meta:HasDoorAccess(door, accessGroup)
    if ( !door:IsDoor() ) then return false end
    accessGroup = accessGroup or MODULE.AccessGroups.NONE

    local try = hook.Run("CanPlayerAccessDoor", self, door, accessGroup)
    if ( try != nil ) then return try end

    local doorTable = door:GetTable()

    local playerAccess = doorTable.axPlayerAccess and doorTable.axPlayerAccess[self] or MODULE.AccessGroups.NONE
    if ( playerAccess >= accessGroup ) then
        return true
    end

    return false
end
