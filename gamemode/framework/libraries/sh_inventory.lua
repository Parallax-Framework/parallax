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
    --- Creates a new inventory in the database and returns the inventory object via callback.
    -- @realm server
    -- @param data table Optional data table containing inventory properties.
    -- @param callback function|nil Optional callback function called with the created inventory or false on failure.
    function ax.inventory:Create(data, callback)
        data = data or {}

        local maxWeight = data.maxWeight or 30.0
        data.maxWeight = maxWeight

        local query = mysql:Insert("ax_inventories")
            query:Insert("items", "[]")
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

        net.Start("ax.inventory.sync")
            net.WriteUInt(inventory.id, 32)
            net.WriteTable(inventory.items)
            net.WriteFloat(inventory.maxWeight)
        net.Send(inventory:GetReceivers())
    end

    --- Restores all inventories associated with the client's characters from the database.
    -- @realm server
    -- @param client Player The player whose inventories should be restored.
    -- @param callback function|nil Optional callback function called with true on success or false on failure.
    -- @usage ax.inventory:Restore(client, function(success) print(success) end)
    function ax.inventory:Restore(client, callback)
        local characterIDs = {}
        for k, v in pairs(client.axCharacters) do
            characterIDs[#characterIDs + 1] = v.id
        end

        local inventoryIDs = {}
        if ( characterIDs[1] != nil ) then
            local query = mysql:Select("ax_characters")
                query:Where("id", characterIDs)
                query:Callback(function(result, status)
                    if ( result == nil or status == false ) then
                        return
                    end

                    for i = 1, #result do
                        if ( result[i].inventory_id != nil ) then
                            inventoryIDs[#inventoryIDs + 1] = result[i].inventory_id
                        end
                    end
                end)
            query:Execute()
        end

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

                    inventory.id = data.id
                    inventory.items = ax.util:SafeParseTable(data.items) or {}
                    inventory.id = data.id

                    if ( isstring(data.items) ) then
                        inventory.items = ax.util:SafeParseTable(data.items) or {}
                    elseif ( istable(data.items) ) then
                        inventory.items = data.items
                    else
                        inventory.items = {}
                    end

                    local maxWeight = data.maxWeight or 30.0
                    inventory.maxWeight = maxWeight
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
