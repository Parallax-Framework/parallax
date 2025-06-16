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

-- Inventory management library.
-- @module ax.inventory

function ax.inventory:Register(data, callback)
    if ( !istable(data) or !data.characterID ) then
        ax.util:PrintError("Invalid data provided for inventory registration.")
        return false
    end

    local bResult = hook.Run("PreInventoryRegistered", data)
    if ( bResult == false ) then
        ax.util:PrintError("PreInventoryRegistered hook denied inventory registration for character " .. data.characterID)
        return false
    end

    ax.database:Insert("ax_inventories", {
        character_id = data.characterID,
        name = data.name or "Main",
        max_weight = data.maxWeight or ax.config:Get("inventory.max.weight", 20),
        data = util.TableToJSON(data.data or {})
    }, function(inventoryID)
        if ( !inventoryID ) then
            ax.util:PrintError("Failed to insert inventory into database for character " .. data.characterID)
            return false
        end

        data.ID = inventoryID

        local inventory = self:CreateObject(data)
        if ( !inventory ) then
            ax.util:PrintError("Failed to create inventory object for ID " .. inventoryID)
            return false
        end

        self.stored[inventoryID] = inventory
        self:AssignToCharacter(data.characterID, inventoryID)
        self:Broadcast(inventory)

        if ( callback ) then
            callback(inventory)
        end

        hook.Run("PostInventoryRegistered", inventory)
    end)
end

function ax.inventory:AssignToCharacter(characterID, inventoryID, callback)
    if ( !characterID or !inventoryID ) then
        ax.util:PrintError("Invalid character ID or inventory ID for assignment.")
        return
    end

    local bResult = hook.Run("PreInventoryAssigned", characterID, inventoryID)
    if ( bResult == false ) then
        ax.util:PrintError("PreInventoryAssigned hook denied assignment of inventory " .. inventoryID .. " to character " .. characterID)
        return
    end

    ax.database:Select("ax_characters", nil, "id = " .. characterID, function(result)
        if ( !result or !result[1] ) then
            ax.util:PrintError("Character with ID " .. characterID .. " not found in database.")
            return
        end

        local inventories = util.JSONToTable(result[1].inventories or "[]") or {}
        if ( !table.HasValue(inventories, inventoryID) ) then
            table.insert(inventories, inventoryID)
        end

        ax.database:Update("ax_characters", {
            inventories = util.TableToJSON(inventories)
        }, "id = " .. characterID)

        local character = ax.character:Get(characterID)
        if ( character ) then
            character:SetInventories(inventories)
        end

        if ( callback ) then
            callback(inventoryID)
        end

        hook.Run("PostInventoryAssigned", characterID, inventoryID)
    end)
end

function ax.inventory:Broadcast(inventory)
    if ( !inventory ) then return end

    local receivers = inventory:GetReceivers()
    if ( !istable(receivers) ) then return end

    ax.net:Start(receivers, "inventory.register", {
        ID = inventory:GetID(),
        CharacterID = inventory:GetOwner(),
        Name = inventory:GetName(),
        MaxWeight = inventory:GetMaxWeight(),
        Items = inventory:GetItems(),
        Data = inventory:GetData(),
        Receivers = inventory.Receivers
    })
end

function ax.inventory:Cache(client, inventoryID, callback)
    if ( !IsValid(client) or !inventoryID ) then
        ax.util:PrintError("Invalid client or inventory ID for caching.")
        return
    end

    local bResult = hook.Run("PreInventoryCached", inventoryID, client)
    if ( bResult == false ) then
        ax.util:PrintError("PreInventoryCached hook denied caching of inventory " .. inventoryID .. " for player " .. tostring(client))
        return
    end

    -- Yeah, big pyramid of function calls...
    ax.database:Select("ax_inventories", nil, "id = " .. inventoryID, function(result)
        if ( !result or !result[1] ) then
            ax.util:PrintError("Failed to cache inventory with ID " .. inventoryID .. " for player " .. tostring(client))
            return
        end

        local inventory = self:CreateObject(result[1])
        if ( !inventory ) then
            ax.util:PrintError("Failed to create inventory object for ID " .. inventoryID)
            return
        end

        self.stored[inventoryID] = inventory

        self:AssignToCharacter(inventory:GetOwner(), inventoryID, function(invID)
            if ( !invID ) then
                ax.util:PrintError("Failed to assign inventory " .. invID .. " to character " .. inventory:GetOwner())
                return
            end

            ax.item:Cache(inventory:GetOwner(), function(items)
                if ( !items ) then
                    ax.util:PrintError("Failed to cache items for inventory " .. invID)
                    return
                end

                local itemIDs = {}
                for _, item in pairs(ax.item.instances) do
                    if ( item:GetOwner() == inventory:GetOwner() ) then
                        table.insert(itemIDs, item:GetID())
                    end
                end

                inventory.Items = itemIDs

                ax.net:Start(client, "inventory.cache", {
                    ID = inventory:GetID(),
                    CharacterID = inventory:GetOwner(),
                    Name = inventory:GetName(),
                    MaxWeight = inventory:GetMaxWeight(),
                    Items = inventory:GetItems(),
                    Data = inventory:GetData(),
                    Receivers = inventory.Receivers
                })

                if ( callback ) then
                    callback(inventory)
                end

                hook.Run("PostInventoryCached", inventory, client)
            end)
        end)
    end)
