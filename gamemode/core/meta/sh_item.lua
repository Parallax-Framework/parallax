----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 --- Made by a transgender queen
 -- Slay queen Riggs
 -- Stay Powerfull against the Patiarchy by a man (Alex Grist) stealing code
 -- #OverwatchFramework #CodeStealingMatters

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local ITEM = ax.item.meta or {}
ITEM.Actions = ITEM.Actions or {}
ITEM.Base = ITEM.Base or "base"
ITEM.Category = ITEM.Category or "Miscellaneous"
ITEM.CharacterID = ITEM.CharacterID or 0
ITEM.Data = ITEM.Data or {}
ITEM.Description = ITEM.Description or "An item that is undefined."
ITEM.Entity = ITEM.Entity or nil
ITEM.Hooks = ITEM.Hooks or {}
ITEM.ID = ITEM.ID or 0
ITEM.InventoryID = ITEM.InventoryID or 0
ITEM.IsBase = ITEM.IsBase or false
ITEM.Material = ITEM.Material or ""
ITEM.Model = ITEM.Model or "models/props_c17/oildrum001.mdl"
ITEM.Name = "Undefined"
ITEM.Skin = ITEM.Skin or 0
ITEM.UniqueID = ITEM.UniqueID or "undefined"
ITEM.Weight = ITEM.Weight or 0

ITEM.__index = ITEM

--- Converts the item to a string representation.
-- @treturn string The string representation of the item.
function ITEM:__tostring()
    return "item[" .. self:GetUniqueID() .. "][" .. self:GetID() .. "]"
end

--- Compares the item with another value.
-- @param other The value to compare with (string or number).
-- @treturn boolean Whether the item matches the given value.
function ITEM:__eq(other)
    if ( isstring(other) ) then
        return self.Name == other
    elseif ( isnumber(other) ) then
        return tonumber(self.ID) == other
    end

    return false
end

--- Gets the item's ID.
-- @treturn number The item's ID.
function ITEM:GetID()
    return tonumber(self.ID) or 0
end

--- Gets the item's unique ID.
-- @treturn string The item's unique ID.
function ITEM:GetUniqueID()
    return self.UniqueID or "undefined"
end

--- Gets the item's name.
-- @treturn string The item's name.
function ITEM:GetName()
    return self.Name or "Undefined"
end

--- Gets the item's description.
-- @treturn string The item's description.
function ITEM:GetDescription()
    return self.Description or "An item that is undefined."
end

--- Gets the item's weight.
-- @treturn number The item's weight.
function ITEM:GetWeight()
    return tonumber(self.Weight) or 0
end

--- Gets the item's category.
-- @treturn string The item's category.
function ITEM:GetCategory()
    return self.Category or "Miscellaneous"
end

--- Gets the item's model.
-- @treturn string The item's model path.
function ITEM:GetModel()
    return self.Model or "models/props_c17/oildrum001.mdl"
end

--- Gets the item's material.
-- @treturn string The item's material.
function ITEM:GetMaterial()
    return self.Material or ""
end

--- Gets the item's skin.
-- @treturn number The item's skin index.
function ITEM:GetSkin()
    return tonumber(self.Skin) or 0
end

--- Gets the item's inventory ID.
-- @treturn number The inventory ID.
function ITEM:GetInventory()
    return tonumber(self.InventoryID) or 0
end

--- Gets the item's owner (character ID).
-- @treturn number The character ID of the owner.
function ITEM:GetOwner()
    return tonumber(self.CharacterID) or 0
end

--- Sets the item's owner (character ID).
-- @tparam number characterID The character ID to set as the owner.
function ITEM:SetOwner(characterID)
    characterID = tonumber(characterID) or 0

    if ( !characterID ) then return end

    self.CharacterID = characterID
end

--- Gets a specific data value from the item.
-- @tparam string key The key of the data to retrieve.
-- @param default The default value to return if the key does not exist.
-- @return The value associated with the key, or the default value.
function ITEM:GetData(key, default)
    if ( !key ) then return end

    if ( self.Data and self.Data[key] ) then
        return self.Data[key]
    end

    return default or nil
end

--- Sets a specific data value for the item.
-- @tparam string key The key of the data to set.
-- @param value The value to set for the key.
function ITEM:SetData(key, value)
    if ( !key ) then return end

    if ( !self.Data ) then
        self.Data = {}
    end

    if ( value == nil ) then
        self.Data[key] = nil
    else
        self.Data[key] = value
    end

    if ( SERVER ) then
        self:SendData(key, value)
    end
end

if ( SERVER ) then
    --- Sends data to the client.
    -- @tparam string key The key of the data to send.
    -- @param value The value of the data to send.
    function ITEM:SendData(key, value)
        local client = ax.character:GetPlayerByCharacter(self:GetOwner())
        if ( !IsValid(client) ) then return end

        ax.net:Start(client, "item.data", self:GetID(), key, value)
    end
end

--- Sets the item's inventory ID.
-- @tparam number id The inventory ID to set.
function ITEM:SetInventory(id)
    if ( !id ) then return end

    self.InventoryID = id
end

--- Gets the item's associated entity.
-- @treturn Entity The entity associated with the item.
function ITEM:GetEntity()
    return self.Entity or nil
end

--- Sets the item's associated entity.
-- @tparam Entity entity The entity to associate with the item.
function ITEM:SetEntity(entity)
    if ( !entity ) then return end

    self.Entity = entity
end

--- Spawns the item in the world.
-- @tparam Vector position The position to spawn the item at.
-- @tparam Angle angles The angles to spawn the item with.
function ITEM:Spawn(position, angles)
    local client = ax.character:GetPlayerByCharacter(self:GetOwner())
    if ( !IsValid(client) ) then return end

    position = position or client:GetDropPosition()
    if ( !position ) then return end

    local item = ax.item:Spawn(nil, uniqueID, position, angles, function()
        if ( self.OnSpawned ) then
            self:OnSpawned(item)
        end

        item:SetUniqueID(self:GetUniqueID())
        item:SetData(self:GetData())
        item:SetEntity(self:GetEntity())

        if ( self.OnSpawned ) then
            self:OnSpawned(item)
        end

        return item
    end)
end

--- Adds a hook to the item.
-- @tparam string name The name of the hook.
-- @tparam function func The function to run when the hook is triggered.
function ITEM:Hook(name, func)
    if ( !name or !func ) then return end

    if ( !self.Hooks ) then
        self.Hooks = {}
    end

    if ( !self.Hooks[name] ) then
        self.Hooks[name] = {}
    end

    table.insert(self.Hooks[name], func)
end

--- Removes the item.
function ITEM:Remove()
    if ( self.Entity and IsValid(self.Entity) ) then
        self.Entity:Remove()
    end

    if ( self.OnRemoved ) then
        self:OnRemoved()
    end

    ax.item:Remove(self:GetID(), callback)
end

--- Registers a new action for this item.
-- @tparam table def The action definition.
--  - Name (string): The name of the action.
--  - Description (string): Optional description of the action.
--  - OnRun (function): The function to run when the action is executed.
--  - OnCanRun (function): Optional function to check if the action can run.
function ITEM:AddAction(def)
    self.Actions = self.Actions or {}
    assert(def.Name and type(def.OnRun) == "function", "ITEM:AddAction requires def.Name (string) and def.OnRun (function)")
    local id = def.ID or def.id or def.Name:gsub("%s+", "")
    self.Actions[id] = def
end

ax.item.meta = ITEM