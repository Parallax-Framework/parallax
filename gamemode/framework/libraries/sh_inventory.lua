--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Inventory management system for creating, storing, and retrieving inventory data.
-- Supports item storage, weight limits, and synchronization between server and clients.
-- @module ax.inventory

ax.inventory = ax.inventory or {}
ax.inventory.meta = ax.inventory.meta or {}
ax.inventory.instances = ax.inventory.instances or {}

--- Candidate index for `ItemOwnsInventory`: `itemID -> inventoryID` for inventories
-- with `ownerKind == "item"`. A candidate only - entries are never actively removed
-- when an inventory is disposed of (disposal happens from many call sites, several
-- of them client-only, and this stays a shared-realm file), so every read re-verifies
-- the candidate against the live instance and self-heals by dropping stale entries.
-- @realm shared
ax.inventory.itemOwnerIndex = ax.inventory.itemOwnerIndex or {}

--- Registry of owner resolvers. `owner_kind`/`owner_id` are unavoidably strings/numbers
-- in the database, but nothing above the database layer should ever type one of those
-- strings by hand - a typo'd `"charcter"` would silently create an unreachable
-- inventory. Instead, every owner-facing API (`Create`, `RestoreOwner`) takes the
-- actual owner object (a character, an item, an entity, ...)
-- and resolves it through this registry via metatable identity, the same way
-- `ax.type:Detect` resolves Lua values to type IDs.
-- @realm shared
ax.inventory.ownerResolvers = ax.inventory.ownerResolvers or {}

