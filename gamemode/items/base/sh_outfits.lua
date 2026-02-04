ITEM.name = "Base Outfit"
ITEM.description = "A base outfit item. This item is not meant to be spawned."
ITEM.model = Model("models/props_junk/garbage_bag001a.mdl")
ITEM.category = "Outfits"
ITEM.weight = 3
ITEM.price = 150

ITEM.shouldStack = false -- Outfits typically do not stack
ITEM.maxStack = 1 -- Maximum number of items that can be stacked, incase should

ITEM.isOutfit = true -- Flag to identify this item as an outfit
ITEM.outfitType = "Generic" -- Default outfit type, should be overridden by specific outfit items
ITEM.replaceBodyGroups = {
    -- Example body groups, should be overridden by specific outfit items
    -- ["Torso"] = 1,
    -- ["Legs"] = 2,
}

ITEM.replaceModel = nil -- Optional model to replace the player's model when outfit is equipped, should be overridden by specific outfit items
ITEM.replaceSkin = nil -- Optional skin to replace the player's skin when outfit is equipped, should be overridden by specific outfit items

ITEM:AddAction("equip", {
    name = "Equip",
    description = "Equip this outfit.",
    icon = "parallax/icons/check-circle.png",
    OnRun = function(action, item, client)
        client:Notify("You have equipped the item: " .. item:GetName(), "info")
        return false -- Returning false prevents the item from being removed after use
    end,
    CanUse = function(action, item, client)
        return true -- TODO: Add checks to see if the player can equip the outfit (e.g., not already wearing an outfit of the same type)
    end
})

ITEM:AddAction("unequip", {
    name = "Unequip",
    description = "Unequip this outfit.",
    icon = "parallax/icons/minus-circle.png",
    OnRun = function(action, item, client)
        client:Notify("You have unequipped the item: " .. item:GetName(), "info")
        return false -- Returning false prevents the item from being removed after use
    end,
    CanUse = function(action, item, client)
        return true -- TODO: Add checks to see if the player can unequip the outfit (e.g., is currently wearing this outfit)
    end
})
