--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- server-side item logic
-- @module Parallax.Item

--- Adds a new item to a character's inventory.
-- This function handles inventory lookup, database insertion, instance creation, and syncing.
-- @tparam number characterID ID of the character receiving the item
-- @tparam[opt] number inventoryID Optional specific inventory ID
-- @tparam string uniqueID The registered unique ID of the item
-- @tparam[opt] table data Optional custom item data
-- @tparam[opt] function callback Optional callback called with (itemID, data)
-- @within Parallax.Item
function Parallax.Item:Add(characterID, inventoryID, uniqueID, data, callback)
    if ( !characterID or !uniqueID or !self.stored[uniqueID] ) then
        Parallax.Util:PrintError("Invalid parameters for item addition: characterID=" .. tostring(characterID) .. ", uniqueID=" .. tostring(uniqueID))
        return
    end

    local character = Parallax.Character:Get(characterID)
    if ( character and !inventoryID ) then
        inventoryID = character:GetInventory()
    end

    local inventory = Parallax.Inventory:Get(inventoryID)
    if ( inventory and !inventory:HasSpaceFor(self.stored[uniqueID].Weight) ) then
        return
    end

    data = data or {}

    Parallax.Database:Insert("ax_items", {
        inventory_id = inventoryID,
        character_id = characterID,
        unique_id = uniqueID,
        data = util.TableToJSON(data)
    }, function(result)
        local itemID = tonumber(result)
        if ( !itemID ) then
            Parallax.Util:PrintError("Failed to create item in database: " .. tostring(result))
            return
        end

        local item = self:CreateObject({
            ID = itemID,
            UniqueID = uniqueID,
            Data = data,
            InventoryID = inventoryID,
            CharacterID = characterID
        })

        if ( !item ) then
            Parallax.Util:PrintError("Failed to create item object for item ID " .. itemID)
            return
        end

        self.instances[itemID] = item

        if ( inventory ) then
            local items = inventory:GetItems()
            local found = false

            for i = 1, #items do
                if ( items[i] == itemID ) then
                    found = true
                    break
                end
            end

            if ( !found ) then
                table.insert(items, itemID)
            end
        end

        local receiver = Parallax.Character:GetPlayerByCharacter(characterID)
        if ( IsValid(receiver) ) then
            Parallax.Net:Start(receiver, "item.add", itemID, inventoryID, uniqueID, data)
        end

        if ( callback ) then
            callback(itemID, data)
        end

        hook.Run("OnItemAdded", item, characterID, uniqueID, data)
    end)
end

function Parallax.Item:Transfer(itemID, fromInventoryID, toInventoryID, callback)
    if ( !itemID or !fromInventoryID or !toInventoryID ) then return false end

    local item = self.instances[itemID]
    if ( !item ) then return false end

    local fromInventory = Parallax.Inventory:Get(fromInventoryID)
    local toInventory = Parallax.Inventory:Get(toInventoryID)

    if ( toInventory and !toInventory:HasSpaceFor(item:GetWeight()) ) then
        local receiver = Parallax.Character:GetPlayerByCharacter(item:GetOwner())
        if ( IsValid(receiver) ) then
            receiver:Notify("Inventory is too full to transfer this item.")
        end

        return false
    end

    local prevent = hook.Run("PreItemTransferred", item, fromInventoryID, toInventoryID)
    if ( prevent == false ) then
        return false
    end

    if ( fromInventory ) then
        fromInventory:RemoveItem(itemID)
    end

    if ( toInventory ) then
        toInventory:AddItem(itemID, item:GetUniqueID(), item:GetData())
    end

    item:SetInventory(toInventoryID)

    Parallax.Database:Update("ax_items", {
        inventory_id = toInventoryID
    }, "id = " .. itemID)

    if ( callback ) then
        callback(itemID, fromInventoryID, toInventoryID)
    end

    hook.Run("PostItemTransferred", item, fromInventoryID, toInventoryID)

    return true
end

