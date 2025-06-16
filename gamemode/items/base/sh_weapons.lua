--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ITEM.Name = "Weapon Base"
ITEM.Description = "A base for all weapons."
ITEM.Category = "Weapons"
ITEM.Model = Model("models/weapons/w_smg1.mdl")

ITEM.Weight = 5

ITEM.WeaponClass = "weapon_base"

ITEM:AddAction({
    Name = "Equip",
    OnCanRun = function(this, item, client)
        local axWeapons = client:GetRelay("weapons", {})
        return !axWeapons[item.WeaponClass] and !client:HasWeapon(item.WeaponClass)
    end,
    OnRun = function(this, item, client)
        local weapon = client:Give(item.WeaponClass)
        if ( !IsValid(weapon) ) then return end

        local axWeapons = client:GetRelay("weapons", {})
        axWeapons[item.WeaponClass] = item:GetID()
        client:SetRelay("weapons", axWeapons)

        client:SelectWeapon(item.WeaponClass)

        item:SetData("equipped", true)
    end
})

ITEM:AddAction({
    Name = "Unequip",
    OnCanRun = function(this, item, client)
        local axWeapons = client:GetRelay("weapons", {})
        local axWeaponID = axWeapons[item.WeaponClass]
        return tobool(axWeaponID and client:HasWeapon(item.WeaponClass) and axWeaponID == item:GetID())
    end,
    OnRun = function(this, item, client)
        client:StripWeapon(item.WeaponClass)
        client:SelectWeapon("ax_hands")

        local axWeapons = client:GetRelay("weapons", {})
        axWeapons[item.WeaponClass] = nil
        client:SetRelay("weapons", axWeapons)

        item:SetData("equipped", false)
    end
})

ITEM:Hook("Drop", function(item, client)
    local axWeapons = client:GetRelay("weapons", {})
    if ( client:HasWeapon(item.WeaponClass) and axWeapons[item.WeaponClass] == item:GetID() ) then
        client:StripWeapon(item.WeaponClass)
        client:SelectWeapon("ax_hands")

        axWeapons[item.WeaponClass] = nil
        client:SetRelay("weapons", axWeapons)

        item:SetData("equipped", false)
    end
end)

function ITEM:OnCache()
    self:SetData("equipped", self:GetData("equipped", false))
end