--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local item = ax.item.meta or {}
item.__index = item

function item:GetData(key)
    if ( !istable(self.data) ) then self.data = {} end

    return self.data[key]
end

function item:SetData(key, value)
    if ( !istable(self.data) ) then self.data = {} end

    self.data[key] = value
end

function item:GetActions()
    return self.actions
end

function item:AddAction(name, action)
    if ( !istable(self.actions) ) then self.actions = {} end

    self.actions[name] = action
end

function item:CanInteract( client, action )
    local try, catch = hook.Run("CanPlayerInteractItem", client, self, action)
    if ( try == false ) then
        if ( isstring(catch) and #catch > 0 ) then
            client:Notify(catch, "error")
        end

        return false
    end

    return true
end

ax.item.meta = item
