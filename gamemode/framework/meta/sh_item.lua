--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local item = ax.item.meta or {}
item.__index = item
item.id = item.id
item.class = item.class

--- Returns a human-readable string representation of the item.
-- Format: `"Item [id][name][class]"`. Useful for debug output and logging.
-- @realm shared
-- @return string A formatted string identifying this item.
function item:__tostring()
    return string.format("Item [%d][%s][%s]", self.id, self:GetName(), self:GetClass())
end

--- Returns the unique numeric ID of this item instance.
-- This is the primary key from the `ax_items` table. Temporary items use negative IDs auto-decremented from -1.
-- @realm shared
-- @return number The item's numeric ID.
function item:GetID()
    return self.id
end

--- Returns the class name of this item.
-- The class name identifies which registered item definition in `ax.item.stored` this instance belongs to (e.g. `"weapon_pistol"`, `"food_bread"`).
-- @realm shared
-- @return string The item's class name string.
function item:GetClass()
    return self.class or "undefined_item_class"
end

--- Returns the display name of this item.
-- Falls back to `"Unknown"` when `self.name` is nil or not set. This is the value shown in inventory UIs and item tooltips.
-- @realm shared
-- @return string The item's display name, or `"Unknown"` if unset.
function item:GetName()
    return self.name or "Unknown"
end

--- Returns the description text for this item.
-- Falls back to `"No description available."` when `self.description` is nil.
-- Displayed in item tooltips and examine prompts.
-- @realm shared
-- @return string The item's description, or a default placeholder string.
function item:GetDescription()
    return self.description or "No description available."
end

--- Returns the weight of this item.
-- Used by `inventory:GetWeight()` and `inventory:CanStoreWeight()` for capacity checks. Falls back to 0 when no weight is defined on the item class.
-- @realm shared
-- @return number The item's weight, or 0 if not set.
function item:GetWeight()
    return self.weight or 0
end

--- Returns the world model path for this item.
-- Used when spawning the item as a world entity or displaying it in a 3D panel.
-- Falls back to the wooden crate model when `self.model` is unset.
-- @realm shared
-- @return string The model path string.
function item:GetModel()
    return self.model or Model("models/props_junk/wood_crate001a.mdl")
end

--- Returns the skin index for this item's model.
-- Clamps the value to 0 or above via `math.max` and coerces it to a non-negative integer via `math.floor`. Falls back to 0 when `self.skin` is unset or non-numeric.
-- @realm shared
-- @return number The skin index (≥ 0).
function item:GetSkin()
    return math.max(math.floor(tonumber(self.skin) or 0), 0)
end

--- Returns the color applied to this item's model.
-- Delegates to `ax.item:NormalizeColor` which coerces `self.color` into a valid `Color` object. Returns white (`Color(255, 255, 255, 255)`) when unset.
-- @realm shared
-- @return Color The item's color value.
function item:GetColor()
    return ax.util:NormalizeColor(self.color)
end

--- Returns the material override for this item's model.
-- Returns an empty string when `self.material` is not a string, which is interpreted by GMod as "no material override".
-- @realm shared
-- @return string The material path, or `""` if not set.
function item:GetMaterial()
    return isstring(self.material) and self.material or ""
end

--[[
    ITEM.bodygroups = {
        ["groupID"] = groupValue,
    }
]]
--- Returns the bodygroup overrides table for this item.
-- The table maps bodygroup IDs (string or number keys) to their desired values. The format is `{ ["groupID"] = groupValue }` where groupID can be either the numeric bodygroup index or a named string resolved via `ax.util:ResolveBodygroupIndex`.
-- Returns an empty table when no bodygroups are defined.
-- @realm shared
-- @return table The bodygroups table, or `{}` if not set.
function item:GetBodygroups()
    return istable(self.bodygroups) and self.bodygroups or {}
end

--- Returns whether this item has any non-default appearance overrides.
-- Checks skin (> 0), material (non-empty), color (not pure white/opaque), or any bodygroup entries. Used to decide whether `ApplyAppearance` needs to be called at all, avoiding unnecessary engine calls for items using default visuals.
-- @realm shared
-- @return boolean True if any appearance property differs from the default.
function item:HasAppearanceOverrides()
    local color = self:GetColor()
    if ( self:GetSkin() > 0 ) then
        return true
    end

    if ( self:GetMaterial() != "" ) then
        return true
    end

    if ( color.r != 255 or color.g != 255 or color.b != 255 or color.a != 255 ) then
        return true
    end

    return next(self:GetBodygroups()) != nil
