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

function ax.item:Instance()
    local object = {}

    local path = debug.getinfo(2, "S").source
    local uniqueID = string.GetFileFromFilename(path)
    uniqueID = string.StripExtension(uniqueID)
    uniqueID = string.lower(uniqueID)
    uniqueID = string.gsub(uniqueID, "^sh_", "")

    if ( !uniqueID or uniqueID == "" ) then
        ax.util:PrintError("Invalid unique ID for item instance.")
        return false
    end

    if ( string.find(path, "/base/") ) then
        object.IsBase = true
    else
        local baseItems = {}
        for k, v in pairs(ax.item.stored) do
            if ( v.IsBase == true ) then
                baseItems[v.UniqueID] = v
            end
        end

        for baseUniqueID, baseItem in pairs(baseItems) do
            if ( string.find(path, baseUniqueID) ) then
                object.Base = baseItem
                break
            end
        end

        if ( object.Base ) then
            table.Merge(object, object.Base)
            object.BaseClass = nil
            object.Base = nil
            object.IsBase = nil
        end
    end

    object.UniqueID = uniqueID
    object = setmetatable(object, self.meta)

    object:AddDefaultActions()

    return object
end

function ax.item:Get(input)
    if ( input == nil ) then
        ax.util:PrintError("Invalid unique ID provided to ax.item:Get()")
        return false
    end

    if ( isstring(input) ) then -- Search through the stored items by unique ID
        local item = self.stored[input]
        if ( !item ) then
            ax.util:PrintError("Item with unique ID '" .. input .. "' not found.")
            return false
        end

        return item
    elseif ( isnumber(input) ) then -- Search through the instances by ID
        local item = self.instances[input]
        if ( !item ) then
            ax.util:PrintError("Item with ID '" .. input .. "' not found.")
            return false
        end

        return item
    end

    ax.util:PrintError("Invalid input type provided to ax.item:Get()")
    return false
end

function ax.item:Load(path)
    if ( !isstring(path) ) then return end

    local files, _ = file.Find(path .. "/*.lua", "LUA")
    if ( !files or files[1] == nil ) then return end

    for i = 1, #files do
        local v = files[i]
        if ( v:sub(-4) == ".lua" ) then
            local filePath = path .. "/" .. v
            ax.util:LoadFile(filePath, "shared")
            print("Loaded item file: " .. filePath)
        end
    end
end

function ax.item:LoadFolder(path)
    if ( !path or !isstring(path) ) then return end

    local _, folders = file.Find(path .. "/*", "LUA")

    -- If there is a base folder, we need to load it first so we can inherit from it later.
    local found = false
    for i = 1, #folders do
        local v = folders[i]
        if ( v == "base" ) then
            found = true
            break
        end
    end

    if ( found ) then
        self:Load(path .. "/base")
    end

    -- Now we can load the rest of the folders and files.
    for i = 1, #folders do
        local v = folders[i]
        if ( v == "base" ) then continue end

        self:Load(path .. "/" .. v)
    end

    self:Load(path)
end

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