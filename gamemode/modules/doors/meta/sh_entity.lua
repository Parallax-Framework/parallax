local MODULE = MODULE

local ENTITY = FindMetaTable("Entity")
function ENTITY:GiveDoorAccess(client, accessGroup)
    if ( !self:IsDoor() ) then return false end
    accessGroup = accessGroup or MODULE.AccessGroups.TENANT

    local doorTable = self:GetTable()
    doorTable.axPlayerAccess = doorTable.axPlayerAccess or {}

    if ( accessGroup == MODULE.AccessGroups.NONE ) then
        return self:TakeDoorAccess(client)
    end

    doorTable.axPlayerAccess[client] = accessGroup

    local receivers = {}
    for k, v in pairs(doorTable.axPlayerAccess) do
        receivers[#receivers + 1] = k
    end

    ax.net:Start(nil, "ax.doors.door_access.give", self, client, accessGroup)

    -- not sure whether to call this here, or in a hook/command
    hook.Run("OnPlayerReceivedDoorAccess", client, self, accessGroup)
    return true
end

function ENTITY:TakeDoorAccess(client)
    if ( !self:IsDoor() ) then return false end

    local doorTable = self:GetTable()
    local playerAccess = doorTable.axPlayerAccess
    if ( !doorTable.axPlayerAccess or !isnumber(doorTable.axPlayerAccess[client]) ) then return false end

    local doorAccessHad = doorTable.axPlayerAccess[client]

    doorTable.axPlayerAccess[client] = nil

    local receivers = { client }
    for k, v in pairs(doorTable.axPlayerAccess) do
        receivers[#receivers + 1] = k
    end

    ax.net:Start(receivers, "ax.doors.door_access.take", self, client)

    hook.Run("OnPlayerLostDoorAccess", client, self, doorAccessHad)
    return true
end

--- Locks a door and syncs the state to clients via relay. Also locks the partner door if one exists.
-- @realm server
-- @param bNoPartner boolean If true, skips locking the partner door (used internally to avoid recursion)
-- @return boolean success
function ENTITY:LockDoor(bNoPartner)
    if ( !self:IsDoor() ) then return false end

    self:Fire("Lock")
    self:SetRelay("locked", true)
    hook.Run("OnDoorLocked", self)

    if ( !bNoPartner ) then
        local partner = self:GetDoorPartner()
        if ( IsValid(partner) and partner:IsDoor() ) then
            partner:LockDoor(true)
        end
    end

    return true
end

--- Unlocks a door and syncs the state to clients via relay. Also unlocks the partner door if one exists.
-- @realm server
-- @param bNoPartner boolean If true, skips unlocking the partner door (used internally to avoid recursion)
-- @return boolean success
function ENTITY:UnlockDoor(bNoPartner)
    if ( !self:IsDoor() ) then return false end

    self:Fire("Unlock")
    self:SetRelay("locked", false)
    hook.Run("OnDoorUnlocked", self)

    if ( !bNoPartner ) then
        local partner = self:GetDoorPartner()
        if ( IsValid(partner) and partner:IsDoor() ) then
            partner:UnlockDoor(true)
        end
    end

    return true
end

--- Toggles a door's lock state and syncs to clients via relay.
-- @realm server
-- @return boolean success
function ENTITY:ToggleDoorLock()
    if ( !self:IsDoor() ) then return false end

    if ( self:IsLocked() ) then
        return self:UnlockDoor()
    end

    return self:LockDoor()
end

function ENTITY:GetDoorOwner()
    if ( !self:IsDoor() ) then return nil end

    local charOwnerID = self:GetRelay("owner", -1)
    if ( charOwnerID == -1 ) then return nil end

    return ax.character.instances[charOwnerID]
end
