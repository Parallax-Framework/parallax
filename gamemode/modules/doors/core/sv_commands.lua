local MODULE = MODULE

local function GetAllDoors()
    local doors = {}
    for _, ent in ipairs(ents.GetAll()) do
        if ( ent:IsDoor() ) then
            doors[#doors + 1] = ent
        end
    end
    return doors
end

local function IsAdminOrRCON(client)
    return !IsValid(client) or client:IsAdmin()
end

local function Feedback(client, msg)
    if ( IsValid(client) ) then
        client:Notify(msg, ax.notification.enums.TYPE_SUCCESS)
    else
        print("[Parallax Doors] " .. msg)
    end
end

concommand.Add("ax_door_lockall", function(client)
    if ( !IsAdminOrRCON(client) ) then return end

    local doors = GetAllDoors()
    local count = 0
    for i = 1, #doors do
        local door = doors[i]
        if ( !door:IsLocked() ) then
            door:LockDoor()
            count = count + 1
        end
    end

    Feedback(client, "Locked " .. count .. " door(s) on the map.")
end, nil, "Locks all unlocked doors on the map. Requires admin.")

concommand.Add("ax_door_unlockall", function(client)
    if ( !IsAdminOrRCON(client) ) then return end

    local doors = GetAllDoors()
    local count = 0
    for i = 1, #doors do
        local door = doors[i]
        if ( door:IsLocked() ) then
            door:UnlockDoor()
            count = count + 1
        end
    end

    Feedback(client, "Unlocked " .. count .. " door(s) on the map.")
end, nil, "Unlocks all locked doors on the map. Requires admin.")

concommand.Add("ax_door_openall", function(client)
    if ( !IsAdminOrRCON(client) ) then return end

    local doors = GetAllDoors()
    for i = 1, #doors do
        doors[i]:Fire("Open")
    end

    Feedback(client, "Opened " .. #doors .. " door(s) on the map.")
end, nil, "Opens all doors on the map. Requires admin.")

concommand.Add("ax_door_closeall", function(client)
    if ( !IsAdminOrRCON(client) ) then return end

    local doors = GetAllDoors()
    for i = 1, #doors do
        doors[i]:Fire("Close")
    end

    Feedback(client, "Closed " .. #doors .. " door(s) on the map.")
end, nil, "Closes all doors on the map. Requires admin.")

concommand.Add("ax_door_resetownership", function(client)
    if ( !IsAdminOrRCON(client) ) then return end

    local doors = GetAllDoors()
    local count = 0

    for i = 1, #doors do
        local door = doors[i]
        if ( !door:GetRelay("purchased", false) ) then continue end

        local owner = door:GetDoorOwner()
        if ( owner and owner.OwnedDoors ) then
            owner.OwnedDoors[door:EntIndex()] = nil
        end

        local doorTable = door:GetTable()
        if ( doorTable.axPlayerAccess ) then
            local accessList = {}
            for pl, _ in pairs(doorTable.axPlayerAccess) do
                accessList[#accessList + 1] = pl
            end
            for j = 1, #accessList do
                door:TakeDoorAccess(accessList[j])
            end
        end

        door:SetRelay("owner", -1)
        door:SetRelay("cost", 0)
        door:SetRelay("purchased", false)
        door:SetRelay("ownerSteamID", "")

        count = count + 1
    end

    Feedback(client, "Cleared ownership on " .. count .. " door(s).")
end, nil, "Resets all door ownership on the map. Requires admin.")

concommand.Add("ax_door_makeallunownable", function(client)
    if ( !IsAdminOrRCON(client) ) then return end

    local doors = GetAllDoors()
    local unownableData = ax.data:Get("doors_unownable", {}, { scope = "map" })
    local count = 0

    for i = 1, #doors do
        local door = doors[i]
        if ( !door:GetRelay("ownable", true) ) then continue end

        door:SetRelay("ownable", false)
        unownableData[door:MapCreationID()] = true
        count = count + 1
    end

    ax.data:Set("doors_unownable", unownableData, { scope = "map" })
    Feedback(client, "Made " .. count .. " door(s) unownable.")
end, nil, "Makes all ownable doors on the map unownable. Requires admin.")

concommand.Add("ax_door_makeallownable", function(client)
    if ( !IsAdminOrRCON(client) ) then return end

    local doors = GetAllDoors()
    local count = 0

    for i = 1, #doors do
        local door = doors[i]
        if ( door:GetRelay("ownable", true) ) then continue end

        door:SetRelay("ownable", true)
        count = count + 1
    end

    ax.data:Set("doors_unownable", {}, { scope = "map" })
    Feedback(client, "Made " .. count .. " door(s) ownable.")
end, nil, "Makes all unownable doors on the map ownable. Requires admin.")
