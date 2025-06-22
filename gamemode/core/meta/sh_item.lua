--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- NOTE! InventoryID should always be updated when the item is moved to a: different inventory or dropped in the world.

local ITEM = ax.item.meta or {}
ITEM.__index = ITEM
ITEM.Actions = ITEM.Actions or {}
ITEM.Category = ITEM.Category or "Miscellaneous"
ITEM.Data = ITEM.Data or {}
ITEM.Description = ITEM.Description or "An item that is undefined."
ITEM.Entity = ITEM.Entity or NULL
ITEM.Hooks = ITEM.Hooks or {}
ITEM.ID = ITEM.ID or 0
ITEM.InventoryID = ITEM.InventoryID or 0
ITEM.IsBase = ITEM.IsBase or false
ITEM.Material = ITEM.Material or ""
ITEM.Model = ITEM.Model or Model("models/props_c17/oildrum001.mdl")
ITEM.Name = "Undefined"
ITEM.NoStack = ITEM.NoStack or false
ITEM.Skin = ITEM.Skin or 0
ITEM.UniqueID = ITEM.UniqueID or "undefined"
ITEM.Weight = ITEM.Weight or 0

--- Returns the unique identifier of the item.
-- @return string The unique identifier of the item
function ITEM:__tostring()
    return "item[" .. self:GetUniqueID() .. "][" .. self:GetID() .. "]"
end

function ITEM:GetUniqueID()
    return self.UniqueID
end

function ITEM:GetID()
    return self.ID
end

function ITEM:GetInventoryID()
    if ( IsValid(self:GetEntity()) ) then
        return 0
    end

    if ( isnumber(self.InventoryID) and self.InventoryID > 0 ) then
        return self.InventoryID
    end

    for invID, invObject in pairs(ax.inventory.instances) do
        if invObject:HasItem(self) then
            self.InventoryID = invID
            return invID
        end
    end

    ax.util:PrintWarning(tostring(self) .. " is not in an inventory or in the world! How??")
    return -1
end

function ITEM:GetName()
    return self.Name
end

function ITEM:GetDescription()
    return self.Description
end

function ITEM:GetModel()
    return self.Model
end

function ITEM:GetMaterial()
    return self.Material
end

function ITEM:GetSkin()
    return self.Skin
end

function ITEM:GetWeight()
    return self.Weight
end

function ITEM:GetCategory()
    return self.Category
end

function ITEM:GetData()
    return self.Data
end

function ITEM:GetEntity()
    return self.Entity
end

function ITEM:IsNoStack()
    return self.NoStack
end

function ITEM:IsBase()
    return self.IsBase
end

function ITEM:GetHooks()
    return self.Hooks
end

function ITEM:GetInventory()
    return ax.inventory.instances[self.InventoryID]
end

function ITEM:SetName(name)
    if ( !isstring(name) ) then
        ax.util:PrintError("Attempted to set an item's name without a valid name!")
        return false, "Attempted to set an item's name without a valid name!"
    end

    self.Name = name
    return true
end

function ITEM:SetDescription(description)
    if ( !isstring(description) ) then
        ax.util:PrintError("Attempted to set an item's description without a valid description!")
        return false, "Attempted to set an item's description without a valid description!"
    end

    self.Description = description
    return true
end

function ITEM:SetModel(model)
    if ( !isstring(model) and !IsValid(model) ) then
        ax.util:PrintError("Attempted to set an item's model without a valid model!")
        return false, "Attempted to set an item's model without a valid model!"
    end

    self.Model = model
    return true
end

function ITEM:SetMaterial(material)
    if ( !isstring(material) ) then
        ax.util:PrintError("Attempted to set an item's material without a valid material!")
        return false, "Attempted to set an item's material without a valid material!"
    end

    self.Material = material
    return true
end

function ITEM:SetSkin(skin)
    if ( !isnumber(skin) ) then
        ax.util:PrintError("Attempted to set an item's skin without a valid skin!")
        return false, "Attempted to set an item's skin without a valid skin!"
    end

    self.Skin = skin
    return true
end

function ITEM:SetWeight(weight)
    if ( !isnumber(weight) ) then
        ax.util:PrintError("Attempted to set an item's weight without a valid weight!")
        return false, "Attempted to set an item's weight without a valid weight!"
    end

    self.Weight = weight
    return true
end

function ITEM:SetCategory(category)
    if ( !isstring(category) ) then
        ax.util:PrintError("Attempted to set an item's category without a valid category!")
        return false, "Attempted to set an item's category without a valid category!"
    end

    self.Category = category
    return true
end

function ITEM:SetData(data)
    if ( !istable(data) ) then
        ax.util:PrintError("Attempted to set an item's data without a valid table!")
        return false, "Attempted to set an item's data without a valid table!"
    end

    self.Data = data
    return true
