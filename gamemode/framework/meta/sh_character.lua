--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local character = ax.meta.character or {}
character.__index = character

character.data = {}
character.id = 0

function character:__tostring()
    return "Character: " .. tostring(self.id) .. " (" .. self.name .. ")"
end

function character:GetInventory()
    return ax.inventory.instances[self.id_inv]
end

function character:GetData(key)
    return self.data[key]
end

function character:SetData(key, value)
    self.data[key] = value
end

ax.meta.character = character -- Keep, character:GetData is nil otherwise.