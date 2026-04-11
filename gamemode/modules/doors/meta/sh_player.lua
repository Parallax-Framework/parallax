local MODULE = MODULE

function ax.player.meta:HasDoorAccess(door, actions)
    if ( !door:IsDoor() ) then print("not door") return false end

    if ( !actions or actions == 0 ) then
        ax.util:PrintDebug("No actions specified. Available Actions:")
        for k, v in pairs(MODULE.Permissions) do
            ax.util:PrintDebug("\t\t" .. k)
        end

        return false
    end

    local doorTable = door:GetTable()
    local playerAccess = doorTable.axPlayerAccess and doorTable.axPlayerAccess[self] or MODULE.AccessGroups.NONE

    local try = hook.Run("CanPlayerAccessDoor", self, door, playerAccess)
    if ( try != nil ) then return try end

    local permissions = MODULE.AccessGroup_Permissions[playerAccess]
    if ( permissions and bit.band(permissions, actions) == actions ) then
        return true
    end

    return false
end
