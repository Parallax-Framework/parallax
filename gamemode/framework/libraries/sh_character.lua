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

if ( SERVER ) then
    function ax.character:Restore(client, callback)
        local query = mysql:Select("ax_characters")
            query:Where("steamid", client:SteamID64())
            query:Callback(function(result, status)
                if ( result == false ) then
                    ax.util:PrintError("Failed to fetch characters for " .. client:SteamID64())
                    return
                end

                if ( result[1] == nil ) then
                    ax.util:PrintDebug("No characters found for " .. client:SteamID64())
                    return
                end

                local characters = {}

                for i = 1, #result do
                    local charData = result[i]
                    local character = setmetatable({}, ax.meta.character)

                    for k, v in pairs(charData) do
                        if ( k == "vars" ) then
                            character.vars = util.JSONToTable(v) or {}
                        else
                            character[k] = v
                        end

                        for vK, vV in pairs(ax.character.vars) do
                            if ( k == vV.field ) then
                                character[vK] = v
                            end
                        end
                    end

                    ax.character.instances[character.id] = character
                    characters[#characters + 1] = character
                end

                client:GetTable().axCharacters = characters

                ax.util:PrintDebug("Sent character cache to " .. client:SteamID64())

                net.Start("ax.character.cache")
                    net.WriteTable(characters)
                net.Send(client)

                if ( isfunction(callback) ) then
                    callback(characters)
                end
            end)
        query:Execute()
    end

    function ax.character:Create(data, callback)
        if ( !istable(data.name) ) then return end

        local creationTime = math.floor(os.time())

        local query = mysql:Insert("ax_characters")
            query:Insert("schema", data.schema)
            query:Insert("steamid", data.steamid)
            query:Insert("name", data.name)
            query:Insert("description", data.description or "")
            query:Insert("faction", data.faction or 0)
            query:Insert("creationTime", data.creationTime or creationTime)
            query:Insert("inv_id", data.invID or 0)
            query:Insert("data", istable(data) and util.TableToJSON(data.data) or isstring(data.data) and data.data or "[]")
            query:Callback(function(result, status, lastID)
                if ( result == false ) then
                    if ( isfunction(callback) ) then
                        callback(false)
                    end

                    return
                end

                local character = setmetatable({}, ax.meta.character)
                character.id = lastID
                character.steamid = data.steamid
                character.name = data.name
                character.description = data.description or ""
                character.faction = data.faction or 0
                character.creationTime = data.creationTime or creationTime
                character.schema = data.schema or engine.ActiveGamemode()
                character.vars = {}
                character.data = ax.util:SafeParseTable(data.data) or {}

                ax.character.instances[character.id] = character

                ax.inventory:Create(nil, function(inventory)
                    if ( inventory == false ) then
                        ax.util:PrintError("Failed to create inventory for character " .. lastID)
                        return
                    end

                    local invQuery = mysql:Update("ax_characters")
                        invQuery:Where("id", lastID)
                        invQuery:Update("inv_id", inventory.id)
                    invQuery:Execute()

                    character.invID = inventory.id

                    if ( isfunction(callback) ) then
                        callback(character, inventory)
                    end

                    ax.util:PrintDebug("Character created for " .. data.steamid .. ": " .. character.name)
                end)
            end)
        query:Execute()
    end
end