--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.item = ax.item or {}
ax.item.meta = ax.item.meta or {}
ax.item.stored = ax.item.stored or {}
ax.item.instances = ax.item.instances or {}

function ax.item:Add(invID, uniqueID, data, callback)
    if ( ax.util:IsCharacter(invID) ) then
        invID = invID:GetID()
    end

    if ( !isnumber(invID) or invID <= 0 ) then
        ax.util:PrintError("Invalid inventory ID provided to ax.item:Add()")
        return false
    end

    if ( !isstring(uniqueID) or uniqueID == "" ) then
        ax.util:PrintError("Invalid unique ID provided to ax.item:Add()")
        return false
    end

    local item = ax.item:Get(uniqueID)
    if ( !ax.util:IsItem(item) ) then
        ax.util:PrintError("Item with unique ID '" .. uniqueID .. "' does not exist.")
        return false
    end

    local inventory = ax.inventory:Get(invID)
    if ( !ax.util:IsInventory(inventory) ) then
        ax.util:PrintError("Inventory with ID '" .. invID .. "' does not exist.")
        return false
    end

    if ( !istable(data) ) then
        data = {}
    end

    -- Use the inventory's AddItem method
    ax.inventory:AddItem(invID, uniqueID, data, callback)
end

function ax.item:PerformAction(itemID, actionName)
    local item = self:Get(itemID)
    if ( !item ) then
        ax.util:PrintError("Item not found: " .. tostring(itemID))
        return false
    end

    local character = ax.character:Get(item:GetOwner())
    if ( !character ) then
        ax.util:PrintError("Character not found for item: " .. tostring(itemID))
        return false
    end

    local client = character:GetPlayer()
    if ( !IsValid(client) ) then
        ax.util:PrintError("Player not found for item: " .. tostring(itemID))
        return false
    end

    local actions = item:GetActions()
    if ( !actions or !actions[actionName] ) then
        ax.util:PrintError("Action not found: " .. tostring(actionName))
        return false
    end

    local action = actions[actionName]
    if ( isfunction(action.OnCanRun) and !action:OnCanRun(item, client) ) then
        client:Notify("You cannot perform this action right now.")
        return false
    end

    if ( isfunction(action.OnRun) ) then
        action:OnRun(item, client)
    end

    hook.Run("PostPlayerItemAction", client, actionName, item)

    return true
end

function ax.item:Transfer(itemID, fromInventory, toInventory, callback)
    local item = self:Get(itemID)
    if ( !item ) then
        if ( callback ) then callback(false) end
        return false
    end

    -- Update database
    ax.database:Update("ax_items", {
        inventory_id = toInventory
    }, "id = " .. itemID, function(success)
        if ( !success ) then
            if ( callback ) then callback(false) end
            return false
        end

        -- Update item instance
        item:SetInventoryID(toInventory)

        -- Update inventory lists
        if ( fromInventory > 0 ) then
            local fromInv = ax.inventory:Get(fromInventory)
            if ( fromInv ) then
                table.RemoveByValue(fromInv.Items, itemID)
            end
        end

        if ( toInventory > 0 ) then
            local toInv = ax.inventory:Get(toInventory)
            if ( toInv ) then
                table.insert(toInv.Items, itemID)
            end
        end

        -- Network changes
        if ( fromInventory > 0 ) then
            local fromInv = ax.inventory:Get(fromInventory)
            if ( fromInv ) then
                local character = fromInv:GetCharacter()
                if ( character ) then
                    local client = character:GetPlayer()
                    if ( IsValid(client) ) then
                        net.Start("ax.inventory.item.remove")
                            net.WriteUInt(fromInventory, 16)
                            net.WriteUInt(itemID, 16)
                        net.Send(client)
                    end
                end
            end
        end

        if ( toInventory > 0 ) then
            local toInv = ax.inventory:Get(toInventory)
            if ( toInv ) then
                local character = toInv:GetCharacter()
                if ( character ) then
                    local client = character:GetPlayer()
                    if ( IsValid(client) ) then
                        net.Start("ax.inventory.item.add")
                            net.WriteUInt(toInventory, 16)
                            net.WriteUInt(itemID, 16)
                            net.WriteString(item:GetUniqueID())
                            net.WriteTable(item:GetData())
                        net.Send(client)
                    end
                end
            end
        end

        if ( callback ) then
            callback(true)
        end
    end)
end

function ax.item:Spawn(itemID, uniqueID, pos, ang, callback, data)
    local entity = ents.Create("ax_item")
    if ( !IsValid(entity) ) then
        ax.util:PrintError("Failed to create item entity")
        if ( callback ) then callback(false) end
        return false
    end

    entity:SetPos(pos)
    entity:SetAngles(ang or Angle(0, 0, 0))
    entity:Spawn()
    entity:SetItem(itemID, uniqueID, data)

    if ( callback ) then
        callback(entity)
    end

    return entity
end