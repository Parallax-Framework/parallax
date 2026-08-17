--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

---@class ax.inventory
--- Inventory type registry: how items are addressed within an inventory (grid `x,y`, named `slotID`, or no addressing at all), plus the reusable `gridBehavior`/ `slotBehavior` primitives concrete types build on.
---@realm shared

ax.inventory = ax.inventory or {}
ax.inventory.types = ax.inventory.types or {}

--- Registers an inventory type definition. A type defines how items are addressed within an inventory (grid `x,y`, named `slotID`, or no addressing at all) plus optional access rules and a UI renderer id. Concrete types register themselves from their own schema/module, reusing the shared `ax.inventory.gridBehavior`/`ax.inventory.slotBehavior` primitives as-is or merged with their own `CanReceiveItem`/`CanRemoveItem` rules.
---@realm shared
---@param id string Unique type identifier (e.g. "weight", "bag", "equipment")
---@param data table Type definition. Recognised keys: `GetWidth`, `GetHeight`,
--- `GetItemAt`, `CanItemFit`, `FindEmptySlot` (grid-capable types only),
--- `CanReceiveItem`, `CanRemoveItem`. Addressing is optional - a type with none of
--- these keys is a non-addressed type (e.g. the default `weight` type below), and
--- placement validation is simply skipped for it.
function ax.inventory:RegisterType(id, data)
    self.types[id] = data
end

--- Returns the registered type definition for an inventory instance. Inventories created before the type registry existed (or by code that never set `typeID`) default to `"weight"` for back-compat - the same weight-limited-list behaviour `ax.inventory` has always had.
---@realm shared
---@param inventory table The inventory instance
---@return table|nil # The type definition, or nil if the inventory's typeID is set but unregistered
function ax.inventory:GetType(inventory)
    if ( !istable(inventory) ) then return nil end

    local typeID = inventory.typeID or "weight"
    local typeDef = self.types[typeID]
    if ( !typeDef ) then
        ax.util:PrintError("Inventory typeID '" .. tostring(typeID) .. "' is not registered!")
        return nil
    end

    return typeDef
end

--- Positional (grid/x,y-addressed) behaviour primitive. Reusable as-is by any grid-addressed type (e.g. a personal grid, a bag), or merged with type-specific `CanReceiveItem`/`CanRemoveItem` rules.
---@realm shared
ax.inventory.gridBehavior = {
    GetWidth = function(self)
        return self:GetData("width", 5)
    end,

    GetHeight = function(self)
        return self:GetData("height", 5)
    end,

    GetItemAt = function(self, x, y)
        for _, item in pairs(self:GetItems()) do
            local ix, iy = item:GetGridX(), item:GetGridY()
            local iw, ih = item:GetWidth(), item:GetHeight()

            if ( ix == nil or iy == nil ) then continue end

            if ( x >= ix and x < ix + iw and y >= iy and y < iy + ih ) then
                return item
            end
        end

        return nil
    end,

    CanItemFit = function(self, x, y, w, h, ignoreItem)
        local invW, invH = self:GetWidth(), self:GetHeight()

        if ( x < 1 or y < 1 or x + w - 1 > invW or y + h - 1 > invH ) then
            return false
        end

        for _, item in pairs(self:GetItems()) do
            if ( ignoreItem and item.id == ignoreItem.id ) then continue end

            local ix, iy = item:GetGridX(), item:GetGridY()
            if ( ix == nil or iy == nil ) then continue end

            local iw, ih = item:GetWidth(), item:GetHeight()

            if ( x < ix + iw and x + w > ix and y < iy + ih and y + h > iy ) then
                return false
            end
        end

        return true
    end,

    FindEmptySlot = function(self, w, h, ignoreItem)
        local invW, invH = self:GetWidth(), self:GetHeight()

        for y = 1, invH - h + 1 do
            for x = 1, invW - w + 1 do
                if ( self:CanItemFit(x, y, w, h, ignoreItem) ) then
                    return x, y
                end
            end
        end

        return nil
    end,

    -- Resolves the placement blob a new/incoming item should get: an explicit
    -- `{ gridX, gridY }` request is validated with CanItemFit, an omitted one is
    -- auto-placed via FindEmptySlot. Shared by ax.inventory:AddItem and :Transfer so
    -- neither has to know this type addresses by coordinates rather than slot id.
    ResolvePlacement = function(self, w, h, explicitPlacement, ignoreItem)
        if ( istable(explicitPlacement) and explicitPlacement.gridX != nil and explicitPlacement.gridY != nil ) then
            local x, y = tonumber(explicitPlacement.gridX), tonumber(explicitPlacement.gridY)
            if ( !isnumber(x) or !isnumber(y) ) then
                return nil, "inventory.reason.invalid"
            end

            -- Cells are integer coordinates. The net path floors these (see sv_networking),
            -- but direct/system callers of AddItem/Transfer don't, so normalise here at the
            -- source - CanItemFit/GetItemAt/FindEmptySlot all assume integers, and a
            -- fractional value would otherwise be validated loosely then persisted/synced.
            x, y = math.floor(x), math.floor(y)

            if ( !self:CanItemFit(x, y, w, h, ignoreItem) ) then
                return nil, "inventory.reason.no_space"
            end

            return { gridX = x, gridY = y }
        end

        local x, y = self:FindEmptySlot(w, h, ignoreItem)
        if ( x == nil ) then
            return nil, "inventory.reason.no_space"
        end

        return { gridX = x, gridY = y }
    end,

    -- Extra per-item fields this type wants included in the "inventory.sync" payload -
    -- core sync code never references gridX/gridY by name, it just writes whatever
    -- the inventory's own type contributes here directly onto the shared per-item
    -- `entry` table (no intermediate table/merge - this runs once per item per sync).
    -- width/height aren't included - they're static per item class (see
    -- item:GetWidth/GetHeight), already known client-side from the shared item class
    -- definition, so networking them per sync would just be a wasted payload.
    GetSyncFields = function(item, entry)
        entry.gridX = item:GetGridX()
        entry.gridY = item:GetGridY()
    end,

    -- Client-side counterpart: applies fields produced by GetSyncFields back onto the
    -- restored item instance.
    ApplySyncFields = function(itemObject, fields)
        itemObject.gridX = fields.gridX
        itemObject.gridY = fields.gridY
    end,

    -- Server-side counterpart: applies a parsed `ax_items.placement` blob onto a
    -- freshly-instanced item during database restore (see RestoreRow). `placement` is
    -- its own column, separate from the item's own `data` (item-class-owned, arbitrary
    -- keys), so the two can never collide.
    ApplyItemRow = function(itemObject, placement)
        itemObject.gridX = tonumber(placement.gridX)
        itemObject.gridY = tonumber(placement.gridY)
    end,
}

