--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Character management system for creating, storing, and retrieving character data.
-- Supports character variables with custom getters, setters, and change callbacks.
-- Includes networking for synchronizing character data between server and clients.
-- @module ax.character

ax.character = ax.character or {}
ax.character.instances = ax.character.instances or {}
ax.character.meta = ax.character.meta or {}
ax.character.vars = ax.character.vars or {}

--- Get a character by their unique ID.
-- @realm shared
-- @param id number The character's unique ID
-- @return table|nil The character table if found, nil if invalid ID or not found
-- @usage local character = ax.character:Get(123)
function ax.character:Get(id)
    if ( !isnumber(id) ) then
        ax.util:PrintError("Invalid character ID provided to ax.character:Get()")
        return nil
    end

    return ax.character.instances[id]
end

--- Get a character variable's value.
-- Retrieves a character variable with fallback to default or provided fallback value.
-- @realm shared
-- @param char table The character instance
-- @param name string The variable name to retrieve
-- @param fallback any Optional fallback value if variable is not set
-- @return any The variable value, default value, or fallback
-- @usage local description = ax.character:GetVar(character, "description", "No description")
function ax.character:GetVar(char, name, fallback)
    local varTable = ax.character.vars[name]
    if ( !istable(varTable) ) then
        ax.util:PrintError("Invalid character variable name provided to ax.character:GetVar()")
        return fallback
    end

    if ( fallback == nil and varTable.default != nil ) then
        fallback = varTable.default
    end

    if ( !istable(char.vars) ) then
        char.vars = {}
    end

    return char.vars[name] == nil and fallback or char.vars[name]
end

--- Set a character variable's value.
-- Updates a character variable and handles networking and change callbacks.
-- @realm shared
-- @param char table The character instance
-- @param name string The variable name to set
-- @param value any The new value to set
-- @param bNoNetworking boolean Optional flag to disable networking (server only)
-- @param recipients table Optional specific recipients for networking (server only)
-- @param bNoDBUpdate boolean Optional flag to disable database update (server only)
-- @usage ax.character:SetVar(character, "description", "A mysterious figure")
function ax.character:SetVar(char, name, value, bNoNetworking, recipients, bNoDBUpdate)
    local varTable = ax.character.vars[name]
    if ( !istable(varTable) ) then
        ax.util:PrintError("Invalid character variable name provided to ax.character:SetVar()")
        return
    end

    if ( !istable(char.vars) ) then
        char.vars = {}
    end

    if ( isfunction(varTable.changed) ) then
        local success, err = pcall(varTable.changed, char, value, char.vars[name], bNoNetworking, recipients)
        if ( !success ) then
            ax.util:PrintError("Error occurred in character variable changed callback:", err)
            return
        end
    end

    char.vars[name] = value

    -- Network character variable changes to all clients
    if ( SERVER and !bNoNetworking ) then
        if ( char.isBot ) then
            self:SyncBotToClients(char, recipients)
            return
        end

        if ( istable(recipients) or isentity(recipients) ) then
            ax.net:Start(recipients, "ax.character.var", char:GetID(), name, value)
        elseif ( isvector(recipients) ) then
            ax.net:StartPVS(recipients, "ax.character.var", char:GetID(), name, value)
        else
            ax.net:Start(nil, "ax.character.var", char:GetID(), name, value)
        end
    end

    hook.Run("CharacterVarChanged", char, name, value)

    if ( SERVER and !bNoDBUpdate and isstring(varTable.field) ) then
        local query = mysql:Update("ax_characters")
            query:Where("id", char:GetID())

            if ( istable(value) ) then
                value = ax.util:SafeParseTable(value, true)
            elseif ( isbool(value) ) then
                value = value == true and 1 or 0
            end

            query:Update(varTable.field, value)
            query:Callback(function(result, status, lastID)
                if ( result == false ) then
                    ax.util:PrintError("Failed to update character variable '" .. name .. "' in database for character ID " .. char:GetID())
                end

                print("Character variable '" .. name .. "' updated in database for character ID " .. char:GetID() .. ".")
            end)
        query:Execute()
    end
end

