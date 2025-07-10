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

function ax.inventory:Instance()
    return setmetatable({}, self.meta)
end

--- Creates a new inventory instance accepting data from the database.
-- @param table data The data to create the inventory from
-- @return table The created inventory object
-- @usage local myInventory = ax.inventory:Create({ id = 1, items = '[{"id": 1, "name": "Item1"}]', data = '{"key": "value"}', max_weight = 100 })
function ax.inventory:Create(data)
    if ( !data or !istable(data) ) then
        ax.util:PrintError("Invalid data provided to ax.inventory:Create()")
        return
    end

    local invID = tonumber(data.id)
    if ( !invID or invID <= 0 ) then
        ax.util:PrintError("Invalid ID provided to ax.inventory:Create()")
        return
    end

    if ( self.instances[invID] ) then
        ax.util:PrintWarning("Inventory instance with ID '" .. invID .. "' already exists.")
        return self.instances[invID]
    end

    local instance = self:Instance()
    instance.ID = invID
    instance.Items = ax.util:SafeParseTable(data.items)
    instance.Data = ax.util:SafeParseTable(data.data)
    instance.MaxWeight = tonumber(data.max_weight) or 0

    self.instances[invID] = instance

    return instance
end

--- Retrieves an inventory by its ID.
-- @param number inventoryID The ID of the inventory to retrieve
-- @return table|false The inventory instance if found, or false if not found
function ax.inventory:Get(inventoryID)
    if ( !inventoryID ) then
        ax.util:PrintError("Invalid parameters for ax.inventory:Get")
        return false
    end

    local inventory = self.instances[inventoryID]
    if ( !inventory ) then
        ax.util:PrintError("Inventory with ID " .. inventoryID .. " not found.")
        return false
    end

    return inventory
end

--- Retrieves an inventory by character ID.
-- @param number characterID The ID of the character whose inventory to retrieve
function ax.inventory:GetByCharacterID(characterID)
    if ( !characterID ) then
        ax.util:PrintError("Invalid parameters for ax.inventory:GetByCharacterID")
        return {}
    end

    if ( !isnumber(characterID) or characterID <= 0 ) then
        ax.util:PrintError("Invalid character ID provided to ax.inventory:GetByCharacterID")
        return {}
    end

    local inventory
    for _, inv in pairs(self.instances) do
        if ( inv.CharacterID == characterID ) then
            inventory = inv
            break
        end
    end

    return inventory
end