--- Registers an owner resolver.
-- @realm shared
-- @param def table `{ kind = string, checkOwner = function(owner) -> boolean, getOwner = function(owner) -> number, resolveOwner = function(ownerID) -> any }`. `kind` is the `owner_kind` string this resolver produces (e.g. `"character"`, `"item"`, `"entity"`); `checkOwner` recognises whether a value is this kind of owner; `getOwner` extracts the stable id to persist as `owner_id`. For entity owners this must be a persistent id (survives a restart), never `Entity:EntIndex()`. `resolveOwner` is the inverse - given that id, returns the live owner object again (or nil if it isn't loaded) - it powers `inventory:GetOwner()`. Optional: omitting it just means `GetOwner()` can't resolve that kind back to an object.
function ax.inventory:RegisterOwnerResolver(def)
    if ( !istable(def) or !isstring(def.kind) or def.kind == "" or !isfunction(def.checkOwner) or !isfunction(def.getOwner) ) then
        ax.util:PrintError("Invalid owner resolver registration for kind '" .. tostring(def and def.kind) .. "'.")
        return
    end

    self.ownerResolvers[def.kind] = def
end

--- Resolves an `(ownerKind, ownerID)` pair back to the live owner object, via the
-- `resolveOwner` callback of the resolver registered for `ownerKind` - the inverse of
-- `ResolveOwner`. Returns nil if `ownerKind` is nil, unregistered, or its resolver didn't
-- provide a `resolveOwner` callback (e.g. some `"entity"` resolvers, where the owner may
-- no longer exist in the world).
-- @realm shared
-- @param ownerKind string|nil
-- @param ownerID number|nil
-- @return any|nil The owner object, or nil if it can't be resolved.
function ax.inventory:ResolveOwnerObject(ownerKind, ownerID)
    if ( ownerKind == nil or ownerID == nil ) then return nil end

    local resolver = self.ownerResolvers[ownerKind]
    if ( !istable(resolver) or !isfunction(resolver.resolveOwner) ) then return nil end

    return resolver.resolveOwner(ownerID)
end

--- Resolves an owner object to its `(ownerKind, ownerID)` pair via the registered
-- resolvers. Passing `nil` is valid and yields `nil, nil` (an ownerless/legacy
-- inventory - back-compat for code that never had an owner concept).
-- @realm shared
-- @param owner any A character, item, entity, or anything a registered resolver recognises.
-- @return string|nil ownerKind
-- @return number|nil ownerID
-- @usage local kind, id = ax.inventory:ResolveOwner(character) -- "character", character:GetID()
function ax.inventory:ResolveOwner(owner)
    if ( owner == nil ) then return nil, nil end

    for kind, resolver in pairs(self.ownerResolvers) do
        if ( resolver.checkOwner(owner) ) then
            return kind, resolver.getOwner(owner)
        end
    end

    ax.util:PrintError("ax.inventory:ResolveOwner() could not resolve an owner kind for " .. tostring(owner) .. " - no resolver recognised it.")

    return nil, nil
end

-- Built-in resolvers for the two owner kinds the core itself knows about. Entity-backed
-- owners (world containers, ...) are deliberately not covered here - only the module that
-- creates those entities knows how to derive a persistent id for one, so it registers its
-- own "entity" resolver (see modules/containers).
ax.inventory:RegisterOwnerResolver({
    kind = "character",
    checkOwner = function(owner)
        return istable(owner) and getmetatable(owner) == ax.character.meta
    end,
    getOwner = function(owner)
        return owner:GetID()
    end,
    resolveOwner = function(ownerID)
        return ax.character.instances[ownerID]
    end,
})

-- Item instances don't sit directly on ax.item.meta - ax.item:Instance() wraps them in
-- their own {__index = storedClass} table, and base-inherited classes chain to
-- ax.item.meta through a function __index, so metatable identity can't be checked
-- directly. Instead this confirms `owner` is the exact tracked instance for its id.
ax.inventory:RegisterOwnerResolver({
    kind = "item",
    checkOwner = function(owner)
        return istable(owner) and isnumber(owner.id) and ax.item.instances[owner.id] == owner
    end,
    getOwner = function(owner)
        return owner:GetID()
    end,
    resolveOwner = function(ownerID)
        return ax.item.instances[ownerID]
    end,
})

--- Whether `client` may modify (not merely view/receive sync for) `inventory`, per the
-- core's one built-in rule (an owner-character may modify their own inventories) plus
-- the inventory type's own `CanAccess` rule (distance, locks, faction/rank, ...).
-- Called by `ax.item:Transfer` on both transfer endpoints. Receiver/sync visibility is
-- a separate concept and does not go through this.
-- @realm shared
-- @param inventory table
-- @param client Player
-- @return boolean
function ax.inventory:CanAccess(inventory, client)
    if ( !istable(inventory) ) then return false end
    if ( inventory.id == 0 ) then return true end -- World: Transfer's own callers gate this (entity validity/distance).
    if ( !ax.util:IsValidPlayer(client) ) then return false end

    if ( inventory.ownerKind == "character" ) then
        local character = client:GetCharacter()
        if ( istable(character) and tostring(character:GetID()) == tostring(inventory.ownerID) ) then
            return true
        end
    elseif ( inventory.ownerKind == nil ) then
        -- No owner_kind recorded yet (pre-backfill) - fall back to the legacy
        -- primary-inventory column instead of allowing unconditionally.
        local character = client:GetCharacter()
        if ( istable(character) and character:GetInventoryID() == inventory.id ) then
            return true
        end
    end

    -- Modules may grant additional modify access (e.g. an active search session on a restrained player's inventory) without the inventory type knowing; grant-only, a falsy return changes nothing.
    if ( hook.Run("CanPlayerAccessInventory", client, inventory) == true ) then
        return true
    end

    local typeDef = self:GetType(inventory)
    if ( istable(typeDef) and isfunction(typeDef.CanAccess) ) then
        return typeDef.CanAccess(inventory, client) == true
    end

    return false
end

--- Whether `itemID` owns an inventory (e.g. a bag/container item) - i.e. some
-- inventory instance has `ownerKind == "item"` and `ownerID == itemID`. Used by
-- `ax.item:Transfer` to enforce the depth-1 nesting rule: a bag can never end up
-- inside another inventory that is itself nested inside an item.
--
-- O(1) via `itemOwnerIndex` instead of scanning every live inventory - this is
-- called on every Transfer into an item-owned inventory, so its cost must not
-- scale with how many inventories exist on the server.
-- @realm shared
-- @param itemID number
-- @return boolean
function ax.inventory:ItemOwnsInventory(itemID)
    local inventoryID = self.itemOwnerIndex[itemID]
    if ( inventoryID == nil ) then return false end

    local inventory = self.instances[inventoryID]
    if ( !istable(inventory) or inventory.ownerKind != "item" or tostring(inventory.ownerID) != tostring(itemID) ) then
        self.itemOwnerIndex[itemID] = nil

        return false
    end

    return true
end

ax.inventory.instances[0] = setmetatable({
    id = 0,
    items = {},
    maxWeight = 0.0,
    GetReceivers = function(self)
        local receivers = {}
        for k, v in player.Iterator() do
            receivers[#receivers + 1] = v
        end

        return receivers
    end,
    HasReceiver = function(self, client)
        return true
    end,
}, ax.inventory.meta)

--- Returns a live inventory instance by ID, the canonical read-side counterpart to `ax.inventory:Create` - ID `0` is the world (dropped items) and always resolves, temporary inventories use negative IDs, and an inventory that exists in the database but has not been restored yet resolves to nil.
-- An inventory instance passed straight through is returned as-is, so callers holding either an ID or an instance can normalise with one call.
---@realm shared
---@param id number|table The inventory ID, or an inventory instance to pass through.
---@return table|nil inventory The inventory instance, or nil when it is not loaded.
---@usage local inventory = ax.inventory:Get(character:GetInventoryID())
function ax.inventory:Get(id)
    if ( istable(id) ) then
        return getmetatable(id) == self.meta and id or nil
    end

    id = tonumber(id)
    if ( id == nil ) then return nil end

    return self.instances[id]
end

--- Returns the inventory type (and its instance data) new inventories are created with when
-- `ax.inventory:Create`/`CreateTemporary` is called without an explicit `typeID` - e.g. a
-- character's primary inventory (`vars.inventory`, created via `ax.inventory:Create({ owner =
-- character })`). Reads `SCHEMA.defaultInventoryType`/`SCHEMA.defaultInventoryData` - declare
-- these once in `schema/boot.lua`, the same convention as `SCHEMA.name`/`SCHEMA.author` - falling
-- back to `"weight"`/`{}` if the schema never sets them, so schemas that never opt in see zero
-- behaviour change.
-- @realm shared
-- @return string typeID
-- @return table data Instance data (e.g. `{ width = 8, height = 6 }`), may include `maxWeight`.
-- Falls back to `"weight"` with a warning if `SCHEMA.defaultInventoryType` names a type that was
-- never registered via `ax.inventory:RegisterType` (e.g. a typo, or the registering file hasn't
-- loaded yet) - never silently creates inventories of a type that doesn't exist.
-- @usage -- schema/boot.lua
-- @usage SCHEMA.defaultInventoryType = "character_grid"
-- @usage SCHEMA.defaultInventoryData = { width = 8, height = 6 }
function ax.inventory:GetDefaultType()
    local data = ( SCHEMA and istable(SCHEMA.defaultInventoryData) ) and SCHEMA.defaultInventoryData or {}
    local typeID = ( SCHEMA and SCHEMA.defaultInventoryType ) or "weight"

    if ( !self.types[typeID] ) then
        ax.util:PrintWarning("SCHEMA.defaultInventoryType '" .. tostring(typeID) .. "' is not a registered inventory type, falling back to \"weight\"!")

        typeID = "weight"
        data = {}
    end

    return typeID, data
end

if ( SERVER ) then
    --- Creates a temporary in-memory inventory instance (no database persistence).
    -- @realm server
    -- @param data table Optional data table. Recognised keys: `id`, `maxWeight`, `typeID`
    -- (defaults to `"weight"`), `owner` (resolved via `ax.inventory:ResolveOwner`), `data`
    -- (instance data).
    -- @param callback function|nil Optional callback function called with the created inventory.
    function ax.inventory:CreateTemporary(data, callback)
        data = data or {}

        local inventoryID = data.id
        if ( inventoryID == nil ) then
            self._nextTemporaryID = self._nextTemporaryID or -1
            inventoryID = self._nextTemporaryID

            while ( self.instances[inventoryID] != nil ) do
                inventoryID = inventoryID - 1
            end

            self._nextTemporaryID = inventoryID - 1
        end

        local existing = self.instances[inventoryID]
        if ( istable(existing) and existing.isTemporary and istable(existing.items) and istable(ax.item) and istable(ax.item.instances) ) then
            for itemID in pairs(existing.items) do
                ax.item.instances[itemID] = nil
            end
        end

        local usingDefaultType = data.typeID == nil
        local schemaTypeID, schemaTypeData = self:GetDefaultType()
        local typeID = data.typeID or schemaTypeID
        local instanceData = istable(data.data) and data.data or (usingDefaultType and table.Copy(schemaTypeData) or {})

        local defaultWeight = 30.0
        if ( ax.config and isfunction(ax.config.Get) ) then
            defaultWeight = tonumber(ax.config:Get("inventory.weight.max", defaultWeight)) or defaultWeight
        end

        if ( usingDefaultType and isnumber(schemaTypeData.maxWeight) ) then
            defaultWeight = schemaTypeData.maxWeight
        end

        local ownerKind, ownerID = self:ResolveOwner(data.owner)

        local inventory = setmetatable({}, ax.inventory.meta)
        inventory.id = inventoryID
        inventory.items = {}
        inventory.maxWeight = tonumber(data.maxWeight) or defaultWeight
        inventory.receivers = {}
        inventory.isTemporary = true
        inventory.noSave = true
        inventory.typeID = typeID
        inventory.ownerKind = ownerKind
        inventory.ownerID = ownerID
        inventory.data = instanceData

        self.instances[inventoryID] = inventory

        if ( isfunction(callback) ) then
            callback(inventory)
        end

        return inventory
    end

    --- Creates a new inventory in the database and returns the inventory object via callback.
    -- Back-compat: called with no `typeID`/`owner` (or `data` at all), this creates
    -- exactly the weight-limited, ownerless inventory `ax.inventory:Create` has always
    -- created. `typeID`/`owner`/instance `data` are additive - existing callers are
    -- unaffected.
    -- @realm server
    -- @param data table Optional data table. Recognised keys: `maxWeight`, `typeID`
    -- (defaults to `SCHEMA.defaultInventoryType`, itself `"weight"` unless the schema sets it -
    -- see `ax.inventory:GetDefaultType`), `owner` (a character/item/entity object - resolved via
    -- `ax.inventory:ResolveOwner`, never pass a raw owner_kind string), `data` (instance
    -- data - grid size, slot set - stored on the inventory, see `GetData`).
    -- @param callback function|nil Optional callback function called with the created inventory or false on failure.
    function ax.inventory:Create(data, callback)
        data = data or {}

        local usingDefaultType = data.typeID == nil
        local schemaTypeID, schemaTypeData = self:GetDefaultType()
        local typeID = data.typeID or schemaTypeID
        local instanceData = istable(data.data) and data.data or (usingDefaultType and table.Copy(schemaTypeData) or {})
        local maxWeight = data.maxWeight or (usingDefaultType and schemaTypeData.maxWeight) or 30.0
        local ownerKind, ownerID = self:ResolveOwner(data.owner)

        local query = mysql:Insert("ax_inventories")
            query:Insert("max_weight", maxWeight)
            query:Insert("data", util.TableToJSON(instanceData))
            query:Insert("type_id", typeID)
            query:Insert("owner_kind", ownerKind)
            query:Insert("owner_id", ownerID)
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
                inventory.typeID = typeID
                inventory.ownerKind = ownerKind
                inventory.ownerID = ownerID
                inventory.data = instanceData

                ax.inventory.instances[lastInvId] = inventory

                if ( ownerKind == "item" and ownerID != nil ) then
                    ax.inventory.itemOwnerIndex[ownerID] = lastInvId
                end

                if ( isfunction(callback) ) then
                    callback(inventory)
                end
            end)
        query:Execute()
    end

    --- Restores every inventory owned by `owner` from the database, items included. A
    -- character has as many owned inventories as it was created with (main grid,
    -- equipment, ...) - this is how they're all found again on load, regardless of how
    -- many there are or what types they are.
    -- @realm server
    -- @param owner any A character/item/entity object - resolved via `ax.inventory:ResolveOwner`.
    -- @param callback function|nil Called with an array of restored inventories (possibly empty).
    function ax.inventory:RestoreOwner(owner, callback)
        local ownerKind, ownerID = self:ResolveOwner(owner)
        if ( ownerKind == nil or ownerID == nil ) then
            if ( isfunction(callback) ) then callback({}) end
            return
        end

        local query = mysql:Select("ax_inventories")
            query:Where("owner_kind", ownerKind)
            query:Where("owner_id", ownerID)
            query:Callback(function(result, status)
                if ( result == nil or status == false or result[1] == nil ) then
                    if ( isfunction(callback) ) then callback({}) end
                    return
                end

                local restored = {}
                local remaining = #result

                for i = 1, #result do
                    self:RestoreRow(result[i], function(inventory)
                        if ( inventory != false ) then
                            restored[#restored + 1] = inventory
                        end

                        remaining = remaining - 1

                        if ( remaining <= 0 and isfunction(callback) ) then
                            callback(restored)
                        end
                    end)
                end
            end)
        query:Execute()
    end

    --- Builds a live inventory instance (without items) from an `ax_inventories` row.
    -- Shared by `RestoreRow`/`RestoreRows` so the row-to-instance shape (type/owner/data
    -- columns) is defined once.
    -- @realm server
    -- @param row table A row from `ax_inventories` (as returned by the mysql library).
    -- @return table inventory The shell instance (`.items` not yet populated).
    -- @return table|nil typeDef The inventory's resolved type definition.
    local function BuildInventoryShell(row)
        local inventory = setmetatable({}, ax.inventory.meta)
        inventory.id = tonumber(row.id)
        inventory.maxWeight = tonumber(row.max_weight) or 30.0
        inventory.receivers = {}
        inventory.typeID = row.type_id or "weight"
        inventory.ownerKind = row.owner_kind
        inventory.ownerID = row.owner_id != nil and tonumber(row.owner_id) or nil
        inventory.data = ax.util:SafeParseTable(row.data) or {}

        return inventory, ax.inventory:GetType(inventory)
    end

    --- Populates an inventory shell's `.items` from a set of `ax_items` rows and
    -- publishes it to `self.instances`. Shared by `RestoreRow`/`RestoreRows` so the
    -- item-row-to-object shape (placement columns via the type's `ApplyItemRow`) is
    -- defined once regardless of whether the rows came from a per-inventory or a
    -- batched `WhereIn` query.
    -- @realm server
    -- @param inventory table The inventory shell from `BuildInventoryShell`.
    -- @param typeDef table|nil The inventory's resolved type definition.
    -- @param itemsResult table Rows from `ax_items` belonging to this inventory.
    local function ApplyItemRows(inventory, typeDef, itemsResult)
        local items = {}

        for i = 1, #itemsResult do
            local itemRow = itemsResult[i]
            if ( ax.item.stored[itemRow.class] ) then
                local itemObject = ax.item:Instance(tonumber(itemRow.id), itemRow.class)
                itemObject.invID = inventory.id
                itemObject.data = ax.util:SafeParseTable(itemRow.data) or {}

                if ( istable(typeDef) and isfunction(typeDef.ApplyItemRow) ) then
                    typeDef.ApplyItemRow(itemObject, ax.util:SafeParseTable(itemRow.placement) or {})
                end

                items[itemObject.id] = itemObject
            end
        end

        inventory.items = items

        ax.inventory.instances[inventory.id] = inventory

        if ( inventory.ownerKind == "item" and inventory.ownerID != nil ) then
            ax.inventory.itemOwnerIndex[inventory.ownerID] = inventory.id
        end
    end

    --- Restores a single `ax_inventories` row (plus its items) into a live inventory
    -- instance. Shared by `RestoreOwner`/`Restore` so the row-to-instance shape
    -- (type/owner/data columns, item placement columns) is defined once.
    -- @realm server
    -- @param row table A row from `ax_inventories` (as returned by the mysql library).
    -- @param callback function Called with the restored inventory instance, or `false`
    -- if the item fetch failed - always called exactly once so callers that count down
    -- across multiple rows (e.g. `RestoreOwner`) can rely on it, success or failure.
    function ax.inventory:RestoreRow(row, callback)
        local inventoryID = tonumber(row.id)

        local existing = self.instances[inventoryID]
        if ( istable(existing) and getmetatable(existing) == self.meta ) then
            if ( isfunction(callback) ) then callback(existing) end
            return
        end

        local inventory, typeDef = BuildInventoryShell(row)

        local itemQuery = mysql:Select("ax_items")
            itemQuery:Where("inventory_id", inventoryID)
            itemQuery:Callback(function(itemsResult, itemsStatus)
                if ( itemsResult == nil or itemsStatus == false ) then
                    ax.util:PrintError(string.format("Failed to restore items for inventory %d, aborting restore.", inventoryID))

                    if ( isfunction(callback) ) then callback(false) end

                    return
                end

                ApplyItemRows(inventory, typeDef, itemsResult)

                if ( isfunction(callback) ) then
                    callback(inventory)
                end
            end)
        itemQuery:Execute()
    end

    --- Batch-restores multiple `ax_inventories` rows (plus their items) using a single
    -- `WhereIn` items query instead of one items query per row. Used by `Restore` to
    -- load every inventory owned by any of a client's characters without the query
    -- count scaling with the number of inventories found.
    -- @realm server
    -- @param rows table Array of `ax_inventories` rows (as returned by the mysql library).
    -- @param callback function|nil Called once with an array of restored inventory
    -- instances (order not guaranteed to match `rows`). Already-live instances are
    -- resolved instantly and included without issuing any query for them.
    function ax.inventory:RestoreRows(rows, callback)
        if ( !istable(rows) or rows[1] == nil ) then
            if ( isfunction(callback) ) then callback({}) end
            return
        end

        local restored = {}
        local shells = {}
        local pendingIDs = {}

        for i = 1, #rows do
            local row = rows[i]
            local inventoryID = tonumber(row.id)

            local existing = self.instances[inventoryID]
            if ( istable(existing) and getmetatable(existing) == self.meta ) then
                restored[#restored + 1] = existing
            else
                local inventory, typeDef = BuildInventoryShell(row)

                shells[inventoryID] = { inventory = inventory, typeDef = typeDef }
                pendingIDs[#pendingIDs + 1] = inventoryID
            end
        end

        if ( pendingIDs[1] == nil ) then
            if ( isfunction(callback) ) then callback(restored) end
            return
        end

        local itemQuery = mysql:Select("ax_items")
            itemQuery:WhereIn("inventory_id", pendingIDs)
            itemQuery:Callback(function(itemsResult, itemsStatus)
                if ( itemsResult == nil or itemsStatus == false ) then
                    ax.util:PrintError(string.format("Failed to batch-restore items for %d inventories, aborting restore.", #pendingIDs))

                    if ( isfunction(callback) ) then callback(restored) end

                    return
                end

                local itemsByInventory = {}
                for i = 1, #itemsResult do
                    local itemRow = itemsResult[i]
                    local inventoryID = tonumber(itemRow.inventory_id)

                    local bucket = itemsByInventory[inventoryID]
                    if ( bucket == nil ) then
                        bucket = {}
                        itemsByInventory[inventoryID] = bucket
                    end

                    bucket[#bucket + 1] = itemRow
                end

                for i = 1, #pendingIDs do
                    local inventoryID = pendingIDs[i]
                    local shell = shells[inventoryID]

                    ApplyItemRows(shell.inventory, shell.typeDef, itemsByInventory[inventoryID] or {})

                    restored[#restored + 1] = shell.inventory
                end

                if ( isfunction(callback) ) then callback(restored) end
            end)
        itemQuery:Execute()
    end

    local function SyncInventoryNow(self, inventory)
        -- Base entry shape is exactly the pre-registry payload (id/class/data/inventoryID).
        -- Any additional fields (grid position, slot id, ...) are contributed by the
        -- inventory's own type via GetSyncFields, so this function never has to know
        -- what any given type's addressing looks like.
        local typeDef = ax.inventory:GetType(inventory)

        local items = {}
        if ( istable(inventory.items) ) then
            for _, v in pairs(inventory.items) do
                local entry = {
                    id = v.id,
                    class = v.class,
                    data = v.data or {},
                    inventoryID = v.invID,
                }

                if ( istable(typeDef) and isfunction(typeDef.GetSyncFields) ) then
                    typeDef.GetSyncFields(v, entry)
                end

                items[#items + 1] = entry
            end
        end

        -- typeID/instance data/owner fields are additive tail arguments - a receiver
        -- that never reads them (old client build) still gets a working weight-type sync.
        ax.net:Start(inventory:GetReceivers(), "inventory.sync", inventory.id, items, inventory.maxWeight, inventory.receivers or {}, inventory:GetTypeID(), inventory.data or {}, inventory.ownerKind, inventory.ownerID)

        self._syncState = self._syncState or {}
        local state = self._syncState[inventory.id] or {}
        state.lastSync = CurTime()
        self._syncState[inventory.id] = state

        ax.util:PrintDebug(string.format("Synchronized inventory %s with %d receivers.", tostring(inventory.id), #inventory:GetReceivers()))
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

        local useSyncScheduling = tobool(ax.config:Get("inventory.sync.delta", false))
        local debounce = math.max(tonumber(ax.config:Get("inventory.sync.debounce", 0.0)) or 0.0, 0)
        local minRefreshInterval = math.max(tonumber(ax.config:Get("inventory.sync.full_refresh_interval", 0.0)) or 0.0, 0)

        if ( !useSyncScheduling ) then
            SyncInventoryNow(self, inventory)
            return
        end

        self._syncState = self._syncState or {}
        local inventoryID = inventory.id
        local state = self._syncState[inventoryID] or {lastSync = 0}
        self._syncState[inventoryID] = state

        local now = CurTime()
        local nextSyncTime = math.max(now + debounce, (state.lastSync or 0) + minRefreshInterval)
        local delay = math.max(nextSyncTime - now, 0)
        local timerName = "ax.inventory.sync." .. tostring(inventoryID)

        if ( delay <= 0 ) then
            timer.Remove(timerName)
            SyncInventoryNow(self, inventory)
            return
        end

        timer.Create(timerName, delay, 1, function()
            local liveInventory = self.instances[inventoryID]
            if ( getmetatable(liveInventory) != ax.inventory.meta ) then
                return
            end

            SyncInventoryNow(self, liveInventory)
        end)
    end

    --- Restores all inventories associated with the client's characters from the database.
    -- @realm server
    -- @param client Player The player whose inventories should be restored.
    -- @usage ax.inventory:Restore(client)
    -- @internal
    function ax.inventory:Restore(client, callback)
        local characterIDs = {}
        local clientTable = client:GetTable()
        for k, v in pairs(clientTable.axCharacters) do
            characterIDs[#characterIDs + 1] = v.id
        end

        ax.util:PrintDebug(string.format("Found %d character IDs for %s", #characterIDs, client:SteamID64()))

        -- Sync all world items (inventory_id = 0) to the client
        local worldItems = {}
        for itemID, item in pairs(ax.item.instances) do
            if ( item.invID == 0 or item:GetInventoryID() == 0 ) then
                worldItems[#worldItems + 1] = {
                    id = itemID,
                    class = item.class,
                    data = item.data or {}
                }
            end
        end

        local restoreBatchSize = math.max(math.floor(tonumber(ax.config:Get("inventory.restore.batch_size", 32)) or 32), 1)
        for i = 1, #worldItems do
            local batchIndex = math.floor((i - 1) / restoreBatchSize)
            local delay = batchIndex * 0.02
            local worldItem = worldItems[i]

            timer.Simple(delay, function()
                if ( !ax.util:IsValidPlayer(client) ) then return end

                ax.net:Start(client, "item.spawn", worldItem.id, worldItem.class, worldItem.data)
            end)
        end

        ax.util:PrintDebug(string.format("Synced world items to %s", client:SteamID64()))

        if ( characterIDs[1] == nil ) then return end

        -- All inventories owned by any of this client's characters (primary plus any
        -- extra ones a schema/module created via ax.inventory:Create({ owner = character }))
        -- are addressed uniformly via owner_kind/owner_id - a single batched query here
        -- restores all of them without a separate legacy `.inventory` column lookup.
        local inventoryQuery = mysql:Select("ax_inventories")
        inventoryQuery:Where("owner_kind", "character")
        inventoryQuery:WhereIn("owner_id", characterIDs)
        inventoryQuery:Callback(function(invResult, invStatus)
            if ( invResult == nil or invStatus == false ) then return end

            ax.util:PrintDebug(string.format("Restoring %d inventories for %s", #invResult, client:SteamID64()))

            local clientChar = client:GetCharacter()
            local activeCharacterID = clientChar and clientChar.id

            self:RestoreRows(invResult, function(inventories)
                for i = 1, #inventories do
                    local inventory = inventories[i]

                    self:Sync(inventory)

                    if ( tostring(inventory.ownerID) == tostring(activeCharacterID) ) then
                        inventory:AddReceiver(client)
                        ax.util:PrintDebug(string.format("Added %s as a receiver to inventory %d", client:SteamID64(), inventory.id))
                    end

                    -- and finally, call the callback if provided
                    if ( isfunction(callback) ) then
                        callback(inventory)
                    end
                end
            end)
        end)
        inventoryQuery:Execute()
    end
end

concommand.Add("ax_inventory_restore", function(client, command, args)
    if ( !ax.util:IsValidPlayer(client) ) then return end
    if ( !client:IsSuperAdmin() ) then return end

    ax.inventory:Restore(client)
end)
