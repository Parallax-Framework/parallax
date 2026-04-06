local MODULE = MODULE

net.Receive("ax.doors.door_access.give", function(length)
    local door = net.ReadEntity()
    local client = net.ReadPlayer()
    local accessGroup = net.ReadUInt(8)

    local doorTable = door:GetTable()
    doorTable.axPlayerAccess = doorTable.axPlayerAccess or {}
    doorTable.axPlayerAccess[client] = accessGroup
end)

net.Receive("ax.doors.door_access.take", function(length)
    local door = net.ReadEntity()
    local client = net.ReadPlayer()

    local doorTable = door:GetTable()
    doorTable.axPlayerAccess = doorTable.axPlayerAccess or {}
    doorTable.axPlayerAccess[client] = nil
end)