function Parallax.Item:PerformAction(itemID, actionName, callback)
    local item = self:Get(itemID)
    if ( !item or !actionName ) then
        Parallax.Util:PrintError("Invalid parameters for item action: itemID=" .. tostring(itemID) .. ", actionName=" .. tostring(actionName))
        return false
    end

    local base = self.stored[item:GetUniqueID()]
    if ( !base or !base.Actions ) then
        Parallax.Util:PrintError("Item '" .. item:GetUniqueID() .. "' does not have actions defined.")
        return false
    end

    local action = base.Actions[actionName]
    if ( !action ) then
        Parallax.Util:PrintError("Action '" .. actionName .. "' not found for item '" .. item:GetUniqueID() .. "'.")
        return false
    end

    local client = Parallax.Character:GetPlayerByCharacter(item:GetOwner())
    if ( !IsValid(client) ) then
        Parallax.Util:PrintError("Invalid client for item action: " .. tostring(item:GetOwner()))
        return false
    end

    local character = Parallax.Character:Get(item:GetOwner())
    if ( !character ) then
        Parallax.Util:PrintError("Invalid character for item action: " .. tostring(item:GetOwner()))
        return false
    end

    local inventoryID = item:GetInventory()
    if ( inventoryID != character:GetInventory():GetID() ) then
        if ( inventoryID == 0 and actionName != "Take" ) then
            Parallax.Util:PrintWarning(client, " attempted to perform action '" .. actionName .. "' on item '" .. item:GetUniqueID() .. "' without a valid inventory.")
            return false
        elseif ( inventoryID != 0 and actionName == "Take" ) then
            Parallax.Util:PrintWarning(client, " attempted to perform action '" .. actionName .. "' on item '" .. item:GetUniqueID() .. "' in inventory ID " .. inventoryID .. ", but the action is not allowed.")
            return false
        end
    end

    if ( action.OnCanRun and !action:OnCanRun(item, client) ) then
        return false
    end

    local prevent = hook.Run("PrePlayerItemAction", client, actionName, item)
    if ( prevent == false ) then
        return false
    end

    if ( action.OnRun ) then
        action:OnRun(item, client)
    end

    if ( callback ) then
        callback(item, client)
    end

    local hooks = base.Hooks or {}
    if ( hooks[actionName] ) then
        for _, hookFunc in pairs(hooks[actionName]) do
            if ( hookFunc ) then
                hookFunc(item, client)
            end
        end
    end

    Parallax.Net:Start(client, "inventory.refresh", inventoryID)

    hook.Run("PostPlayerItemAction", client, actionName, item)

    return true
end

