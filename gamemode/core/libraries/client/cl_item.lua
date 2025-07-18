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

--- Creates an item instance on the client
-- @param number itemID The ID of the item instance
-- @param string uniqueID The unique identifier of the item type
-- @param table data The item's data
-- @return table|false The created item instance or false on failure
function ax.item:CreateObject(itemID, uniqueID, data)
    if ( !isnumber(itemID) or itemID <= 0 ) then
        ax.util:PrintError("Invalid item ID provided to ax.item:CreateObject")
        return false
    end
    
    if ( !isstring(uniqueID) or uniqueID == "" ) then
        ax.util:PrintError("Invalid unique ID provided to ax.item:CreateObject")
        return false
    end
    
    local itemDef = self:Get(uniqueID)
    if ( !itemDef ) then
        ax.util:PrintError("Item definition not found for: " .. uniqueID)
        return false
    end
    
    if ( !istable(data) ) then
        data = {}
    end
    
    -- Create instance based on definition
    local instance = table.Copy(itemDef)
    instance.ID = itemID
    instance.Data = data
    instance.Entity = NULL
    instance.InventoryID = 0
    
    setmetatable(instance, self.meta)
    
    return instance
end

--- Adds an item to the client's item instances
-- @param number itemID The ID of the item instance
-- @param number inventoryID The inventory ID (0 for world items)
-- @param string uniqueID The unique identifier of the item type
-- @param table data The item's data
-- @return table|false The created item instance or false on failure
function ax.item:Add(itemID, inventoryID, uniqueID, data)
    if ( !isnumber(itemID) or itemID <= 0 ) then
        ax.util:PrintError("Invalid item ID provided to ax.item:Add")
        return false
    end
    
    if ( !isnumber(inventoryID) or inventoryID < 0 ) then
        ax.util:PrintError("Invalid inventory ID provided to ax.item:Add")
        return false
    end
    
    if ( !isstring(uniqueID) or uniqueID == "" ) then
        ax.util:PrintError("Invalid unique ID provided to ax.item:Add")
        return false
    end
    
    if ( !istable(data) ) then
        data = {}
    end
    
    -- Create item instance
    local item = self:CreateObject(itemID, uniqueID, data)
    if ( !item ) then
        return false
    end
    
    item:SetInventoryID(inventoryID)
    self.instances[itemID] = item
    
    return item
end

--- Removes an item from the client's item instances
-- @param number itemID The ID of the item instance
function ax.item:Remove(itemID)
    if ( !isnumber(itemID) or itemID <= 0 ) then
        ax.util:PrintError("Invalid item ID provided to ax.item:Remove")
        return false
    end
    
    local item = self.instances[itemID]
    if ( item ) then
        -- Call remove hook if it exists
        if ( item.OnRemove ) then
            item:OnRemove()
        end
        
        self.instances[itemID] = nil
        return true
    end
    
    return false
end

--- Updates item data on the client
-- @param number itemID The ID of the item instance
-- @param string key The data key
-- @param any value The data value
function ax.item:UpdateData(itemID, key, value)
    if ( !isnumber(itemID) or itemID <= 0 ) then
        ax.util:PrintError("Invalid item ID provided to ax.item:UpdateData")
        return false
    end
    
    if ( !isstring(key) or key == "" ) then
        ax.util:PrintError("Invalid key provided to ax.item:UpdateData")
        return false
    end
    
    local item = self.instances[itemID]
    if ( !item ) then
        ax.util:PrintError("Item instance not found for ID: " .. itemID)
        return false
    end
    
    if ( !istable(item.Data) ) then
        item.Data = {}
    end
    
    item.Data[key] = value
    
    -- Call data update hook if it exists
    if ( item.OnDataUpdate ) then
        item:OnDataUpdate(key, value)
    end
    
    return true
end

--- Caches multiple items at once
-- @param table items Table of item data to cache
function ax.item:CacheItems(items)
    if ( !istable(items) ) then
        ax.util:PrintError("Invalid items table provided to ax.item:CacheItems")
        return false
    end
    
    for _, itemData in pairs(items) do
        if ( istable(itemData) and itemData.ID and itemData.UniqueID ) then
            local item = self:CreateObject(itemData.ID, itemData.UniqueID, itemData.Data or {})
            if ( item ) then
                item:SetInventoryID(itemData.InventoryID or 0)
                self.instances[itemData.ID] = item
                
                if ( item.OnCache ) then
                    item:OnCache()
                end
            end
        end
    end
    
    return true
end

--- Gets all items in a specific inventory
-- @param number inventoryID The inventory ID
-- @return table Array of item instances
function ax.item:GetByInventory(inventoryID)
    if ( !isnumber(inventoryID) or inventoryID < 0 ) then
        return {}
    end
    
    local items = {}
    for _, item in pairs(self.instances) do
        if ( item:GetInventoryID() == inventoryID ) then
            table.insert(items, item)
        end
    end
    
    return items
end

--- Gets all world items (items not in inventories)
-- @return table Array of world item instances
function ax.item:GetWorldItems()
    return self:GetByInventory(0)
end

--- Clears all item instances
function ax.item:ClearInstances()
    for itemID, item in pairs(self.instances) do
        if ( item.OnRemove ) then
            item:OnRemove()
        end
    end
    
    self.instances = {}
end