--- Sync a bot character to all clients for variable updates.
-- Sends bot character data to clients so they can receive variable changes.
-- @realm server
-- @param char table The bot character instance
-- @param recipients table Optional specific recipients, defaults to all players
-- @usage ax.character:SyncBotToClients(botCharacter)
function ax.character:SyncBotToClients(char, recipients)
    if ( CLIENT ) then return end

    if ( !istable(char) or !char.isBot ) then
        ax.util:PrintError("Invalid bot character provided to ax.character:SyncBotToClients()")
        return
    end

    -- Send bot character data to clients
    ax.net:Start(recipients or player.GetAll(), "ax.character.bot.sync", char:GetID(), char)
end

--- Check if a variable can be populated during character creation.
-- Server-side validation to determine if a variable is available for population.
-- @realm server
-- @param varName string The variable name to check
-- @param payload table Character creation payload data
-- @param client Player The client creating the character
-- @return boolean, string|nil True if allowed, false if not. Error message if denied.
-- @usage local canPop, reason = ax.character:CanPopulateVar("description", data, player)
function ax.character:CanPopulateVar(varName, payload, client)
    local varTable = self.vars[varName]
    if ( !istable(varTable) ) then
        return false, "Invalid character variable"
    end

    if ( isfunction(varTable.canPopulate) ) then
        local success, result = pcall(function()
            return varTable:canPopulate(payload, client)
        end)

        if ( !success ) then
            return false, "canPopulate callback failed: " .. tostring(result)
        end

        return result, result and nil or "Variable not available for this configuration"
    end

    -- If no canPopulate function, allow by default
    return true, nil
end

--- Register a new character variable.
-- Creates a character variable with getter/setter methods and database integration.
-- Automatically generates Get/Set methods unless disabled with bNoGetter/bNoSetter.
-- @realm shared
-- @param name string The variable name
-- @param data table Variable configuration including default, field, fieldType, etc.
-- @usage ax.character:RegisterVar("description", {default = "", fieldType = ax.type.text})
function ax.character:RegisterVar(name, data)
    if ( !isstring(name) or !istable(data) ) then
        ax.util:PrintError("Invalid arguments provided to ax.character:RegisterVar()")
        return
    end

    data.key = name
    if ( !data.field ) then data.field = name end

    self.vars[name] = data

    if ( SERVER and data.field ) then
        ax.database:AddToSchema("ax_characters", data.field, data.fieldType or ax.type.string)
    end

    local prettyName = utf8.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
    if ( !data.bNoGetter ) then
        local nameGet = "Get" .. prettyName

        ax.character.meta[nameGet] = function(char, fallback)
            if ( isfunction(data.Get) ) then
                if ( !istable(char.vars) ) then char.vars = {} end

                return data:Get(char, fallback)
            else
                return ax.character:GetVar(char, name, fallback)
            end
        end
    end

    if ( !data.bNoSetter ) then
        local nameSet = "Set" .. prettyName
        ax.character.meta[nameSet] = function(char, value, bNoNetworking, recipients)
            local previousValue = nil
            if ( isfunction(data.Get) ) then
                if ( !istable(char.vars) ) then char.vars = {} end

                previousValue = data:Get(char)
            else
                previousValue = ax.character:GetVar(char, name)
            end

            if ( isfunction(data.Set) ) then
                if ( !istable(char.vars) ) then char.vars = {} end

                data:Set(char, value, previousValue, bNoNetworking, recipients)

                if ( isfunction(data.changed) ) then
                    -- Protect the callback to avoid crashes
                    local success, err = pcall(data.changed, char, value, previousValue, bNoNetworking, recipients)
                    if ( !success ) then
                        ax.util:PrintError("Error occurred in character variable changed callback:", err)
                    end
                end
            else
                ax.character:SetVar(char, name, value, previousValue, bNoNetworking, recipients)
            end
        end
    end

    if ( istable(data.alias) ) then
        for i = 1, #data.alias do
            local alias = data.alias[i]
            if ( !isstring(alias) ) then
                ax.util:PrintWarning("Invalid alias provided for character variable '" .. name .. "'")
                continue
            end

            self.vars[alias] = data

            local aliasPrettyName = utf8.upper(string.sub(alias, 1, 1)) .. string.sub(alias, 2)

            if ( !data.bNoGetter ) then
                ax.character.meta["Get" .. aliasPrettyName] = ax.character.meta["Get" .. prettyName]
            end

            if ( !data.bNoSetter ) then
                ax.character.meta["Set" .. aliasPrettyName] = ax.character.meta["Set" .. prettyName]
            end
        end
    end
end
