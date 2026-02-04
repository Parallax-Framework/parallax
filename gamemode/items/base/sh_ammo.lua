ITEM.name = "Base Ammo"
ITEM.description = "A base ammo item. This item is not meant to be spawned."
ITEM.model = Model("models/Items/BoxSRounds.mdl")
ITEM.category = "Ammo"
ITEM.weight = 1
ITEM.price = 50

ITEM.shouldStack = true -- Allows this item to stack with others of the same type
ITEM.maxStack = 20 -- Maximum number of items that can be stacked

ITEM.isAmmo = true -- Flag to identify this item as ammo
ITEM.ammoType = "Pistol" -- Default ammo type, should be overridden by specific ammo items
ITEM.ammoAmount = 30 -- Default ammo amount, should be overridden by specific ammo items

ITEM:AddAction("use", {
    name = "Use",
    description = "Use this item to gain ammo.",
    icon = "parallax/icons/check-circle.png",
    OnRun = function(action, item, client)
        local ammoType = item.ammoType
        local ammoAmount = item.ammoAmount

        if ( !ammoType or ammoType == "" or !ammoAmount or ammoAmount <= 0 ) then
            client:Notify("This ammo item is not properly configured, please contact a developer!")
            return false
        end

        client:GiveAmmo(ammoAmount, ammoType)
        client:Notify("You have used the item: " .. item:GetName() .. " and gained " .. ammoAmount .. " " .. ammoType .. " ammo.", "info")

        return true -- Returning true removes the item after use
    end,
    CanUse = function(action, item, client)
        return true
    end
})