function Parallax.Item:Cache(characterID, callback)
    if ( !Parallax.Character:Get(characterID) ) then
        Parallax.Util:PrintError("Invalid character ID for item cache: " .. tostring(characterID))
        return
    end

    Parallax.Database:Select("ax_items", nil, "character_id = " .. characterID .. " OR character_id = 0", function(result)
        if ( !result or #result == 0 ) then
            Parallax.Util:PrintWarning("No items found for character ID " .. characterID)
            if ( callback ) then
                callback({})
            end
            return
        end

        for i = 1, #result do
            local row = result[i]
            local itemID = tonumber(row.id)
            local uniqueID = row.unique_id

            if ( self.stored[uniqueID] ) then
                local item = self:CreateObject(row)
                if ( !item ) then
                    Parallax.Util:PrintError("Failed to create object for item #" .. itemID .. ", skipping")
                    continue
                end

                if ( item:GetOwner() == 0 ) then
                    local inventory = Parallax.Inventory:Get(item:GetInventory())
                    if ( inventory ) then
                        local newCharID = inventory:GetOwner()
                        item:SetOwner(newCharID)

                        Parallax.Database:Update("ax_items", {
                            character_id = newCharID
                        }, "id = " .. itemID)
                    else
                        Parallax.Util:PrintError("Invalid orphaned item #" .. itemID .. " (no inventory)")
                        Parallax.Database:Delete("ax_items", "id = " .. itemID)
                        continue
                    end
                end

                self.instances[itemID] = item

                if ( item.OnCache ) then
                    item:OnCache()
                end
            else
                Parallax.Util:PrintError("Unknown item unique ID '" .. tostring(uniqueID) .. "' in DB, skipping")
            end
        end

        local instanceList = {}
        for _, item in pairs(self.instances) do
            if ( item:GetOwner() == characterID ) then
                table.insert(instanceList, {
                    ID = item:GetID(),
                    UniqueID = item:GetUniqueID(),
                    Data = item:GetData(),
                    InventoryID = item:GetInventory()
                })
            end
        end

        local client = Parallax.Character:GetPlayerByCharacter(characterID)
        if ( IsValid(client) ) then
            Parallax.Net:Start(client, "item.cache", instanceList)
        end

        if ( callback ) then
            callback(instanceList)
        end
    end)
end

--- Completely removes an item from the inventory system.
-- Deletes the item from the database, removes it from inventory, and clears it from memory.
-- @param itemID The item ID to remove.
-- @param callback Optional function to call after removal.
function Parallax.Item:Remove(itemID, callback)
    local item = self.instances[itemID]
    if ( !item ) then
        Parallax.Util:PrintError("Invalid item ID for removal: " .. tostring(itemID))
        return false
    end

    local inventoryID = item:GetInventory()
    local inventory = Parallax.Inventory:Get(inventoryID)

    -- Remove from inventory object
    if ( inventory ) then
        Parallax.Inventory:RemoveItem(inventoryID, itemID)
    end

    -- Delete from database
    Parallax.Database:Delete("ax_items", "id = " .. itemID)

    -- Notify client
    local client = Parallax.Character:GetPlayerByCharacter(item:GetOwner())
    if ( IsValid(client) ) then
        Parallax.Net:Start(client, "inventory.item.remove", inventoryID, itemID)
    end

    -- Remove from memory
    self.instances[itemID] = nil

    hook.Run("OnItemRemovedPermanently", itemID)

    if ( callback ) then
        callback(itemID)
    end

    return true
end

function Parallax.Item:Spawn(itemID, uniqueID, position, angles, callback, data)
    if ( !uniqueID or !position or !self.stored[uniqueID] ) then
        Parallax.Util:PrintError("Invalid parameters for item spawn.")
        return nil
    end

    local entity = ents.Create("ax_item")
    if ( !IsValid(entity) ) then
        Parallax.Util:PrintError("Failed to create item entity for unique ID '" .. uniqueID .. "'.")
        return nil
    end

    if ( IsValid(position) and position:IsPlayer() ) then
        position = position:GetDropPosition()
        angles = position:GetAngles()
    elseif ( !isvector(position) ) then
        Parallax.Util:PrintError("Invalid position provided for item spawn: " .. tostring(position))
        return nil
    end

    entity:SetPos(position)
    entity:SetAngles(angles or angle_zero)
    entity:Spawn()
    entity:Activate()

    entity:SetItem(itemID, uniqueID)
    entity:SetData(data or {})

    if ( callback ) then
        callback(entity)
    end

    return entity
end

concommand.Add("ax_item_add", function(client, cmd, arguments)
    if ( !client:IsAdmin() ) then
        client:Notify("You do not have permission to use this command!")
        return
    end

    local uniqueID = arguments[1]
    if ( !uniqueID or !Parallax.Item.stored[uniqueID] ) then
        client:Notify("Invalid item unique ID specified.")
        return
    end

    local characterID = client:GetCharacterID()
    local inventories = Parallax.Inventory:GetByCharacterID(characterID)
    if ( #inventories == 0 ) then
        client:Notify("No inventories found for character ID " .. characterID .. ".")
        return
    end

    local inventoryID = inventories[1]:GetID()

    Parallax.Item:Add(characterID, inventoryID, uniqueID, nil, function(itemID)
        client:Notify("Item " .. uniqueID .. " added to inventory " .. inventoryID .. ".")
    end)
end)

concommand.Add("ax_item_spawn", function(client, cmd, arguments)
    if ( !client:IsAdmin() ) then
        client:Notify("You do not have permission to use this command!")
        return
    end

    local uniqueID = arguments[1]
    if ( !uniqueID ) then
        client:Notify("You must specify an item unique ID to spawn.")
        return
    end

    local pos = client:GetEyeTrace().HitPos + vector_up * 10

    Parallax.Item:Spawn(nil, uniqueID, pos, nil, function(ent)
        if ( IsValid(ent) ) then
            client:Notify("Item " .. uniqueID .. " spawned.")
        else
            client:Notify("Failed to spawn item " .. uniqueID .. ".")
        end
    end)
end)