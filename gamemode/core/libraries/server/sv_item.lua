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

    local inventory = ax.inventory:GetInventory(invID)
    if ( !ax.util:IsInventory(inventory) ) then
        ax.util:PrintError("Inventory with ID '" .. invID .. "' does not exist.")
        return false
    end

    // My brain is filled with confusion
end