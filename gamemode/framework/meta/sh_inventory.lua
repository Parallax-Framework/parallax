--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local inventory = ax.inventory.meta or {}
inventory.__index = inventory

--- Returns a human-readable string representation of the inventory.
-- Format: `"Inventory [id]"`. Useful for debug output and logging.
-- @realm shared
-- @return string A formatted string identifying this inventory.
function inventory:__tostring()
    return string.format("Inventory [%s]", tostring(self.id or 0))
end

--- Returns the maximum weight capacity of this inventory.
-- This is the value set when the inventory was created or loaded.
-- Items cannot be added when `GetWeight() + item.weight > GetMaxWeight()`.
-- @realm shared
-- @return number The maximum weight this inventory can hold.
function inventory:GetMaxWeight()
    return self.maxWeight
end

--- Calculates and returns the total weight of all items currently in the inventory.
-- Iterates `self.items` and sums the weight of each item by calling `item:GetWeight()` if it exists, otherwise reading `item.weight` directly.
-- Only positive weight values are counted; items with no weight or negative weight contribute 0. Returns 0 for an empty inventory.
-- @realm shared
-- @return number The total weight of all items in the inventory.
function inventory:GetWeight()
    local weight = 0
    for k, v in pairs(self.items) do
        if ( istable(v) ) then
            local itemWeight

            if ( isfunction(v.GetWeight) ) then
                itemWeight = tonumber(v:GetWeight())
            else
                itemWeight = tonumber(v.weight)
            end

            if ( isnumber(itemWeight) and itemWeight > 0 ) then
                weight = weight + itemWeight
            end
        end
    end

    return weight
end

--- Returns the unique ID of this inventory.
-- This is the primary key from the `ax_inventories` table (or a negative temporary ID for in-memory-only inventories).
-- @realm shared
-- @return number The inventory's numeric ID.
function inventory:GetID()
    return self.id
end

--- Returns the items table for this inventory.
-- The returned table is keyed by item ID (number) and valued by item instance tables. Returns an empty table when the inventory has no items loaded.
-- @realm shared
-- @return table The `{ [itemID] = itemObject }` items table.
function inventory:GetItems()
    return self.items or {}
end