end

--- Applies this item's visual appearance to a world entity.
-- Sets the entity's skin, material, color, and bodygroups from the item's current values. Bodygroup IDs are resolved through `ax.util:ResolveBodygroupIndex` which supports both numeric indices and named string keys. Skips bodygroups whose index cannot be resolved. Returns false immediately if `entity` is not valid.
-- @realm shared
-- @param entity Entity The entity to apply appearance properties to.
-- @return boolean True on success, false if `entity` is not valid.
function item:ApplyAppearance(entity)
    if ( !IsValid(entity) ) then
        return false
    end

    local color = self:GetColor()
    entity:SetSkin(self:GetSkin())
    entity:SetMaterial(self:GetMaterial())
    entity:SetColor(color)

    for groupID, value in pairs(self:GetBodygroups()) do
        local bodygroupIndex = ax.util:ResolveBodygroupIndex(entity, groupID)
        if ( bodygroupIndex == nil ) then
            continue
        end

        entity:SetBodygroup(bodygroupIndex, math.max(math.floor(tonumber(value) or 0), 0))
    end

    return true
end

--- Returns the inventory ID that contains this item.
-- First checks `self.invID` (set when the item is loaded into an inventory). If that is nil, performs a linear search through all loaded inventory instances to find which one's items table contains this item ID. Returns nil when the item is not found in any loaded inventory.
-- @realm shared
-- @return number|nil The inventory ID, or nil if not found in any loaded inventory.
function item:GetInventoryID()
    if ( self.invID != nil ) then
        return self.invID
    end

    local inventoryID
    for _, v in pairs(ax.inventory.instances) do
        for id, item in pairs(v.items) do
            if ( id == self.id ) then
                inventoryID = v.id
                break
            end
        end
    end

    return inventoryID
end

--- Returns a value from this item's data store, with an optional fallback.
-- Initialises `self.data` to an empty table if it is not already a table. Returns `default` when the key is nil; returns the stored value otherwise.
-- Use `SetData` to write values that should be persisted to the database.
-- @realm shared
-- @param key string The data key to retrieve.
-- @param default any The value to return when the key is not set. Defaults to nil.
-- @return any The stored value, or `default` if the key is absent.
-- @usage local isActive = item:GetData("active", false)
function item:GetData(key, default)
    if ( !istable(self.data) ) then self.data = {} end

    return self.data[key] == nil and default or self.data[key]
end

--- Calls a named method on this item instance with optional player and entity context.
-- Temporarily sets `self.player` and `self.entity` on the item table before invoking the method, then restores both values afterwards. This allows item methods to access `self.player` and `self.entity` without the caller needing to pass them as arguments.
-- Returns all values returned by the invoked method via `unpack`. Returns nothing if `method` is not a string or the method does not exist on this item.
-- @realm shared
-- @param method string The name of the method to call on this item.
-- @param client Player|nil The player to bind as `self.player` during the call. Pass nil to leave unchanged.
-- @param entity Entity|nil The entity to bind as `self.entity` during the call. Pass nil to leave unchanged.
-- @param ... any Additional arguments forwarded to the method.
-- @return any All return values from the called method.
function item:Call(method, client, entity, ...)
    if ( !isstring(method) or method == "" ) then
        return
    end

    local fn = self[method]
    if ( !isfunction(fn) ) then
        return
    end

    local oldPlayer, oldEntity = self.player, self.entity

    if ( client != nil ) then
        self.player = client
    end

    if ( entity != nil ) then
        self.entity = entity
    end

    local results = {fn(self, ...)}

    self.player = oldPlayer
    self.entity = oldEntity

    return unpack(results)
end

