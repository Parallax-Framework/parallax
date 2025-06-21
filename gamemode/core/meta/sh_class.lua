--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local CLASS = Parallax.Class.Meta or {}
CLASS.__index = CLASS

CLASS.Name = "Unknown"
CLASS.Description = "No description available."
CLASS.IsDefault = false
CLASS.CanSwitchTo = nil
CLASS.OnSwitch = nil

--- Converts the class to a string representation.
-- @treturn string The string representation of the class.
function CLASS:__tostring()
    return "class[" .. self:GetID() .. "][" .. self:GetUniqueID() .. "]"
end

--- Compares the class with another class.
-- @param other The other class to compare with.
-- @treturn boolean Whether the classes are equal.
function CLASS:__eq(other)
    return self.ID == other.ID
end

--- Gets the class's ID.
-- @treturn number The class's ID.
function CLASS:GetID()
    return self.ID
end

--- Gets the players in the class.
-- @treturn table A table of players in the class.
function CLASS:GetPlayer()
    return team.GetPlayers(self:GetID())
end

--- Gets the class's name.
-- @treturn string The class's name.
function CLASS:GetName()
    return self.Name or "Unknown Class"
end

--- Gets the class's unique ID.
-- @treturn string The class's unique ID.
function CLASS:GetUniqueID()
    return self.UniqueID or "unknown_class"
end

--- Gets the class's description.
-- @treturn string The class's description.
function CLASS:GetDescription()
    return self.Description or "No description available."
end

--- Gets the faction associated with the class.
-- @treturn table The faction associated with the class.
function CLASS:GetFaction()
    return Parallax.Faction:Get(self.Faction)
end

--- Checks if the class is the default class.
-- @treturn boolean Whether the class is the default class.
function CLASS:GetIsDefault()
    return self.IsDefault or false
end