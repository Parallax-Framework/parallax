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

function item:__tostring()
    return string.format("Item [%d][%s]", self.id, self.name or "Unknown")
end

function item:GetID()
    return self.id
end

function item:GetClass()
    return self.class
end

function item:GetName()
    return self.name or "Unknown"
end

function item:GetDescription()
    return self.description or "No description available."
end

function item:GetWeight()
    return self.weight or 0
end

function item:GetModel()
    return self.model or Model("models/props_junk/wood_crate001a.mdl")
end

function item:GetInventoryID()
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

function item:GetData(key, default)
    if ( !istable(self.data) ) then self.data = {} end

    return self.data[key] == nil and default or self.data[key]
end

function item:SetData(key, value)
    if ( !istable(self.data) ) then self.data = {} end

    self.data[key] = value
    if ( SERVER ) then
        -- Persist changes to database
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

        -- Sync changes to relevant receivers
        local inventoryID = self:GetInventoryID()
        if ( inventoryID and inventoryID > 0 ) then
            ax.inventory:Sync(inventoryID)
        end
    end
end

function item:GetActions()
    if ( isstring(self.class) and ax.item and isfunction(ax.item.GetActionsForClass) ) then
        return ax.item:GetActionsForClass(self.class)
    end

    return self.actions or {}
end

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

function item:CanInteract(client, action, silent)
    local try, catch = hook.Run("CanPlayerInteractItem", client, self, action)
    if ( try == false ) then
        if ( isstring(catch) and #catch > 0 and !silent ) then
            client:Notify(catch, "error")
        end

        return false, catch
    end

    local actions = self:GetActions()
    local actionTable = actions[action]
    if ( istable(actionTable) and isfunction(actionTable.CanUse) ) then
        local canRun, reason = actionTable:CanUse(self, client)
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
