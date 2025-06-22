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

function ax.class:Instance()
    return setmetatable({}, self.meta)
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

    for i = 1, #self.instances do
        local v = self.instances[i]
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