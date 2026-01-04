--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

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
    return self.model or Model( "models/props_junk/wood_crate001a.mdl" )
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

    -- TODO: Sync changes to Receivers
end

function item:GetActions()
    return self.actions or {}
end

function item:AddAction(name, actionData)
    -- If actions table doesn't exist directly on this item (it's inherited), create a new one
    if ( !rawget(self, "actions") ) then
        -- Copy existing actions from inheritance chain to preserve base actions
        local inheritedActions = self.actions or {}
        self.actions = table.Copy(inheritedActions)
    end

    self.actions[name] = actionData
end

function item:CanInteract(client, action)
    local try, catch = hook.Run("CanPlayerInteractItem", client, self, action)
    if ( try == false ) then
        if ( isstring(catch) and #catch > 0 ) then
            client:Notify(catch, "error")
        end

        return false
    end

    local actionTable = self.actions[action]
    if ( istable(actionTable) and isfunction(actionTable.CanUse) ) then
        local canRun, reason = actionTable:CanUse(self, client)
        if ( canRun == false ) then
            if ( isstring(reason) and #reason > 0 ) then
                client:Notify(reason, "error")
            end

            return false
        end
    end

    return true
end

ax.item.meta = item
