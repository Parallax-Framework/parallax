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

function ITEM:OnPlayerLoadedCharacter(client, character) -- Called when a character is loaded
    if ( !IsValid(client) or !client:IsPlayer() ) then return end

    if ( self:GetData("equipped") ) then
        if ( self.weaponClass and !client:HasWeapon(self.weaponClass) ) then
            pcall(function()
                client:Give(self.weaponClass)
                client:SelectWeapon(self.weaponClass)
            end)
        else
            self:SetData("equipped", nil)
        end
    end
end

hook.Add("OnPlayerItemAction", "ax.weapon_unequip_cleanup", function(client, item, action)
    if ( item.isWeapon and action == "drop" and item:GetData("equipped") ) then
        client:StripWeapon(item.weaponClass)
        item:SetData("equipped", nil)
    end
end)

hook.Add("PlayerDeath", "ax.weapon_unequip_on_death", function(client)
    for _, item in pairs(client:GetCharacter():GetInventory():GetItems()) do
        if ( item.isWeapon and item:GetData("equipped") ) then
            item:SetData("equipped", nil)
        end
    end
end)
