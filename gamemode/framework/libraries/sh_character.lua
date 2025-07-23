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
ax.character.vars = ax.character.vars or {}

function ax.character:Get(id)
    if ( !isnumber(id) ) then
        ax.util:PrintError("Invalid character ID provided to ax.character:Get()")
        return nil
    end

    return ax.character.instances[id]
end

local function SetVar(character, name, value, shouldNetwork, recipients)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("Invalid variable name provided")
        return
    end

    local varData = ax.character.vars[name]

    if ( !istable(varData) ) then
        ax.util:PrintError("Variable \"" .. name .. "\" does not exist.")
        return
    end

    if ( !istable(character.vars) ) then
        character.vars = {}
    end

    if ( SERVER and shouldNetwork == true ) then
        if ( recipients == nil ) then
            recipients = select(2, player.Iterator())
        end

        net.Start("ax.character.SetVar")
            net.WriteUInt(character.id, 32)
            net.WriteString(name)
            net.WriteType(value)
        net.Send(recipients)
    end

    character.vars[name] = value
end

local function GetVar(character, name, fallback)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("Invalid variable name provided")
        return nil
    end

    local varData = ax.character.vars[name]

    if ( !istable(varData) ) then
        ax.util:PrintError("Variable \"" .. name .. "\" does not exist.")
        return
    end

    if ( !istable(character.vars) ) then
        character.vars = {}
    end

    if ( fallback == nil ) then
        fallback = ax.character.vars[name].Default
    end

    local var = character.vars[name]
    return var == nil and fallback or var
end

function ax.character:NewVar(name, data)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("Invalid variable name provided")
        return
    end

    if ( !istable(data) ) then
        ax.util:PrintError("Invalid variable data provided for variable \"" .. name .. "\"")
        return
    end

    name = string.lower(name)
    name = string.Trim(name)

    data.id = table.Count(self.vars) + 1

    self.vars[name] = data

    local fancyVarName = string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)

    if ( istable(data.Alias) and isstring(data.Alias[1]) ) then
        for i = 1, #data.Alias do
            self.vars[data.Alias[i]] = data
            fancyVarName = string.upper(string.sub(data.Alias[i], 1, 1)) .. string.sub(data.Alias[i], 2)

            ax.meta.character["Get" .. fancyVarName] = function(character)
                return !isfunction(data.OnGet) and GetVar(character, name) or data:OnGet(character, name, GetVar(character, name))
            end

            ax.meta.character["Set" .. fancyVarName] = function(character, value, shouldNetwork, recipients)
                if ( shouldNetwork == nil ) then shouldNetwork = false end

                if ( !isfunction(data.OnSet) ) then
                    SetVar(character, name, value, shouldNetwork, recipients)
                else
                    data:OnSet(character, name, value, shouldNetwork, recipients)
                end
            end
        end
    end

    ax.meta.character["Get" .. fancyVarName] = function(character)
        return !isfunction(data.OnGet) and GetVar(character, name) or data:OnGet(character, name, GetVar(character, name))
    end

    ax.meta.character["Set" .. fancyVarName] = function(character, value, shouldNetwork, recipients)
        if ( shouldNetwork == nil ) then shouldNetwork = false end

        if ( !isfunction(data.OnSet) ) then
            SetVar(character, name, value, shouldNetwork, recipients)
        else
            data:OnSet(character, name, value, shouldNetwork, recipients)
        end
    end

    ax.util:PrintDebug("Variable \"" .. name .. "\" added successfully.")
end