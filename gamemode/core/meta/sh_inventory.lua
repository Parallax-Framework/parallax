----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 --- Made by a transgender queen
 -- Slay queen Riggs
 -- Stay Powerfull against the Patiarchy by a man (Alex Grist) stealing code
 -- #OverwatchFramework #CodeStealingMatters

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local INV = ax.inventory.meta
INV.__index = INV
INV.ID = 0
INV.Items = {}

--- Converts the inventory to a string representation.
-- @treturn string The string representation of the inventory.
function INV:__tostring()
    return "inventory[" .. self:GetID() .. "]"
end

--- Compares the inventory with another inventory.
-- @param other The other inventory to compare with.
-- @treturn boolean Whether the inventories are equal.
function INV:__eq(other)
    return self.ID == other.ID
end

--- Gets the inventory's ID.
-- @treturn number The inventory's ID.
function INV:GetID()
    return self.ID
end

--- Gets the inventory's name.
-- @treturn string The inventory's name.
function INV:GetName()
    return self.Name or "Inventory"
end

--- Gets the inventory's owner (character ID).
-- @treturn number The character ID of the owner.
function INV:GetOwner()
    return self.CharacterID
end

--- Gets the inventory's data.
-- @treturn table The inventory's data.
function INV:GetData()
    return self.Data or {}
end

--- Gets the maximum weight the inventory can hold.
-- @treturn number The maximum weight.
function INV:GetMaxWeight()
    local override = hook.Run("GetInventoryMaxWeight", self)
    if ( isnumber(override) ) then return override end

    return self.MaxWeight or ax.config:Get("inventory.max.weight", 20)
end

--- Gets the current weight of the inventory.
-- @treturn number The current weight of the inventory.
function INV:GetWeight()
    local weight = 0

    for _, itemID in ipairs(self:GetItems()) do
        local item = ax.item:Get(itemID)
        if ( item ) then
            local itemWeight = item:GetWeight() or 0
            if ( itemWeight >= 0 ) then
                weight = weight + itemWeight
            end
        end
    end

    return weight
end

--- Checks if the inventory has space for a given weight.
-- @tparam number weight The weight to check for.
-- @treturn boolean Whether the inventory has space for the weight.
function INV:HasSpaceFor(weight)
    return (self:GetWeight() + weight) <= self:GetMaxWeight()
end

--- Gets the items in the inventory.
-- @treturn table A table of item IDs in the inventory.
function INV:GetItems()
    return self.Items or {}
end

--- Adds an item to the inventory.
-- @tparam number itemID The ID of the item to add.
-- @tparam string uniqueID The unique ID of the item.
-- @tparam table data Optional data associated with the item.
function INV:AddItem(itemID, uniqueID, data)
    ax.inventory:AddItem(self:GetID(), itemID, uniqueID, data)
end

--- Removes an item from the inventory.
-- @tparam number itemID The ID of the item to remove.
function INV:RemoveItem(itemID)
    ax.inventory:RemoveItem(self:GetID(), itemID)
end

--- Gets the receivers of the inventory.
-- @treturn table A table of players who can receive updates about the inventory.
function INV:GetReceivers()
    local receivers = {}
    local owner = ax.character:GetPlayerByCharacter(self.CharacterID)

    if ( IsValid(owner) ) then
        table.insert(receivers, owner)
    end

    if ( self.Receivers ) then
        for _, receiver in ipairs(self.Receivers) do
            if ( IsValid(receiver) and receiver:IsPlayer() ) then
                table.insert(receivers, receiver)
            end
        end
    end

    return receivers
end

--- Adds a receiver to the inventory.
-- @tparam Player receiver The player to add as a receiver.
function INV:AddReceiver(receiver)
    if ( !IsValid(receiver) or !receiver:IsPlayer() ) then return end

    self.Receivers = self.Receivers or {}

    if ( !table.HasValue(self.Receivers, receiver) ) then
        table.insert(self.Receivers, receiver)
    end
end

--- Removes a receiver from the inventory.
-- @tparam Player receiver The player to remove as a receiver.
function INV:RemoveReceiver(receiver)
    if ( !IsValid(receiver) or !receiver:IsPlayer() ) then return end

    if ( self.Receivers ) then
        table.RemoveByValue(self.Receivers, receiver)
    end
end

--- Clears all receivers from the inventory.
function INV:ClearReceivers()
    self.Receivers = {}
    local owner = ax.character:GetPlayerByCharacter(self.CharacterID)

    if ( IsValid(owner) ) then
        table.insert(self.Receivers, owner)
    end
end

--- Checks if the inventory contains an item with a specific unique ID.
-- @tparam string itemUniqueID The unique ID of the item to check for.
-- @treturn table|nil The item if found, or nil if not found.
function INV:HasItem(itemUniqueID)
    if ( !isstring(itemUniqueID) ) then return false end

    for _, itemID in ipairs(self:GetItems()) do
        local item = ax.item:Get(itemID)
        if ( item and item:GetUniqueID() == itemUniqueID ) then
            return item
        end
    end

    return nil
end

--- Checks if the inventory contains a specific quantity of an item.
-- @tparam string itemUniqueID The unique ID of the item to check for.
-- @tparam number quantity The quantity to check for.
-- @treturn boolean Whether the inventory contains the specified quantity of the item.
function INV:HasItemQuantity(itemUniqueID, quantity)
    if ( !isstring(itemUniqueID) or !isnumber(quantity) ) then return false end

    local count = 0

    for _, itemID in ipairs(self:GetItems()) do
        local item = ax.item:Get(itemID)
        if ( item and item:GetUniqueID() == itemUniqueID ) then
            count = count + 1
        end
    end

    return count >= quantity
end