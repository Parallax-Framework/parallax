--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local INVENTORY = ax.inventory.meta or {}
INVENTORY.__index = INVENTORY
INVENTORY.Data = INVENTORY.Data or {}
INVENTORY.ID = INVENTORY.ID or 0
INVENTORY.Items = INVENTORY.Items or {}
INVENTORY.MaxWeight = INVENTORY.MaxWeight or 0

function INVENTORY:__tostring()
    return "inventory[" .. self:GetID() .. "]"
end

function INVENTORY:GetID()
    return self.ID
end

function INVENTORY:GetCharacterID()
    return self.CharacterID
end

function INVENTORY:GetCharacter()
    return ax.character:Get(self.CharacterID)
end

function INVENTORY:GetMaxWeight()
    return self.MaxWeight
end

function INVENTORY:GetWeight()
    local weight = 0
    for _, item in ipairs(self:GetItems()) do
        if ( item ) then
            weight = weight + item:GetWeight()
        else
            ax.util:PrintWarning("Invalid item found in inventory " .. self:GetID() .. ": " .. tostring(item))

        end
    end

    return weight
end

function INVENTORY:CanAddItem(item)
    if ( !ax.util:IsItem(item) ) then
        ax.util:PrintError("Invalid item provided to INVENTORY:CanAddItem()")
        return false
    end

    return self:GetWeight() + item:GetWeight() <= self:GetMaxWeight()
end

function INVENTORY:AddItem(item, callback)
    if ( !ax.util:IsItem(item) ) then
        ax.util:PrintError("Invalid item provided to INVENTORY:AddItem()")
        return false
    end

    table.insert(self.Items, item)
    item:SetInventoryID(self:GetID())

    -- TODO: database

    if ( isfunction(callback) ) then
        callback(item)
    end

    return true
end

function INVENTORY:GetItems()
    return self.Items
end

function INVENTORY:GetData()
    return self.Data
end

ax.inventory.meta = INVENTORY