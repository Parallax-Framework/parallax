--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.item = ax.item or {}
ax.item.stored = ax.item.stored or {}
ax.item.instances = ax.item.instances or {}
ax.item.meta = ax.item.meta or {}

function ax.item:Initialize()
    self:Include("parallax/gamemode/items")
    self:Include(engine.ActiveGamemode() .. "/gamemode/items")

    -- Look through modules for items
    local _, modules = file.Find("parallax/gamemode/modules/*", "LUA")
    for i = 1, #modules do
        self:Include("parallax/gamemode/modules/" .. modules[i] .. "/items")
    end
end

function ax.item:Include(path)
    local files, _ = file.Find(path .. "/*.lua", "LUA")

    for i = 1, #files do
        local fileName = files[i]

        local itemName = string.StripExtension(fileName)
        local prefix = string.sub(itemName, 1, 3)
        if ( prefix == "sh_" or prefix == "cl_" or prefix == "sv_" ) then
            itemName = string.sub(itemName, 4)
        end

        ITEM = setmetatable({ class = itemName }, ax.item.meta)
            ax.util:Include(path .. "/" .. fileName, "shared")
            ax.util:PrintSuccess("Item \"" .. tostring(ITEM.name) .. "\" initialized successfully.")
            ax.item.stored[itemName] = ITEM
        ITEM = nil
    end
end

function ax.item:Get(identifier)
    if ( isstring(identifier) ) then
        return self.stored[identifier]
    elseif ( isnumber(identifier) ) then
        return self.instances[identifier]
    end

    return nil
end

--- Inserts a new item instance into the database and returns the item object via callback.
-- @realm server
-- @param class string The unique ID of the item to create.
-- @param inventoryID number The ID of the inventory to which this item belongs.
-- @param data table Optional data table containing item properties.
-- @param callback function|nil Optional callback function called with the created item or false on failure.
-- @usage ax.item:Create("item_unique_id", 1, { customData = true }, function(item) print(item.id) end)
function ax.item:Create(class, inventoryID, data, callback)
    data = data or {}

    local query = mysql:Insert("ax_items")
        query:Insert("class", class)
        query:Insert("inventory_id", inventoryID)
        query:Insert("data", util.TableToJSON(data))
        query:Callback(function(result, status, lastItemId)
            if ( result == false ) then
                if ( isfunction(callback) ) then
                    callback(false)
                end

                return
            end

            -- Create the item object
            local item = setmetatable(ax.item.stored[class], ax.item.meta)
            item.id = lastItemId
            item.class = class
            item.data = data or {}

            ax.item.instances[lastItemId] = item

            -- Look for the inventory and add the item to it
            local inventory = ax.inventory.instances[inventoryID]
            if ( inventory ) then
                inventory.items[ item.id ] = item
                ax.inventory:Sync(inventory)
            end

            -- Call the callback with the created item
            if ( isfunction(callback) ) then
                callback(item)
            end
        end)
    query:Execute()
end

concommand.Add("ax_item_create", function(client, command, args, argStr)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then
        ax.util:PrintError("You do not have permission to use this command!")
        return
    end

    local class = args[1]
    local inventoryID = tonumber(args[2]) or 0

    if ( !class or class == "" ) then
        ax.util:PrintError("You must provide an item class.")

        ax.util:Print(Color(0, 255, 0), "Available item classes:")
        for k, v in pairs(ax.item.stored) do
            ax.util:Print(Color(0, 255, 0), "- " .. k)
        end

        return
    end

    if ( inventoryID <= 0 ) then
        ax.util:PrintError("You must provide a valid inventory ID.")

        ax.util:Print(Color(0, 255, 0), "Available inventory IDs:")
        for k, v in pairs(ax.inventory.instances) do
            ax.util:Print(Color(0, 255, 0), "- " .. k)
        end

        return
    end

    ax.item:Create(class, inventoryID, {}, function(item)
        if ( item ) then
            ax.util:Print(Color(0, 255, 0), "Item created successfully with ID: " .. item.id)
        else
            ax.util:PrintError("Failed to create item.")
        end
    end)
end)
