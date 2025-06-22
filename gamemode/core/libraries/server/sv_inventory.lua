--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.inventory = ax.inventory or {}
ax.inventory.meta = ax.inventory.meta or {}
ax.inventory.stored = ax.inventory.stored or {}
ax.inventory.instances = ax.inventory.instances or {}

--- Adds an item to the specified inventory through the database.
-- @param number inventoryID The ID of the inventory to add the item to
-- @param string uniqueID The unique identifier of the item to add
-- @param[opt] table data Additional data for the item (optional)
-- @param function[opt] callback Callback function to execute after adding the item (optional)
function ax.inventory:AddItem(inventoryID, uniqueID, data, callback)
    if ( !inventoryID or !uniqueID ) then
        ax.util:PrintError("Invalid parameters for ax.inventory:AddItem")
        return false
    end

    if ( !data or type(data) != "table" ) then
        data = {}
    end

    ax.database:Insert("ax_items", {
        inventory_id = inventoryID,
        unique_id = uniqueID,
        data = util.TableToJSON(data)
    }, function(itemID)
        if ( !itemID ) then
            ax.util:PrintError("Failed to add item to inventory. Item ID is nil.")

            return false
        end

        ax.util:PrintSuccess("Item added to inventory successfully.")

        if ( callback ) then
            callback(itemID)
        end

        return true
    end)
end

--- Removes an item from the specified inventory through the database.
-- @param number inventoryID The ID of the inventory to remove the item from
-- @param string itemID The ID of the item to remove
-- @param function[opt] callback Callback function to execute after removing the item (optional)
function ax.inventory:RemoveItem(inventoryID, itemID, callback)
    if ( !inventoryID or !itemID ) then
        ax.util:PrintError("Invalid parameters for ax.inventory:RemoveItem")
        return false
    end

    ax.database:Delete("ax_items", {
        inventory_id = inventoryID,
        id = itemID
    }, function(success)
        if ( !success ) then
            ax.util:PrintError("Failed to remove item from inventory.")

            return false
        end

        ax.util:PrintSuccess("Item removed from inventory successfully.")

        if ( callback ) then
            callback(true)
        end

        return true
    end)
end

