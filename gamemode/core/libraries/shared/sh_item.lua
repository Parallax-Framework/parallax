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
    if ( !files or #files == 0 ) then return end

    for _, v in ipairs(files) do
        local filePath = path .. "/" .. v
        ITEM = setmetatable({}, self.meta)

        ITEM.UniqueID = string.StripExtension(v):sub(4)

        -- Check if we are in the /base/ folder, if so, we need to set the base table
        -- to the ITEM table so we can use it in the item.
        if ( string.find(path, "/base") ) then
            ITEM.IsBase = true
            self.base[ITEM.UniqueID] = ITEM
        end

        -- If we are inside of a folder that is in the ax.item.base table, we need to set the base of the item to the base of the folder.
        -- This allows us to inherit from the base item.
        for k, _ in pairs(self.base) do
            if ( string.find(path, "/" .. k) ) then
                ITEM.Base = k
                break
            end
        end

        local bResult = hook.Run("PreItemRegistered", ITEM.UniqueID, ITEM)
        if ( bResult == false ) then continue end

        ITEM.Weight = ITEM.Weight or 0
        ITEM.Category = ITEM.Category or "Miscellaneous"

        ITEM.Actions = ITEM.Actions or {}
        ITEM.Actions.Drop = ITEM.Actions.Drop or {
            Name = "Drop",
            OnRun = function(this, item, client)
                if ( !IsValid(client) ) then return end

                local pos = client:GetDropPosition()
                if ( !pos ) then return end

                local prevent = hook.Run("PrePlayerDropItem", client, item, pos)
                if ( prevent == false ) then return end

                ax.item:Spawn(item:GetID(), item:GetUniqueID(), pos, Angle(0, 0, 0), function(entity)
                    ax.inventory:RemoveItem(item:GetInventory(), item:GetID())

                    hook.Run("PostPlayerDropItem", client, item, entity)
                end, item:GetData())
            end,
            OnCanRun = function(this, item, client)
                return !IsValid(item:GetEntity())
            end
        }

        ITEM.Actions.Take = ITEM.Actions.Take or {
            Name = "Take",
            OnRun = function(this, item, client)
                if ( !IsValid(client) ) then return end

                local char = ax.character:Get(item:GetOwner())
                local inventoryMain = char and char:GetInventory()
                if ( !inventoryMain ) then return end

                local entity = item:GetEntity()
                if ( !IsValid(entity) ) then return end

                local weight = item:GetWeight()
                if ( inventoryMain:GetWeight() + weight > inventoryMain:GetMaxWeight() ) then
                    client:Notify("You cannot take this item, it is too heavy!")
                    return
                end

                local prevent = hook.Run("PrePlayerTakeItem", client, item, entity)
                if ( prevent == false ) then return end

                ax.item:Transfer(item:GetID(), 0, inventoryMain:GetID(), function(success)
                    if ( success ) then
                        if ( item.OnTaken ) then
                            item:OnTaken(entity)
                        end

                        hook.Run("PostPlayerTakeItem", client, item, entity)
                        SafeRemoveEntity(entity)
                    else
                        client:Notify("Failed to transfer item to inventory.")
                    end
                end)
            end,
            OnCanRun = function(this, item, client)
                return true
            end
        }

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
                ax.util:PrintError("Base item " .. ITEM.Base .. " not found for item " .. ITEM.UniqueID)
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
    if ( table.HasValue(folders, "base") ) then
        self:Load(path .. "/base")
    end

    -- Now we can load the rest of the folders and files.
    for _, v in ipairs(folders) do
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

    for key, value in pairs(base) do
        item[key] = value
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
            if ( !table.HasValue(items, itemID) ) then
                table.insert(items, itemID)
            end
        end

        if ( callback ) then
            callback(itemID, data)
        end

        return item
    end
end