--- Returns all items in the inventory that match a given base class name.
-- Checks each item's registered class entry in `ax.item.stored` for either a `base` field or `class` field matching `baseName`. When `includeInactive` is explicitly `false`, items with `data.inactive == true` are excluded.
-- Returns an empty table when no matches are found or `baseName` is invalid.
-- @realm shared
-- @param baseName string The base class name to filter by.
-- @param includeInactive boolean|nil When false, inactive items are excluded. Defaults to including all items regardless of active state.
-- @return table An ordered array of matching item instances.
function inventory:GetItemsByBase(baseName, includeInactive)
    if ( !isstring(baseName) or baseName == "" ) then return {} end

    local results = {}
    for id, item in pairs(self.items or {}) do
        if ( istable(item) ) then
            local stored = ax.item.stored[item.class]

            -- Match either an explicit base field or the stored class name for base items
            if ( istable(stored) and ( stored.base == baseName or stored.class == baseName ) ) then
                local include = true

                if ( includeInactive == false ) then
                    local inactive = false

                    if ( isfunction(item.GetData) ) then
                        inactive = ( item:GetData("inactive") == true )
                    elseif ( istable(item.data) ) then
                        inactive = ( item.data.inactive == true )
                    end

                    if ( inactive ) then
                        include = false
                    end
                end

                if ( include ) then
                    results[#results + 1] = item
                end
            end
        end
    end

    return results
end

--- Returns the item instance with the given ID, or nil if not found.
-- Performs a linear search through `self.items`. For large inventories, consider caching the result. Returns nil when no item with that ID exists.
-- @realm shared
-- @param itemID number The numeric item ID to look up.
-- @return table|nil The item instance, or nil if not found.
function inventory:GetItemByID(itemID)
    for id, v in pairs(self.items) do
        if ( id == itemID ) then
            return v
        end
    end

    return nil
end

--- Counts items in the inventory matching an ID or class name.
-- When `itemID` is a number, counts items whose key matches that ID (0 or 1).
-- When `itemID` is a string, counts all items whose `class` field matches it (useful for stackable or multi-instance items sharing the same class).
-- @realm shared
-- @param itemID number|string The item ID (number) or class name (string) to count.
-- @return number The number of matching items.
function inventory:GetItemCount(itemID)
    local count = 0
    for id, v in pairs(self.items) do
        if ( type(itemID) == "number" and id == itemID ) then
            count = count + 1
        elseif ( type(itemID) == "string" and v.class == itemID ) then
            count = count + 1
        end
    end

    return count
end

--- Returns the list of players who receive inventory network updates.
-- Receivers are players who should be notified of item additions, removals, and data changes (e.g. the character owner and any observers). Returns an empty table when no receivers have been registered.
-- @realm shared
-- @return table An ordered array of player entities.
function inventory:GetReceivers()
    return self.receivers or {}
end

--- Returns the character that owns this inventory.
-- Searches all loaded character instances in `ax.character.instances` for one whose `vars.inventory` matches this inventory's ID. Returns the first match, or nil if no character claims this inventory (e.g. unassigned or temporary inventories).
-- @realm shared
-- @return table|nil The owning character instance, or nil if not found.
function inventory:GetOwner()
    for k, v in pairs(ax.character.instances) do
        local characterInventoryID = v and v.vars and v.vars.inventory
        if ( characterInventoryID != nil and tostring(characterInventoryID) == tostring(self.id) ) then
            return v
        end
    end

    return nil
end

--- Returns the first item matching the given ID or class name, or false if none found.
-- Accepts either a numeric item ID (matches the inventory key directly) or a string class name (matches `item.class` on each entry). Returns the item instance table on success so callers can immediately act on it without a second lookup. Returns false when no item matches, making it safe to use in boolean conditions.
-- @realm shared
-- @param identifier number|string The item ID (number) or class name (string) to find.
-- @return table|false The matching item instance, or false if not found.
-- @usage if ( inventory:HasItem("weapon_pistol") ) then ... end
-- @usage local item = inventory:HasItem(42)
function inventory:HasItem(identifier)
    for id, v in pairs(self.items) do
        if ( isnumber(identifier) and id == identifier ) then
            return v
        elseif ( isstring(identifier) and v.class == identifier ) then
            return v
        end
    end

    return false
end

--- Returns the first item whose class matches the given base name, or false if none found.
-- Checks each item's registered class entry in `ax.item.stored` for either a `base` field or `class` field equal to `baseName`. Unlike `GetItemsByBase`, this stops at the first match and is intended for simple existence checks rather than collecting all matches. Returns false immediately when `baseName` is empty or non-string.
-- @realm shared
-- @param baseName string The base class name to check against.
-- @return table|false The first matching item instance, or false if none found.
-- @usage if ( inventory:HasItemOfBase("base_weapon") ) then ... end
function inventory:HasItemOfBase(baseName)
    if ( !isstring(baseName) or baseName == "" ) then return false end

    for id, item in pairs(self.items or {}) do
        if ( istable(item) ) then
            local stored = ax.item.stored[item.class]

            if ( istable(stored) and ( stored.base == baseName or stored.class == baseName ) ) then
                return item
            end
        end
    end

    return false
end

--- Returns whether the given player is registered as a receiver for this inventory.
-- If `self.receivers` has not been initialised, it is created and the owning character's player is automatically added as the first receiver before the check runs. This lazy-init behaviour ensures that the owner always receives updates even if `AddReceiver` was never called explicitly. Returns true if `client` is found in the receivers list, false otherwise.
-- @realm shared
-- @param client Player The player entity to test.
-- @return boolean True if `client` is in the receiver list.
function inventory:IsReceiver(client)
    if ( !istable(self.receivers) ) then
        self.receivers = {}

        local owner = self:GetOwner()
        if ( owner ) then
            local ownerPlayer = owner:GetOwner()
            if ( IsValid(ownerPlayer) ) then
                self:AddReceiver(ownerPlayer)
            end
        end
    end

    for i = 1, #self.receivers do
        if ( self.receivers[i] == client ) then
            return true
        end
    end

    return false
end

--- Registers a player (or table of players) to receive network updates for this inventory.
-- When `receiver` is a table, iterates it in reverse order and adds each player individually, validating each entry via `ax.util:IsValidPlayer`. When `receiver` is a single player, it is resolved through `ax.util:FindPlayer` first. Duplicate entries are silently rejected (idempotent). On the server, broadcasts an `"inventory.receiver.add"` net message to all current receivers after each addition.
-- Returns false if the receiver is already registered, invalid, or cannot be resolved.
-- @realm shared
-- @param receiver Player|table A player entity or an array of player entities to add.
-- @return boolean True on success, false if the receiver was already present or invalid.
function inventory:AddReceiver(receiver)
    if ( !istable(self.receivers) ) then self.receivers = {} end

    if ( self.receivers[1] != nil ) then
        for i = 1, #self.receivers do
            if ( self.receivers[i] == receiver ) then
                return false -- Already exists.
            end
        end
    end

    if ( istable(receiver) ) then
        for i = #receiver, 1, -1 do
            if ( !ax.util:IsValidPlayer(receiver[i]) ) then
                ax.util:PrintError("Invalid player provided to ax.inventory:AddReceiver() (" .. tostring(receiver[i]) .. ")")
                return false
            end

            self.receivers[#self.receivers + 1] = receiver[i]

            if ( SERVER ) then
                ax.net:Start(self:GetReceivers(), "inventory.receiver.add", self, receiver)
            end

            return true
        end
    elseif ( ax.util:FindPlayer(receiver) ) then
        self.receivers[#self.receivers + 1] = receiver

        if ( SERVER ) then
            ax.net:Start(self:GetReceivers(), "inventory.receiver.add", self, receiver)
        end

        return true
    end

    return false
end

--- Removes a single player from the inventory's receiver list.
-- Searches the receivers array for `receiver` and removes it. On the server, broadcasts an `"inventory.receiver.remove"` net message to all remaining receivers before removing the entry. Returns false if the receivers list is empty or `receiver` is not found; returns true on successful removal.
-- @realm shared
-- @param receiver Player The player entity to remove from the receiver list.
-- @return boolean True on successful removal, false if not found.
function inventory:RemoveReceiver(receiver)
    if ( !istable(self.receivers) ) then self.receivers = {} return end
    if ( self.receivers[1] == nil ) then return false end

    for i = 1, #self.receivers do
        if ( self.receivers[i] == receiver ) then
            if ( SERVER ) then
                ax.net:Start(self:GetReceivers(), "inventory.receiver.remove", self.id, receiver)
            end

            table.remove(self.receivers, i)

            return true
        end
    end

    return false
end

--- Removes all players from the inventory's receiver list.
-- On the server, broadcasts an `"inventory.receiver.remove"` net message for each current receiver before clearing the list. After the call `self.receivers` is reset to an empty table. Returns false immediately if the list is already empty; returns true after a successful clear.
-- @realm shared
-- @return boolean True after clearing, false if the list was already empty.
function inventory:RemoveReceivers()
    if ( !istable(self.receivers) ) then self.receivers = {} return end
    if ( self.receivers[1] == nil ) then return false end

    if ( SERVER ) then
        for i = 1, #self.receivers do
            ax.net:Start(self:GetReceivers(), "inventory.receiver.remove", self.id, self.receivers[i])
        end
    end

    self.receivers = {}
    return true
end

--- Returns whether the given weight can be added without exceeding capacity.
-- Computes `GetWeight() + weight` and compares it against `GetMaxWeight()`. Returns true when the addition fits, or false and an error string when it would overflow.
-- Use this before manually adjusting weights; `CanStoreItem` already calls this internally when an item has a weight field.
-- @realm shared
-- @param weight number The additional weight to test against remaining capacity.
-- @return boolean True if the weight fits, false otherwise.
-- @return string|nil A human-readable reason string when returning false.
function inventory:CanStoreWeight(weight)
    local currentWeight = self:GetWeight()
    local maxWeight = self:GetMaxWeight()

    if ( currentWeight + weight > maxWeight ) then
        return false, "This inventory cannot hold that much weight."
    end

    return true
end

--- Returns whether an item of the given class can be stored in this inventory.
-- Performs three checks in order:
-- 1. Validates that `itemClass` is registered in `ax.item.stored`.
-- 2. Checks weight capacity if `itemData.weight` is set (delegates to `CanStoreWeight`).
-- 3. Calls `itemData:CanAddToInventory(self)` if defined — returning false from that hook blocks storage regardless of weight.
-- Returns true on success, or false and a descriptive reason string on failure.
-- Called automatically by `AddItem` before any database operations.
-- @realm shared
-- @param itemClass string The item class name to test (must exist in `ax.item.stored`).
-- @return boolean True if the item can be stored, false otherwise.
-- @return string|nil A human-readable reason string when returning false.
function inventory:CanStoreItem(itemClass)
    local itemData = ax.item.stored[itemClass]
    if ( !istable(itemData) ) then
        return false, "Invalid item class."
    end

    if ( itemData.weight and self:GetWeight() + itemData.weight > self:GetMaxWeight() ) then
        return false, "This inventory cannot hold that much weight."
    end

    if ( isfunction(itemData.CanAddToInventory) and itemData:CanAddToInventory(self) == false ) then
        return false, "This inventory cannot store that item."
    end

    return true
end

if ( SERVER ) then
    --- Adds a new item of the given class to this inventory and persists it to the database.
    -- Validates that `class` exists in `ax.item.stored` and passes `CanStoreItem` before proceeding. For temporary or no-save inventories (`self.isTemporary` or `self.noSave`), the item is created in memory only with a negative auto-decrementing ID and is never written to the database. For persistent inventories, an INSERT query is issued to `ax_items`; the `callback` is invoked with the new item instance once the query completes. On success, broadcasts `"inventory.item.add"` to all receivers.
    -- Returns false and a reason string on validation failure.
    -- @realm server
    -- @param class string The item class name to instantiate (must exist in `ax.item.stored`).
    -- @param data table|nil Initial item data to store in `itemObject.data`. Defaults to `{}`.
    -- @param callback function|nil Called as `callback(itemObject)` after the item is created.
    -- @return boolean|nil False on validation failure; nil on async DB path (result via callback).
    -- @return string|nil A human-readable reason string when returning false.
    function inventory:AddItem(class, data, callback)
        if ( !istable(self.items) ) then self.items = {} end

        local item = ax.item.stored[class]
        if ( !istable(item) ) then
            ax.util:PrintError("Invalid item provided to ax.inventory:AddItem() (" .. tostring(class) .. ")")
            return false, "Invalid item class."
        end

        local canStore, reason = self:CanStoreItem(class)
        if ( !canStore ) then
            return false, reason or "This inventory cannot store that item."
        end

        data = data or {}

        if ( self.isTemporary or self.noSave ) then
            ax.item._nextTemporaryID = ax.item._nextTemporaryID or -1

            while ( ax.item.instances[ax.item._nextTemporaryID] != nil ) do
                ax.item._nextTemporaryID = ax.item._nextTemporaryID - 1
            end

            local temporaryItemID = ax.item._nextTemporaryID
            ax.item._nextTemporaryID = temporaryItemID - 1

            local itemObject = ax.item:Instance(temporaryItemID, class)
            if ( !istable(itemObject) ) then
                return false, "Failed to create temporary item instance."
            end

            itemObject.data = istable(data) and table.Copy(data) or {}
            itemObject.invID = self.id
            itemObject.isTemporary = true
            itemObject.noSave = true

            ax.item.instances[temporaryItemID] = itemObject
            self.items[temporaryItemID] = itemObject

            if ( isfunction(callback) ) then
                callback(itemObject)
            end

            return true, "Item added to inventory."
        end

        local query = mysql:Insert("ax_items")
            query:Insert("class", class)
            query:Insert("inventory_id", self.id)
            query:Insert("data", util.TableToJSON(data))
            query:Callback(function(result, status, lastID)
                if ( result == false ) then
                    ax.util:PrintError("Failed to insert item into database for inventory " .. self.id)
                    return false, "Failed to add item to inventory, DB error."
                end

                local itemObject = ax.item:Instance(lastID, class)
                itemObject.data = data or {}
                itemObject.invID = self.id

                ax.item.instances[lastID] = itemObject

                self.items[lastID] = itemObject

                ax.net:Start(self:GetReceivers(), "inventory.item.add", self.id, itemObject.id, itemObject.class, itemObject.data)

                if ( isfunction(callback) ) then
                    callback(itemObject)
                end

                return true, "Item added to inventory."
            end)
        query:Execute()
    end

    --- Removes an item from this inventory by ID or class name and deletes it from the database.
    -- When `itemID` is a string class name, the first matching item's numeric ID is resolved before removal. For temporary or no-save inventories (or items flagged as such), the item is removed from `self.items` and `ax.item.instances` immediately with no database call. For persistent items, a DELETE query is issued to `ax_items` and, on success, broadcasts `"inventory.item.remove"` to all receivers and removes the item from in-memory tables. Returns false when no matching item is found.
    -- @realm server
    -- @param itemID number|string The numeric item ID or string class name to remove.
    -- @return boolean True on success (or async DB path), false if the item was not found.
    function inventory:RemoveItem(itemID)
        if ( !istable(self.items) ) then
            ax.util:PrintWarning("Invalid inventory items table.")
            self.items = {}
            return
        end

        if ( isstring(itemID) and ax.item.stored[itemID] ) then
            for _, v in pairs(self.items) do
                if ( v.class == itemID ) then
                    itemID = v.id
                    break
                end
            end
        end

        ax.util:PrintDebug("Attempting to remove item ID " .. tostring(itemID) .. " from inventory " .. self.id)

        for item_id, item_data in pairs(self.items) do
            if ( item_id == itemID ) then
                if ( self.isTemporary or self.noSave or ( istable(item_data) and (item_data.isTemporary or item_data.noSave) ) ) then
                    self.items[item_id] = nil
                    ax.item.instances[itemID] = nil

                    ax.util:PrintDebug("Removed temporary item ID " .. tostring(itemID) .. " from inventory " .. tostring(self.id))

                    return true
                end

                local query = mysql:Delete("ax_items")
                    query:Where("id", itemID)
                    query:Callback(function(result, status)
                        if ( result == false ) then
                            ax.util:PrintError("Failed to remove item from database for inventory " .. self.id)
                            return false, "Failed to remove item from inventory, DB error."
                        end

                        self.items[item_id] = nil
                        ax.item.instances[itemID] = nil

                        ax.net:Start(self:GetReceivers(), "inventory.item.remove", self.id, itemID)

                        ax.util:PrintDebug("Removed item ID " .. itemID .. " from inventory " .. self.id)

                        return true, "Item removed from inventory."
                    end)
                query:Execute()

                break
            end
        end

        return false
    end
end

ax.inventory.meta = inventory
