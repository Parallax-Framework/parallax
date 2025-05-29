-- server-side item logic
-- @module ax.item

--- Adds a new item to a character's inventory.
-- This function handles inventory lookup, database insertion, instance creation, and syncing.
-- @tparam number characterID ID of the character receiving the item
-- @tparam[opt] number inventoryID Optional specific inventory ID
-- @tparam string uniqueID The registered unique ID of the item
-- @tparam[opt] table data Optional custom item data
-- @tparam[opt] function callback Optional callback called with (itemID, data)
-- @within ax.item
function ax.item:Add(characterID, inventoryID, uniqueID, data, callback)
    if ( !characterID or !uniqueID or !self.stored[uniqueID] ) then
        ax.util:PrintError("Invalid parameters for item addition: characterID=" .. tostring(characterID) .. ", uniqueID=" .. tostring(uniqueID))
        return
    end

    local character = ax.character:Get(characterID)
    if ( character and !inventoryID ) then
        inventoryID = character:GetInventory()
    end

    local inventory = ax.inventory:Get(inventoryID)
    if ( inventory and !inventory:HasSpaceFor(self.stored[uniqueID].Weight) ) then
        return
    end

    data = data or {}

    ax.database:Insert("ax_items", {
        inventory_id = inventoryID,
        character_id = characterID,
        unique_id = uniqueID,
        data = util.TableToJSON(data)
    }, function(result)
        local itemID = tonumber(result)
        if ( !itemID ) then
            ax.util:PrintError("Failed to create item in database: " .. tostring(result))
            return
        end

        local item = self:CreateObject({
            ID = itemID,
            UniqueID = uniqueID,
            Data = data,
            InventoryID = inventoryID,
            CharacterID = characterID
        })

        if ( !item ) then
            ax.util:PrintError("Failed to create item object for item ID " .. itemID)
            return
        end

        self.instances[itemID] = item

        if ( inventory ) then
            local items = inventory:GetItems()
            if ( !table.HasValue(items, itemID) ) then
                table.insert(items, itemID)
            end
        end

        local receiver = ax.character:GetPlayerByCharacter(characterID)
        if ( IsValid(receiver) ) then
            ax.net:Start(receiver, "item.add", itemID, inventoryID, uniqueID, data)
        end

        if ( callback ) then
            callback(itemID, data)
        end

        hook.Run("OnItemAdded", item, characterID, uniqueID, data)
    end)
end

function ax.item:Transfer(itemID, fromInventoryID, toInventoryID, callback)
    if ( !itemID or !fromInventoryID or !toInventoryID ) then return false end

    local item = self.instances[itemID]
    if ( !item ) then return false end

    local fromInventory = ax.inventory:Get(fromInventoryID)
    local toInventory = ax.inventory:Get(toInventoryID)

    if ( toInventory and !toInventory:HasSpaceFor(item:GetWeight()) ) then
        local receiver = ax.character:GetPlayerByCharacter(item:GetOwner())
        if ( IsValid(receiver) ) then
            receiver:Notify("Inventory is too full to transfer this item.")
        end

        return false
    end

    local prevent = hook.Run("PreItemTransferred", item, fromInventoryID, toInventoryID)
    if ( prevent == false ) then
        return false
    end

    if ( fromInventory ) then
        fromInventory:RemoveItem(itemID)
    end

    if ( toInventory ) then
        toInventory:AddItem(itemID, item:GetUniqueID(), item:GetData())
    end

    item:SetInventory(toInventoryID)

    ax.database:Update("ax_items", {
        inventory_id = toInventoryID
    }, "id = " .. itemID)

    if ( callback ) then
        callback(itemID, fromInventoryID, toInventoryID)
    end

    hook.Run("PostItemTransferred", item, fromInventoryID, toInventoryID)

    return true
end

function ax.item:PerformAction(itemID, actionName, callback)
    local item = self.instances[itemID]
    if ( !item or !actionName ) then
        ax.util:PrintError("Invalid parameters for item action: itemID=" .. tostring(itemID) .. ", actionName=" .. tostring(actionName))
        return false
    end

    local base = self.stored[item:GetUniqueID()]
    if ( !base or !base.Actions ) then
        ax.util:PrintError("Item '" .. item:GetUniqueID() .. "' does not have actions defined.")
        return false
    end

    local action = base.Actions[actionName]
    if ( !action ) then
        ax.util:PrintError("Action '" .. actionName .. "' not found for item '" .. item:GetUniqueID() .. "'.")
        return false
    end

    local client = ax.character:GetPlayerByCharacter(item:GetOwner())
    if ( !IsValid(client) ) then
        ax.util:PrintError("Invalid client for item action: " .. tostring(item:GetOwner()))
        return false
    end

    if ( action.OnCanRun and !action:OnCanRun(item, client) ) then
        return false
    end

    local prevent = hook.Run("PrePlayerItemAction", client, actionName, item)
    if ( prevent == false ) then
        return false
    end

    if ( action.OnRun ) then
        action:OnRun(item, client)
    end

    if ( callback ) then
        callback(item, client)
    end

    local hooks = base.Hooks or {}
    if ( hooks[actionName] ) then
        for _, hookFunc in pairs(hooks[actionName]) do
            if ( hookFunc ) then
                hookFunc(item, client)
            end
        end
    end

    ax.net:Start(client, "inventory.refresh", item:GetInventory())

    hook.Run("PostPlayerItemAction", client, actionName, item)

    return true
end