end

function ITEM:SetEntity(entity)
    if ( !IsValid(entity) ) then
        ax.util:PrintError("Attempted to set an item's entity without a valid entity!")
        return false, "Attempted to set an item's entity without a valid entity!"
    end

    self.Entity = entity
    return true
end

function ITEM:SetInventoryID(inventoryID)
    if ( !isnumber(inventoryID) or inventoryID < 0 ) then
        ax.util:PrintError("Attempted to set an item's InventoryID without a valid number!")
        return false, "Attempted to set an item's InventoryID without a valid number!"
    end

    self.InventoryID = inventory
    return true
end

function ITEM:SetNoStack(noStack)
    if ( !isbool(noStack) ) then
        ax.util:PrintError("Attempted to set an item's no stack status without a valid boolean!")
        return false, "Attempted to set an item's no stack status without a valid boolean!"
    end

    self.NoStack = noStack
    return true
end

function ITEM:SetIsBase(isBase)
    if ( !isbool(isBase) ) then
        ax.util:PrintError("Attempted to set an item's base status without a valid boolean!")
        return false, "Attempted to set an item's base status without a valid boolean!"
    end

    self.IsBase = isBase
    return true
end

function ITEM:SetHooks(hooks)
    if ( !istable(hooks) ) then
        ax.util:PrintError("Attempted to set an item's hooks without a valid table!")
        return false, "Attempted to set an item's hooks without a valid table!"
    end

    self.Hooks = hooks
    return true
end

function ITEM:SetID(id)
    if ( !isnumber(id) or id < 0 ) then
        ax.util:PrintError("Attempted to set an item's ID without a valid number!")
        return false, "Attempted to set an item's ID without a valid number!"
    end

    self.ID = id
    return true
end

function ITEM:SetUniqueID(uniqueID)
    if ( !isstring(uniqueID) or uniqueID == "" ) then
        ax.util:PrintError("Attempted to set an item's UniqueID without a valid string!")
        return false, "Attempted to set an item's UniqueID without a valid string!"
    end

    self.UniqueID = uniqueID
    return true
end

function ITEM:Register()
    local bResult = hook.Run("PreItemRegistered", self)
    if ( bResult == false ) then
        ax.util:PrintError("Attempted to register a faction that was blocked by a hook!")
        return false, "Attempted to register a faction that was blocked by a hook!"
    end

    -- Get the unique ID by retrieving the file name without the extension
    local uniqueID = string.StripExtension(debug.getinfo(2, "S").source)
    uniqueID = uniqueID:sub(2) -- Remove the leading '@' character
    if ( !uniqueID or uniqueID == "" ) then
        ax.util:PrintError("Invalid unique ID for item instance.")
        return false
    end

    -- Set the unique ID for the instance
    self.UniqueID = uniqueID

    hook.Run("PostItemRegistered", self)

    return #ax.item.instances
end

function ITEM:GetActions()
    self.Actions = self.Actions or {}
    return self.Actions
end

function ITEM:AddAction(def)
    assert(isstring(def.Name) and isfunction(def.OnRun), "ITEM:AddAction requires def.Name (string) and def.OnRun (function)")

    local id = def.ID or def.id or def.Name:gsub("%s+", "")
    self:GetActions()[id] = def
end

function ITEM:RemoveAction(actionID)
    if ( self.Actions ) then
        self.Actions[actionID] = nil
    end
end

function ITEM:RunAction(actionID, client)
    local action = self:GetActions()[actionID]
    if ( action and isfunction(action.OnRun) ) then
        action:OnRun(self, client)
    end
end

function ITEM:CanRunAction(actionID, client)
    local action = self:GetActions()[actionID]
    if ( action and isfunction(action.OnCanRun) ) then
        return action:OnCanRun(self, client)
    end

    return false
end

function ITEM:AddDefaultActions()
    self:AddAction({
        Name = "Drop",
        OnCanRun = function(this, item, client)
            return !IsValid(item:GetEntity())
        end,
        OnRun = function(this, item, client)
            if ( !IsValid(client) ) then return end

            local pos = client:GetDropPosition()
            if ( !pos ) then return end

            local prevent = hook.Run("PrePlayerDropItem", client, item, pos)
            if ( prevent == false ) then return end

            ax.item:Transfer(item:GetID(), item:GetInventory(), 0, function(success)
                if ( success ) then
                    ax.item:Spawn(item:GetID(), item:GetUniqueID(), pos, Angle(0, 0, 0), function(entity)
                        hook.Run("PostPlayerDropItem", client, item, entity)
                    end, item:GetData())
                end
            end)
        end
    })

    self:AddAction({
        Name = "Take",
        OnCanRun = function(this, item, client)
            return IsValid(item:GetEntity())
        end,
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
        end
    })
end