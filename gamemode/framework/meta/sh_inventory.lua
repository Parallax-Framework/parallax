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

inventory.id = 0
inventory.items = {}
inventory.maxWeight = 30.0 -- kg

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

ax.meta.inventory = inventory  -- Keep, invene:GetData is nil otherwise.