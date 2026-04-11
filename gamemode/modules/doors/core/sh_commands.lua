local MODULE = MODULE

local DOOR_PURCHASE_DIST = 96 * 96
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

        local charOwner = door:GetDoorOwner()
        if ( charOwner ) then
            client:Notify(charOwner == character and ax.localization:GetPhrase("door.already_owned") or ax.localization:GetPhrase("door.already_purchased"), ax.notification.enums.TYPE_ERROR)
            return
        end

        if ( !door:GetRelay("ownable", true) ) then
            client:Notify(ax.localization:GetPhrase("door.not_ownable"), ax.notification.enums.TYPE_ERROR)
            return
        end

        local cost = ax.config:Get("doors.purchase_cost", 10)
        local charMoney = character:GetMoney()
        if ( !character:HasMoney(cost) ) then
            client:Notify(ax.localization:GetPhrase("not_enough_money_missing", ax.currencies:Format(cost - charMoney)), ax.notification.enums.TYPE_ERROR)
            return
        end

        character:TakeMoney(cost)
        client:Notify(ax.localization:GetPhrase("door.purchased"), ax.notification.enums.TYPE_SUCCESS)

        door:SetRelay("owner", character:GetID())
        door:SetRelay("cost", cost)
        door:SetRelay("purchased", true)
        door:SetRelay("ownerSteamID", client:SteamID64())
        door:GiveDoorAccess(client, MODULE.AccessGroups.OWNER)

        character.OwnedDoors = character.OwnedDoors or {}
        character.OwnedDoors[door:EntIndex()] = true

        hook.Run("OnDoorPurchased", client, door, cost)
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

        local cost = door:GetRelay("cost", 0)
        if ( cost <= 0 ) then return end

        character:AddMoney(cost)
        client:Notify(ax.localization:GetPhrase("door.sold"), ax.notification.enums.TYPE_SUCCESS)

        door:SetRelay("owner", -1)
        door:SetRelay("cost", 0)
        door:SetRelay("purchased", false)
        door:SetRelay("ownerSteamID", "")
        door:TakeDoorAccess(client)

        character.OwnedDoors[door:EntIndex()] = nil
        hook.Run("OnDoorSold", client, door, cost)
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
