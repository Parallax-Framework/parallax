--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.item = ax.item or {}
ax.item.meta = ax.item.meta or {}
ax.item.stored = ax.item.stored or {}
ax.item.instances = ax.item.instances or {}

function ax.item:Add(invID, uniqueID, data, callback)
    if ( ax.util:IsCharacter(invID) ) then
        invID = invID:GetID()
    end

    if ( !isnumber(invID) or invID <= 0 ) then
        ax.util:PrintError("Invalid inventory ID provided to ax.item:Add()")
        return false
    end

    if ( !isstring(uniqueID) or uniqueID == "" ) then
        ax.util:PrintError("Invalid unique ID provided to ax.item:Add()")
        return false
    end

    local item = ax.item:Get(uniqueID)
    if ( !istable(item) ) then
        ax.util:PrintError("Item with unique ID '" .. uniqueID .. "' does not exist.")
        return false
    end

    local inventory = ax.inventory:Get(invID)
    if ( !istable(inventory) ) then
        ax.util:PrintError("Inventory with ID '" .. invID .. "' does not exist.")
        return false
    end

    if ( !istable(data) ) then
        data = {}
    end

    -- Use the inventory's AddItem method
    ax.inventory:AddItem(invID, uniqueID, data, callback)
end

function ax.item:PerformAction(itemID, actionName)
    local item = self:Get(itemID)
    if ( !item ) then
        ax.util:PrintError("Item not found: " .. tostring(itemID))
        return false
    end

    local client = nil

    -- Handle world items differently
    if ( item:GetInventoryID() == 0 ) then
        -- For world items, we need to get the client from the context (usually the entity user)
        -- This will be handled by the entity's Use function
        local entity = item:GetEntity()
        if ( !IsValid(entity) ) then
            ax.util:PrintError("World item has no valid entity: " .. tostring(itemID))
            return false
        end

        -- The client should be passed through the action call context
        -- For now, we'll handle this in the entity itself
        return false -- Let the entity handle world item actions
    end

    -- Find the inventory that contains this item
    local inventory = ax.inventory:Get(item:GetInventoryID())
    if ( !inventory ) then
        ax.util:PrintError("Inventory not found for item: " .. tostring(itemID))
        return false
    end

    local character = inventory:GetCharacter()
    if ( !character ) then
        ax.util:PrintError("Character not found for item: " .. tostring(itemID))
        return false
    end

    client = character:GetPlayer()
    if ( !IsValid(client) ) then
        ax.util:PrintError("Player not found for item: " .. tostring(itemID))
        return false
    end

    local actions = item:GetActions()
    if ( !actions or !actions[actionName] ) then
        ax.util:PrintError("Action not found: " .. tostring(actionName))
        return false
    end

    local action = actions[actionName]
    if ( isfunction(action.OnCanRun) and !action:OnCanRun(item, client) ) then
        client:Notify("You cannot perform this action right now.")
        return false
    end

    if ( isfunction(action.OnRun) ) then
        action:OnRun(item, client)
    end

    hook.Run("PostPlayerItemAction", client, actionName, item)

    return true
end

