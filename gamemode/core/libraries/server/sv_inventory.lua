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

    if ( !istable(data) ) then
        data = {}
    end

    -- Get inventory instance
    local inventory = self:Get(inventoryID)
    if ( !inventory ) then
        ax.util:PrintError("Inventory with ID " .. inventoryID .. " not found in memory.")
        return false
    end

    -- Create item in database
    ax.database:Insert("ax_items", {
        unique_id = uniqueID,
        data = util.TableToJSON(data),
        inventory_id = inventoryID
    }, function(itemID)
        if ( !isnumber(itemID) ) then
            ax.util:PrintError("Failed to add item to inventory.")
            if ( callback ) then callback(false) end
            return false
        end

        ax.util:PrintSuccess("Item added to inventory successfully with ID " .. itemID)

        -- Create item instance
        local item = ax.item:CreateObject(itemID, uniqueID, data)
        if ( !item ) then
            ax.util:PrintError("Failed to create item object")
            if ( callback ) then callback(false) end
            return false
        end

        item:SetInventoryID(inventoryID)
        ax.item.instances[itemID] = item

        -- Add to inventory's item list
        table.insert(inventory.Items, itemID)

        -- Network to client
        local character = inventory:GetCharacter()
        if ( character ) then
            local client = character:GetPlayer()
            if ( IsValid(client) ) then
                -- Send item addition notification
                net.Start("ax.inventory.item.add")
                    net.WriteUInt(inventoryID, 16)
                    net.WriteUInt(itemID, 16)
                    net.WriteString(uniqueID)
                    net.WriteTable(data)
                net.Send(client)

                -- Send item instance data
                net.Start("ax.item.add")
                    net.WriteUInt(itemID, 16)
                    net.WriteUInt(inventoryID, 16)
                    net.WriteString(uniqueID)
                    net.WriteTable(data)
                net.Send(client)
            end
        end

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

    -- Get inventory instance
    local inventory = self:Get(inventoryID)
    if ( !inventory ) then
        ax.util:PrintError("Inventory with ID " .. inventoryID .. " not found in memory.")
        return false
    end

    -- Remove from database
    ax.database:Delete("ax_items", {
        id = itemID
    }, function(success)
        if ( success == false ) then
            ax.util:PrintError("Failed to delete item from database.")
            if ( callback ) then callback(false) end
            return false
        end

        ax.util:PrintSuccess("Item with ID " .. itemID .. " deleted from database successfully.")

        -- Remove from inventory's item list
        table.RemoveByValue(inventory.Items, itemID)

        -- Remove from memory
        ax.item.instances[itemID] = nil

        -- Network to client
        local character = inventory:GetCharacter()
        if ( character ) then
            local client = character:GetPlayer()
            if ( IsValid(client) ) then
                net.Start("ax.inventory.item.remove")
                    net.WriteUInt(inventoryID, 16)
                    net.WriteUInt(itemID, 16)
                net.Send(client)
            end
        end

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

    -- Query items directly from ax_items table
    ax.database:Select("ax_items", nil, "inventory_id = " .. inventoryID, function(result)
        if ( !result ) then
            ax.util:PrintError("Database query failed for inventory items.")
            if ( callback ) then callback({}) end
            return false
        end

        local items = {}
        for i = 1, #result do
            local item = result[i]
            item.data = util.JSONToTable(item.data) or {}
            items[tonumber(item.id)] = {
                id = tonumber(item.id),
                unique_id = item.unique_id,
                data = item.data,
                inventory_id = tonumber(item.inventory_id)
            }
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

    -- Delete all items from this inventory
    ax.database:Delete("ax_items", {
        inventory_id = inventoryID
    }, function(success)
        if ( !success ) then
            ax.util:PrintError("Failed to clear inventory items.")
            if ( callback ) then callback(false) end
            return false
        end

        ax.util:PrintSuccess("Inventory cleared successfully.")

        -- Clear from memory
        local inventory = self:Get(inventoryID)
        if ( inventory ) then
            -- Remove all items from memory
            for _, itemID in ipairs(inventory.Items) do
                ax.item.instances[itemID] = nil
            end
            inventory.Items = {}

            -- Network to client
            local character = inventory:GetCharacter()
            if ( character ) then
                local client = character:GetPlayer()
                if ( IsValid(client) ) then
                    net.Start("ax.inventory.refresh")
                        net.WriteUInt(inventoryID, 16)
                    net.Send(client)
                end
            end
        end

        if ( callback ) then
            callback(true)
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

    -- Create inventory without items column
    ax.database:Insert("ax_inventories", {
        max_weight = maxWeight,
        data = util.TableToJSON(data)
    }, function(inventoryID)
        if ( !inventoryID ) then
            ax.util:PrintError("Failed to create inventory. Inventory ID is nil.")
            return false
        end

        local inventoryData = {
            id = inventoryID,
            max_weight = maxWeight,
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
        local inventoryID = tonumber(output.inventory_id)
        if ( !inventoryID or inventoryID <= 0 ) then
            ax.util:PrintError("No valid inventory found for character ID " .. characterID .. " (inventory_id: " .. tostring(output.inventory_id) .. ")")
            return false
        end

        ax.util:PrintSuccess("Loading inventory " .. inventoryID .. " for character ID " .. characterID)

        -- Load inventory data
        ax.database:Select("ax_inventories", nil, "id = " .. inventoryID, function(invResult)
            if ( !invResult or !invResult[1] ) then
                ax.util:PrintError("No inventory found with ID " .. inventoryID)
                return false
            end

            local inventory = ax.inventory:Create(invResult[1])
            if ( !inventory ) then
                ax.util:PrintError("Failed to create inventory instance for ID " .. inventoryID)
                return false
            end

            -- Load items from ax_items table
            ax.database:Select("ax_items", nil, "inventory_id = " .. inventoryID, function(itemsResult)
                local itemInstances = {}

                if ( itemsResult ) then
                    for _, itemData in ipairs(itemsResult) do
                        local itemID = tonumber(itemData.id)
                        local uniqueID = itemData.unique_id
                        local data = util.JSONToTable(itemData.data) or {}

                        if ( !itemID or itemID <= 0 ) then
                            ax.util:PrintError("Invalid item ID in database: " .. tostring(itemData.id))
                            continue
                        end

                        if ( !uniqueID or uniqueID == "" ) then
                            ax.util:PrintError("Invalid unique ID in database for item " .. itemID)
                            continue
                        end

                        -- Validate that the item definition exists
                        local itemDef = ax.item:Get(uniqueID)
                        if ( !itemDef ) then
                            ax.util:PrintError("Item definition not found for unique ID: " .. uniqueID .. " (item ID: " .. itemID .. ")")
                            continue
                        end

                        -- Create item instance
                        local item = ax.item:CreateObject(itemID, uniqueID, data)
                        if ( item ) then
                            -- Ensure inventoryID is a valid number before setting
                            if ( isnumber(inventoryID) and inventoryID > 0 ) then
                                item:SetInventoryID(inventoryID)
                                ax.item.instances[itemID] = item
                                table.insert(inventory.Items, itemID)

                                -- Store item data for networking
                                itemInstances[itemID] = {
                                    ID = itemID,
                                    UniqueID = uniqueID,
                                    Data = data,
                                    InventoryID = inventoryID
                                }

                                ax.util:PrintSuccess("Loaded item " .. itemID .. " (" .. uniqueID .. ") into inventory " .. inventoryID)
                            else
                                ax.util:PrintError("Invalid inventory ID when setting item inventory: " .. tostring(inventoryID))
                            end
                        else
                            ax.util:PrintError("Failed to create item instance for ID " .. itemID)
                        end
                    end
                end

                local client = ax.character:GetPlayerByCharacter(characterID)
                if ( IsValid(client) ) then
                    -- Send inventory data
                    net.Start("ax.inventory.load")
                        net.WriteUInt(characterID, 32)
                        net.WriteTable(invResult[1])
                    net.Send(client)

                    -- Send item instances
                    if ( table.Count(itemInstances) > 0 ) then
                        net.Start("ax.item.cache")
                            net.WriteTable(itemInstances)
                        net.Send(client)
                    end
                end

                local character = ax.character:Get(characterID)
                if ( character ) then
                    character:SetInventory(inventory)
                end

                ax.util:PrintSuccess("Loaded inventory with ID " .. inventoryID .. " for character ID " .. characterID .. " with " .. #inventory.Items .. " items")
            end)
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
    Developer Commands
    These commands are for development and testing purposes only.
    They should only be accessible to administrators.
]]

concommand.Add("ax_inventory_create", function(client, cmd, args)
    if ( !client:IsSuperAdmin() ) then
        client:Notify("You must be an administrator to use this command.")
        return
    end

    if ( #args < 2 ) then
        client:Notify("Usage: ax_inventory_create <character_id> <max_weight> [data_json]")
        return
    end

    local characterID = tonumber(args[1])
    local maxWeight = tonumber(args[2])
    local data = util.JSONToTable(args[3] or "{}")

    ax.inventory:CreateInventory(characterID, maxWeight, data, function(inventory)
        if ( inventory ) then
            client:Notify("Created inventory with ID " .. inventory:GetID() .. " for character ID " .. characterID)
        else
            client:Notify("Failed to create inventory.")
        end
    end)
end)

-- Command to spawn items in the world
concommand.Add("ax_item_spawn", function(ply, cmd, args)
    if ( !ply:IsSuperAdmin() ) then
        ply:Notify("You must be an administrator to use this command.")
        return
    end

    local uniqueID = args[1]
    if ( !uniqueID ) then
        ply:Notify("Usage: ax_item_spawn <unique_id> [amount] [data_json]")
        return
    end

    local itemDef = ax.item:Get(uniqueID)
    if ( !itemDef ) then
        ply:Notify("Item with unique ID '" .. uniqueID .. "' does not exist.")
        return
    end

    local amount = tonumber(args[2]) or 1
    local data = {}

    if ( args[3] ) then
        data = util.JSONToTable(args[3]) or {}
    end

    local pos = ply:GetEyeTrace().HitPos + Vector(0, 0, 10)
    local ang = Angle(0, math.random(0, 360), 0)

    for i = 1, amount do
        local spawnPos = pos + Vector(math.random(-50, 50), math.random(-50, 50), i * 5)

        ax.item:Spawn(nil, uniqueID, spawnPos, ang, function(entity)
            if ( IsValid(entity) ) then
                -- Set custom data if provided
                if ( istable(data) and table.Count(data) > 0 ) then
                    entity:SetData(data)
                end
            end
        end, data)
    end

    ply:Notify("Spawned " .. amount .. " " .. itemDef:GetName() .. "(s) in the world.")
end, function(cmd, argStr, args)
    local items = {}

    for uniqueID, _ in pairs(ax.item.stored) do
        local itemDef = ax.item:Get(uniqueID)
        if ( !itemDef or itemDef.IsBase == true ) then continue end

        table.insert(items, "ax_item_spawn " .. uniqueID)
    end

    return items
end)

-- Command to give items to inventories
concommand.Add("ax_item_give", function(ply, cmd, args)
    if ( !ply:IsSuperAdmin() ) then
        ply:Notify("You must be an administrator to use this command.")
        return
    end

    local uniqueID = args[1]
    local target = args[2]
    local amount = tonumber(args[3]) or 1
    local data = {}

    if ( !uniqueID ) then
        ply:Notify("Usage: ax_item_give <unique_id> [target_name] [amount] [data_json]")
        return
    end

    local itemDef = ax.item:Get(uniqueID)
    if ( !itemDef ) then
        ply:Notify("Item with unique ID '" .. uniqueID .. "' does not exist.")
        return
    end

    if ( args[4] ) then
        data = util.JSONToTable(args[4]) or {}
    end

    -- Find target player
    local targetPlayer = ply
    if ( target ) then
        local found = false
        for _, client in player.Iterator() do
            if ( string.find(string.lower(client:SteamName()), string.lower(target)) ) then
                targetPlayer = client
                found = true
                break
            end
        end

        if ( !found ) then
            ply:Notify("Player '" .. target .. "' not found.")
            return
        end
    end

    local character = targetPlayer:GetCharacter()
    if ( !character ) then
        ply:Notify(targetPlayer:SteamName() .. " does not have a character loaded.")
        return
    end

    local inventory = character:GetInventory()
    if ( !inventory ) then
        ply:Notify(targetPlayer:SteamName() .. " does not have an inventory.")
        return
    end

    -- Check if inventory can fit the items
    if ( !inventory:CanFitItem(uniqueID, amount) ) then
        ply:Notify("Inventory cannot fit " .. amount .. " " .. itemDef:GetName() .. "(s). Not enough weight capacity.")
        return
    end

    -- Add items to inventory
    local itemsAdded = 0
    for i = 1, amount do
        ax.inventory:AddItem(inventory:GetID(), uniqueID, data, function(result)
            if ( result ) then
                itemsAdded = itemsAdded + 1

                if ( itemsAdded == amount ) then
                    ply:Notify("Gave " .. amount .. " " .. itemDef:GetName() .. "(s) to " .. targetPlayer:SteamName())
                    if ( targetPlayer != ply ) then
                        targetPlayer:Notify("You received " .. amount .. " " .. itemDef:GetName() .. "(s)")
                    end
                end
            else
                ply:Notify("Failed to add item to inventory.")
            end
        end)
    end
end, function(cmd, argStr, args)
    local items = {}

    for uniqueID, _ in pairs(ax.item.stored) do
        local itemDef = ax.item:Get(uniqueID)
        if ( !itemDef or itemDef.IsBase == true ) then continue end

        table.insert(items, "ax_item_give " .. uniqueID)
    end

    return items
end)

-- Command to remove items from inventories
concommand.Add("ax_item_remove", function(ply, cmd, args)
    if ( !ply:IsSuperAdmin() ) then
        ply:Notify("You must be an administrator to use this command.")
        return
    end

    local uniqueID = args[1]
    local target = args[2]
    local amount = tonumber(args[3]) or 1

    if ( !uniqueID ) then
        ply:Notify("Usage: ax_item_remove <unique_id> [target_name] [amount]")
        return
    end

    local itemDef = ax.item:Get(uniqueID)
    if ( !itemDef ) then
        ply:Notify("Item with unique ID '" .. uniqueID .. "' does not exist.")
        return
    end

    -- Find target player
    local targetPlayer = ply
    if ( target ) then
        local found = false
        for _, client in player.Iterator() do
            if ( string.find(string.lower(client:SteamName()), string.lower(target)) ) then
                targetPlayer = client
                found = true
                break
            end
        end

        if ( !found ) then
            ply:Notify("Player '" .. target .. "' not found.")
            return
        end
    end

    local character = targetPlayer:GetCharacter()
    if ( !character ) then
        ply:Notify(targetPlayer:SteamName() .. " does not have a character loaded.")
        return
    end

    local inventory = character:GetInventory()
    if ( !inventory ) then
        ply:Notify(targetPlayer:SteamName() .. " does not have an inventory.")
        return
    end

    -- Find items to remove
    local itemsToRemove = {}
    for _, itemID in ipairs(inventory.Items) do
        local item = ax.item:Get(itemID)
        if ( item and item:GetUniqueID() == uniqueID ) then
            table.insert(itemsToRemove, itemID)
            if ( #itemsToRemove >= amount ) then
                break
            end
        end
    end

    if ( #itemsToRemove == 0 ) then
        ply:Notify(targetPlayer:SteamName() .. " does not have any " .. itemDef:GetName() .. "(s) in their inventory.")
        return
    end

    local itemsRemoved = 0
    for _, itemID in ipairs(itemsToRemove) do
        ax.inventory:RemoveItem(inventory:GetID(), itemID, function(success)
            if ( success ) then
                itemsRemoved = itemsRemoved + 1

                -- Remove from memory
                table.RemoveByValue(inventory.Items, itemID)
                ax.item.instances[itemID] = nil

                -- Network to client
                net.Start("ax.inventory.item.remove")
                    net.WriteUInt(inventory:GetID(), 16)
                    net.WriteUInt(itemID, 16)
                net.Send(targetPlayer)

                if ( itemsRemoved == #itemsToRemove ) then
                    ply:Notify("Removed " .. itemsRemoved .. " " .. itemDef:GetName() .. "(s) from " .. targetPlayer:SteamName())
                    if ( targetPlayer != ply ) then
                        targetPlayer:Notify("You lost " .. itemsRemoved .. " " .. itemDef:GetName() .. "(s)")
                    end
                end
            else
                ply:Notify("Failed to remove item from inventory.")
            end
        end)
    end
end)

concommand.Add("ax_item_list", function(ply, cmd, args)
    if ( !ply:IsSuperAdmin() ) then
        ply:Notify("You must be an administrator to use this command.")
        return
    end

    local filter = args[1] or ""
    local items = {}

    for uniqueID, itemDef in pairs(ax.item.stored) do
        if ( filter == "" or string.find(string.lower(itemDef:GetName()), string.lower(filter)) or string.find(string.lower(uniqueID), string.lower(filter)) ) then
            table.insert(items, {
                id = uniqueID,
                name = itemDef:GetName(),
                weight = itemDef:GetWeight(),
                category = itemDef:GetCategory()
            })
        end
    end

    table.sort(items, function(a, b) return a.name < b.name end)

    if ( #items == 0 ) then
        ply:Notify("No items found" .. (filter != "" and " matching '" .. filter .. "'" or "") .. ".")
        return
    end

    print("=== Available Items " .. (filter != "" and "(filtered by '" .. filter .. "')" or "") .. " ===")
    for _, item in ipairs(items) do
        print(string.format("%-20s | %-30s | %3.1fkg | %s", item.id, item.name, item.weight, item.category))
    end
    print("=== Total: " .. #items .. " items ===")

    ply:Notify("Listed " .. #items .. " items in console.")
end)

-- Command to inspect player's inventory
concommand.Add("ax_inventory_inspect", function(ply, cmd, args)
    if ( !ply:IsSuperAdmin() ) then
        ply:Notify("You must be an administrator to use this command.")
        return
    end

    local target = args[1]
    local targetPlayer = ply

    if ( target ) then
        local found = false
        for _, client in player.Iterator() do
            if ( string.find(string.lower(client:SteamName()), string.lower(target)) ) then
                targetPlayer = client
                found = true
                break
            end
        end

        if ( !found ) then
            ply:Notify("Player '" .. target .. "' not found.")
            return
        end
    end

    local character = targetPlayer:GetCharacter()
    if ( !character ) then
        ply:Notify(targetPlayer:SteamName() .. " does not have a character loaded.")
        return
    end

    local inventory = character:GetInventory()
    if ( !inventory ) then
        ply:Notify(targetPlayer:SteamName() .. " does not have an inventory.")
        return
    end

    local items = {}
    for _, itemID in ipairs(inventory.Items) do
        local item = ax.item:Get(itemID)
        if ( item ) then
            local uniqueID = item:GetUniqueID()
            if ( !items[uniqueID] ) then
                items[uniqueID] = {
                    name = item:GetName(),
                    count = 0,
                    weight = item:GetWeight()
                }
            end
            items[uniqueID].count = items[uniqueID].count + 1
        end
    end

    print("=== " .. targetPlayer:SteamName() .. "'s Inventory ===")
    print(string.format("Weight: %.1f/%.1f kg", inventory:GetWeight(), inventory:GetMaxWeight()))
    print("Items:")

    local totalItems = 0
    for uniqueID, itemData in pairs(items) do
        print(string.format("  %-20s | %dx | %.1fkg each", itemData.name, itemData.count, itemData.weight))
        totalItems = totalItems + itemData.count
    end

    if ( totalItems == 0 ) then
        print("  (Empty)")
    end

    print("=== Total: " .. totalItems .. " items ===")

    ply:Notify("Inspected " .. targetPlayer:SteamName() .. "'s inventory in console.")
end)

-- Command to clear inventory
concommand.Add("ax_inventory_clear", function(ply, cmd, args)
    if ( !ply:IsSuperAdmin() ) then
        ply:Notify("You must be an administrator to use this command.")
        return
    end

    local target = args[1]
    local targetPlayer = ply

    if ( target ) then
        local found = false
        for _, client in player.Iterator() do
            if ( string.find(string.lower(client:SteamName()), string.lower(target)) ) then
                targetPlayer = client
                found = true
                break
            end
        end

        if ( !found ) then
            ply:Notify("Player '" .. target .. "' not found.")
            return
        end
    end

    local character = targetPlayer:GetCharacter()
    if ( !character ) then
        ply:Notify(targetPlayer:SteamName() .. " does not have a character loaded.")
        return
    end

    local inventory = character:GetInventory()
    if ( !inventory ) then
        ply:Notify(targetPlayer:SteamName() .. " does not have an inventory.")
        return
    end

    ax.inventory:ClearInventory(inventory:GetID(), function(success)
        if ( success ) then
            -- Clear memory
            inventory.Items = {}

            -- Network to client
            net.Start("ax.inventory.refresh")
                net.WriteUInt(inventory:GetID(), 16)
            net.Send(targetPlayer)

            ply:Notify("Cleared " .. targetPlayer:SteamName() .. "'s inventory.")
            if ( targetPlayer != ply ) then
                targetPlayer:Notify("Your inventory has been cleared by an administrator.")
            end
        else
            ply:Notify("Failed to clear inventory.")
        end
    end)
end)