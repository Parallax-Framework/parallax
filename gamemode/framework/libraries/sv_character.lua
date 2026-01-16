--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

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

    -- Ensure required fields are present and properly typed before initial INSERT
    payload = payload or {}
    payload.schema = payload.schema or engine.ActiveGamemode()

    local query = mysql:Insert("ax_characters")
    for k, v in pairs(self.vars) do
        local value = payload[k]
        if ( value == nil ) then
            value = v.default
        end

        -- Serialize tables to JSON to avoid unsupported bind types (e.g., skills payload)
        if ( istable(value) ) then
            value = util.TableToJSON(value)
        elseif ( isbool(value) ) then
            value = value == true and 1 or 0
        end

        query:Insert(v.field, value)
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
    if ( !IsValid(client) ) then
        ax.util:PrintError("Attempted to load character ID " .. character.id .. " for an invalid player")
        return
    end

    if ( !istable(character) or character.id == nil ) then
        ax.util:PrintError("Attempted to load an invalid character for player " .. client:SteamID64())
        return
    end

    if ( !client:IsBot() and character:GetSchema() != engine.ActiveGamemode() ) then
        ax.util:PrintError("Attempted to load character ID " .. character.id .. " with mismatched schema (" .. character:GetSchema() .. " != " .. engine.ActiveGamemode() .. ")")
        return
    end

    local clientData = client:GetTable()
    character.player = client

    clientData.axCharacterPrevious = clientData.axCharacter
    if ( clientData.axCharacterPrevious ) then
        local inventory = clientData.axCharacter:GetInventory()
        if ( istable(inventory) ) then
            inventory:RemoveReceivers()
        end

        clientData.axCharacterPrevious.player = nil

        local receivers = select(2, player.Iterator())
        for i = 1, #receivers do
            if ( receivers[i] == client ) then table.remove(receivers, i) break end
        end

        ax.net:Start(receivers, "character.invalidate", client.axCharacterPrevious:GetID())
    end

    clientData.axCharacter = character
    ax.character:Sync(client, character)

    -- Only handle inventory for non-bot characters
    if ( !character.isBot ) then
        local inventory = character:GetInventory()
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
        ax.net:Start(client, "character.load", character.id)
    end

    character:SetLastPlayed(os.time())
    character:Save()

    -- we need to re-equip all items after spawning
    local inventory = character:GetInventory()
    if ( istable(inventory) ) then
        for _, item in pairs(inventory:GetItems()) do
            if ( !istable(item) ) then continue end

            -- Call optional item-level OnPlayerLoadedCharacter if present (allows custom initialization)
            if ( isfunction(item.OnPlayerLoadedCharacter) ) then
                pcall(function()
                    item:OnPlayerLoadedCharacter(client, character)
                end)
            end
        end
    end

    local faction = ax.faction:Get(character:GetFaction())
    if ( istable(faction ) and isfunction(faction.OnPlayerLoadedCharacter) ) then
        faction:OnPlayerLoadedCharacter(client, character)
    end

    local class = ax.class:Get(character:GetClass())
    if ( istable(class) and isfunction(class.OnPlayerLoadedCharacter) ) then
        class:OnPlayerLoadedCharacter(client, character)
    end

    hook.Run("PlayerLoadedCharacter", client, character, clientData.axCharacterPrevious)
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
            if ( !result[i] or !istable(result[i]) ) then
                ax.util:PrintDebug("Skipping character ID " .. tostring(result[i].id) .. " due to invalid data.")
                continue
            end

            local schema = result[i].schema
            if ( schema != engine.ActiveGamemode() ) then
                ax.util:PrintDebug("Skipping character ID " .. result[i].id .. " due to schema mismatch (" .. schema .. " != " .. engine.ActiveGamemode() .. ")")
                continue
            end

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

        ax.net:Start(client, "character.restore", clientData.axCharacters)

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
    -- First fetch the character row to validate existence and schema
    local sel = mysql:Select("ax_characters")
    sel:Where("id", id)
    sel:Callback(function(result, status)
        ax.util:PrintDebug("ax.character:Delete - SELECT callback fired for ID " .. tostring(id))
        ax.util:PrintDebug("mysql:IsConnected() = " .. tostring(mysql:IsConnected()))
        ax.util:PrintDebug("engine.ActiveGamemode() = " .. tostring(engine.ActiveGamemode()))
        ax.util:PrintDebug("SELECT result type = " .. type(result) .. ", status = " .. tostring(status) .. ", count = " .. tostring(result and #result or 0))
        if ( istable(result) and result[1] ) then
            -- Avoid dumping player references in the table; print core fields if present
            ax.util:PrintDebug("SELECT row[1]: id=" .. tostring(result[1].id) .. ", schema=" .. tostring(result[1].schema) .. ", inventory=" .. tostring(result[1].inventory))
        end

        -- Print runtime instance if present for correlation
        if ( ax.character.instances and ax.character.instances[id] ) then
            local rc = ax.character.instances[id]
            local model = rc.vars and rc.vars.model or "<nil>"
            local name = rc.vars and rc.vars.name or "<nil>"
            ax.util:PrintDebug("Runtime character exists: id=" .. tostring(id) .. ", name=" .. tostring(name) .. ", model=" .. tostring(model))
        else
            ax.util:PrintDebug("No runtime character instance for id " .. tostring(id))
        end

        if ( result == false ) then
            ax.util:PrintError("Failed to query character with ID " .. id .. " for deletion")
            if ( isfunction(callback) ) then
                callback(false)
            end

            return
        end

        if ( result[1] == nil ) then
            -- If the database row is missing but a runtime instance exists, clean
            -- up the runtime data and attempt to remove any associated inventory.
            if ( ax.character.instances and ax.character.instances[id] ) then
                ax.util:PrintWarning("No DB row for character ID " .. id .. " but runtime instance exists; cleaning up runtime state")

                local rc = ax.character.instances[id]
                local invID = rc and rc.vars and rc.vars.inventory and tonumber(rc.vars.inventory) or nil

                -- Remove runtime character instance
                ax.character.instances[id] = nil

                -- Attempt to delete the associated inventory row if present
                if ( invID and invID > 0 ) then
                    ax.util:PrintDebug("Attempting to delete inventory ID " .. tostring(invID) .. " for missing character row")
                    local inventoryQuery = mysql:Delete("ax_inventories")
                    inventoryQuery:Where("id", invID)
                    inventoryQuery:Execute()

                    local result = mysql:Delete("ax_items")
                    result:Where("inventory_id", invID)
                    result:Execute()

                    if ( ax.inventory and ax.inventory.instances and ax.inventory.instances[invID] ) then
                        ax.inventory.instances[invID]:RemoveReceivers()
                        ax.inventory.instances[invID] = nil
                    end
                end

                if ( isfunction(callback) ) then
                    callback(true)
                end

                return
            end

            ax.util:PrintError("No character found with ID " .. id .. " to delete")
            if ( isfunction(callback) ) then
                callback(false)
            end

            return
        end

        local row = result[1]
        if ( row.schema != engine.ActiveGamemode() ) then
            ax.util:PrintError("Attempted to delete character ID " .. id .. " with mismatched schema (" .. row.schema .. " != " .. engine.ActiveGamemode() .. ")")
            if ( isfunction(callback) ) then
                callback(false)
            end

            return
        end

        -- Proceed to delete the character
        local del = mysql:Delete("ax_characters")
        del:Where("id", id)
        del:Callback(function(delResult, delStatus)
            ax.util:PrintDebug("ax.character:Delete - DELETE callback fired for ID " .. tostring(id) .. ", delStatus = " .. tostring(delStatus) .. ", delResult type = " .. type(delResult) .. ", count = " .. tostring(delResult and #delResult or 0))

            if ( delResult == false ) then
                ax.util:PrintError("Failed to delete character with ID " .. id)
                if ( isfunction(callback) ) then
                    callback(false)
                end

                return
            end

            -- Remove from runtime instances if present
            if ( ax.character.instances[id] ) then
                ax.character.instances[id] = nil
            end

            ax.util:PrintDebug(color_success, "Character with ID " .. id .. " deleted successfully")

            -- Delete the associated inventory if present
            if ( row.inventory and tonumber(row.inventory) and tonumber(row.inventory) > 0 ) then
                local inventoryQuery = mysql:Delete("ax_inventories")
                inventoryQuery:Where("id", tonumber(row.inventory))
                inventoryQuery:Execute()

                local result = mysql:Delete("ax_items")
                result:Where("inventory_id", tonumber(row.inventory))
                result:Execute()

                -- Also remove runtime inventory instance if loaded
                local invToNum = tonumber(row.inventory)
                if ( ax.inventory and ax.inventory.instances and ax.inventory.instances[invToNum] ) then
                    ax.inventory.instances[invToNum]:RemoveReceivers()
                    ax.inventory.instances[invToNum] = nil
                end
            end

            if ( isfunction(callback) ) then
                callback(true)
            end
        end)
        del:Execute()
    end)
    sel:Execute()
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
    if ( istable(recipient) or isentity(recipient) ) then
        ax.net:Start(recipient, "character.sync", client, character)
    elseif ( isvector(recipient) ) then
        ax.net:StartPVS(recipient, "character.sync", client, character)
    else
        ax.net:Start(nil, "character.sync", client, character)
    end
end
