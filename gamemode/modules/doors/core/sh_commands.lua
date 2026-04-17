local MODULE = MODULE

local DOOR_PURCHASE_DIST = 96 * 96

local function GetLinkedDoors(door)
    local doors = { door }

    local partner = door:GetDoorPartner()
    if ( IsValid(partner) and partner:IsDoor() ) then
        doors[#doors + 1] = partner
    end

    return doors
end

ax.command:Add("DoorBuy", {
    description = "Purchase a door.",
    OnRun = function(def, client)
        local character = client:GetCharacter()
        if ( !character ) then return end

        local trace = client:GetEyeTrace()
        local door = trace.Entity

        local try, catch = hook.Run("CanPlayerPurchaseDoor", client, door)
        if ( try == false ) then
            if ( catch and #catch > 0 ) then
                client:Notify(catch, ax.notification.enums.TYPE_ERROR)
            end

            return
        end

        if ( !trace.Hit or trace.HitPos:DistToSqr(client:EyePos()) > DOOR_PURCHASE_DIST or !IsValid(door) or !door:IsDoor() ) then
            client:Notify(ax.localization:GetPhrase("door.invalid"), ax.notification.enums.TYPE_ERROR)
            return
        end

        local linkedDoors = GetLinkedDoors(door)

        for i = 1, #linkedDoors do
            local linkedDoor = linkedDoors[i]
            local charOwner = linkedDoor:GetDoorOwner()
            if ( charOwner ) then
                client:Notify(charOwner == character and ax.localization:GetPhrase("door.already_owned") or ax.localization:GetPhrase("door.already_purchased"), ax.notification.enums.TYPE_ERROR)
                return
            end

            if ( !linkedDoor:GetRelay("ownable", true) ) then
                client:Notify(ax.localization:GetPhrase("door.not_ownable"), ax.notification.enums.TYPE_ERROR)
                return
            end
        end

        local unitCost = ax.config:Get("doors.purchase_cost", 10)
        local totalCost = unitCost * #linkedDoors

        if ( !character:HasMoney(totalCost) ) then
            local charMoney = character:GetMoney()
            client:Notify(ax.localization:GetPhrase("not_enough_money_missing", ax.currencies:Format(totalCost - charMoney)), ax.notification.enums.TYPE_ERROR)
            return
        end

        character:TakeMoney(totalCost)
        character.OwnedDoors = character.OwnedDoors or {}

        for i = 1, #linkedDoors do
            local linkedDoor = linkedDoors[i]
            linkedDoor:SetRelay("owner", character:GetID())
            linkedDoor:SetRelay("cost", unitCost)
            linkedDoor:SetRelay("purchased", true)
            linkedDoor:SetRelay("ownerSteamID", client:SteamID64())
            linkedDoor:GiveDoorAccess(client, MODULE.AccessGroups.OWNER)
            character.OwnedDoors[linkedDoor:EntIndex()] = true
            hook.Run("OnDoorPurchased", client, linkedDoor, unitCost)
        end

        local count = #linkedDoors
        if ( count > 1 ) then
            client:Notify("You have purchased " .. count .. " doors.", ax.notification.enums.TYPE_SUCCESS)
        else
            client:Notify(ax.localization:GetPhrase("door.purchased"), ax.notification.enums.TYPE_SUCCESS)
        end
    end
})

ax.command:Add("DoorSell", {
    description = "Sell a door.",
    OnRun = function(def, client)
        local character = client:GetCharacter()
        if ( !character ) then return end

        local trace = client:GetEyeTrace()
        local door = trace.Entity

        if ( !trace.Hit or !IsValid(door) or !door:IsDoor() ) then
            client:Notify(ax.localization:GetPhrase("door.invalid"), ax.notification.enums.TYPE_ERROR)
            return
        end

        local owner = door:GetDoorOwner()
        if ( !owner or owner != character ) then
            client:Notify(ax.localization:GetPhrase("door.no_ownership"), ax.notification.enums.TYPE_ERROR)
            return
        end

        local try, catch = hook.Run("CanPlayerSellDoor", client, door)
        if ( try == false ) then
            if ( catch and #catch > 0 ) then
                client:Notify(catch, ax.notification.enums.TYPE_ERROR)
            end

            return
        end

        local linkedDoors = GetLinkedDoors(door)
        local totalRefund = 0
        local soldCount = 0

        character.OwnedDoors = character.OwnedDoors or {}

        for i = 1, #linkedDoors do
            local linkedDoor = linkedDoors[i]
            local linkedOwner = linkedDoor:GetDoorOwner()
            if ( !linkedOwner or linkedOwner != character ) then continue end

            local cost = linkedDoor:GetRelay("cost", 0)
            totalRefund = totalRefund + cost

            linkedDoor:SetRelay("owner", -1)
            linkedDoor:SetRelay("cost", 0)
            linkedDoor:SetRelay("purchased", false)
            linkedDoor:SetRelay("ownerSteamID", "")
            linkedDoor:TakeDoorAccess(client)

            character.OwnedDoors[linkedDoor:EntIndex()] = nil
            hook.Run("OnDoorSold", client, linkedDoor, cost)
            soldCount = soldCount + 1
        end

        if ( totalRefund > 0 ) then
            character:AddMoney(totalRefund)
        end

        if ( soldCount > 1 ) then
            client:Notify("You have sold " .. soldCount .. " doors.", ax.notification.enums.TYPE_SUCCESS)
        else
            client:Notify(ax.localization:GetPhrase("door.sold"), ax.notification.enums.TYPE_SUCCESS)
        end
    end
})

ax.command:Add("DoorSellAll", {
    description = "Sell all your doors.",
    OnRun = function(def, client)
        local character = client:GetCharacter()
        if ( !character ) then return end

        local ownedDoors = character.OwnedDoors or {}
        if ( table.Count(ownedDoors) == 0 ) then
            client:Notify(ax.localization:GetPhrase("door.none_owned"), ax.notification.enums.TYPE_ERROR)
            return
        end

        local try, catch = hook.Run("CanPlayerSellAllDoors", client)
        if ( try == false ) then
            if ( catch and #catch > 0 ) then
                client:Notify(catch, ax.notification.enums.TYPE_ERROR)
            end

            return
        end

        for doorIndex, _ in pairs(ownedDoors) do
            local door = Entity(doorIndex)
            if ( IsValid(door) and door:IsDoor() ) then
                local cost = door:GetRelay("cost", 0)
                if ( cost > 0 ) then
                    character:AddMoney(cost)
                end

                door:SetRelay("owner", -1)
                door:SetRelay("cost", 0)
                door:SetRelay("purchased", false)
                door:SetRelay("ownerSteamID", "")
                door:TakeDoorAccess(client)
            end
        end

        character.OwnedDoors = {}
        client:Notify(ax.localization:GetPhrase("door.sold_all"), ax.notification.enums.TYPE_SUCCESS)
    end
})
