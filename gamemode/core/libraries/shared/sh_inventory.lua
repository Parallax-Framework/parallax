--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.inventory = ax.inventory or {}
ax.inventory.meta = ax.inventory.meta or {}
ax.inventory.instances = ax.inventory.instances or {}

function ax.inventory:Instance()
    local instance = setmetatable({}, self.meta)
    instance.ID = #self.instances + 1
    self.instances[instance.ID] = instance
    
    return instance
end

function ax.inventory:Get(id)
    if ( !isnumber(id) ) then ax.util:PrintError("Invalid inventory ID: " .. tostring(id)) return end
    
    return self.instances[id]
end