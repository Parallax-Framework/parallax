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

--- Class library
-- @module ax.class

ax.class = ax.class or {}
ax.class.stored = {}
ax.class.instances = {}
ax.class.meta = ax.class.meta or {}

function ax.class:Register(classData)
    local CLASS = setmetatable(classData, self.meta)
    if ( !isnumber(CLASS.Faction) ) then
        ax.util:PrintError("Attempted to register a class without a valid faction!")
        return false
    end

    local faction = ax.faction:Get(CLASS.Faction)
    if ( faction == nil or !istable(faction) ) then
        ax.util:PrintError("Attempted to register a class for an invalid faction!")
        return false
    end

    local bResult = hook.Run("PreClassRegistered", CLASS)
    if ( bResult == false ) then
        ax.util:PrintError("Attempted to register a class that was blocked by a hook!")
        return false, "Attempted to register a class that was blocked by a hook!"
    end

    local uniqueID = string.lower(string.gsub(CLASS.Name, "%s+", "_")) .. "_" .. CLASS.Faction
    for k, v in ipairs(self.instances) do
        if ( v.UniqueID == uniqueID ) then
            return false, "Attempted to register a class that already exists!"
        end
    end

    CLASS.UniqueID = CLASS.UniqueID or uniqueID

    self.stored[CLASS.UniqueID] = CLASS

    for k, v in ipairs(self.instances) do
        if ( v.UniqueID == CLASS.UniqueID ) then
            table.remove(self.instances, k)
            break
        end
    end

    CLASS.ID = #self.instances + 1

    table.insert(self.instances, CLASS)
    self.stored[CLASS.UniqueID] = CLASS

    hook.Run("PostClassRegistered", CLASS)

    return CLASS.ID
end

function ax.class:Get(identifier)
    if ( identifier == nil ) then
        ax.util:PrintError("Attempted to get a faction with an invalid identifier!")
        return false
    end

    if ( isnumber(identifier) ) then
        return self.instances[identifier]
    end

    if ( self.stored[identifier] ) then
        return self.stored[identifier]
    end

    for k, v in ipairs(self.instances) do
        if ( ax.util:FindString(v.Name, identifier) or ax.util:FindString(v.UniqueID, identifier) ) then
            return v
        end
    end

    return nil
end

function ax.class:CanSwitchTo(client, classID)
    local class = self:Get(classID)
    if ( !class ) then return false end

    local hookRun = hook.Run("CanPlayerJoinClass", client, class)
    if ( hookRun == false ) then return false end

    if ( isfunction(class.CanSwitchTo) and !class:CanSwitchTo(client) ) then
        return false
    end

    if ( !class.IsDefault ) then
        return false
    end

    return true
end

function ax.class:OnSwitch(client, classID)
    local class = self:Get(classID)
    if ( !class ) then return false end

    local character = client:GetCharacter()
    if ( !character ) then
        ax.util:PrintError("Attempted to switch class for a player without a character!")
        return false
    end

    local hookRun = hook.Run("CanPlayerJoinClass", client, classID)
    if ( hookRun != nil and hookRun == false ) then return false end

    character:SetClass(classID)

    if ( isfunction(class.OnBecome) ) then
        class:OnBecome(client)
    end

    return true
end

function ax.class:GetAll()
    return self.instances
end