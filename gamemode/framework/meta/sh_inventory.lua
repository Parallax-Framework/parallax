--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local inventory = ax.inventory.meta or {}
inventory.__index = inventory

function inventory:__tostring()
    return string.format("Inventory [%d]", self.id or 0)
end

function inventory:GetMaxWeight()
    return self.maxWeight
end

function inventory:GetWeight()
    local weight = 0
    for k, v in pairs(self.items) do
        if ( istable(v) and isnumber(v.weight) ) then
            weight = weight + v.weight
        end
    end

    return weight
end

function inventory:GetID()
    return self.id
end

function inventory:GetItems()
    return self.items or {}
end

function inventory:GetItemByID(itemID)
    for k, v in pairs(self.items) do
        if ( v.id == itemID ) then
            return v
        end
    end

    return nil
end

function inventory:GetReceivers()
    return self.receivers or {}
end

function inventory:IsReceiver(client)
    for i = 1, #self.receivers do
        if ( self.receivers[i] == client ) then
            return true
        end
    end

    return false
end

function inventory:AddReceiver(receiver)
    if ( !istable(self.receivers) ) then self.receivers = {} end

    for i = #self.receivers, 1, -1 do
        if ( self.receivers[i] == receiver ) then
            return false -- Already exists.
        end
    end

    if ( istable(receiver) ) then
        for i = #receiver, 1, -1 do
            if ( !receiver[i]:IsPlayer() ) then
                ax.util:PrintError("Invalid player provided to ax.inventory:AddReceiver() (" .. tostring(receiver[i]) .. ")")
                return false
            end

            self.receivers[#self.receivers + 1] = receiver[i]

            if ( SERVER ) then
                net.Start("ax.inventory.receiver.add")
                    net.WriteUInt(self.id, 32)
                    net.WritePlayer(receiver)
                net.Send(self:GetReceivers())
            end

            return true
        end
    elseif ( ax.util:FindPlayer(receiver) ) then
        self.receivers[#self.receivers + 1] = receiver

        if ( SERVER ) then
            net.Start("ax.inventory.receiver.add")
                net.WriteUInt(self.id, 32)
                net.WritePlayer(receiver)
            net.Send(self:GetReceivers())
        end

        return true
    end

    return false
end

function inventory:RemoveReceiver(receiver)
    if ( !istable(self.receivers) ) then self.receivers = {} return end

    for i = #self.receivers, 1, -1 do
        if ( self.receivers[i] == receiver ) then
            table.remove(self.receivers, i)

            if ( SERVER ) then
                net.Start("ax.inventory.receiver.remove")
                    net.WriteUInt(self.id, 32)
                    net.WritePlayer(receiver)
                net.Send(self:GetReceivers())
            end

            return true
        end
    end

    return false
end

if ( SERVER ) then
    function inventory:AddItem(class, data)
        if ( !istable(self.items) ) then self.items = {} end

        local item = ax.item.stored[class]
        if ( !istable(item) ) then
            ax.util:PrintError("Invalid item provided to ax.inventory:AddItem() (" .. tostring(class) .. ")")
            return false
        end

        data = data or {}

        local query = mysql:Insert("ax_items")
            query:Insert("class", class)
            query:Insert("inventory_id", self.id)
            query:Insert("data", util.TableToJSON(data))
            query:Callback(function(result, status, lastID)
                if ( result == false ) then
                    ax.util:PrintError("Failed to insert item into database for inventory " .. self.id)
                    return false
                end

                local itemObject = setmetatable(item, ax.item.meta)
                itemObject.id = lastID
                itemObject.data = data or {}

                ax.item.instances[ lastID ] = itemObject

                self.items[ lastID ] = itemObject

                net.Start("ax.inventory.item.add")
                    net.WriteUInt(self.id, 32)
                    net.WriteUInt( itemObject.id, 32 )
                    net.WriteString( itemObject.class )
                    net.WriteTable( itemObject.data )
                net.Send(self:GetReceivers())

                return true
            end)
        query:Execute()
    end

    function inventory:RemoveItem(itemID)
        if ( !istable(self.items) ) then self.items = {} return end

        if ( isstring( itemID ) and ax.item.stored[ itemID ] ) then
            for _, v in pairs(self.items) do
                if ( v.class == itemID ) then
                    itemID = v.id
                    break
                end
            end
        end

        for item_id, item_data in pairs(self.items) do
            if ( item_data.id == itemID ) then
                local query = mysql:Delete("ax_items")
                    query:Where("id", itemID)
                    query:Callback(function(result, status)
                        if ( result == false ) then
                            ax.util:PrintError("Failed to remove item from database for inventory " .. self.id)
                            return false
                        end

                        self.items[item_id] = nil
                        ax.item.instances[itemID] = nil

                        net.Start("ax.inventory.item.remove")
                            net.WriteUInt(self.id, 32)
                            net.WriteUInt(itemID, 32)
                        net.Send(self:GetReceivers())

                        return true
                    end)
                query:Execute()

                break
            end
        end

        return false
    end
end

ax.inventory.meta = inventory
