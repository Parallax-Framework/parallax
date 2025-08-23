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

function ax.character:Create(payload, callback)
    local creationTime = math.floor(os.time())

    local query = mysql:Insert("ax_characters")
    for k, v in pairs(self.vars) do
        query:Insert(v.field, payload[k] or v.default)
    end

    query:Callback(function(result, status, lastID)
        ax.util:PrintDebug("Character creation query executed with status: " .. tostring(status))

        if ( result == false ) then
            if ( isfunction(callback) ) then
                callback(false)
            end

            ax.util:PrintError("Failed to create character for " .. payload.steamID64)

            return
        end

        local character = setmetatable({}, ax.character.meta)
        character.id = lastID
        character.vars = {}

        for k, v in pairs(self.vars) do
            character.vars[k] = payload[k] or v.default
        end

        -- Override creationTime
        character.vars.creationTime = creationTime

        -- Turn the data into a table rather than JSON from the database
        character.vars.data = util.JSONToTable(character.vars.data)

        ax.character.instances[character.id] = character

        ax.util:PrintDebug("Character created with ID: " .. lastID)

        ax.inventory:Create(nil, function(inventory)
            if ( inventory == false ) then
                ax.util:PrintError("Failed to create inventory for character " .. lastID)
                return
            end

            local invQuery = mysql:Update("ax_characters")
                invQuery:Where("id", lastID)
                invQuery:Update("inventory", inventory.id)
            invQuery:Execute()

            character.vars.inventory = inventory.id

            if ( isfunction(callback) ) then
                callback(character, inventory)
            end

            ax.util:PrintDebug("Character created for " .. payload.steamID64 .. ": " .. character.vars.name)
        end)
    end)

    query:Execute()
end

function ax.character:Restore(client, callback)
    local clientData = client:GetTable()
    clientData.axCharacters = {}

    local steamID64 = client:SteamID64()
    local query = mysql:Select("ax_characters")
        query:Where("steamID64", steamID64)
        query:Callback(function(result, status)
            if ( result == false ) then
                ax.util:PrintError("Failed to fetch characters for " .. steamID64)
                return
            end

            if ( result[1] == nil ) then
                ax.util:PrintDebug("No characters found for " .. steamID64)
                return
            end

            for i = 1, #result do
                local character = setmetatable({}, ax.character.meta)
                character.id = result[i].id
                character.vars = {}

                for k, v in pairs(self.vars) do
                    local field = v.field
                    local var = result[i][field] or v.default
                    character.vars[k] = var
                end

                -- Turn the data into a table rather than JSON from the database
                character.vars.data = util.JSONToTable(character.vars.data)

                ax.character.instances[character.id] = character
                clientData.axCharacters[ #clientData.axCharacters + 1 ] = character
            end

            net.Start("ax.character.restore")
                net.WriteTable(clientData.axCharacters)
            net.Send(client)

            if ( isfunction(callback) ) then
                callback(clientData.axCharacters)
            end
        end)
    query:Execute()
end

function ax.character:Sync(client, character)
    net.Start("ax.character.sync")
        net.WritePlayer(client)
        net.WriteTable(character)
    net.Broadcast()
end