--- Retrieves all items from the specified inventory through the database.
-- @param number inventoryID The ID of the inventory to retrieve items from
-- @param function callback Callback function to execute with the retrieved items (optional)
function ax.inventory:GetItems(inventoryID, callback)
    if ( !inventoryID ) then
        ax.util:PrintError("Invalid parameters for ax.inventory:GetItems")
        return false
    end

    ax.database:Select("ax_items", {
        inventory_id = inventoryID
    }, function(items)
        if ( !items or #items == 0 ) then
            ax.util:PrintError("No items found in inventory.")

            if ( callback ) then
                callback({})
            end

            return false
        end

        local itemList = {}
        for _, item in ipairs(items) do
            item.data = util.JSONToTable(item.data) or {}
            table.insert(itemList, item)
        end

        ax.util:PrintSuccess("Items retrieved from inventory successfully.")

        if ( callback ) then
            callback(itemList)
        end

        return true
    end)
end

--- Clears all items from the specified inventory through the database.
-- @param number inventoryID The ID of the inventory to clear
-- @param function[opt] callback Callback function to execute after clearing the inventory (optional)
function ax.inventory:ClearInventory(inventoryID, callback)
    if ( !inventoryID ) then
        ax.util:PrintError("Invalid parameters for ax.inventory:ClearInventory")
        return false
    end

    ax.database:Delete("ax_items", {
        inventory_id = inventoryID
    }, function(success)
        if ( !success ) then
            ax.util:PrintError("Failed to clear inventory.")

            return false
        end

        ax.util:PrintSuccess("Inventory cleared successfully.")

        if ( callback ) then
            callback(true)
        end

        return true
    end)
end

--- Initializes the inventory system by loading existing inventories from the database.
-- This function should be called during the server startup process.
function ax.inventory:Initialize()
    ax.util:PrintInfo("Initializing inventory system...")

    ax.database:Select("ax_inventories", {}, function(inventories)
        if ( !inventories or #inventories == 0 ) then
            ax.util:PrintWarning("No inventories found in the database.")
            return false
        end

        for _, inventory in ipairs(inventories) do
            inventory.data = util.JSONToTable(inventory.data) or {}
            self.instances[inventory.id] = inventory
            ax.util:PrintSuccess("Loaded inventory ID " .. inventory.id)
        end

        return true
    end)
end

--- Creates a new inventory for a character.
-- @param number characterID The ID of the character to create the inventory for
-- @param number maxWeight The maximum weight capacity of the inventory
-- @param[opt] table data Initial data for the inventory (optional)
-- @param function[opt] callback Callback function to execute after creating the inventory (optional)
function ax.inventory:CreateInventory(characterID, maxWeight, data, callback)
    if ( !characterID or !maxWeight ) then
        ax.util:PrintError("Invalid parameters for ax.inventory:CreateInventory")
        return false
    end

    if ( !data or type(data) != "table" ) then
        data = {}
    end

    ax.database:Insert("ax_inventories", {
        character_id = characterID,
        max_weight = maxWeight,
        data = util.TableToJSON(data)
    }, function(inventoryID)
        if ( !inventoryID ) then
            ax.util:PrintError("Failed to create inventory. Inventory ID is nil.")

            return false
        end

        local inventory = {
            id = inventoryID,
            character_id = characterID,
            max_weight = maxWeight,
            data = data
        }

        self.instances[inventoryID] = inventory

        ax.util:PrintSuccess("Inventory created successfully with ID " .. inventoryID)

        if ( callback ) then
            callback(inventory)
        end

        return true
    end)
end

--- Deletes an inventory by its ID.
-- @param number inventoryID The ID of the inventory to delete
-- @param function[opt] callback Callback function to execute after deleting the inventory (optional)
function ax.inventory:DeleteInventory(inventoryID, callback)
    if ( !inventoryID ) then
        ax.util:PrintError("Invalid parameters for ax.inventory:DeleteInventory")
        return false
    end

    ax.database:Delete("ax_inventories", {
        id = inventoryID
    }, function(success)
        if ( !success ) then
            ax.util:PrintError("Failed to delete inventory with ID " .. inventoryID)

            if ( callback ) then
                callback(false)
            end

            return false
        end

        self.instances[inventoryID] = nil

        ax.util:PrintSuccess("Inventory with ID " .. inventoryID .. " deleted successfully.")

        if ( callback ) then
            callback(true)
        end

        return true
    end)
end

--- Retrieves an inventory by its ID.
-- @param number inventoryID The ID of the inventory to retrieve
-- @param function[opt] callback Callback function to execute with the retrieved inventory (optional)
function ax.inventory:GetInventory(inventoryID, callback)
    if ( !inventoryID ) then
        ax.util:PrintError("Invalid parameters for ax.inventory:GetInventory")
        return false
    end

    local inventory = self.instances[inventoryID]
    if ( !inventory ) then
        ax.util:PrintError("Inventory with ID " .. inventoryID .. " not found.")

        if ( callback ) then
            callback()
        end

        return false
    end

    ax.util:PrintSuccess("Retrieved inventory with ID " .. inventoryID)

    if ( callback ) then
        callback(inventory)
    end

    return true
end

--- Retrieves all inventories for a character.
-- @param number characterID The ID of the character to retrieve inventories for
-- @param function[opt] callback Callback function to execute with the retrieved inventories (optional)
function ax.inventory:GetCharacterInventories(characterID, callback)
    if ( !characterID ) then
        ax.util:PrintError("Invalid parameters for ax.inventory:GetCharacterInventories")
        return false
    end

    local inventories = {}
    for _, inventory in pairs(self.instances) do
        if ( inventory.character_id == characterID ) then
            table.insert(inventories, inventory)
        end
    end

    if ( #inventories == 0 ) then
        ax.util:PrintWarning("No inventories found for character ID " .. characterID)

        if ( callback ) then
            callback({})
        end

        return false
    end

    ax.util:PrintSuccess("Retrieved " .. #inventories .. " inventories for character ID " .. characterID)

    if ( callback ) then
        callback(inventories)
    end

    return true
end