--- Sets a value in this item's data store and persists the change to the database.
-- Writes `value` to `self.data[key]`. On the server, skips persistence for temporary or no-save items (and inventories). For persistent items, issues a MySQL UPDATE to `ax_items` serialising the entire data table as JSON. After the write, calls `ax.inventory:Sync` to push the change to all receivers of the owning inventory.
-- This function is safe to call on the client (does not issue queries client-side).
-- @realm shared
-- @param key string The data key to write.
-- @param value any The value to store. Must be JSON-serialisable when persisting.
-- @param bNoDBUpdate boolean Whether to skip the database update. Defaults to false.
function item:SetData(key, value, bNoDBUpdate)
    if ( !istable(self.data) ) then self.data = {} end

    self.data[key] = value
    if ( SERVER ) then
        local inventoryID = self.invID
        if ( inventoryID == nil ) then
            inventoryID = self:GetInventoryID()
        end

        local inventory = inventoryID != nil and ax.inventory.instances[inventoryID] or nil
        if ( self.isTemporary or self.noSave or ( istable(inventory) and (inventory.isTemporary or inventory.noSave) ) ) then
            return
        end

        -- Persist changes to database
        if ( !bNoDBUpdate ) then
            local query = mysql:Update("ax_items")
                query:Update("data", util.TableToJSON(self.data))
                query:Where("id", self.id)
                query:Callback(function(result, status)
                    if ( result == false ) then
                        ax.util:PrintError("Failed to update item data in database for item ID " .. tostring(self.id))
                        return
                    end

                    ax.util:PrintDebug("Updated item data for item ID " .. tostring(self.id))
                end)
            query:Execute()
        end

        -- Sync changes to relevant receivers
        if ( istable(inventory) and inventoryID != 0 ) then
            ax.inventory:Sync(inventory)
        end
    end
end

--- Returns the actions table for this item.
-- Delegates to `ax.item:GetActionsForClass(self.class)` when the item has a valid class string, which returns the merged action set (including inherited base actions).
-- Falls back to `self.actions` or an empty table when the class is unavailable.
-- Actions are keyed by name and each entry is a table with at minimum a `label` and an `OnRun` callback.
-- @realm shared
-- @return table The actions table keyed by action name.
function item:GetActions()
    if ( isstring(self.class) and ax.item and isfunction(ax.item.GetActionsForClass) ) then
        return ax.item:GetActionsForClass(self.class)
    end

    return self.actions or {}
end

--- Registers a named action on this item class.
-- Actions are stored globally in `ax.item.actions[self.class]` rather than on the instance, so they are shared across all instances of the same class. When the class has a base, the base class actions are copied first so inheritance is preserved.
-- Passing an empty or invalid `name` or non-table `actionData` returns immediately.
-- @realm shared
-- @param name string The unique action identifier (e.g. `"use"`, `"drop"`, `"eat"`).
-- @param actionData table The action definition table. Should contain at minimum a `label` string and an `OnRun` callback function.
-- @usage item:AddAction("eat", { label = "Eat", OnRun = function(self) ... end })
function item:AddAction(name, actionData)
    if ( !isstring(name) or name == "" ) then return end
    if ( !istable(actionData) ) then return end
    if ( !isstring(self.class) or self.class == "" ) then return end

    ax.item.actions = ax.item.actions or {}

    local actions = ax.item.actions[self.class]
    if ( !istable(actions) ) then
        actions = {}

        if ( isstring(self.base) and self.base != "" ) then
            actions = table.Copy(ax.item:GetActionsForClass(self.base))
        end
    end

    actions[name] = actionData
    ax.item.actions[self.class] = actions
end

--- Returns whether a player is allowed to perform a named action on this item.
-- Runs two checks in order:
-- 1. Fires `"CanPlayerInteractItem"` hook — returning false blocks the action and optionally sends `catch` as an error notification to the client (unless `silent`).
-- 2. Calls `actionTable:CanUse(client, self, context)` if the action defines it — returning false similarly blocks the action with an optional notification.
-- Returns true and no second value when all checks pass.
-- @realm shared
-- @param client Player The player attempting the interaction.
-- @param action string The action name to validate (must exist in `self:GetActions()`).
-- @param silent boolean|nil When true, suppresses error notifications sent to `client`.
-- @param context any|nil Optional context value forwarded to `CanUse` and the hook.
-- @return boolean True if the interaction is allowed, false otherwise.
-- @return string|nil A human-readable reason when returning false.
function item:CanInteract(client, action, silent, context)
    local try, catch = hook.Run("CanPlayerInteractItem", client, self, action, context)
    if ( try == false ) then
        if ( isstring(catch) and #catch > 0 and !silent ) then
            client:Notify(catch, "error")
        end

        return false, catch
    end

    local actions = self:GetActions()
    local actionTable = actions[action]
    if ( istable(actionTable) and isfunction(actionTable.CanUse) ) then
        local canRun, reason = actionTable:CanUse(client, self, context)
        if ( canRun == false ) then
            if ( isstring(reason) and #reason > 0 and !silent ) then
                client:Notify(reason, "error")
            end

            return false, reason
        end
    end

    return true
end

ax.item.meta = item
