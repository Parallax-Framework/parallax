--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Player management system for creating, storing, and retrieving player data.
-- Supports player variables with custom getters, setters, and change callbacks.
-- Includes networking for synchronizing player data between server and clients.
-- @module ax.player

ax.player = ax.player or {}
ax.player.meta = FindMetaTable("Player")
ax.player.vars = ax.player.vars or {}

--- Get a player variable's value.
-- Retrieves a player variable with fallback to default or provided fallback value.
-- @realm shared
-- @param client Player The player entity
-- @param key string The variable name to retrieve
-- @param fallback any Optional fallback value if variable is not set
-- @return any The variable value, default value, or fallback
-- @usage local data = ax.player:GetVar(player, "customData", "default")
function ax.player:GetVar(client, key, fallback)
    local varTable = ax.player.vars[key]
    if ( !istable(varTable) ) then
        ax.util:PrintError("Invalid player variable key provided to ax.player:GetVar()")
        return fallback
    end

    if ( fallback == nil and varTable.default != nil ) then
        fallback = varTable.default
    end

    local clientTable = client:GetTable()
    if ( !istable(clientTable.axVars) ) then
        clientTable.axVars = {}
    end

    return clientTable.axVars[key] == nil and fallback or clientTable.axVars[key]
end

--- Set a player variable's value.
-- Updates a player variable and handles networking and change callbacks.
-- @realm shared
-- @param client Player The player entity
-- @param key string The variable name to set
-- @param value any The new value to set
-- @param bNoNetworking boolean Optional flag to disable networking (server only)
-- @param recipients table Optional specific recipients for networking (server only)
-- @usage ax.player:SetVar(player, "customData", "new value")
function ax.player:SetVar(client, key, value, bNoNetworking, recipients)
    local varTable = ax.player.vars[key]
    if ( !istable(varTable) ) then
        ax.util:PrintError("Invalid player variable key provided to ax.player:SetVar()")
        return
    end

    if ( isfunction(varTable.changed) ) then
        local success, err = pcall(varTable.changed, client, value, bNoNetworking, recipients)
        if ( !success ) then
            ax.util:PrintError("Error occurred in player variable changed callback:", err)
        end
    end

    local clientTable = client:GetTable()
    if ( !istable(clientTable.axVars) ) then
        clientTable.axVars = {}
    end

    clientTable.axVars[key] = value

    if ( SERVER and !bNoNetworking ) then
        net.Start("ax.player.var")
            net.WritePlayer(client)
            net.WriteString(key)
            net.WriteType(value)
        net.Send(recipients or player.GetAll())
    end
end

--- Register a new player variable.
-- Creates a player variable with getter/setter methods and database integration.
-- Automatically generates Get/Set methods unless disabled with bNoGetter/bNoSetter.
-- @realm shared
-- @param key string The variable name
-- @param data table Variable configuration including default, field, fieldType, etc.
-- @usage ax.player:RegisterVar("customData", {default = "", fieldType = ax.type.text})
function ax.player:RegisterVar(key, data)
    if ( !isstring(key) or !istable(data) ) then
        ax.util:PrintError("Invalid arguments provided to ax.player:RegisterVar()")
        return
    end

    data.key = key
    -- default field key to the provided key if not specified
    if ( !data.field ) then data.field = key end

    self.vars[key] = data

    if ( SERVER and data.field ) then
        ax.database:AddToSchema("ax_players", data.field, data.fieldType or ax.type.string)
    end

    local prettyName = utf8.upper(string.sub(key, 1, 1)) .. string.sub(key, 2)

    if ( !data.bNoGetter ) then
        local keyGet = "Get" .. prettyName
        ax.player.meta[keyGet] = function(client, fallback)
            if ( isfunction(data.Get) ) then
                return data:Get(client, fallback)
            else
                return ax.player:GetVar(client, key, fallback)
            end
        end
    end

    if ( !data.bNoSetter ) then
        local keySet = "Set" .. prettyName
        ax.player.meta[keySet] = function(client, value, bNoNetworking, recipients)
            if ( isfunction(data.Set) ) then
                data:Set(client, value, bNoNetworking, recipients)

                if ( isfunction(data.changed) ) then
                    local success, err = pcall(data.changed, client, value, bNoNetworking, recipients)
                    if ( !success ) then
                        ax.util:PrintError("Error occurred in player variable changed callback:", err)
                    end
                end
            else
                ax.player:SetVar(client, key, value, bNoNetworking, recipients)
            end
        end
    end

    if ( istable(data.alias) ) then
        for i = 1, #data.alias do
            local alias = data.alias[i]
            if ( !isstring(alias) ) then continue end

            self.vars[alias] = data

            local aliasPrettyName = utf8.upper( string.sub( alias, 1, 1 ) ) .. string.sub( alias, 2 )

            if ( !data.bNoGetter ) then
                ax.player.meta[ "Get" .. aliasPrettyName ] = ax.player.meta[ "Get" .. prettyName ]
            end

            if ( !data.bNoSetter ) then
                ax.player.meta[ "Set" .. aliasPrettyName ] = ax.player.meta[ "Set" .. prettyName ]
            end
        end
    end
end
