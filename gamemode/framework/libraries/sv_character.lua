--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Server-side character management for database operations and character lifecycle.
-- Handles character creation, loading, saving, and synchronization with clients.
-- @module ax.character

ax.character = ax.character or {}
ax.character.instances = ax.character.instances or {}
ax.character.meta = ax.character.meta or {}
ax.character.vars = ax.character.vars or {}

--- Create a new character in the database.
-- Creates a character with the provided payload data and automatically creates an inventory.
-- Calls the callback with the character and inventory objects upon completion.
-- @realm server
-- @param payload table Character creation data containing variable values
-- @param callback function Optional callback function called with (character, inventory) or (false) on failure
-- @usage ax.character:Create({name = "John Doe", description = "A citizen"}, function(char, inv) end)
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
        character:SetCreationTime( creationTime )
        character:Save()

        -- Turn the data into a table rather than JSON from the database
        character.vars.data = ax.util:SafeParseTable(character.vars.data)

        ax.character.instances[character.id] = character

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

            -- If we don't have an active character for the player, load this one.
            local client = player.GetBySteamID64(payload.steamID64)
            if ( IsValid(client) and (client:GetTable().axCharacter == nil or client:GetTable().axCharacter.id == nil) ) then
                ax.character:Load(client, character)
            end
        end)
    end)

    query:Execute()
end

--- Load a character for a player.
-- Associates a character with a player, syncs character data, and sets up inventory.
-- Automatically respawns the player after loading the character.
-- @realm server
-- @param client Player The player entity to load the character for
-- @param character table The character object to load
-- @usage ax.character:Load(player, characterObject)
function ax.character:Load(client, character)
    local clientData = client:GetTable()
    character.player = client

    clientData.axCharacter = character
    ax.character:Sync(client, character)

    -- Only handle inventory for non-bot characters
    if ( !character.isBot and character.vars.inventory and character.vars.inventory > 0 ) then
        local inventory = ax.inventory.instances[character.vars.inventory]
        if ( istable(inventory) ) then
            inventory:AddReceiver(client)
            ax.inventory:Sync(inventory)
        end
    end

    client:KillSilent()
    client:SetTeam(character.vars.faction)
    client:Spawn()

    -- Only send character load message to real players, not bots
    if ( !client:IsBot() ) then
        net.Start("ax.character.load")
            net.WriteUInt(character.id, 32)
        net.Send(client)
    end

    hook.Run("PlayerLoadedCharacter", client, character)
end

--- Restore all characters for a player from the database.
-- Loads all characters associated with the player's SteamID64 and sends them to the client.
-- @realm server
-- @param client Player The player entity to restore characters for
-- @param callback function Optional callback function called with the character array
-- @usage ax.character:Restore(player, function(characters) print("Loaded", #characters, "characters") end)
function ax.character:Restore(client, callback)
    local clientData = client:GetTable()
    clientData.axCharacters = clientData.axCharacters or {}

    local steamID64 = client:SteamID64()
    local query = mysql:Select("ax_characters")
    query:Where("steamid64", steamID64)
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
            character.vars.data = ax.util:SafeParseTable(character.vars.data)

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

--- Delete a character from the database.
-- Permanently removes a character and its associated inventory from the database.
-- @realm server
-- @param id number The character ID to delete
-- @param callback function Optional callback function called with success boolean
-- @usage ax.character:Delete(123, function(success) print("Deleted:", success) end)
function ax.character:Delete(id, callback)
    local query = mysql:Delete("ax_characters")
    query:Where("id", id)
    query:Callback(function(result, status)
        if ( result == false ) then
            ax.util:PrintError("Failed to delete character with ID " .. id)
            if ( isfunction(callback) ) then
                callback(false)
            end

            return
        end

        ax.util:PrintDebug(color_success, "Character with ID " .. id .. " deleted successfully")

        local data = result[1] or {}

        local inventoryQuery = mysql:Delete("ax_inventories")
        inventoryQuery:Where("id", data.inventory)
        inventoryQuery:Execute()

        if ( isfunction(callback) ) then
            callback(true)
        end
    end)
    query:Execute()
end

--- Synchronize character data to all clients or a specific recipient.
-- Broadcasts character information to all connected players or a specific player for client-side access.
-- @realm server
-- @param client Player The player associated with the character
-- @param character table The character object to synchronize
-- @param recipient Player Optional specific recipient; if nil, broadcasts to all
-- @usage ax.character:Sync(player, characterObject)
-- @usage ax.character:Sync(player, characterObject, newPlayer)
function ax.character:Sync(client, character, recipient)
    net.Start("ax.character.sync")
        net.WritePlayer(client)
        net.WriteTable(character)
    if ( recipient ) then
        net.Send(recipient)
    else
        net.Broadcast()
    end
end