function ax.item:Cache(characterID, callback)
    if ( !ax.character:Get(characterID) ) then
        ax.util:PrintError("Invalid character ID for item cache: " .. tostring(characterID))
        return
    end

    ax.database:Select("ax_items", nil, "character_id = " .. characterID .. " OR character_id = 0", function(result)
        if ( !result or #result == 0 ) then
            ax.util:PrintWarning("No items found for character ID " .. characterID)
            if ( callback ) then
                callback({})
            end
            return
        end

        for _, row in ipairs(result) do
            local itemID = tonumber(row.id)
            local uniqueID = row.unique_id

            if ( self.stored[uniqueID] ) then
                local item = self:CreateObject(row)
                if ( !item ) then
                    ax.util:PrintError("Failed to create object for item #" .. itemID .. ", skipping")
                    continue
                end

                if ( item:GetOwner() == 0 ) then
                    local inventory = ax.inventory:Get(item:GetInventory())
                    if ( inventory ) then
                        local newCharID = inventory:GetOwner()
                        item:SetOwner(newCharID)

                        ax.database:Update("ax_items", {
                            character_id = newCharID
                        }, "id = " .. itemID)
                    else
                        ax.util:PrintError("Invalid orphaned item #" .. itemID .. " (no inventory)")
                        ax.database:Delete("ax_items", "id = " .. itemID)
                        continue
                    end
                end

                self.instances[itemID] = item

                if ( item.OnCache ) then
                    item:OnCache()
                end
            else
                ax.util:PrintError("Unknown item unique ID '" .. tostring(uniqueID) .. "' in DB, skipping")
            end
        end

        local instanceList = {}
        for _, item in pairs(self.instances) do
            if ( item:GetOwner() == characterID ) then
                table.insert(instanceList, {
                    ID = item:GetID(),
                    UniqueID = item:GetUniqueID(),
                    Data = item:GetData(),
                    InventoryID = item:GetInventory()
                })
            end
        end

        local client = ax.character:GetPlayerByCharacter(characterID)
        if ( IsValid(client) ) then
            ax.net:Start(client, "item.cache", instanceList)
        end

        if ( callback ) then
            callback(instanceList)
        end
    end)
end

--- Completely removes an item from the inventory system.
-- Deletes the item from the database, removes it from inventory, and clears it from memory.
-- @param itemID The item ID to remove.
-- @param callback Optional function to call after removal.
function ax.item:Remove(itemID, callback)
    local item = self.instances[itemID]
    if ( !item ) then
        ax.util:PrintError("Invalid item ID for removal: " .. tostring(itemID))
        return false
    end

    local inventoryID = item:GetInventory()
    local inventory = ax.inventory:Get(inventoryID)

    -- Remove from inventory object
    if ( inventory ) then
        ax.inventory:RemoveItem(inventoryID, itemID)
    end

    -- Delete from database
    ax.database:Delete("ax_items", "id = " .. itemID)

    -- Notify client
    local client = ax.character:GetPlayerByCharacter(item:GetOwner())
    if ( IsValid(client) ) then
        ax.net:Start(client, "inventory.item.remove", inventoryID, itemID)
    end

    -- Remove from memory
    self.instances[itemID] = nil

    hook.Run("OnItemRemovedPermanently", itemID)

    if ( callback ) then
        callback(itemID)
    end

    return true
end

function ax.item:Spawn(itemID, uniqueID, position, angles, callback, data)
    if ( !uniqueID or !position or !self.stored[uniqueID] ) then
        ax.util:PrintError("Invalid parameters for item spawn.")
        return nil
    end

    local entity = ents.Create("ax_item")
    if ( !IsValid(entity) ) then
        ax.util:PrintError("Failed to create item entity for unique ID '" .. uniqueID .. "'.")
        return nil
    end

    if ( IsValid(position) and position:IsPlayer() ) then
        position = position:GetDropPosition()
        angles = position:GetAngles()
    elseif ( !isvector(position) ) then
        ax.util:PrintError("Invalid position provided for item spawn: " .. tostring(position))
        return nil
    end

    entity:SetPos(position)
    entity:SetAngles(angles or angle_zero)
    entity:Spawn()
    entity:Activate()
    entity:SetItem(itemID, uniqueID)
    entity:SetData(data or {})

    if ( callback ) then
        callback(entity)
    end

    return entity
end

concommand.Add("ax_item_add", function(client, cmd, arguments)
    if ( !client:IsAdmin() ) then
        client:Notify("You do not have permission to use this command!")
        return
    end

    local uniqueID = arguments[1]
    if ( !uniqueID or !ax.item.stored[uniqueID] ) then
        client:Notify("Invalid item unique ID specified.")
        return
    end

    local characterID = client:GetCharacterID()
    local inventories = ax.inventory:GetByCharacterID(characterID)
    if ( #inventories == 0 ) then
        client:Notify("No inventories found for character ID " .. characterID .. ".")
        return
    end

    local inventoryID = inventories[1]:GetID()

    ax.item:Add(characterID, inventoryID, uniqueID, nil, function(itemID)
        client:Notify("Item " .. uniqueID .. " added to inventory " .. inventoryID .. ".")
    end)
end)

concommand.Add("ax_item_spawn", function(client, cmd, arguments)
    if ( !client:IsAdmin() ) then
        client:Notify("You do not have permission to use this command!")
        return
    end

    local uniqueID = arguments[1]
    if ( !uniqueID ) then
        client:Notify("You must specify an item unique ID to spawn.")
        return
    end

    local pos = client:GetEyeTrace().HitPos + vector_up * 10

    ax.item:Spawn(nil, uniqueID, pos, nil, function(ent)
        if ( IsValid(ent) ) then
            client:Notify("Item " .. uniqueID .. " spawned.")
        else
            client:Notify("Failed to spawn item " .. uniqueID .. ".")
        end
    end)
end)