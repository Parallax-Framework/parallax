--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

util.AddNetworkString("ax.doors.buy")
util.AddNetworkString("ax.doors.lock")
util.AddNetworkString("ax.doors.sell")
util.AddNetworkString("ax.doors.setownable")
util.AddNetworkString("ax.doors.setunownable")

net.Receive("ax.doors.buy", function(len, client)
    local ent = net.ReadEntity()
    if ( !IsValid(ent) or !ent:IsDoor() ) then return end

    -- Check if door is ownable
    if ( !MODULE.doors:IsOwnable(ent) ) then
        client:Notify("This door cannot be owned!")
        return
    end

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

    character:TakeMoney(price)

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

    local child = ent:GetChildDoor()
    if ( IsValid(child) ) then
        child:SetRelay("locked", !locked)

        if ( locked ) then
            child:Fire("Unlock")
        else
            child:Fire("Lock")
        end
    end

    local master = ent:GetMasterDoor()
    if ( IsValid(master) ) then
        master:SetRelay("locked", !locked)

        if ( locked ) then
            master:Fire("Unlock")
        else
            master:Fire("Lock")
        end
    end

    if ( locked ) then
        client:Notify("You have unlocked the door!")
    else
        client:Notify("You have locked the door!")
    end
end)

net.Receive("ax.doors.setownable", function(len, client)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Doors", nil) ) then
        client:Notify("You don't have permission to manage doors!")
        return
    end

    local ent = net.ReadEntity()
    if ( !IsValid(ent) or !ent:IsDoor() ) then return end

    MODULE.doors:SetOwnable(ent, true)
    client:Notify("Door has been set as ownable!")
end)

net.Receive("ax.doors.setunownable", function(len, client)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Manage Doors", nil) ) then
        client:Notify("You don't have permission to manage doors!")
        return
    end

    local ent = net.ReadEntity()
    if ( !IsValid(ent) or !ent:IsDoor() ) then return end

    MODULE.doors:SetOwnable(ent, false)
    client:Notify("Door has been set as unownable!")
end)