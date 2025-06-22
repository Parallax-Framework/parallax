--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local CLASS = ax.class.meta or {}
CLASS.__index = CLASS

--- Converts the class to a string representation.
-- @treturn string The string representation of the class.
function CLASS:__tostring()
    return "class[" .. self:GetID() .. "][" .. self:GetUniqueID() .. "][" .. self:GetName() .. "]"
end

--- Compares the class with another class.
-- @param other The other class to compare with.
-- @treturn boolean Whether the classes are equal.
function CLASS:__eq(other) -- TODO: I don't think this even works lol
    return isnumber(other) and self:GetID() == other or
            isstring(other) and self:GetUniqueID() == other or
            istable(other) and self:GetID() == other:GetID() and self:GetUniqueID() == other:GetUniqueID()
end

CLASS.Name          = "Unknown"
CLASS.Description   = "No description available."
CLASS.IsDefault     = false
CLASS.CanSwitchTo   = nil
CLASS.OnSwitch      = nil

function CLASS:SetName(name)
    if ( !isstring(name) or #name == 0 ) then
        ax.util:PrintError("Attempted to set a class's name to an invalid value: " .. tostring(name))
        return false
    end

    self.Name = name
end

--- Sets the class's description.
-- @param description The description to set.
function CLASS:SetDescription(description)
    if ( !isstring(description) ) then
        ax.util:PrintError("Attempted to set a class's description to an invalid value: " .. tostring(description))
        return false
    end

    self.Description = description
end

--- Sets the class's faction by its identifier.
-- @param identifier The identifier of the faction to set.
-- @treturn boolean Whether the faction was set successfully.
-- @realm shared
function CLASS:SetFaction(identifier)
    local factionTable = ax.faction:Get(identifier)
    if ( !ax.util:IsFaction(factionTable) ) then
        ax.util:PrintError("Attempted to set a class's faction to an invalid faction: " .. tostring(identifier))
        return false
    end

    self.Faction = factionTable.ID
end

function CLASS:MakeDefault()
    self.IsDefault = true
end

--- Gets the class's ID.
-- @treturn number The class's ID.
function CLASS:GetID()
    return self.ID
end

--- Gets the players in the class.
-- @treturn table A table of players in the class.
function CLASS:GetPlayers()
    local players = {}
    for _, client in player.Iterator() do
        if ( client:Team() == self:GetFaction() and client:GetClass() == self:GetID() ) then
            table.insert(players, client)
        end
    end

    return players
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
    return self.Faction
end

--- Gets the faction table for the class.
-- @treturn table The faction table for the class.
function CLASS:GetFactionTable()
    return ax.faction:Get(self.Faction)
end

--- Checks if the class is the default class.
-- @treturn boolean Whether the class is the default class.
function CLASS:IsDefault()
    return self.IsDefault
end

--- Registers the class.
-- @treturn boolean Whether the class was registered successfully.
-- @treturn string|nil An error message if the registration failed.
-- @realm shared
function CLASS:Register()
    if ( !ax.util:IsFaction(self:GetFactionTable()) ) then
        ax.util:PrintError("Attempted to register a class without a valid faction!")
        return false
    end

    local bResult = hook.Run("PreClassRegistered", self)
    if ( bResult == false ) then
        ax.util:PrintError("Attempted to register a class that was blocked by a hook!")
        return false, "Attempted to register a class that was blocked by a hook!"
    end

    local uniqueID = string.lower(string.gsub(self:GetName(), "%s+", "_")) .. "_" .. self:GetFaction()
    local instances = ax.class:GetAll()
    for i = 1, #instances do
        if ( instances[i].UniqueID == uniqueID ) then
            return false, "Attempted to register a class that already exists!"
        end
    end

    self.UniqueID = self.UniqueID or uniqueID
    ax.class.stored[self.UniqueID] = self

    for i = 1, #instances do
        if ( instances[i].UniqueID == self.UniqueID ) then
            table.remove(instances, i)
            break
        end
    end

    self.ID = #instances + 1

    table.insert(instances, self)
    ax.class.stored[self.UniqueID] = self

    hook.Run("PostClassRegistered", self)

    return #instances
end