end

function ax.inventory:CacheAll(characterID, callback)
    if ( !characterID ) then
        ax.util:PrintError("Invalid character ID for caching inventories.")
        return
    end

    local bResult = hook.Run("PreInventoryCacheAll", characterID)
    if ( bResult == false ) then
        ax.util:PrintError("PreInventoryCacheAll hook denied caching of all inventories for character " .. characterID)
        return
    end

    ax.database:Select("ax_characters", nil, "id = " .. characterID, function(result)
        if ( !result or !result[1] ) then
            ax.util:PrintError("Character with ID " .. characterID .. " not found in database.")
            return
        end

        local inventories = util.JSONToTable(result[1].inventories or "[]") or {}
        -- Check if we are the last inventory to cache, and if so, run the callback
        for i, inventoryID in ipairs(inventories) do
            local client = ax.character:GetPlayerByCharacter(characterID)
            if ( !IsValid(client) ) then
                ax.util:PrintError("Invalid client for character " .. characterID)
                return
            end

            self:Cache(client, inventoryID, function(success, inventory)
                if ( !success ) then
                    ax.util:PrintError("Failed to cache inventory " .. inventoryID .. " for character " .. characterID)
                    return
                end

                ax.util:Print("Cached inventory " .. inventoryID .. " for character " .. characterID)

                -- If we have a callback, call it with the cached inventory
                if ( callback and i == #inventories ) then
                    callback(inventory)
                end
            end)
        end

        hook.Run("PostInventoryCacheAll", characterID)
    end)
end

function ax.inventory:AddItem(inventoryID, itemID, uniqueID, data)
    if ( !inventoryID or !itemID or !uniqueID ) then
        ax.util:PrintError("Invalid parameters for item addition.")
        return false
    end

    local item = ax.item:Get(itemID)
    if ( !item ) then
        ax.util:PrintError("Invalid item ID " .. itemID .. " for addition.")
        return false
    end

    local inventory = self:Get(inventoryID)
    if ( !inventory ) then
        ax.util:PrintError("Invalid inventory ID " .. inventoryID .. " for item addition.")
        return false
    end

    local receivers = inventory:GetReceivers()
    if ( !receivers or !istable(receivers) ) then
        receivers = {}
    end

    local items = inventory:GetItems()
    if ( !items or !istable(items) ) then
        items = {}
    end

    if ( !table.HasValue(items, itemID) ) then
        table.insert(items, itemID)
    end

    item:SetInventory(inventoryID)

    if ( SERVER ) then
        data = data or {}

        ax.database:Update("ax_items", {
            inventory_id = inventoryID,
            data = util.TableToJSON(data)
        }, "id = " .. itemID)

        ax.net:Start(receivers, "inventory.item.add", inventoryID, itemID, uniqueID, data)
    end

    hook.Run("OnItemAdded", item, inventoryID, uniqueID, data)

    return true
end

function ax.inventory:RemoveItem(inventoryID, itemID)
    if ( !inventoryID or !itemID ) then
        ax.util:PrintError("Invalid parameters for item removal.")
        return false
    end

    local item = ax.item:Get(itemID)
    if ( !item ) then
        ax.util:PrintError("Invalid item ID " .. itemID .. " for removal.")
        return false
    end

    local inventory = self:Get(inventoryID)
    if ( !inventory ) then
        ax.util:PrintError("Invalid inventory ID " .. inventoryID .. " for item removal.")
        return false
    end

    local items = inventory:GetItems()
    if ( table.HasValue(items, itemID) ) then
        table.RemoveByValue(items, itemID)
    end

    item:SetInventory(0)

    if ( SERVER ) then
        ax.database:Update("ax_items", {
            inventory_id = 0
        }, "id = " .. itemID)

        local receivers = inventory:GetReceivers()
        if ( istable(receivers) ) then
            ax.net:Start(receivers, "inventory.item.remove", inventoryID, itemID)
        end
    end

    hook.Run("OnItemRemoved", item, inventoryID)

    return true
end