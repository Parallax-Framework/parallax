--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.item = ax.item or {}

function ax.item:RunAction(client, item, action, context, callback)
    if ( !ax.util:IsValidPlayer(client) ) then
        if ( isfunction(callback) ) then callback(false, "Invalid player.") end
        return false, "Invalid player."
    end

    if ( !istable(item) ) then
        if ( isfunction(callback) ) then callback(false, "Invalid item.") end
        return false, "Invalid item."
    end

    if ( !isstring(action) or action == "" ) then
        if ( isfunction(callback) ) then callback(false, "Invalid action.") end
        return false, "Invalid action."
    end

    local actions = item:GetActions()
    local actionTable = istable(actions) and actions[action] or nil
    if ( !istable(actionTable) ) then
        if ( isfunction(callback) ) then callback(false, "That action is not available for this item.") end
        return false, "That action is not available for this item."
    end

    local canRun, reason = item:CanInteract(client, action, false, context)
    if ( canRun == false ) then
        if ( isfunction(callback) ) then callback(false, reason) end
        return false, reason
    end

    local bRemoveAfter = actionTable:OnRun(client, item, context)
    if ( bRemoveAfter == true ) then
        local inventory = ax.inventory.instances[item:GetInventoryID()]
        if ( istable(inventory) ) then
            inventory:RemoveItem(item.id)
        else
            ax.util:PrintError("Failed to remove item ID " .. item.id .. " after action '" .. action .. "' because its inventory does not exist.")
        end
    end

    local lower = ( utf8 and utf8.lower ) or string.lower
    local soundVar = "sound_" .. lower(action)
    if ( actionTable[soundVar] ) then
        client:EmitSound(Sound(actionTable[soundVar]))
    end

    hook.Run("OnPlayerItemAction", client, item, action, context)

    local inventoryID = item:GetInventoryID()
    if ( inventoryID and inventoryID > 0 ) then
        ax.inventory:Sync(inventoryID)
    end

    if ( isfunction(callback) ) then callback(true) end

    return true
end

