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
    return "Inventory [" .. self:GetID() .. "]"
end

function INVENTORY:GetID()
    return self.ID
end

function INVENTORY:GetCharacter()
    for _, character in pairs(ax.character.stored) do
        if ( character:GetInventory():GetID() == self:GetID() ) then
            return character
        end
    end

    return nil
end

function INVENTORY:GetMaxWeight()
    return self.MaxWeight
end

function INVENTORY:GetWeight()
    local weight = 0
    for _, itemID in ipairs(self:GetItems()) do
        if ( isnumber(itemID) ) then
            local item = ax.item:Get(itemID)
            if ( item ) then
                weight = weight + item:GetWeight()
            else
                ax.util:PrintWarning("Invalid item ID found in inventory " .. self:GetID() .. ": " .. tostring(itemID))
            end
        else
            ax.util:PrintWarning("Non-numeric item ID found in inventory " .. self:GetID() .. ": " .. tostring(itemID))
        end
    end

    return weight
end

function INVENTORY:GetItems()
    return self.Items
end

function INVENTORY:GetData()
    return self.Data
end

if ( SERVER ) then
    function INVENTORY:AddItem(uniqueID, amount, data, callback)
        if ( !isstring(uniqueID) ) then
            ax.util:PrintError("Invalid uniqueID provided to INVENTORY:AddItem")
            return false
        end

        ax.inventory:AddItem(self:GetID(), uniqueID, data, function(itemID)
            if ( !isnumber(itemID) ) then
                ax.util:PrintError("Failed to add item to inventory.")
                if ( callback ) then
                    callback(false)
                end
                return false
            end

            local item = ax.item:CreateObject(itemID, uniqueID, data)
            if ( !item ) then
                ax.util:PrintError("Failed to create item object for inventory.")
                if ( callback ) then
                    callback(false)
                end
                return false
            end

            --self.Items[#self.Items + 1] -- TODO: Don't even have the bloody item object funcs

            -- TODO: Network

            if ( callback ) then
                callback(item)
            end

            return true
        end)
    end

    function INVENTORY:RemoveItem(itemID, callback)
        if ( !isnumber(itemID) or itemID <= 0 ) then
            ax.util:PrintError("Invalid item ID provided to INVENTORY:RemoveItem")
            if ( callback ) then
                callback(false)
            end
            return false
        end

        if ( ax.util:IsItem(itemID) ) then
            itemID = itemID:GetID()
        end

        ax.inventory:RemoveItem(self:GetID(), itemID, function(success)
            if ( success == false ) then
                ax.util:PrintError("Failed to remove item from inventory.")
                if ( callback ) then
                    callback(false)
                end
                return false
            end

            -- Remove the item from the local items table
            self.Items[itemID] = nil

            -- TODO: Network

            if ( callback ) then
                callback(true)
            end

            return true
        end)
    end
end

function INVENTORY:HasItem(itemID)
    if ( ax.util:IsItem(itemID) ) then
        itemID = itemID:GetID()
    end

    if ( !isnumber(itemID) ) then
        return false
    end

    for _, id in ipairs(self.Items) do
        if ( id == itemID ) then
            return true
        end
    end

    return false
end

function INVENTORY:GetItemsByUniqueID(uniqueID)
    local items = {}

    for _, itemID in ipairs(self.Items) do
        local item = ax.item:Get(itemID)
        if ( item and item:GetUniqueID() == uniqueID ) then
            table.insert(items, item)
        end
    end

    return items
end

function INVENTORY:GetItemCount(uniqueID)
    local count = 0

    for _, itemID in ipairs(self.Items) do
        local item = ax.item:Get(itemID)
        if ( item and item:GetUniqueID() == uniqueID ) then
            count = count + 1
        end
    end

    return count
end

function INVENTORY:CanFitItem(uniqueID, amount)
    amount = amount or 1
    local itemDef = ax.item:Get(uniqueID)
    if ( !itemDef ) then
        return false
    end

    local totalWeight = itemDef:GetWeight() * amount
    return (self:GetWeight() + totalWeight) <= self:GetMaxWeight()
end

ax.inventory.meta = INVENTORY