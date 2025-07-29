--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.inventory = ax.inventory or {}
ax.meta.inventory = ax.meta.inventory or {}
ax.inventory.instances = ax.inventory.instances or {}

if ( SERVER ) then
    function ax.inventory:Create(data, callback)
        if !istable(data) then return end

        local query = mysql:Insert("ax_inventories")
            query:Insert("maxWeight", data.maxWeight or 30.0)
            query:Insert("items", istable(data) and util.TableToJSON(data.items) or isstring(data.items) and data.items or "[]")
            query:Callback(function(result, status, lastInvId)
                if ( result == false ) then
                    if ( isfunction(callback) ) then
                        callback(false)
                    end

                    return
                end

                local inventory = setmetatable({}, ax.meta.inventory)
                inventory.id = lastInvId
                inventory.items = ax.util:SafeParseTable(data.items) or {}
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

        if ( getmetatable(inventory) != ax.meta.inventory ) then
            ax.util:PrintError("Invalid inventory provided to ax.inventory:Sync()")
            return
        end

        net.Start("ax.inventory.sync")
            net.WriteTable(inventory)
        net.Broadcast()
    end

    function ax.inventory:Restore(callback)
        local query = mysql:Select("ax_inventories")
            query:Callback(function(result, status)
                if ( result == false ) then
                    if ( isfunction(callback) ) then
                        callback(false)
                    end

                    return
                end

                for i = 1, #result do
                    local data = result[i]
                    local inventory = setmetatable({}, ax.meta.inventory)

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