--- The single transaction that moves (or repositions) an item. Every scenario that
-- changes an item's placement - drag-and-drop, equip, world drop/pickup, a reward
-- grant - goes through this; there is no other way to change `ax_items.placement`
-- / `inventory_id`.
-- Check order: client access to both endpoints -> anti-dupe lock -> item-level
-- "CanTransferItem" hook -> `from` type's `CanRemoveItem` -> weight capacity + `to`
-- type's `CanReceiveItem` -> placement resolution/validation (skipped for
-- non-addressed types) -> depth-1 nesting. Memory is only mutated after the database
-- write confirms - failures before that point never touch `self.items`, so there is
-- nothing to roll back on a DB error, only the lock to release.
-- @realm server
-- @param item table The item instance to move.
-- @param fromInventory table|number|nil Source inventory (instance, id, or 0/nil for world).
-- @param toInventory table|number|nil Destination inventory (instance, id, or 0/nil for world).
-- @param placement table|nil Target placement for addressed types - `{ gridX, gridY }`
-- or `{ slotID }`. Omit to auto-place (grid types only - `FindEmptySlot`).
-- @param client Player|nil The player initiating the transfer. Nil means a trusted/system
-- call (reward grants, admin commands, migrations) - the access gate is skipped.
-- @param callback function|nil Called as `callback(success, reasonCode|nil)`.
-- @return boolean|nil False on synchronous validation failure; nil once the async DB path has started (result via callback).
-- @return string|nil A phrase-key reason (e.g. `"inventory.reason.no_space"`) when returning false.
function ax.item:Transfer(item, fromInventory, toInventory, placement, client, callback)
    if ( !istable(item) ) then
        return false, "inventory.reason.invalid"
    end

    local fromInventoryID = 0
    if ( istable(fromInventory) ) then
        fromInventoryID = fromInventory.id
    elseif ( isnumber(fromInventory) and fromInventory > 0 ) then
        fromInventoryID = fromInventory
        fromInventory = ax.inventory.instances[fromInventoryID]

        if ( !istable(fromInventory) ) then
            return false, "inventory.reason.invalid"
        end
    else
        fromInventory = ax.inventory.instances[0]
    end

    local toInventoryID = 0
    if ( istable(toInventory) ) then
        toInventoryID = toInventory.id
    elseif ( isnumber(toInventory) and toInventory > 0 ) then
        toInventoryID = toInventory
        toInventory = ax.inventory.instances[toInventoryID]

        if ( !istable(toInventory) ) then
            return false, "inventory.reason.invalid"
        end
    else
        toInventory = ax.inventory.instances[0]
    end

    local repositioning = ( fromInventoryID == toInventoryID )
    if ( repositioning and fromInventoryID == 0 ) then
        return false, "inventory.reason.invalid" -- World has no addressing - nothing to reposition.
    end

    ax.util:PrintDebug(string.format("Transferring item %s from inventory %s to inventory %s", item.id, tostring(fromInventoryID), tostring(toInventoryID)))

    local fromIsTemporary = fromInventory.isTemporary or fromInventory.noSave
    local toIsTemporary = toInventory.isTemporary or toInventory.noSave
    local itemIsTemporary = item.isTemporary or item.noSave

    if ( itemIsTemporary or fromIsTemporary or toIsTemporary ) then
        if ( fromInventoryID == 0 or toInventoryID == 0 ) then
            return false, "inventory.reason.invalid" -- Temporary items cannot be transferred to/from the world inventory.
        end

        if ( !fromIsTemporary or !toIsTemporary ) then
            return false, "inventory.reason.invalid" -- Temporary inventory transfers are only supported between temporary inventories.
        end
    end

    -- Client access to both endpoints. World is always reachable
    -- through Transfer itself - entity validity/distance is the caller's job (see
    -- CreateDefaultDropAction/CreateDefaultTakeAction). A nil client is a trusted/system
    -- call and skips this gate entirely.
    if ( client != nil and ( !ax.inventory:CanAccess(fromInventory, client) or !ax.inventory:CanAccess(toInventory, client) ) ) then
        return false, "inventory.reason.no_access"
    end

    -- Anti-dupe lock - closes the race where two clients act on the
    -- same item before the first transfer's database write returns.
    if ( item:IsLocked() ) then
        return false, "inventory.reason.locked"
    end

    item:Lock()

    -- Synchronous validation failure (everything before the DB write): the return
    -- value is the only signal - callback is reserved for the genuinely async DB
    -- outcome below, never double-fired for a sync failure.
    local function fail(reason)
        item:Unlock()

        return false, reason
    end

    -- Item-level veto hook - any module can block a specific transfer.
    local hookOk, hookReason = hook.Run("CanTransferItem", client, item, fromInventory, toInventory, placement)
    if ( hookOk == false ) then
        return fail(hookReason or "inventory.reason.invalid")
    end

    -- Type-level from/to rules.
    local fromTypeDef = ax.inventory:GetType(fromInventory)
    if ( istable(fromTypeDef) and isfunction(fromTypeDef.CanRemoveItem) ) then
        local canRemove, removeReason = fromTypeDef.CanRemoveItem(fromInventory, item)
        if ( canRemove == false ) then
            return fail(removeReason or "inventory.reason.invalid")
        end
    end

    -- Weight capacity is a universal base-meta check (back-compat) - types layer
    -- additional rules via CanReceiveItem on top of it, they don't replace it.
    if ( toInventoryID != 0 and math.Round(toInventory:GetWeight() + item:GetWeight(), 2) > toInventory:GetMaxWeight() ) then
        return fail("inventory.reason.no_space")
    end

    local toTypeDef = ax.inventory:GetType(toInventory)
    if ( istable(toTypeDef) and isfunction(toTypeDef.CanReceiveItem) ) then
        local canReceive, receiveReason = toTypeDef.CanReceiveItem(toInventory, item, placement)
        if ( canReceive == false ) then
            return fail(receiveReason or "inventory.reason.invalid")
        end
    end

    -- Placement resolution/validation - skipped entirely for non-addressed
    -- types, which keep writing an empty placement blob.
    local resolvedPlacement = {}
    if ( istable(toTypeDef) and isfunction(toTypeDef.ResolvePlacement) ) then
        local itemWidth = tonumber(item.width) or 1
        local itemHeight = tonumber(item.height) or 1

        -- `item` itself is passed as the ignored occupant so repositioning within the
        -- same grid inventory doesn't collide with the item's own current cells.
        local resolved, placementReason = toTypeDef.ResolvePlacement(toInventory, itemWidth, itemHeight, placement, item)
        if ( !istable(resolved) ) then
            return fail(placementReason or "inventory.reason.no_space")
        end

        resolvedPlacement = resolved
    end

    -- Depth-1 nesting - a universal engine rule, not a type's responsibility. An
    -- item that itself owns an inventory (a bag) can never end up inside an inventory
    -- that is itself nested inside an item.
    if ( toInventory.ownerKind == "item" and ax.inventory:ItemOwnsInventory(item.id) ) then
        return fail("inventory.reason.nesting")
    end

    if ( itemIsTemporary or fromIsTemporary or toIsTemporary ) then
        toInventory.items[item.id] = item
        item.invID = toInventoryID

        fromInventory.items[item.id] = nil

        if ( istable(toTypeDef) and isfunction(toTypeDef.ApplyItemRow) ) then
            toTypeDef.ApplyItemRow(item, resolvedPlacement)
        end

        item:Unlock()

        if ( isfunction(callback) ) then
            callback(true)
        end

        return true
    end

    local dropPos
    if ( fromInventoryID != 0 and toInventoryID == 0 ) then
        local dropPlayer = client
        if ( !ax.util:IsValidPlayer(dropPlayer) ) then
            local owner = fromInventory:GetOwner()
            dropPlayer = istable(owner) and owner:GetOwner() or nil
        end

        if ( ax.util:IsValidPlayer(dropPlayer) ) then
            local trace = {}
            trace.start = dropPlayer:GetShootPos()
            trace.endpos = trace.start + (dropPlayer:GetAimVector() * 96)
            trace.filter = dropPlayer
            trace = util.TraceLine(trace)

            dropPos = trace.HitPos + trace.HitNormal * 16
        end

        if ( !isvector(dropPos) ) then
            return fail("inventory.reason.invalid")
        end
    end

    -- The database write happens first, memory is only mutated in the success
    -- callback below - so a DB failure never leaves in-memory/DB state diverged and
    -- there is nothing to roll back.
    local query = mysql:Update("ax_items")
        query:Update("inventory_id", toInventoryID)
        query:Update("placement", util.TableToJSON(resolvedPlacement))
        query:Where("id", item.id)
        query:Callback(function(result, status)
            -- The query has already been dispatched and Transfer has already returned
            -- true synchronously below - from here, the callback is the only way to
            -- report an outcome, so (unlike the sync `fail()` above) this always fires it.
            local function finish(reason)
                item:Unlock()

                if ( isfunction(callback) ) then
                    callback(false, reason)
                end

                return false, reason
            end

            if ( result == false ) then
                ax.util:PrintError("Failed to update item in database during transfer.")
                return finish("inventory.reason.invalid")
            end

            if ( toInventoryID != 0 ) then
                toInventory.items[item.id] = item
                item.invID = toInventoryID
            else
                item.invID = 0
            end

            if ( !repositioning ) then
                fromInventory.items[item.id] = nil
            end

            if ( istable(toTypeDef) and isfunction(toTypeDef.ApplyItemRow) ) then
                toTypeDef.ApplyItemRow(item, resolvedPlacement)
            end

            ax.util:PrintDebug(string.format("Transferred item %s from inventory %s to inventory %s", item.id, tostring(fromInventoryID), tostring(toInventoryID)))

            if ( toInventoryID == 0 ) then
                local itemEntity = ents.Create("ax_item")
                if ( !IsValid(itemEntity) ) then
                    ax.util:PrintError("Failed to create item entity during transfer to world inventory.")
                    return finish("inventory.reason.invalid")
                end

                itemEntity:SetItemID(item.id)
                itemEntity:SetItemClass(item.class)
                itemEntity:SetPos(dropPos or vector_origin)
                itemEntity:Spawn()
                itemEntity:Activate()

                -- Clients outside the source inventory never had this instance clientside,
                -- so seed the world item before broadcasting the transfer.
                ax.net:Start(nil, "item.spawn", item.id, item.class, item.data or {})
                ax.net:Start(nil, "item.transfer", item.id, fromInventoryID, toInventoryID)
            elseif ( !repositioning ) then
                local targetReceivers = toInventory:GetReceivers() or {}
                for i = 1, #targetReceivers do
                    local receiver = targetReceivers[i]
                    if ( !ax.util:IsValidPlayer(receiver) ) then
                        continue
                    end

                    local alreadyKnowsItem = fromInventory:IsReceiver(receiver)
                    if ( !alreadyKnowsItem ) then
                        ax.net:Start(receiver, "inventory.item.add", toInventoryID, item.id, item.class, item.data or {})
                    end
                end

                ax.net:Start(toInventory:GetReceivers(), "item.transfer", item.id, fromInventoryID, toInventoryID)
            end

            ax.inventory:Sync(toInventory)

            if ( !repositioning and fromInventoryID != 0 ) then
                ax.inventory:Sync(fromInventory)
            end

            item:Unlock()

            if ( isfunction(callback) ) then
                callback(true)
            end

            return true
        end)
    query:Execute()

    return true
