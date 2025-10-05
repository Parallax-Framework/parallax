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

ITEM:AddAction("equip", {
    name = "Equip",
    description = "Equip this item.",
    icon = "icon16/accept.png",
    OnRun = function(action, item, client)
        client:Give(item.weaponClass)
        client:Notify("You have equipped the item: " .. item:GetName(), "info")
        return false -- Returning false prevents the item from being removed after use
    end,
    CanUse = function(action, item, client)
        return true -- TODO: Add checks to see if the player can equip the weapon (e.g., not already holding a weapon of the same type)
    end
})

ITEM:AddAction("unequip", {
    name = "Unequip",
    description = "Unequip this item.",
    icon = "icon16/cross.png",
    OnRun = function(action, item, client)
        client:StripWeapon(item.weaponClass)
        client:Notify("You have unequipped the item: " .. item:GetName(), "info")
        return false -- Returning false prevents the item from being removed after use
    end,
    CanUse = function(action, item, client)
        return true -- TODO: Add checks to see if the player can unequip the weapon (e.g., is currently holding this weapon)
    end
})
