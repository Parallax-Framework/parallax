--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Entity and global variable relay system for synchronized data storage.
-- Provides networked variable storage for entities and global values with automatic cleanup.
-- Similar to SetNWVar/GetNWVar but with more control over networking and recipients.
-- @module ax.relay

ax.relay = ax.relay or {}
ax.relay.data = ax.relay.data or {}

if ( SERVER ) then
    function ax.relay:Sync(recipients)
        net.Start("ax.relay.sync")
            net.WriteTable(ax.relay.data)
        if ( recipients ) then
            net.Send(recipients)
        else
            net.Broadcast()
        end
    end
end

local ENTITY = FindMetaTable("Entity")

--- Set a relay variable on an entity with optional networking.
-- Stores a value associated with this entity and optionally syncs it to clients.
-- @realm shared
-- @param name string The variable name to set
-- @param value any The value to store (will be networked if on server)
-- @param bNoNetworking boolean Optional flag to disable networking (server only)
-- @param recipients table Optional specific recipients for networking (server only)
-- @usage entity:SetRelay("health_percentage", 0.75)
-- @usage player:SetRelay("status", "injured", false, {otherPlayer})
function ENTITY:SetRelay(name, value, bNoNetworking, recipients)
    if ( !isstring(name) ) then
        ax.util:PrintError("Invalid 'name' argument provided to method Entity:SetRelay()")
        return
    end

    local index = tostring(self:EntIndex())
    if ( self:IsPlayer() ) then
        index = self:SteamID64()
    end

    ax.relay.data[index] = ax.relay.data[index] or {}
    
    -- Only network if the value actually changed
    local oldValue = ax.relay.data[index][name]
    if ( oldValue == value ) then
        return  -- No change, skip networking
    end
    
    ax.relay.data[index][name] = value

    if ( !bNoNetworking and SERVER ) then
        net.Start("ax.relay.update")
            net.WriteString(index)
            net.WriteString(name)
            net.WriteType(value)
        if ( recipients ) then
            net.Send(recipients)
        else
            net.Broadcast()
        end
    end
end

--- Get a relay variable from an entity.
-- Retrieves a stored value associated with this entity.
-- @realm shared
-- @param name string The variable name to retrieve
-- @param fallback any Optional fallback value if variable is not set
-- @return any The stored value or fallback if not found
-- @usage local health = entity:GetRelay("health_percentage", 1.0)
-- @usage local status = player:GetRelay("status", "healthy")
function ENTITY:GetRelay(name, fallback)
    if ( !isstring(name) ) then return fallback end

    local index = tostring(self:EntIndex())
    if ( self:IsPlayer() ) then
        index = self:SteamID64()
    end

    ax.relay.data[index] = ax.relay.data[index] or {}

    return ax.relay.data[index][name] != nil and ax.relay.data[index][name] or fallback
end

--- Set a global relay variable with optional networking.
-- Stores a global value that can be accessed from anywhere and optionally syncs to clients.
-- @realm shared
-- @param name string The variable name to set
-- @param value any The value to store (will be networked if on server)
-- @param bNoNetworking boolean Optional flag to disable networking (server only)
-- @param recipients table Optional specific recipients for networking (server only)
-- @usage SetRelay("round_state", "preparation")
-- @usage SetRelay("server_message", "Welcome!", false, specificPlayers)
function SetRelay(name, value, bNoNetworking, recipients)
    if ( !isstring(name) ) then
        ax.util:PrintError("Invalid 'name' argument provided to function SetRelay()")
        return
    end

    ax.relay.data["global"] = ax.relay.data["global"] or {}
    ax.relay.data["global"][name] = value

    if ( !bNoNetworking and SERVER ) then
        net.Start("ax.relay.update")
            net.WriteString("global")
            net.WriteString(name)
            net.WriteType(value)
        if ( recipients ) then
            net.Send(recipients)
        else
            net.Broadcast()
        end
    end
end

--- Get a global relay variable.
-- Retrieves a stored global value that can be accessed from anywhere.
-- @realm shared
-- @param name string The variable name to retrieve
-- @param fallback any Optional fallback value if variable is not set
-- @return any The stored value or fallback if not found
-- @usage local roundState = GetRelay("round_state", "waiting")
-- @usage local message = GetRelay("server_message", "")
function GetRelay(name, fallback)
    if ( !isstring(name) ) then return fallback end

    ax.relay.data["global"] = ax.relay.data["global"] or {}
    return ax.relay.data["global"][name] != nil and ax.relay.data["global"][name] or fallback
end

-- Clean up existing hook to prevent duplicates on reload
hook.Remove("EntityRemoved", "ax.relay.cleanup")

hook.Add("EntityRemoved", "ax.relay.cleanup", function(ent, fullUpdate)
    if ( fullUpdate ) then return end

    local index = tostring(ent:EntIndex())
    if ( ent:IsPlayer() ) then
        index = ent:SteamID64()
    end

    ax.relay.data[index] = nil
end)
