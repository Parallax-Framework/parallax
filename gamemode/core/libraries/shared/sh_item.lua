--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Item management library.
-- @module ax.item

ax.item = ax.item or {}
ax.item.base = ax.item.base or {}
ax.item.meta = ax.item.meta or {}
ax.item.stored = ax.item.stored or {}
ax.item.instances = ax.item.instances or {}

function ax.item:Load(path)
    if ( !path or !isstring(path) ) then return end

    local files, _ = file.Find(path .. "/*.lua", "LUA")
    if ( !files or files[1] == nil ) then return end

    for i = 1, #files do
        local v = files[i]
        local filePath = path .. "/" .. v
        ITEM = setmetatable({}, self.meta)

        ITEM.UniqueID = string.StripExtension(v):sub(4)

        -- Check if we are in the /base/ folder, if so, we need to set the base table
        -- to the ITEM table so we can use it in the item.
        if ( string.find(filePath, "/base/") ) then
            ITEM.IsBase = true
            self.base[ITEM.UniqueID] = ITEM
        end

        -- If we are inside of a folder that is in the ax.item.base table, we need to set the base of the item to the base of the folder.
        -- This allows us to inherit from the base item.
        for k, _ in pairs(self.base) do
            if ( string.find(path, "/" .. k) and !ITEM.Base and !ITEM.IsBase ) then
                ITEM.Base = k
                break
            end
        end

        local bResult = hook.Run("PreItemRegistered", ITEM.UniqueID, ITEM)
        if ( bResult == false ) then continue end

        ITEM:AddDefaultActions()

        -- Inherit the info from the base and add it to the item table.
        if ( ITEM.Base ) then
            local baseTable = self.base[ITEM.Base]
            if ( baseTable ) then
                for k2, v2 in pairs(baseTable) do
                    if ( ITEM[k2] == nil ) then
                        ITEM[k2] = v2
                    end

                    ITEM.BaseTable = baseTable
                end

                local mergeTable = table.Copy(baseTable)
                ITEM = table.Merge(mergeTable, ITEM)
            else
                ax.util:PrintError("Item base '" .. ITEM.Base .. "' not found for item '" .. ITEM.UniqueID .. "'.")
            end
        end

        ax.util:LoadFile(filePath, "shared")

        self.stored[ITEM.UniqueID] = ITEM

        if ( isfunction(ITEM.OnRegistered) ) then
            ITEM:OnRegistered()
        end

        hook.Run("PostItemRegistered", ITEM.UniqueID, ITEM)
        ITEM = nil
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

function ax.item:Get(identifier)
    if ( isstring(identifier) ) then
        return self.stored[identifier]
    elseif ( isnumber(identifier) ) then
        return self.instances[identifier]
    end

    return nil
end

function ax.item:GetAll()
    return self.stored
end

function ax.item:GetInstances()
    return self.instances
end

function ax.item:CreateObject(data)
    if ( !istable(data) ) then return end

    local id = tonumber(data.ID or data.id)
    local uniqueID = data.UniqueID or data.unique_id
    local characterID = tonumber(data.CharacterID or data.character_id or 0)
    local inventoryID = tonumber(data.InventoryID or data.inventory_id or 0)
    local itemData = ax.util:SafeParseTable(data.Data or data.data)

    local base = self.stored[uniqueID]
    if ( !base ) then return end

    local item = setmetatable({}, self.meta)

    for k, v in pairs(base) do
        item[k] = v
    end

    item.ID = id
    item.UniqueID = uniqueID
    item.CharacterID = characterID
    item.InventoryID = inventoryID
    item.Data = itemData

    return item
end

-- client-side addition
if ( CLIENT ) then
    function ax.item:Add(itemID, inventoryID, uniqueID, data, callback)
        if ( !itemID or !uniqueID or !self.stored[uniqueID] ) then return end

        data = data or {}

        local item = self:CreateObject({
            ID = itemID,
            UniqueID = uniqueID,
            Data = data,
            InventoryID = inventoryID,
            CharacterID = ax.client and ax.client:GetCharacterID() or 0
        })

        if ( !item ) then return end

        self.instances[itemID] = item

        local inventory = ax.inventory:Get(inventoryID)
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

        if ( callback ) then
            callback(itemID, data)
        end

        return item
    end
end