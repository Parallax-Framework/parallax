--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

util.AddNetworkString("ax.player.ready")
util.AddNetworkString("ax.character.sync")

util.AddNetworkString("ax.character.create")
net.Receive("ax.character.create", function(length, client)
    local payload = net.ReadTable()
    if ( !istable(payload) ) then
        ax.util:Error("Invalid payload received for character creation.")
        return
    end

    local try, catch = hook.Run("CanCreateCharacter", client, payload)
    if ( try == false ) then
        if ( isstring(catch) and #catch > 0 ) then
            client:ChatPrint(catch)
        end

        return
    end

    local curTime = math.floor(os.time())

    query = mysql:Insert("ax_characters")
        query:Insert("schema", engine.ActiveGamemode())
        query:Insert("steamid", client:SteamID64())
        query:Insert("name", payload.name)
        query:Insert("description", payload.description)
        query:Insert("faction", payload.faction or 0)
        query:Insert("creationTime", curTime)
        query:Callback(function(result, status, lastID)
            if ( result == false ) then
                ax.util:PrintError("Failed to create character for " .. client:SteamID64() .. ": " .. (result and result.error or "Unknown error"))
                return
            end

            local invQuery = mysql:Insert("ax_inventories")
                invQuery:Insert("maxWeight", "30.0")
                invQuery:Insert("items", "[]")
                invQuery:Callback(function(invResult, invStatus, invLastID)
                    if ( invResult == false ) then
                        ax.util:PrintError("Failed to create inventory for character " .. lastID .. ": " .. (invResult and invResult.error or "Unknown error"))
                        return
                    end

                    local inventory = setmetatable({}, ax.meta.inventory)
                    inventory.id = invLastID
                    inventory.items = {}
                    inventory.maxWeight = 30.0

                    local character = setmetatable({}, ax.meta.character)
                    character.id = lastID
                    character.steamid = client:SteamID64()
                    character.name = payload.name

                    character.invID = inventory.id

                    local updQuery = mysql:Update("ax_characters")
                        updQuery:Where("id", lastID)
                        updQuery:Update("inv_id", inventory.id)
                    updQuery:Execute()

                    character.schema = engine.ActiveGamemode()
                    character.description = payload.description or ""
                    character.faction = payload.faction or 0
                    character.creationTime = curTime
                    character.vars = {}

                    ax.inventory.instances[inventory.id] = inventory
                    ax.character.instances[character.id] = character

                    client:GetTable().axCharacter = character

                    net.Start("ax.character.sync")
                        net.WritePlayer(client)
                        net.WriteTable(character)
                    net.Broadcast()

                    hook.Run("OnCharacterCreated", client, character)
                end)
            invQuery:Execute()
        end)
    query:Execute()
end)