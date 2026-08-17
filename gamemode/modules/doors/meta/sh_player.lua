local MODULE = MODULE

local player = ax.player.meta or FindMetaTable("Player")

--- Returns whether this player has access to a door and optional action permissions. Checks the door's stored Parallax access group for this player and lets `CanPlayerAccessDoor` override the result. When `actions` is provided, the player's access group must include every requested action bit.
---@realm shared
---@param door Entity The door entity to check.
---@param actions number|nil Bitmask of required `MODULE.AccessGroup_Permissions` actions. If nil, any non-none access grants permission.
---@return boolean # True if the player has the requested access, false otherwise.
---@usage if ( client:HasDoorAccess(door, MODULE.Permissions.UNLOCK) ) then
---     print("Player can perform this door action.")
--- end
function player:HasDoorAccess(door, actions)
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
