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
ax.meta.character = ax.meta.character or {}
ax.character.vars = ax.character.vars or {}

function ax.character:Get(id)
    if ( !isnumber(id) ) then
        ax.util:PrintError("Invalid character ID provided to ax.character:Get()")
        return nil
    end

    return ax.character.instances[id]
end

local function GetVar(char, name, fallback)
    local varTable = ax.character.vars[name]
    if ( !istable(varTable) ) then
        ax.util:PrintError("Invalid character variable name provided to ax.character:GetVar()")
        return fallback
    end


    if ( fallback == nil and varTable.Default != nil ) then
        fallback = varTable.Default
    end

    if ( !istable(char.vars) ) then
        char.vars = {}
    end

    return char.vars[name] == nil and fallback or char.vars[name]
end

local function SetVar(char, name, value, isNetworked, recipients)
    local varTable = ax.character.vars[name]
    if ( !istable(varTable) ) then
        ax.util:PrintError("Invalid character variable name provided to ax.character:SetVar()")
        return
    end

    if ( !istable(char.vars) ) then
        char.vars = {}
    end

    char.vars[name] = value

    if ( SERVER and isNetworked ) then
        net.Start("ax.character.var.set")
            net.WriteUInt(char:GetID(), 32)
            net.WriteString(name)
            net.WriteType(value)
        net.Send(recipients or player.GetAll())
    end
end

function ax.character:RegisterVar(name, data)
    if ( !isstring(name) or !istable(data) ) then
        ax.util:PrintError("Invalid arguments provided to ax.character:RegisterVar()")
        return
    end

    self.vars[name] = data

    if ( !data.bNoFuncs ) then
        local prettyName = string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
        local nameGet = "Get" .. prettyName
        local nameSet = "Set" .. prettyName

        ax.meta.character[nameGet] = function(char, fallback)
            if ( isfunction(data.Get) ) then
                if ( !istable(char.vars) ) then char.vars = {} end
                return data:Get(char, fallback)
            else
                return GetVar(char, name, fallback)
            end
        end

        ax.meta.character[nameSet] = function(char, value, isNetworked, recipients)
            if ( isfunction(data.Set) ) then
                if ( !istable(char.vars) ) then char.vars = {} end
                data:Set(char, value)
            else
                SetVar(char, name, value, isNetworked, recipients)
            end
        end

        if ( istable(data.Alias) ) then
            for i = 1, #data.Alias do
                local alias = data.Alias[i]
                if ( !isstring(alias) ) then continue end

                self.vars[alias] = data

                local aliasPrettyName = string.upper(string.sub(alias, 1, 1)) .. string.sub(2)
                local aliasGet = "Get" .. aliasPrettyName
                local aliasSet = "Set" .. aliasPrettyName

                ax.meta.character[aliasGet] = ax.meta.character[nameGet]
                ax.meta.character[aliasSet] = ax.meta.character[nameSet]
            end
        end
    end

    if ( SERVER and isstring(data.field) and data.fieldType != nil ) then
        ax.database:InsertSchema("ax_characters", data.field, data.fieldType)
    end
end