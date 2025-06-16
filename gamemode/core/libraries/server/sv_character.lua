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

--- Character library.
-- @module ax.character

function ax.character:Create(client, query, callback)
    if ( !IsValid(client) or !client:IsPlayer() ) then
        return callback(false, "Invalid player!")
    end

    if ( !istable(query) ) then
        return callback(false, "Invalid query!")
    end

    local insertQuery = {}
    for k, v in pairs(self.variables) do
        if ( query[k] != nil ) then
            insertQuery[k] = query[k]
        elseif ( v.Default ) then
            insertQuery[k] = v.Default
        end
    end

    insertQuery.steamid = client:SteamID64()
    insertQuery.schema = SCHEMA.Folder
    insertQuery.play_time = 0
    insertQuery.last_played = os.time()

    ax.database:Insert("ax_characters", insertQuery, function(characterID)
        if ( !characterID ) then
            return callback(false, "Failed to insert character into database!")
        end

        local character = self:CreateObject(characterID, insertQuery, client)
        if ( !character ) then
            return callback(false, "Failed to create character object!")
        end

        local canCreate, reason = hook.Run("PrePlayerCreatedCharacter", client, character, query)
        if ( canCreate == false ) then
            self:Delete(characterID)
            return callback(false, reason or "Hook denied character creation!")
        end

        local clientTable = client:GetTable()
        clientTable.axCharacters = clientTable.axCharacters or {}
        clientTable.axCharacters[characterID] = character

        self.stored[characterID] = character

        ax.net:Start(client, "character.cache", character)
        ax.inventory:Register({characterID = characterID})

        hook.Run("PostPlayerCreatedCharacter", client, character, query)

        return callback(true, character)
    end)
end

function ax.character:Load(client, characterID)
    if ( !IsValid(client) or !client:IsPlayer() ) then
        ax.util:PrintError("Attempted to load character for invalid player (" .. tostring(client) .. ")")
        return false
    end

    if ( !characterID ) then
        client:Notify("You are attempting to load a character with an invalid ID!")
        return false
    end

    local currentCharacter = client:GetCharacter()
    if ( currentCharacter ) then
        currentCharacter.Player = NULL

        if ( currentCharacter:GetID() == characterID ) then
            client:Notify("You are already using this character!")
            return false
        end
    end

    local steamID = client:SteamID64()
    local condition = string.format("steamid = %s AND id = %s", sql.SQLStr(steamID), sql.SQLStr(characterID))

    ax.database:Select("ax_characters", nil, condition, function(result)
        if ( result and result[1] ) then
            local character = self:CreateObject(characterID, result[1], client)
            if ( !character ) then
                client:Notify("Failed to load character!")
                return
            end

            self.stored[characterID] = character

            hook.Run("PrePlayerLoadedCharacter", client, character, currentCharacter)

            ax.net:Start(client, "character.load", characterID, character)

            local clientTable = client:GetTable()
            clientTable.axCharacters = clientTable.axCharacters or {}
            clientTable.axCharacters[characterID] = character
            clientTable.axCharacter = character

            client:SetTeam(character:GetFaction())
            client:SetModel(character:GetModel())
            client:SetSkin(character:GetSkin())
            client:Spawn()

            ax.inventory:CacheAll(characterID, function(inventory)
                ax.item:Cache(characterID)
            end)

            hook.Run("PostPlayerLoadedCharacter", client, character, currentCharacter)

            return character
        else
            ax.util:PrintError("Failed to load character with ID " .. characterID .. " for player " .. tostring(client))
            return
        end
    end)
end

