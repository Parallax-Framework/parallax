--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local ITEM = ax.item.meta or {}
ITEM.Category = ITEM.Category or "Miscellaneous"
ITEM.CharacterID = ITEM.CharacterID or 0
ITEM.Data = ITEM.Data or {}
ITEM.Description = ITEM.Description or "An item that is undefined."
ITEM.Entity = ITEM.Entity or NULL
ITEM.Hooks = ITEM.Hooks or {}
ITEM.ID = ITEM.ID or 0
ITEM.InventoryID = ITEM.InventoryID or 0
ITEM.IsBase = ITEM.IsBase or false
ITEM.Material = ITEM.Material or ""
ITEM.Model = ITEM.Model or "models/props_c17/oildrum001.mdl"
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
    return self.InventoryID
end

function ITEM:GetCharacterID()
    return self.CharacterID
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

function ITEM:GetCharacter()
    return ax.character.instances[self.CharacterID]
end

ITEM.Name = ITEM.Name or "Unnamed Item"
ITEM.Description = ITEM.Description or "No description provided."
ITEM.Model = ITEM.Model or Model("models/props_c17/oildrum001.mdl")
ITEM.Weight = ITEM.Weight or 1
ITEM.Price = ITEM.Price or 0
ITEM.MaxStack = ITEM.MaxStack or 1
ITEM.Category = ITEM.Category or "Miscellaneous"
-- We will not be having OwnerIDs, that'll be for inventories.

ITEM.Actions = ITEM.Actions or {}

function ITEM:AddAction(name, callback)
    if ( !isnumber(name) and !isfunction(callback) ) then
        ax.util:PrintError("Invalid parameters for ITEM:AddAction")
        return
    end

    if ( self.Actions[name] ) then
        ax.util:PrintError("Action with name \"" .. name .. "\" already exists.")
        return
    end

    self.Actions[name] = callback
end

function ITEM:RemoveAction(name)
    if ( !isfunction(self.Actions[name]) ) then
        ax.util:PrintError("Action with name \"" .. name .. "\" does not exist.")
        return
    end

    self.Actions[name] = nil
end