--- Non-positional (named-slot-addressed) behaviour primitive. Used by equipment-like types - occupancy is by a unique slot key rather than x/y coordinates, so there is only ever one item per slot and no width/height concept. Deliberately has no `FindEmptySlot`: an item's target slot is always its own `GetSlotID()`, never a free choice among several.
---@realm shared
ax.inventory.slotBehavior = {
    GetItemAt = function(self, slotID)
        if ( slotID == nil ) then return nil end

        for _, item in pairs(self:GetItems()) do
            if ( item:GetSlotID() == slotID ) then
                return item
            end
        end

        return nil
    end,

    CanItemFit = function(self, slotID, ignoreItem)
        if ( slotID == nil ) then return false end

        local occupant = self:GetItemAt(slotID)
        if ( !occupant ) then return true end

        return ignoreItem != nil and occupant.id == ignoreItem.id
    end,

    -- See gridBehavior.ResolvePlacement. No auto-choice here (deliberately, see the
    -- module doc above) - the caller must always name the target slotID explicitly.
    ResolvePlacement = function(self, w, h, explicitPlacement, ignoreItem)
        local slotID = istable(explicitPlacement) and explicitPlacement.slotID or nil
        if ( !isstring(slotID) or slotID == "" ) then
            return nil, "inventory.reason.wrong_slot"
        end

        if ( !self:CanItemFit(slotID, ignoreItem) ) then
            return nil, "inventory.reason.no_space"
        end

        return { slotID = slotID }
    end,

    -- See ax.inventory.gridBehavior.GetSyncFields/ApplySyncFields.
    GetSyncFields = function(item, entry)
        entry.slotID = item:GetSlotID()
    end,

    ApplySyncFields = function(itemObject, fields)
        itemObject.slotID = fields.slotID
    end,

    -- See ax.inventory.gridBehavior.ApplyItemRow.
    ApplyItemRow = function(itemObject, placement)
        itemObject.slotID = placement.slotID
    end,
}

--- The default inventory type: a weight-limited list with no positional addressing, i.e. exactly current `ax.inventory` behaviour (`GetWeight`/`CanStoreWeight`/ `CanStoreItem` on the meta already implement this). Every inventory without an explicit `typeID` resolves to this type (see `GetType` above) so existing schemas and the containers module see no behaviour change.
---@realm shared
ax.inventory:RegisterType("weight", {})
