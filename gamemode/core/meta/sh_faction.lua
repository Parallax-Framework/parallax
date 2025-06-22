--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local FACTION = ax.faction.meta or {}
FACTION.__index = FACTION

local defaultModels = {
    Model("models/player/group01/male_01.mdl"),
    Model("models/player/group01/male_02.mdl"),
    Model("models/player/group01/male_03.mdl"),
    Model("models/player/group01/male_04.mdl"),
    Model("models/player/group01/male_05.mdl"),
    Model("models/player/group01/male_06.mdl"),
    Model("models/player/group01/male_07.mdl"),
    Model("models/player/group01/male_08.mdl"),
    Model("models/player/group01/male_09.mdl"),
    Model("models/player/group01/female_01.mdl"),
    Model("models/player/group01/female_02.mdl"),
    Model("models/player/group01/female_03.mdl"),
    Model("models/player/group01/female_04.mdl"),
    Model("models/player/group01/female_05.mdl"),
    Model("models/player/group01/female_06.mdl")
}

FACTION.Name = "Unknown Faction"
FACTION.Description = "No description available."
FACTION.IsDefault = false
FACTION.Color = color_white
FACTION.Models = defaultModels
FACTION.Classes = {}

--- Converts the faction to a string representation.
-- @treturn string The string representation of the faction.
function FACTION:__tostring()
    return "faction[" .. self:GetID() .. "][" .. self:GetUniqueID() .. "]"
end

--- Compares the faction with another faction.
-- @param other The other faction to compare with.
-- @treturn boolean Whether the factions are equal.
function FACTION:__eq(other) -- TODO: I don't think this even works lol
    return isnumber(other) and self:GetID() == other or
            isstring(other) and self:GetUniqueID() == other or
            istable(other) and self:GetID() == other:GetID() and self:GetUniqueID() == other:GetUniqueID()
end

--- Gets the faction's ID.
-- @treturn number The faction's ID.
function FACTION:GetID()
    return self.ID
end

--- Gets the players in the faction.
-- @treturn table A table of players in the faction.
function FACTION:GetPlayer()
    return team.GetPlayers(self:GetID())
end

--- Gets the faction's name.
-- @treturn string The faction's name.
function FACTION:GetName()
    return self.Name or "Unknown Faction"
end

--- Gets the faction's unique ID.
-- @treturn string The faction's unique ID.
function FACTION:GetUniqueID()
    return self.UniqueID or "unknown_faction"
end

--- Gets the faction's description.
-- @treturn string The faction's description.
function FACTION:GetDescription()
    return self.Description or "No description available."
end

--- Gets the faction's color.
-- @treturn table The faction's color as a color table.
function FACTION:GetColor()
    return self.Color or ax.color:Get("white")
end
FACTION.GetColour = FACTION.GetColor

--- Gets the faction's models.
-- @treturn table A table of model paths for the faction.
function FACTION:GetModels()
    return self.Models or defaultModels
end

--- Gets the classes associated with the faction.
-- @treturn table A table of class instances associated with the faction.
function FACTION:GetClasses()
    local classes = {}
    local instanceCount = #ax.class.instances
    for i = 1, instanceCount do
        local v = ax.class.instances[i]
        if ( v.Faction == self:GetID() ) then
            table.insert(classes, v)
        end
    end

    return classes
end

--- Sets the faction's name.
-- @param name The name of the faction.
-- @treturn boolean True if the name was set successfully, false otherwise.
-- @treturn string|nil An error message if the name was not set successfully.
function FACTION:SetName(name)
    if ( !isstring(name) ) then
        ax.util:PrintError("Attempted to set a faction's name without a valid name!")
        return false, "Attempted to set a faction's name without a valid name!"
    end

    self.Name = name
    return true
end

--- Sets the faction's description.
-- @param description The description of the faction.
-- @treturn boolean True if the description was set successfully, false otherwise.
-- @treturn string|nil An error message if the description was not set successfully.
function FACTION:SetDescription(description)
    if ( !isstring(description) ) then
        ax.util:PrintError("Attempted to set a faction's description without a valid description!")
        return false, "Attempted to set a faction's description without a valid description!"
    end

    self.Description = description
    return true
end

--- Sets the faction's color.
-- @param color The color of the faction.
-- @treturn boolean True if the color was set successfully, false otherwise.
function FACTION:SetColor(color)
    if ( !ax.util:CoerceType(ax.types.color, color) ) then
        ax.util:PrintError("Attempted to set a faction's color without a valid color!")
        return false, "Attempted to set a faction's color without a valid color!"
    end

    self.Color = color
    return true
end

FACTION.SetColour = FACTION.SetColor

--- Sets the faction's models.
-- @param models A table of model paths for the faction.
-- @treturn boolean True if the models were set successfully, false otherwise.
function FACTION:SetModels(models)
    if ( !istable(models) and !isstring(models) ) then
        ax.util:PrintError("Attempted to set a faction's models without a valid table or string!")
        return false, "Attempted to set a faction's models without a valid table or string!"
    end

    self.Models = models
    return true
end

function FACTION:MakeDefault()
    self.IsDefault = true
end

function FACTION:Register()
    local bResult = hook.Run("PreFactionRegistered", self)
    if ( bResult == false ) then
        ax.util:PrintError("Attempted to register a faction that was blocked by a hook!")
        return false, "Attempted to register a faction that was blocked by a hook!"
    end

    local uniqueID = string.lower(string.gsub(self:GetName(), "%s+", "_"))
    for i = 1, #ax.faction.instances do
        if ( ax.faction.instances[i].UniqueID == uniqueID ) then
            return false, "Attempted to register a faction that already exists!"
        end
    end

    self.UniqueID = self.UniqueID or uniqueID
    self.ID = #ax.faction.instances + 1

    table.insert(ax.faction.instances, self)
    ax.faction.stored[self.UniqueID] = self

    team.SetUp(self:GetID(), self:GetName(), self:GetColor(), false)
    hook.Run("PostFactionRegistered", self)

    return #ax.faction.instances
end