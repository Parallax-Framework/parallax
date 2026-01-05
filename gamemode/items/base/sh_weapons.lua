ITEM.name = "Base Weapon"
ITEM.description = "A base weapon item. This item is not meant to be spawned."
ITEM.model = Model("models/weapons/w_pistol.mdl")
ITEM.category = "Weapons"
ITEM.weight = 2
ITEM.price = 250

ITEM.shouldStack = false -- Weapons typically do not stack
ITEM.maxStack = 1 -- Maximum number of items that can be stacked, incase shouldStack is true

ITEM.isWeapon = true -- Flag to identify this item as a weapon
ITEM.weaponClass = "weapon_pistol" -- Default weapon class, should be overridden by specific weapon items
ITEM.weaponType = "Pistol" -- Default weapon type, should be overridden by specific weapon items
ITEM.equipSound = "items/ammo_pickup.wav" -- Default equip sound
ITEM.unequipSound = "items/ammo_pickup.wav" -- Default unequip sound

ITEM:AddAction("equip", {
    name = "Equip",
    description = "Equip this item.",
    icon = "icon16/accept.png",
    OnRun = function(action, item, client)
        client:Give(item.weaponClass)
        client:SelectWeapon(item.weaponClass)
        client:EmitSound(item.equipSound or "items/ammo_pickup.wav")

        item:SetData("equipped", true)

        return false
    end,
    CanUse = function(action, item, client)
        if ( item:GetData("equipped") ) then
            return false, "Item is already equipped."
        end

        -- check if we have the same weapon type equipped
        for _, invItem in pairs(client:GetCharacter():GetInventory():GetItems()) do
            if ( invItem.isWeapon and invItem.weaponType == item.weaponType and invItem:GetData("equipped") ) then
                return false, "You already have a " .. item.weaponType .. " equipped."
            end
        end

        return true
    end
})

ITEM:AddAction("unequip", {
    name = "Unequip",
    description = "Unequip this item.",
    icon = "icon16/cross.png",
    OnRun = function(action, item, client)
        client:StripWeapon(item.weaponClass)
        client:EmitSound(item.unequipSound or "items/ammo_pickup.wav")

        item:SetData("equipped", nil)

        return false
    end,
    CanUse = function(action, item, client)
        if ( !item:GetData("equipped") ) then
            return false, "Item is not equipped."
        end

        return true
    end
})
