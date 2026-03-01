--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.item = ax.item or {}

function ax.item:RunAction(client, item, action, context)
    if ( !ax.util:IsValidPlayer(client) ) then
        return false, "Invalid player."
    end

    if ( !istable(item) ) then
        return false, "Invalid item."
    end

    if ( !isstring(action) or action == "" ) then
        return false, "Invalid action."
    end

    local actions = item:GetActions()
    local actionTable = istable(actions) and actions[action] or nil
    if ( !istable(actionTable) ) then
        return false, "That action is not available for this item."
    end

    local canRun, reason = item:CanInteract(client, action, false, context)
    if ( canRun == false ) then
        return false, reason
    end

    local bRemoveAfter = actionTable:OnRun(item, client, context)
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

    return true
end

function ax.item:Transfer(item, fromInventory, toInventory, callback)
    if ( !istable(item) ) then
        return false, "Invalid item provided."
    end

    ax.util:PrintDebug(string.format("Transferring item %s from inventory %s to inventory %s", item.id, tostring(fromInventory), tostring(toInventory)))

    local fromInventoryID = 0
    if ( istable(fromInventory) ) then
        fromInventoryID = fromInventory.id
    elseif ( isnumber(fromInventory) and fromInventory > 0 ) then
        fromInventoryID = fromInventory
        fromInventory = ax.inventory.instances[fromInventoryID]

        if ( !istable(fromInventory) ) then
            return false, "From inventory with ID " .. fromInventoryID .. " does not exist."
        end
    end

    local toInventoryID = 0
    if ( istable(toInventory) ) then
        toInventoryID = toInventory.id
    elseif ( isnumber(toInventory) and toInventory > 0 ) then
        toInventoryID = toInventory
        toInventory = ax.inventory.instances[toInventoryID]

        if ( !istable(toInventory) ) then
            return false, "To inventory with ID " .. toInventoryID .. " does not exist."
        end
    end

    if ( fromInventory == toInventory ) then
        return false, "Source and destination inventories cannot be the same."
    end

    if ( toInventory != 0 and math.Round(toInventory:GetWeight() + item:GetWeight(), 2) > toInventory:GetMaxWeight() ) then
        local message = "The destination inventory cannot hold this item."
        local owner = toInventory:GetOwner()
        if ( istable(owner) and IsValid(owner:GetOwner()) ) then
            message = "Your inventory cannot hold this item."
        end

        return false, message
    end

    local fromIsTemporary = istable(fromInventory) and (fromInventory.isTemporary or fromInventory.noSave)
    local toIsTemporary = istable(toInventory) and (toInventory.isTemporary or toInventory.noSave)
    local itemIsTemporary = item.isTemporary or item.noSave

    if ( itemIsTemporary or fromIsTemporary or toIsTemporary ) then
        if ( fromInventoryID == 0 or toInventoryID == 0 ) then
            return false, "Temporary items cannot be transferred to or from the world inventory."
        end

        if ( !fromIsTemporary or !toIsTemporary ) then
            return false, "Temporary inventory transfers are only supported between temporary inventories."
        end

        toInventory.items[item.id] = item
        item.invID = toInventoryID

        if ( istable(fromInventory) ) then
            fromInventory.items[item.id] = nil
        end

        if ( isfunction(callback) ) then
            callback(true)
        end

        return true
    end

    if ( istable(fromInventory) ) then
        fromInventoryID = fromInventory.id
    elseif ( fromInventory == 0 or fromInventory == nil ) then
        fromInventoryID = 0
    end

    local dropPos
    if ( fromInventoryID != 0 and toInventoryID == 0 ) then
        local owner = fromInventory:GetOwner()
        if ( istable(owner) and IsValid(owner:GetOwner()) ) then
            local trace = {}
            trace.start = owner:GetOwner():GetShootPos()
            trace.endpos = trace.start + (owner:GetOwner():GetAimVector() * 96)
            trace.filter = owner:GetOwner()
            trace = util.TraceLine(trace)

            dropPos = trace.HitPos + trace.HitNormal * 16
        end

        if ( !isvector(dropPos) ) then
            return false, "Failed to determine drop position."
        end
    end

    local query = mysql:Update("ax_items")
        query:Update("inventory_id", toInventoryID)
        query:Where("id", item.id)
        query:Callback(function(result, status)
            local function finish(success, reason)
                if ( isfunction(callback) ) then
                    callback(success, reason)
                end

                return success, reason
            end

            if ( result == false ) then
                ax.util:PrintError("Failed to update item in database during transfer.")
                return finish(false, "A database error occurred.")
            end

            if ( istable(toInventory) and toInventoryID != 0 ) then
                toInventory.items[item.id] = item
                item.invID = toInventoryID
            elseif ( toInventoryID == 0 ) then
                item.invID = 0
            end

            if ( fromInventory != 0 ) then
                fromInventory.items[item.id] = nil
            end

            ax.util:PrintDebug(string.format("Transferred item %s from inventory %s to inventory %s", item.id, tostring(fromInventoryID), tostring(toInventoryID)))

            if ( toInventoryID == 0 ) then
                local itemEntity = ents.Create("ax_item")
                if ( !IsValid(itemEntity) ) then
                    ax.util:PrintError("Failed to create item entity during transfer to world inventory.")
                    return finish(false, "Failed to create item entity.")
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

                ax.util:PrintDebug("Broadcasting to all clients (world inventory)")
            else
                ax.net:Start(toInventory:GetReceivers(), "item.transfer", item.id, fromInventoryID, toInventoryID)

                ax.util:PrintDebug("Sending to inventory receivers only")
                for _, receiver in pairs(toInventory:GetReceivers()) do
                    ax.util:PrintDebug(" - Sent to: " .. tostring(receiver))
                end
            end

            return finish(true)
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
