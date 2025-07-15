util.AddNetworkString("ax.doors.buy")
util.AddNetworkString("ax.doors.sell")
util.AddNetworkString("ax.doors.lock")

net.Receive("ax.doors.buy", function(len, client)
    local ent = net.ReadEntity()
    if ( !IsValid(ent) or !ent:IsDoor() ) then return end

    local owner = Entity(ent:GetRelay("owner", 0))
    if ( IsValid(owner) and owner != client ) then
        client:Notify("This door is already owned by someone else!")
        return
    end

    local character = client:GetCharacter()
    if ( !character ) then return end

    local priceConfig = ax.config:Get("door.price", 5)
    local price = ent:GetRelay("price") or priceConfig
    local child = ent:GetChildDoor()
    local master = ent:GetMasterDoor()

    if ( IsValid(child) ) then
        price = price + (child:GetRelay("price") or priceConfig)
    end

    if ( IsValid(master) ) then
        price = price + (master:GetRelay("price") or priceConfig)
    end

    if ( !character:CanAfford(price) ) then
        client:Notify("You cannot afford this door!")
        return
    end

    ent:SetRelay("owner", client:EntIndex())
    ent:SetRelay("locked", ent:IsLocked())

    if ( IsValid(child) ) then
        child:SetRelay("owner", client:EntIndex())
        child:SetRelay("locked", child:IsLocked())
    end

    if ( IsValid(master) ) then
        master:SetRelay("owner", client:EntIndex())
        master:SetRelay("locked", master:IsLocked())
    end

    client:Notify("You have bought the door!")
end)

net.Receive("ax.doors.sell", function(len, client)
    local ent = net.ReadEntity()
    if ( !IsValid(ent) or !ent:IsDoor() ) then return end

    local owner = Entity(ent:GetRelay("owner", 0))
    if ( !IsValid(owner) or owner != client ) then
        client:Notify("You do not own this door!")
        return
    end

    local character = client:GetCharacter()
    if ( !character ) then return end

    local priceConfig = ax.config:Get("door.price", 5)
    local price = ent:GetRelay("price") or priceConfig
    local child = ent:GetChildDoor()
    local master = ent:GetMasterDoor()

    if ( IsValid(child) ) then
        price = price + (child:GetRelay("price") or priceConfig)
    end

    if ( IsValid(master) ) then
        price = price + (master:GetRelay("price") or priceConfig)
    end

    character:GiveMoney(price)

    ent:SetRelay("owner", 0)
    ent:SetRelay("locked", false)
    ent:Fire("Unlock")

    if ( IsValid(child) ) then
        child:SetRelay("owner", 0)
        child:SetRelay("locked", false)
        child:Fire("Unlock")
    end

    if ( IsValid(master) ) then
        master:SetRelay("owner", 0)
        master:SetRelay("locked", false)
        master:Fire("Unlock")
    end

    client:Notify("You have sold the door!")
end)

net.Receive("ax.doors.lock", function(len, client)
    local ent = net.ReadEntity()
    if ( !IsValid(ent) or !ent:IsDoor() ) then return end

    local owner = Entity(ent:GetRelay("owner", 0))
    if ( !IsValid(owner) or owner != client ) then
        client:Notify("You do not own this door!")
        return
    end

    local locked = ent:GetRelay("locked", false)
    ent:SetRelay("locked", !locked)

    if ( locked ) then
        ent:Fire("Unlock")
    else
        ent:Fire("Lock")
    end

    debugoverlay.Text(ent:WorldSpaceCenter(), "Door: " .. (!locked and "Locked" or "Unlocked"), 1, Color(255, 0, 0), true)

    local child = ent:GetChildDoor()
    if ( IsValid(child) ) then
        child:SetRelay("locked", !locked)

        if ( locked ) then
            child:Fire("Unlock")
        else
            child:Fire("Lock")
        end

        debugoverlay.Text(child:WorldSpaceCenter(), "Child Door: " .. (!locked and "Locked" or "Unlocked"), 1, Color(255, 0, 0), true)
    end

    local master = ent:GetMasterDoor()
    if ( IsValid(master) ) then
        master:SetRelay("locked", !locked)

        if ( locked ) then
            master:Fire("Unlock")
        else
            master:Fire("Lock")
        end

        debugoverlay.Text(master:WorldSpaceCenter(), "Master Door: " .. (!locked and "Locked" or "Unlocked"), 1, Color(255, 0, 0), true)
    end

    if ( locked ) then
        client:Notify("You have unlocked the door!")
    else
        client:Notify("You have locked the door!")
    end
end)