end

function ax.item:Spawn(class, pos, ang, callback, data)
    local item = ax.item.stored[class]
    if ( !istable(item) ) then
        ax.util:PrintError("Invalid item provided to ax.item:Spawn() (" .. tostring(class) .. ")")
        return false
    end

    data = data or {}

    local query = mysql:Insert("ax_items")
        query:Insert("class", class)
        query:Insert("inventory_id", 0)
        query:Insert("data", util.TableToJSON(data))
        query:Insert("placement", "{}")
        query:Callback(function(result, status, lastID)
            if ( result == false ) then
                ax.util:PrintError("Failed to insert item into database for world spawn.")
                return false
            end

            local itemObject = ax.item:Instance(lastID, class)
            itemObject.invID = 0

            local entity = ents.Create("ax_item")
            entity:SetItemID(lastID)
            entity:SetItemClass(class)
            entity:SetPos(pos)
            entity:SetAngles(ang)
            entity:Spawn()
            entity:Activate()

            ax.net:Start(nil, "item.spawn", lastID, class, data or {})

            if ( isfunction(callback) ) then
                callback(entity, itemObject)
            end

            return true
        end)
    query:Execute()
end

concommand.Add("ax_item_create", function(client, command, args, argStr)
    if ( ax.util:IsValidPlayer(client) and !client:IsSuperAdmin() ) then
        ax.util:PrintError("You do not have permission to use this command!")
        return
    end

    local class = args[1]
    local inventoryID = tonumber(args[2]) or 0

    if ( !class or class == "" ) then
        ax.util:PrintError("You must provide an item class.")

        ax.util:Print(Color(0, 255, 0), "Available item classes:")
        for k in pairs(ax.item.stored) do
            ax.util:Print(Color(0, 255, 0), "- " .. k)
        end

        return
    end

    if ( inventoryID <= 0 ) then
        ax.util:PrintError("You must provide a valid inventory ID.")

        ax.util:Print(Color(0, 255, 0), "Available inventory IDs:")
        for k in pairs(ax.inventory.instances) do
            ax.util:Print(Color(0, 255, 0), "- " .. k)
        end

        return
    end

    local inventory = ax.inventory.instances[inventoryID]
    if ( !istable(inventory) ) then
        ax.util:PrintError("Inventory with ID " .. inventoryID .. " does not exist.")
        return
    end

    local item = ax.item.stored[class]
    if ( !istable(item) ) then
        ax.util:PrintError("Item with class " .. class .. " does not exist.")
        return
    end

    inventory:AddItem(class)
end)

concommand.Add("ax_item_list", function(client, command, args, argStr)
    if ( ax.util:IsValidPlayer(client) and !client:IsSuperAdmin() ) then
        ax.util:PrintError("You do not have permission to use this command!")
        return
    end

    ax.util:Print(Color(0, 255, 0), "Available item classes:")
    for k in pairs(ax.item.stored) do
        ax.util:Print(Color(0, 255, 0), "- " .. k)
    end
end)

concommand.Add("ax_item_spawn", function(client, command, args, argStr)
    if ( ax.util:IsValidPlayer(client) and !client:IsSuperAdmin() ) then
        ax.util:PrintError("You do not have permission to use this command!")
        return
    end

    local class = args[1]
    if ( !class or class == "" ) then
        ax.util:PrintError("You must provide an item class.")
        return
    end

    local trace = client:GetEyeTrace()
    local pos = trace.HitPos + trace.HitNormal * 16
    local ang = trace.HitNormal:Angle()

    ax.item:Spawn(class, pos, ang)
end)
