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
util.AddNetworkString("ax.character.cache")

util.AddNetworkString("ax.inventory.sync")
util.AddNetworkString("ax.inventory.receiver.add")
util.AddNetworkString("ax.inventory.receiver.remove")
util.AddNetworkString("ax.inventory.item.add")
util.AddNetworkString("ax.inventory.item.remove")
util.AddNetworkString("ax.inventory.item.update")

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
            ax.util:Error("Character creation failed for " .. client:SteamID64() .. ": " .. catch)
        end

        return
    end

    ax.util:PrintDebug("Creating character for " .. client:SteamID64() .. " with payload: " .. util.TableToJSON(payload))

    local curTime = math.floor(os.time())

    ax.character:Create({
        steamid = client:SteamID64(),
        faction = payload.faction or 0,
        name = payload.name,
        description = payload.description,
        schema = engine.ActiveGamemode(),
        data = {},
        created_at = curTime,
        updated_at = curTime
    },
    function(character, inventory)
        inventory.receivers = { client }

        if ( !client:GetCharacter() ) then
            client:SetNoDraw(false)
            client:SetNotSolid(false)
            client:SetMoveType(MOVETYPE_WALK)
        end

        client:GetTable().axCharacter = character

        ax.inventory.instances[inventory.id] = inventory
        ax.character.instances[character.id] = character

        ax.inventory:Sync(inventory)
        ax.character:Sync(client, character)

        net.Start("ax.character.create")
            net.WriteUInt(character.id, 32)
        net.Send(client)

        ax.util:PrintSuccess("Character created for " .. client:SteamID64() .. ": " .. character.name)

        hook.Run("OnCharacterCreated", client, character)
    end)
end)

util.AddNetworkString("ax.character.load")
net.Receive("ax.character.load", function(length, client)
    local charID = net.ReadUInt(32)
    if ( !isnumber(charID) or charID < 1 ) then
        ax.util:Error("Invalid character ID received for loading.")
        return
    end

    local character = ax.character.instances[charID]
    if ( !character ) then
        ax.util:PrintError("Character with ID " .. charID .. " does not exist.")
        return
    end

    if ( character.steamid != client:SteamID64() ) then
        ax.util:PrintError("Character ID " .. charID .. " does not belong to " .. client:SteamID64())
        return
    end

    local prevChar = client:GetCharacter()
    if ( prevChar ) then
        if ( prevChar.id == charID ) then
            ax.util:PrintDebug("Character " .. charID .. " is already loaded for " .. client:SteamID64())
            return
        end

        prevChar.player = NULL
    end

    local try, catch = hook.Run("CanLoadCharacter", client, character)
    if ( try == false ) then
        if ( isstring(catch) and #catch > 0 ) then
            client:ChatPrint(catch)
        end

        return
    end

    character.player = client

    client:GetTable().axCharacter = character
    ax.character:Sync(client, character)

    local inventory = ax.inventory.instances[character.invID]
    if ( istable(inventory) ) then
        inventory:AddReceiver(client)
    end

    hook.Run("OnCharacterLoaded", client, character)
end)