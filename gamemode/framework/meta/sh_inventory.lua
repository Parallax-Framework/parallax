--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local inventory = ax.meta.inventory or {}
inventory.__index = inventory

function inventory:__tostring()
    return "Inventory: " .. tostring(self.id)
end

function inventory:GetMaxWeight()
    return self.maxWeight
end

function inventory:GetWeight()
    local weight = 0
    for i = 1, #self.items do
        local item = self.items[i]
        if ( istable(item) and isnumber(item.weight) ) then
            return weight + item.weight
        end
    end

    return 0
end

function inventory:GetID()
    return self.id
end

function inventory:GetItems()
    return self.items or {}
end

function inventory:GetItemByID(itemID)
    for i = 1, #self.items do
        if ( self.items[i].id == itemID ) then
            return self.items[i]
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

    for i = 1, #self.receivers do
        if ( self.receivers[i] == receiver ) then
            return false -- Already exists.
        end
    end

    if ( istable(receiver) ) then
        for i = 1, #receiver do
            if ( !receiver[i]:IsPlayer() ) then
                ax.util:PrintError("Invalid player provided to ax.inventory:AddReceiver() (" .. tostring(receiver[i]) .. ")")
                return false
            end

            self.receivers[#self.receivers + 1] = receiver[i]

            if ( SERVER ) then
                net.Start("ax.inventory.receiver.add")
                    net.WriteUInt( self.id, 32 )
                    net.WritePlayer(receiver)
                net.Send(self:GetReceivers())
            end

            return true
        end
    elseif ( ax.util:FindPlayer(receiver) ) then
        self.receivers[#self.receivers + 1] = receiver

        if ( SERVER ) then
            net.Start("ax.inventory.receiver.add")
                net.WriteUInt( self.id, 32 )
                net.WritePlayer(receiver)
            net.Send(self:GetReceivers())
        end

        return true
    end

    return false
end

function inventory:RemoveReceiver(receiver)
    if ( !istable(self.receivers) ) then self.receivers = {} return end

    for i = 1, #self.receivers do
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
    function inventory:AddItem(itemUniqueID, data)
        if ( !istable(self.items) ) then self.items = {} end

        local item = ax.item.stored[itemUniqueID]
        if ( !istable(item) ) then
            ax.util:PrintError("Invalid item provided to ax.inventory:AddItem() (" .. tostring(itemUniqueID) .. ")")
            return false
        end

        data = data or {}

        local query = mysql:Insert("ax_items")
            query:Insert("inv_id", self.id)
            query:Insert("data", util.TableToJSON(data))
            query:Callback(function(result, status, lastID)
                if result == false then
                    ax.util:PrintError("Failed to insert item into database for inventory " .. self.id)
                    return false
                end

                local itemObject = setmetatable({}, ax.meta.item)
                for k, v in pairs(item) do
                    itemObject[k] = v
                end

                itemObject.id = lastID
                itemObject.data = data or {}
                itemObject.invID = self.id

                ax.item.instances[itemObject.id] = itemObject

                self.items[#self.items + 1] = itemObject

                net.Start("ax.inventory.item.add")
                    net.WriteUInt(self.id, 32)
                    net.WriteUInt(itemObject.id, 32)
                    net.WriteTable(itemObject.data)
                net.Send(self:GetReceivers())

                return true
            end)
        query:Execute()
    end

    function inventory:RemoveItem(itemID)
        if ( !istable(self.items) ) then self.items = {} return end

        for i = 1, #self.items do
            if ( self.items[i].id == itemID ) then
                local item = self.items[i]

                local query = mysql:Delete("ax_items")
                    query:Where("id", item.id)
                    query:Callback(function(result, status)
                        if result == false then
                            ax.util:PrintError("Failed to remove item from database for inventory " .. self.id)
                            return false
                        end

                        table.remove(self.items, i)

                        net.Start("ax.inventory.item.remove")
                            net.WriteUInt(self.id, 32)
                            net.WriteUInt(item.id, 32)
                        net.Send(self:GetReceivers())

                        return true
                    end)
                query:Execute()

                ax.item.instances[item.id] = nil
                return true
            end
        end

        return false
    end
end

ax.meta.inventory = inventory  -- Keep, inv:GetData is nil otherwise.