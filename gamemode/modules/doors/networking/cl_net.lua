local MODULE = MODULE

ax.net:Hook("ax.doors.door_access.give", function(door, client, accessGroup)
    local doorTable = door:GetTable()

    doorTable.axPlayerAccess = doorTable.axPlayerAccess or {}
    doorTable.axPlayerAccess[client] = accessGroup
end)

ax.net:Hook("ax.doors.door_access.take", function(door, client)
    local doorTable = door:GetTable()
    doorTable.axPlayerAccess = doorTable.axPlayerAccess or {}
    doorTable.axPlayerAccess[client] = nil
end)
