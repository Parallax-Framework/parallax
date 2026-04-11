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

    local receivers = {}
    for k, v in pairs(doorTable.axPlayerAccess) do
        receivers[#receivers + 1] = k
    end

    ax.net:Start(receivers, "ax.doors.door_access.take", self, client)

    hook.Run("OnPlayerLostDoorAccess", client, self, doorAccessHad)
    return true
end

function ENTITY:GetDoorOwner()
    if ( !self:IsDoor() ) then return nil end

    local charOwnerID = self:GetRelay("owner", -1)
    if ( charOwnerID == -1 ) then return nil end

    return ax.character.instances[charOwnerID]
end
