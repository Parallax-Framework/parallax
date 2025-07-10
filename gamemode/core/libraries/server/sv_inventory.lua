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

    if ( !ax.item:Get(uniqueID) ) then
        ax.util:PrintError("Item with unique ID '" .. uniqueID .. "' does not exist.")
        return false
    end

    if ( !data or type(data) != "table" ) then
        data = {}
    end

    ax.database:Select("ax_inventories", nil, "id = " .. inventoryID, function(result)
        if ( !result or !result[1] ) then
            ax.util:PrintError("No inventory found with ID " .. inventoryID)

            if ( callback ) then
                callback(false)
            end

            return false
        end

        local items = util.JSONToTable(result[1].items) or {}
        if ( !items ) then
            items = {}
        end

        ax.database:Insert("ax_items", {
            unique_id = uniqueID,
            data = util.TableToJSON(data)
        }, function(itemID)
            if ( !itemID ) then
                ax.util:PrintError("Failed to add item to inventory.")

                if ( callback ) then
                    callback(false)
                end

                return false
            end

            ax.util:PrintSuccess("Item added to inventory successfully with ID " .. itemID)

            -- Add item to the in-memory list
            items[itemID] = {
                unique_id = uniqueID,
                data = data
            }

            -- Update the inventory items in the database
            ax.database:Update("ax_inventories", {
                items = util.TableToJSON(items)
            }, "id = " .. inventoryID, function(success)
                if ( !success ) then
                    ax.util:PrintError("Failed to update inventory items.")
                    return false
                end

                if ( callback ) then
                    callback(itemID)
                end

                return true
            end)
        end)
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

    ax.database:Select("ax_inventories", nil, "id = " .. inventoryID, function(result)
        if ( !result or !result[1] ) then
            ax.util:PrintError("No inventory found with ID " .. inventoryID)

            if ( callback ) then
                callback(false)
            end

            return false
        end

        local items = util.JSONToTable(result[1].items) or {}
        if ( !items or !items[itemID] ) then
            ax.util:PrintError("Item with ID " .. itemID .. " not found in inventory.")

            if ( callback ) then
                callback(false)
            end

            return false
        end

        items[itemID] = nil -- Remove the item from the list

        ax.database:Update("ax_inventories", {
            items = util.TableToJSON(items)
        }, "id = " .. inventoryID, function(success)
            if ( !success ) then
                ax.util:PrintError("Failed to update inventory items after removal.")
                return false
            end

            ax.util:PrintSuccess("Item removed from inventory successfully.")

            if ( callback ) then
                callback(true)
            end

            return true
        end)

        ax.database:Delete("ax_items", {
            id = itemID
        }, function(success)
            if ( !success ) then
                ax.util:PrintError("Failed to delete item from database.")
                return false
            end

            ax.util:PrintSuccess("Item with ID " .. itemID .. " deleted from database successfully.")
        end)
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

    -- ax.database:Select("ax_items", nil, "inventory_id = " .. inventoryID, function(result)
    --     if ( !result or !result[1] ) then
    --         ax.util:PrintError("No items found in inventory.")
-- 
    --         if ( callback ) then
    --             callback({})
    --         end
-- 
    --         return false
    --     end
-- 
    --     PrintTable(result)
-- 
    --     for i = 1, #result do
    --         local item = result[i]
    --         item.data = util.JSONToTable(item.data) or {}
    --         itemList[i] = item
    --     end
    --     ax.util:PrintSuccess("Items retrieved from inventory successfully.")
-- 
    --     if ( callback ) then
    --         callback(itemList)
    --     end
-- 
    --     return true
    -- end)

    ax.database:Select("ax_inventories", nil, "id = " .. inventoryID, function(result)
        if ( !result or !result[1] ) then
            ax.util:PrintError("No inventory found with ID " .. inventoryID)

            if ( callback ) then
                callback({})
            end

            return false
        end

        local items = util.JSONToTable(result[1].items) or {}
        if ( !items ) then
            items = {}
        end

        for itemID, itemData in pairs(items) do
            itemData.data = util.JSONToTable(itemData.data) or {}
            items[itemID] = itemData
        end

        ax.util:PrintSuccess("Items retrieved from inventory successfully.")

        if ( callback ) then
            callback(items)
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

    -- ax.database:Delete("ax_items", {
    --     inventory_id = inventoryID
    -- }, function(success)
    --     if ( !success ) then
    --         ax.util:PrintError("Failed to clear inventory.")
-- 
    --         return false
    --     end
-- 
    --     ax.util:PrintSuccess("Inventory cleared successfully.")
-- 
    --     if ( callback ) then
    --         callback(true)
    --     end
-- 
    --     return true
    -- end)

    ax.database:Select("ax_inventories", nil, "id = " .. inventoryID, function(result)
        if ( !result or !result[1] ) then
            ax.util:PrintError("No inventory found with ID " .. inventoryID)

            if ( callback ) then
                callback(false)
            end

            return false
        end

        local items = {}
        ax.database:Update("ax_inventories", {
            items = util.TableToJSON(items)
        }, "id = " .. inventoryID, function(success)
            if ( !success ) then
                ax.util:PrintError("Failed to clear inventory items.")
                return false
            end

            ax.util:PrintSuccess("Inventory cleared successfully.")

            if ( callback ) then
                callback(true)
            end

            return true
        end)
    end)
end

--- Creates a new inventory for a character.
-- @param number characterID The ID of the character to create the inventory for
-- @param number maxWeight The maximum weight capacity of the inventory
-- @param[opt] table data Initial data for the inventory (optional)
-- @param function[opt] callback Callback function to execute after creating the inventory (optional)
function ax.inventory:CreateInventory(characterID, maxWeight, data, callback)
    if ( !characterID ) then
        ax.util:PrintError("Invalid character ID for inventory creation.")
        return false
    end

    if ( !maxWeight or maxWeight <= 0 ) then
        maxWeight = ax.config:Get("inventory.max.weight", 20)
    end

    if ( !data or type(data) != "table" ) then
        data = {}
    end

    ax.database:Insert("ax_inventories", {
        max_weight = maxWeight,
        items = util.TableToJSON({}), -- Start with an empty item list
        data = util.TableToJSON(data)
    }, function(inventoryID)
        if ( !inventoryID ) then
            ax.util:PrintError("Failed to create inventory. Inventory ID is nil.")

            return false
        end

        local inventoryData = {
            id = inventoryID,
            max_weight = maxWeight,
            items = {},
            data = data
        }
        local inventory = ax.inventory:Create(inventoryData)

        ax.database:Update("ax_characters", { inventory_id = inventoryID, }, "id = " .. characterID)

        local client = ax.character:GetPlayerByCharacter(characterID)
        if ( IsValid(client) ) then
            net.Start("ax.inventory.create")
                net.WriteTable(inventoryData)
            net.Send(client)
        end

        ax.util:PrintSuccess("Inventory created successfully with ID " .. inventoryID)

        if ( callback ) then
            callback(inventory)
        end
    end)
end

function ax.inventory:LoadInventory(characterID)
    if ( !characterID ) then
        ax.util:PrintError("Invalid character ID for loading inventories.")
        return false
    end

    ax.database:Select("ax_characters", nil, "id = " .. characterID, function(result)
        if ( !result or !result[1] ) then
            ax.util:PrintError("No character found with ID " .. characterID)
            return false
        end

        local output = result[1]

        local inventoryID = output.inventory_id
        if ( !inventoryID ) then
            ax.util:PrintError("No inventory found for character ID " .. characterID)
            return false
        end

        ax.util:PrintSuccess("Loading inventories for character ID " .. characterID)

        ax.database:Select("ax_inventories", nil, "id = " .. inventoryID, function(invResult)
            if ( !invResult or !invResult[1] ) then
                ax.util:PrintError("No inventory found with ID " .. inventoryID)
                return false
            end

            local inventory = ax.inventory:Create(invResult[1])

            local client = ax.character:GetPlayerByCharacter(characterID)
            if ( IsValid(client) ) then
                net.Start("ax.inventory.load")
                    net.WriteUInt(characterID, 32)
                    net.WriteTable(invResult[1])
                net.Send(client)
            end

            local character = ax.character:Get(characterID)
            if ( character ) then
                character:SetInventory(inventory)
            end

            ax.util:PrintSuccess("Loaded inventory with ID " .. inventoryID .. " for character ID " .. characterID)
        end)
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

--[[
    Testing Commands
    These commands are for testing purposes only and should not be used in production.
]]

concommand.Add("ax_inventory_create", function(ply, cmd, args)
    if ( !ply:IsAdmin() ) then
        return
    end

    local characterID = tonumber(args[1])
    local maxWeight = tonumber(args[2])
    local data = util.JSONToTable(args[3] or "{}")

    ax.inventory:CreateInventory(characterID, maxWeight, data, function(inventory)
        if ( inventory ) then
            ply:Notify("Created inventory with ID " .. inventory:GetID() .. " for character ID " .. characterID)
        else
            ply:Notify("Failed to create inventory.")
        end
    end)
end)