function ax.character:Delete(characterID, callback)
    if ( !isnumber(characterID) ) then
        ax.util:PrintError("Attempted to delete character with invalid ID (" .. tostring(characterID) .. ")")
        return false
    end

    local character = self.stored[characterID]
    if ( !character ) then
        ax.util:PrintError("Attempted to delete character that does not exist (" .. characterID .. ")")
        return false
    end

    local client = character:GetPlayer()
    if ( IsValid(client) ) then
        local clientTable = client:GetTable()
        clientTable.axCharacters[characterID] = nil
        clientTable.axCharacter = nil

        client:SetTeam(0)
        client:SetModel("models/player/kleiner.mdl")

        client:SetNoDraw(true)
        client:SetNotSolid(true)
        client:SetMoveType(MOVETYPE_NONE)

        client:KillSilent()

        ax.net:Start(client, "character.delete", characterID)
    end

    self.stored[characterID] = nil

    -- Delete all related inventories and items for this character
    ax.database:Delete("ax_inventories", string.format("character_id = %s", sql.SQLStr(characterID)))
    ax.database:Delete("ax_items", string.format("character_id = %s", sql.SQLStr(characterID)))

    -- Finally, delete the character from the database
    ax.database:Delete("ax_characters", string.format("id = %s", sql.SQLStr(characterID)), function(result)
        if ( callback ) then
            callback(tobool(result))
        end
    end)
end

function ax.character:Cache(client, characterID, callback)
    if ( !IsValid(client) or !client:IsPlayer() ) then
        ax.util:PrintError("Attempted to cache character for invalid player (" .. tostring(client) .. ")")
        return false
    end

    local condition = string.format("steamid = %s AND id = %s", sql.SQLStr(client:SteamID64()), sql.SQLStr(characterID))
    ax.database:Select("ax_characters", nil, condition, function(result)
        if ( !result or !result[1] ) then
            ax.util:PrintError("Failed to cache character with ID " .. characterID .. " for player " .. tostring(client))

            if ( callback ) then
                callback(false)
            end

            return false
        end

        characterID = tonumber(characterID)
        if ( !characterID ) then
            ax.util:PrintError("Failed to convert character ID " .. characterID .. " to number for player " .. tostring(client))
            return false
        end

        -- Make sure we are not loading a character from a different schema
        if ( result[1].schema != SCHEMA.Folder ) then
            return false
        end

        local clientTable = client:GetTable()
        clientTable.axCharacters = clientTable.axCharacters or {}
        clientTable.axCharacters[characterID] = result[1]
        self.stored[characterID] = result[1]

        ax.net:Start(client, "character.cache", result[1])

        if ( callback ) then
            callback(true, result[1])
        end
    end)
end

function ax.character:CacheAll(client, callback)
    if ( !IsValid(client) or !client:IsPlayer() ) then
        ax.util:PrintError("Attempted to load characters for invalid player (" .. tostring(client) .. ")")

        if ( callback ) then
            callback(false)
        end

        return false
    end

    -- Ensure the player has a table to store characters in later
    local clientTable = client:GetTable()
    clientTable.axCharacters = {}

    local condition = string.format("steamid = %s", sql.SQLStr(client:SteamID64()))
    ax.database:Select("ax_characters", nil, condition, function(result)
        if ( result ) then
            for _, row in ipairs(result) do
                local id = tonumber(row.id)
                if ( !id ) then
                    ax.util:PrintError("Failed to convert character ID " .. tostring(row.id) .. " to number for player " .. tostring(client))
                    continue
                end

                -- Make sure we are not loading a character from a different schema
                if ( row.schema != SCHEMA.Folder ) then
                    ax.util:PrintWarning("Character with ID " .. id .. " does not belong to the current schema (" .. SCHEMA.Folder .. ") for player " .. tostring(client))
                    continue
                end

                local character = self:CreateObject(id, row, client)
                if ( !character ) then
                    ax.util:PrintError("Failed to create character object for ID " .. id .. " for player " .. tostring(client))
                    continue
                end

                self.stored[id] = character
                clientTable.axCharacters[id] = character
            end

            ax.net:Start(client, "character.cache.all", clientTable.axCharacters)

            if ( callback ) then
                callback(true, clientTable.axCharacters)
            end

            hook.Run("PlayerLoadedAllCharacters", client, clientTable.axCharacters)
        else
            ax.util:PrintError("Failed to load characters for player " .. tostring(client) .. "\n")

            if ( callback ) then
                callback(false)
            end
        end
    end)
end

concommand.Add("ax_character_test_create", function(client, cmd, arguments)
    ax.character:Create(client, {
        name = "Test Character"
    })
end)