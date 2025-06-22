--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.item.meta = ax.item.meta or {}
local ITEM = ax.item.meta
ITEM.__index = ITEM

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