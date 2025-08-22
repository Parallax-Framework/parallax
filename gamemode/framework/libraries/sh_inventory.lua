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

if ( SERVER ) then
    function ax.inventory:Create(data, callback)
        data = data or {}
        data.maxWeight = data.maxWeight or 30.0

        local query = mysql:InsertIgnore("ax_inventories")
        query:Insert("items", "[]")
        query:Insert("max_weight", data.maxWeight)
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
            inventory.maxWeight = data.maxWeight or 30.0
            inventory.receivers = {}

            ax.inventory.instances[lastInvId] = inventory

            if ( isfunction(callback) ) then
                callback(inventory)
            end
        end)
        query:Execute()
    end

    function ax.inventory:Sync(inventory)
        if ( isnumber(inventory) ) then
            inventory = ax.inventory.instances[inventory]
        end

        if ( getmetatable(inventory) != ax.inventory.meta ) then
            ax.util:PrintError("Invalid inventory provided to ax.inventory:Sync()")
            return
        end

        net.Start("ax.inventory.sync")
            net.WriteUInt(inventory.id, 32)
            net.WriteTable(inventory.items, true) -- sequentiable table :: [1] = itemID
            net.WriteFloat(inventory.maxWeight)
        net.Broadcast()
    end

    function ax.inventory:Restore(client, callback)
        -- Step 1: Retrieve all character IDs the client owns.
        local characterIDs = {}
        for k, v in pairs(client.axCharacters) do
            table.insert(characterIDs, v.id)
        end

        -- Step 2: Retrieve all inventory IDs associated with the character IDs.
        local inventoryIDs = {}
        for _, characterID in ipairs(characterIDs) do
            local query = mysql:Select("ax_character")
                query:Where("id", characterID)
                query:Callback(function(result, status)
                    if ( result == nil or status == false ) then
                        return
                    end

                    for i = 1, #result do
                        table.insert(inventoryIDs, result[i].inventory_id)
                    end
                end)
            query:Execute()
        end

        --
        local query = mysql:Select("ax_inventories")
            query:Callback(function(result, status)
                if ( result == nil or status == false ) then
                    if ( isfunction(callback) ) then
                        callback(false)
                    end

                    return
                end

                for i = 1, #result do
                    local data = result[i]
                    local inventory = setmetatable({}, ax.inventory.meta)

                    data.id = tonumber(data.id)

                    inventory.id = data.id
                    inventory.items = ax.util:SafeParseTable(data.items) or {}
                    inventory.maxWeight = data.maxWeight or 30.0
                    inventory.receivers = {}

                    self.instances[inventory.id] = inventory
                    self:Sync(inventory)
                end

                if ( isfunction(callback) ) then
                    callback(true)
                end
            end)
        query:Execute()
    end
end