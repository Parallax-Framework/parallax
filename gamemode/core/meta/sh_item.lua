--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local ITEM = ax.item.meta or {}
ITEM.__index = ITEM
ITEM.Category = ITEM.Category or "Miscellaneous"
ITEM.Data = ITEM.Data or {}
ITEM.Description = ITEM.Description or "An item that is undefined."
ITEM.Entity = ITEM.Entity or NULL
ITEM.Hooks = ITEM.Hooks or {}
ITEM.ID = ITEM.ID or 0
-- NOTE! InventoryID should always be updated when the item is moved to a: different inventory or dropped in the world.
ITEM.InventoryID = ITEM.InventoryID or 0
ITEM.IsBase = ITEM.IsBase or false
ITEM.Material = ITEM.Material or ""
ITEM.Model = ITEM.Model or Model("models/props_c17/oildrum001.mdl")
ITEM.Name = "Undefined"
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

function ITEM:IsBase()
    return self.IsBase
end

function ITEM:GetHooks()
    return self.Hooks
end

function ITEM:GetInventory()
    return ax.inventory.instances[self.InventoryID]
end