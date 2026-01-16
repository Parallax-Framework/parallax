--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Inventory management system for creating, storing, and retrieving inventory data.
-- Supports item storage, weight limits, and synchronization between server and clients.
-- @module ax.inventory

ax.inventory = ax.inventory or {}
ax.inventory.meta = ax.inventory.meta or {}
ax.inventory.instances = ax.inventory.instances or {}

if ( SERVER ) then
    --- Creates a new inventory in the database and returns the inventory object via callback.
    -- @realm server
    -- @param data table Optional data table containing inventory properties.
    -- @param callback function|nil Optional callback function called with the created inventory or false on failure.
    function ax.inventory:Create(data, callback)
        data = data or {}

        local maxWeight = data.maxWeight or 30.0
        data.maxWeight = maxWeight

        local query = mysql:Insert("ax_inventories")
            query:Insert("max_weight", maxWeight)
            query:Insert("data", "[]")
            query:Callback(function(result, status, lastInvId)
                if ( result == false ) then
                    if ( isfunction(callback) ) then
                        callback(false)
                    end

                    return
                end

                local inventory = setmetatable({}, ax.inventory.meta)
                inventory.id = lastInvId
                inventory.items = {}
                inventory.maxWeight = maxWeight
                inventory.receivers = {}

                ax.inventory.instances[lastInvId] = inventory

                if ( isfunction(callback) ) then
                    callback(inventory)
                end
            end)
        query:Execute()
    end

    --- Synchronizes the specified inventory with all clients.
    -- @realm server
    -- @param inventory table|number The inventory table or inventory ID to sync.
    -- @usage ax.inventory:Sync(inventory)
    function ax.inventory:Sync(inventory)
        if ( isnumber(inventory) ) then
            inventory = ax.inventory.instances[inventory]
        end

        if ( getmetatable(inventory) != ax.inventory.meta ) then
            ax.util:PrintError(string.format(
                "Invalid inventory provided to ax.inventory:Sync() (type: %s, value: %s)",
                type(inventory), tostring(inventory)
            ))

            return
        end

        local items = {}
        if ( istable(inventory.items) ) then
            for k, v in pairs(inventory.items) do
                items[#items + 1] = {
                    id = v.id,
                    class = v.class,
                    data = v.data or {},
                    inventoryID = v.invID
                }
            end
        end

        net.Start("ax.inventory.sync")
            net.WriteUInt(inventory.id, 32)
            net.WriteTable(items)
            net.WriteFloat(inventory.maxWeight)
            net.WriteTable(inventory.receivers or {})
        net.Send(inventory:GetReceivers())

        ax.util:PrintDebug(string.format("Synchronized inventory %d with %d receivers.", inventory.id, #inventory:GetReceivers()))
    end

    --- Restores all inventories associated with the client's characters from the database.
    -- @realm server
    -- @param client Player The player whose inventories should be restored.
    -- @usage ax.inventory:Restore(client)
    -- @internal
    function ax.inventory:Restore(client)
        local characterIDs = {}
        local clientTable = client:GetTable()
        for k, v in pairs(clientTable.axCharacters) do
            characterIDs[#characterIDs + 1] = v.id
        end

        ax.util:PrintDebug(string.format("Found %d character IDs for %s", #characterIDs, client:SteamID64()))

        -- Sync all world items (inventory_id = 0) to the client
        for itemID, item in pairs(ax.item.instances) do
            if ( item.invID == 0 or item:GetInventoryID() == 0 ) then
                net.Start("ax.item.spawn")
                    net.WriteUInt(itemID, 32)
                    net.WriteString(item.class)
                    net.WriteTable(item.data or {})
                net.Send(client)
            end
        end
        ax.util:PrintDebug(string.format("Synced world items to %s", client:SteamID64()))

        -- TODO: Find a way to optimize this to use fewer pyramids
        local inventoryIDs = {}
        if ( characterIDs[1] != nil ) then
            for _, characterID in pairs(characterIDs) do
                local characterQuery = mysql:Select("ax_characters")
                characterQuery:Where("id", characterID)
                characterQuery:Callback(function(result, status)
                    if ( result == nil or status == false ) then
                        return
                    end

                    for i = 1, #result do
                        if ( result[i].inventory != nil ) then
                            inventoryIDs[#inventoryIDs + 1] = result[i].inventory
                        end
                    end

                    ax.util:PrintDebug(string.format("Found %d inventories for %s", #inventoryIDs, client:SteamID64()))

                    for _, inventoryID in pairs(inventoryIDs) do
                        local inventoryQuery = mysql:Select("ax_inventories")
                        inventoryQuery:Where("id", inventoryID)
                        inventoryQuery:Callback(function(result, status)
                            if ( result == nil or status == false ) then return end

                            ax.util:PrintDebug(string.format("Restoring %d inventories for %s", #result, client:SteamID64()))

                            for i = 1, #result do
                                local data = result[i]
                                local inventory = setmetatable({}, ax.inventory.meta)

                                data.id = tonumber(data.id)
                                inventory.id = data.id

                                local maxWeight = data.maxWeight or 30.0
                                inventory.maxWeight = maxWeight
                                inventory.receivers = {}

                                local itemFetchQuery = mysql:Select("ax_items")
                                itemFetchQuery:Where("inventory_id", data.id)
                                itemFetchQuery:Callback(function(itemsResult, itemsStatus)
                                    if ( itemsResult == nil or itemsStatus == false ) then return end

                                    local itemsInInv = {}
                                    for j = 1, #itemsResult do
                                        local itemData = itemsResult[j]
                                        local item = ax.item.stored[itemData.class]
                                        if ( !item ) then continue end

                                        local itemObject = ax.item:Instance(itemData.id, itemData.class)
                                        itemObject.invID = itemData.inventory_id
                                        itemObject.data = util.JSONToTable(itemData.data) or {}

                                        ax.item.instances[itemObject.id] = itemObject
                                        itemsInInv[itemObject.id] = itemObject
                                    end

                                    inventory.items = itemsInInv

                                    self.instances[inventory.id] = inventory
                                    self:Sync(inventory)

                                    local clientChar = client:GetCharacter()
                                    local charInv = clientChar and clientChar.vars and clientChar.vars.inventory
                                    if ( charInv == inventory.id ) then
                                        inventory:AddReceiver(client)
                                        ax.util:PrintDebug(string.format("Added %s as a receiver to inventory %d", client:SteamID64(), inventory.id))
                                    end
                                end)
                                itemFetchQuery:Execute()
                            end
                        end)
                        inventoryQuery:Execute()
                    end
                end)
                characterQuery:Execute()
            end
        end
    end
end

concommand.Add("ax_inventory_restore", function(client, command, args)
    if ( !IsValid(client) or !client:IsPlayer() ) then return end
    if ( !client:IsSuperAdmin() ) then return end

    ax.inventory:Restore(client)
end)
