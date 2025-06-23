--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local CHAR = ax.character.meta or {}
CHAR.__index = CHAR
CHAR.ID = 0
CHAR.Variables = {}

--- Converts the character to a string representation.
-- @treturn string The string representation of the character.
function CHAR:__tostring()
    return "character[" .. self:GetID() .. "]"
end

--- Compares the character with another character.
-- @param other The other character to compare with.
-- @treturn boolean Whether the characters are equal.
function CHAR:__eq(other)
    return self.ID == other.ID
end

--- Gets the character's ID.
-- @treturn number The character's ID.
function CHAR:GetID()
    return self.ID
end

--- Gets the character's Steam ID.
-- @treturn string The character's Steam ID.
function CHAR:GetSteamID()
    return self.SteamID
end

--- Gets the player associated with the character.
-- @treturn Player The player associated with the character.
function CHAR:GetPlayer()
    return self.Player
end

--- Gets a specific inventory by name.
-- @tparam string name The name of the inventory (default: "Main").
-- @treturn table|nil The inventory if found, or nil if not found.
function CHAR:GetInventoryID()
    return self.InventoryID
end

--- Gets the character's inventory instance.
-- @treturn table|nil The inventory instance if found, or nil if not found.
function CHAR:GetInventory()
    local invID = self:GetInventoryID()
    if ( !isnumber(invID) or invID <= 0 ) then
        ax.util:PrintError("Invalid inventory ID for character " .. self:GetID())
        return nil
    end

    return ax.inventory:GetInventory(invID)
end

--- Gives money to the character.
-- @tparam number amount The amount of money to give.
function CHAR:GiveMoney(amount)
    if ( amount < 0 ) then
        amount = math.abs(amount)
        ax.util:PrintWarning("Character " .. self:GetID() .. " tried to give negative amount, converted to positive number. Call :TakeMoney instead!")
    end

    self:SetMoney(self:GetMoney() + amount)
    hook.Run("OnCharacterGiveMoney", self, amount)
end

--- Takes money from the character.
-- @tparam number amount The amount of money to take.
function CHAR:TakeMoney(amount)
    if ( amount < 0 ) then
        amount = math.abs(amount)
        ax.util:PrintWarning("Character " .. self:GetID() .. " tried to take negative amount, converted to positive number. Call :GiveMoney instead!")
    end

    self:SetMoney(self:GetMoney() - amount)
    hook.Run("OnCharacterTakeMoney", self, amount)
end

--- Checks if the character has a specific flag.
-- @tparam string flag The flag to check for.
-- @treturn boolean Whether the character has the flag.
function CHAR:HasFlag(flag)
    if ( !ax.flag:Get(flag) ) then return false end

    local flags = self:GetFlags()
    if ( !isstring(flags) or flags == "" ) then return false end

    if ( string.find(flags, flag) ) then return true end

    return false
end

--- Gets the faction data associated with the character.
-- @treturn table|nil The faction data if found, or nil if not found.
function CHAR:GetFactionData()
    local faction = self:GetFaction()
    if ( !faction ) then return end

    local factionData = ax.faction:Get(faction)
    if ( !factionData ) then return end

    return factionData
end

--- Gets the class data associated with the character.
-- @treturn table|nil The class data if found, or nil if not found.
function CHAR:GetClassData()
    local class = self:GetClass()
    if ( !class ) then return end

    local classData = ax.class:Get(class)
    if ( !classData ) then return end

    return classData
end

--- Gets a specific data value associated with the character.
-- @tparam string key The key of the data to retrieve.
-- @param default The default value to return if the key does not exist.
-- @return The value associated with the key, or the default value.
function CHAR:GetData(key, default)
    if ( !isstring(key) or key == "" ) then return default end

    local data = self:GetDataInternal() or "[]"
    if ( !istable(data) ) then
        data = util.JSONToTable(data) or {}
    end

    local value = data[key]
    if ( value == nil ) then
        return default
    end

    return value
end

function CHAR:SetInventory(inventory)
    if ( !inventory or !isnumber(inventory:GetID()) or inventory:GetID() <= 0 ) then
        ax.util:PrintError("Invalid inventory provided to CHAR:SetInventory()")
        return
    end

    self.InventoryID = inventory:GetID()
end

if ( SERVER ) then
    --- Sets a specific data value for the character.
    -- @tparam string key The key of the data to set.
    -- @param value The value to set for the key.
    function CHAR:SetData(key, value)
        if ( !isstring(key) or key == "" ) then return end

        local data = self:GetDataInternal() or "[]"
        if ( !istable(data) ) then
            data = util.JSONToTable(data) or {}
        end

        data[key] = value

        data = util.TableToJSON(data)
        self:SetDataInternal(data)
    end

    --- Gives a specific flag to the character.
    -- @tparam string flag The flag to give.
    function CHAR:GiveFlag(flag)
        if ( !ax.flag:Get(flag) ) then return end

        local hasFlag = self:HasFlag(flag)
        if ( hasFlag ) then return end

        local flags = self:GetFlags()
        if ( !isstring(flags) or flags == "" ) then
            flags = flag
        else
            flags = flags .. flag
        end

        self:SetFlags(flags)

        local flagInfo = ax.flag:Get(flag)
        if ( istable(flagInfo) and isfunction(flagInfo.callback) ) then
            flagInfo:callback(self, true)
        end
    end

    --- Removes a specific flag from the character.
    -- @tparam string flag The flag to remove.
    function CHAR:TakeFlag(flag)
        if ( !ax.flag:Get(flag) ) then return end

        local hasFlag = self:HasFlag(flag)
        if ( !hasFlag ) then return end

        local flags = self:GetFlags()
        if ( !flags or flags == "" ) then return end

        flags = string.Replace(flags, flag, "")
        flags = string.Trim(flags)
        self:SetFlags(flags)

        local flagInfo = ax.flag:Get(flag)
        if ( istable(flagInfo) and isfunction(flagInfo.callback) ) then
            flagInfo:callback(self, false)
        end
    end
end