function ax.item:Transfer(itemID, fromInventory, toInventory, callback)
    -- Type checking
    if ( !isnumber(itemID) ) then
        ax.util:PrintError("itemID must be a number, got: " .. type(itemID))
        if ( callback ) then callback(false) end
        return false
    end

    if ( !isnumber(fromInventory) ) then
        ax.util:PrintError("fromInventory must be a number, got: " .. type(fromInventory) .. " - " .. tostring(fromInventory))
        if ( callback ) then callback(false) end
        return false
    end

    if ( !isnumber(toInventory) ) then
        ax.util:PrintError("toInventory must be a number, got: " .. type(toInventory))
        if ( callback ) then callback(false) end
        return false
    end

    local item = self:Get(itemID)
    if ( !item ) then
        ax.util:PrintError("Item not found for transfer: " .. tostring(itemID))
        if ( callback ) then callback(false) end
        return false
    end

    ax.util:PrintSuccess("Transferring item " .. itemID .. " from inventory " .. fromInventory .. " to inventory " .. toInventory)

    -- First verify the item exists in the database
    ax.database:Select("ax_items", nil, "id = " .. itemID, function(result)
        if ( !result or !result[1] ) then
            ax.util:PrintError("Item " .. itemID .. " not found in database for transfer")
            if ( callback ) then callback(false) end
            return false
        end

        local currentInventoryID = tonumber(result[1].inventory_id)
        if ( currentInventoryID != fromInventory ) then
            ax.util:PrintError("Item " .. itemID .. " inventory mismatch. Expected: " .. fromInventory .. ", Found: " .. currentInventoryID)
            if ( callback ) then callback(false) end
            return false
        end

        -- Update database
        ax.database:Update("ax_items", {
            inventory_id = toInventory
        }, "id = " .. itemID, function(success)
            if ( !success ) then
                ax.util:PrintError("Database update failed for item transfer: Item " .. itemID .. " from " .. fromInventory .. " to " .. toInventory)
                if ( callback ) then callback(false) end
                return false
            end

            ax.util:PrintSuccess("Database updated successfully for item " .. itemID)

            -- Update item instance
            item:SetInventoryID(toInventory)

            -- Update inventory lists
            if ( fromInventory > 0 ) then
                local fromInv = ax.inventory:Get(fromInventory)
                if ( fromInv ) then
                    table.RemoveByValue(fromInv.Items, itemID)
                    ax.util:PrintSuccess("Removed item " .. itemID .. " from inventory " .. fromInventory)
                end
            end

            if ( toInventory > 0 ) then
                local toInv = ax.inventory:Get(toInventory)
                if ( toInv ) then
                    table.insert(toInv.Items, itemID)
                    ax.util:PrintSuccess("Added item " .. itemID .. " to inventory " .. toInventory)
                end
            end

            -- Network changes
            if ( fromInventory > 0 ) then
                local fromInv = ax.inventory:Get(fromInventory)
                if ( fromInv ) then
                    local character = fromInv:GetCharacter()
                    if ( character ) then
                        local client = character:GetPlayer()
                        if ( IsValid(client) ) then
                            net.Start("ax.inventory.item.remove")
                                net.WriteUInt(fromInventory, 16)
                                net.WriteUInt(itemID, 16)
                            net.Send(client)
                            ax.util:PrintSuccess("Networked item removal to client")
                        end
                    end
                end
            end

            if ( toInventory > 0 ) then
                local toInv = ax.inventory:Get(toInventory)
                if ( toInv ) then
                    local character = toInv:GetCharacter()
                    if ( character ) then
                        local client = character:GetPlayer()
                        if ( IsValid(client) ) then
                            net.Start("ax.inventory.item.add")
                                net.WriteUInt(toInventory, 16)
                                net.WriteUInt(itemID, 16)
                                net.WriteString(item:GetUniqueID())
                                net.WriteTable(item:GetData())
                            net.Send(client)
                            ax.util:PrintSuccess("Networked item addition to client")
                        end
                    end
                end
            end

            if ( callback ) then
                callback(true)
            end
        end)
    end)
end

function ax.item:Spawn(itemID, uniqueID, pos, ang, callback, data)
    local entity = ents.Create("ax_item")
    if ( !IsValid(entity) ) then
        ax.util:PrintError("Failed to create item entity")
        if ( callback ) then callback(false) end
        return false
    end

    entity:SetPos(pos)
    entity:SetAngles(ang or Angle(0, 0, 0))
    entity:Spawn()
    entity:SetItem(itemID, uniqueID, data)

    if ( callback ) then
        callback(entity)
    end

    return entity
end

-- Command to spawn items in the world
concommand.Add("ax_item_spawn", function(ply, cmd, args)
    if ( !CAMI.PlayerHasAccess(ply, "Parallax - Manage Items", nil) ) then
        ply:Notify("You don't have permission to spawn items.")
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
    if ( !CAMI.PlayerHasAccess(ply, "Parallax - Manage Items", nil) ) then
        ply:Notify("You don't have permission to give items.")
        return
    end

    local uniqueID = args[1]
    local targetName = args[2]
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

    -- Find target player
    local targetPlayer = ply
    if ( targetName ) then
        local found = false
        for _, client in player.Iterator() do
            if ( string.find(string.lower(client:SteamName()), string.lower(targetName)) ) then
                targetPlayer = client
                found = true
                break
            end
        end

        if ( !found ) then
            ply:Notify("Player '" .. targetName .. "' not found.")
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

    if ( args[4] ) then
        data = util.JSONToTable(args[4]) or {}
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