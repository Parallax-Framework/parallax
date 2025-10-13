--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.character = ax.character or {}
ax.character.instances = ax.character.instances or {}
ax.character.meta = ax.character.meta or {}
ax.character.vars = ax.character.vars or {}

function ax.character:Get(id)
    if ( !isnumber(id) ) then
        ax.util:PrintError("Invalid character ID provided to ax.character:Get()")
        return nil
    end

    return ax.character.instances[id]
end

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

function ax.character:SetVar(char, name, value, bNoNetworking, recipients)
    local varTable = ax.character.vars[name]
    if ( !istable(varTable) ) then
        ax.util:PrintError("Invalid character variable name provided to ax.character:SetVar()")
        return
    end

    if ( isfunction(varTable.changed) ) then
        local success, err = pcall(varTable.changed, char, value, bNoNetworking, recipients)
        if ( !success ) then
            ax.util:PrintError("Error occurred in character variable changed callback:", err)
            return
        end
    end

    if ( !istable(char.vars) ) then
        char.vars = {}
    end

    char.vars[name] = value

    -- Skip networking for bot characters since they don't need client-side updates
    if ( SERVER and !bNoNetworking and !char.isBot ) then
        net.Start("ax.character.var")
            net.WriteUInt(char:GetID(), 32)
            net.WriteString(name)
            net.WriteType(value)
        net.Send(recipients or player.GetAll())
    end
end

-- Server-side validation function to check if a variable can be populated during character creation
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

function ax.character:RegisterVar(name, data)
    if ( !isstring(name) or !istable(data) ) then
        ax.util:PrintError("Invalid arguments provided to ax.character:RegisterVar()")
        return
    end

    data.key = name

    self.vars[name] = data

    if ( SERVER and data.field ) then
        ax.database:AddToSchema("ax_characters", data.field, data.fieldType or ax.type.string)
    end

    local prettyName = string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
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
            if ( isfunction(data.Set) ) then
                if ( !istable(char.vars) ) then char.vars = {} end

                data:Set(char, value, bNoNetworking, recipients)

                -- Call changed callback if present
                if ( isfunction(data.changed) ) then
                    -- Protect the callback to avoid crashes
                    local success, err = pcall(data.changed, char, value, bNoNetworking, recipients)
                    if ( !success ) then
                        ax.util:PrintError("Error occurred in character variable changed callback:", err)
                    end
                end
            else
                ax.character:SetVar(char, name, value, bNoNetworking, recipients)
            end
        end
    end

    if ( istable(data.alias) ) then
        for i = 1, #data.alias do
            local alias = data.alias[i]
            if ( !isstring(alias) ) then continue end

            self.vars[alias] = data

            local aliasPrettyName = string.upper( string.sub( alias, 1, 1 ) ) .. string.sub( alias, 2 )

            if ( !data.bNoGetter ) then
                ax.character.meta[ "Get" .. aliasPrettyName ] = ax.character.meta["Get" .. prettyName]
            end

            if ( !data.bNoSetter ) then
                ax.character.meta[ "Set" .. aliasPrettyName ] = ax.character.meta["Set" .. prettyName]
            end
        end
    end
end
