--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local ITEM = ax.item:Instance()

ITEM:SetName("Weapon Base")
ITEM:SetDescription("A base for all weapons.")
ITEM:SetCategory("Weapons")
ITEM:SetModel(Model("models/weapons/w_smg1.mdl"))

ITEM:SetWeight(5)
ITEM:SetNoStack(true)

ITEM:SetWeaponClass("weapon_base")

ITEM:AddAction({
    Name = "Equip",
    OnCanRun = function(this, item, client)
        local axWeapons = client:GetRelay("weapons", {})
        return !axWeapons[item:GetWeaponClass()] and !client:HasWeapon(item:GetWeaponClass())
    end,
    OnRun = function(this, item, client)
        local weapon = client:Give(item:GetWeaponClass())
        if ( !IsValid(weapon) ) then return end

        local axWeapons = client:GetRelay("weapons", {})
        axWeapons[item:GetWeaponClass()] = item:GetID()
        client:SetRelay("weapons", axWeapons)

        client:SelectWeapon(item:GetWeaponClass())

        item:SetData("equipped", true)
    end
})

ITEM:AddAction({
    Name = "Unequip",
    OnCanRun = function(this, item, client)
        local axWeapons = client:GetRelay("weapons", {})
        local axWeaponID = axWeapons[item:GetWeaponClass()]
        return tobool(axWeaponID and client:HasWeapon(item:GetWeaponClass()) and axWeaponID == item:GetID())
    end,
    OnRun = function(this, item, client)
        client:StripWeapon(item:GetWeaponClass())
        client:SelectWeapon("ax_hands")

        local axWeapons = client:GetRelay("weapons", {})
        axWeapons[item:GetWeaponClass()] = nil
        client:SetRelay("weapons", axWeapons)

        item:SetData("equipped", false)
    end
})

ITEM:Hook("Drop", function(item, client)
    local axWeapons = client:GetRelay("weapons", {})
    if ( client:HasWeapon(item:GetWeaponClass()) and axWeapons[item:GetWeaponClass()] == item:GetID() ) then
        client:StripWeapon(item:GetWeaponClass())
        client:SelectWeapon("ax_hands")

        axWeapons[item:GetWeaponClass()] = nil
        client:SetRelay("weapons", axWeapons)

        item:SetData("equipped", false)
    end
end)

function ITEM:OnCache()
    self:SetData("equipped", self:GetData("equipped", false))
end

ITEM:Register()