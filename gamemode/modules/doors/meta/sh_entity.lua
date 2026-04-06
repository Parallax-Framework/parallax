local MODULE = MODULE

local ENTITY = FindMetaTable("Entity")
function ENTITY:GiveDoorAccess(client, accessGroup)
    if ( !self:IsDoor() ) then return false end
    accessGroup = accessGroup or MODULE.AccessGroups.TENANT

    local doorTable = self:GetTable()
    doorTable.axPlayerAccess = doorTable.axPlayerAccess or {}
    doorTable.axPlayerAccess[client] = accessGroup

    local receivers = {}
    for k, v in pairs(doorTable.axPlayerAccess) do
        receivers[#receivers + 1] = k
    end

    net.Start("ax.doors.door_access.give")
        net.WriteEntity(self)
        net.WritePlayer(client)
        net.WriteUInt(accessGroup, 8)
    net.Send(receivers)

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

    net.Start("ax.doors.door_access.take")
        net.WriteEntity(self)
        net.WritePlayer(client)
    net.Send(receivers)

    hook.Run("OnPlayerLostDoorAccess", client, self, doorAccessHad)
    return true
end
