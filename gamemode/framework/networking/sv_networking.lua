--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

util.AddNetworkString("ax.player.ready")
util.AddNetworkString("ax.player.var")
util.AddNetworkString("ax.player.data")

util.AddNetworkString("ax.character.sync")
util.AddNetworkString("ax.character.restore")
util.AddNetworkString("ax.character.var")
util.AddNetworkString("ax.character.setnameprompt")

util.AddNetworkString("ax.relay.update")

util.AddNetworkString("ax.inventory.sync")
util.AddNetworkString("ax.inventory.receiver.add")
util.AddNetworkString("ax.inventory.receiver.remove")
util.AddNetworkString("ax.inventory.item.add")
util.AddNetworkString("ax.inventory.item.remove")
util.AddNetworkString("ax.inventory.item.update")

util.AddNetworkString("ax.item.transfer")
util.AddNetworkString("ax.item.spawn")

util.AddNetworkString("ax.inventory.item.action")
net.Receive("ax.inventory.item.action", function(length, client)
    if ( !client:RateLimit("inventory.action", 0.1) ) then return end

    local itemID = net.ReadUInt(32)
    local action = net.ReadString()

    if ( !isnumber(itemID) or itemID < 1 or !isstring(action) or #action < 1 ) then
        ax.util:Error("Invalid payload received for item action.")
        return
    end

    local item = ax.item.instances[itemID]
    if ( !istable(item) ) then
        ax.util:PrintError("Item with ID " .. itemID .. " does not exist.")
        return
    end

    local actionTable = item.actions[action]
    if ( !istable( item.actions[action] ) ) then
        ax.util:PrintError("Item with ID " .. itemID .. " does not have action '" .. action .. "'.")
        return
    end

    if ( !item:CanInteract(client, action) ) then return end

    local bRemoveAfter = actionTable:OnRun(item, client)
    if ( bRemoveAfter == nil or !isbool(bRemoveAfter) ) then bRemoveAfter = false end

    if ( bRemoveAfter ) then
        local inventory = ax.inventory.instances[item.invID]
        if ( istable(inventory) ) then
            inventory:RemoveItem(item.id)
        end
    end

    local soundVar = "sound_" .. string.lower(action)
    if ( actionTable[ soundVar ] ) then
        client:EmitSound( Sound( actionTable[ soundVar ] ) )
    end

    hook.Run("OnPlayerItemAction", client, item, action)
end)

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
            client:Notify(catch, "error")
            ax.util:Error("Character creation failed for " .. client:SteamID64() .. ": " .. catch)
        end

        return
    end

    local newPayload = {
        steamID64 = client:SteamID64(),
        schema = engine.ActiveGamemode(),
    }

    for k, v in pairs(payload) do
        local var = ax.character.vars[k]
        if ( !var ) then
            ax.util:PrintError("Invalid character variable '" .. k .. "' provided in payload.")
            return
        end

        -- Check if this variable can be populated during character creation (server-side validation)
        local canPop, reason = ax.character:CanPopulateVar(k, payload, client)
        if ( !canPop ) then
            ax.util:PrintError(("Client '%s' attempted to send data for restricted character variable '%s': %s"):format(client:SteamID64(), tostring(k), reason or "Unknown reason"))
            client:Notify("Invalid character data submitted.", "error")
            return
        end

        if ( var.validate and var:validate(v) ) then
            newPayload[k] = v
        else
            ax.util:PrintError("Validation failed for character variable '" .. k .. "': " .. v)
            return
        end
    end

    ax.util:PrintDebug("Creating character for " .. client:SteamID64() .. " with payload: " .. util.TableToJSON(newPayload))

    ax.character:Create(newPayload, function(character, inventory)
        inventory:AddReceiver( client )

        if ( !client:GetCharacter() ) then
            client:SetNoDraw(false)
            client:SetNotSolid(false)
            client:SetMoveType(MOVETYPE_WALK)
        end

        local clientData = client:GetTable()

        clientData.axCharacters = clientData.axCharacters or {}
        clientData.axCharacters[ #clientData.axCharacters + 1 ] = character

        ax.inventory.instances[inventory.id] = inventory
        ax.character.instances[character.id] = character

        ax.inventory:Sync(inventory)
        ax.character:Sync(client, character)

        net.Start("ax.character.create")
            net.WriteUInt(character.id, 32)
            net.WriteTable(clientData.axCharacters)
        net.Send(client)

        ax.util:PrintSuccess("Character created for " .. client:SteamID64() .. ": " .. character:GetName())

        client:Notify("You have successfully created a new character!", "success")

        hook.Run("PlayerCreatedCharacter", client, character)
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

    if ( character:GetSteamID64() != client:SteamID64() ) then
        ax.util:PrintError("Character ID " .. charID .. " does not belong to " .. client:SteamID64())
        return
    end

    local prevChar = client:GetCharacter()
    if ( prevChar ) then
        if ( prevChar.id == charID ) then
            ax.util:PrintDebug("Character " .. charID .. " is already loaded for " .. client:SteamID64())
            return
        end

        for i = #ax.inventory.instances, 1, -1 do
            local inventory = ax.inventory.instances[ i ]
            if ( istable(inventory) and inventory:IsReceiver( client ) ) then
                inventory:RemoveReceiver( client )
            end
        end

        prevChar.player = NULL
        hook.Run("PlayerUnloadedCharacter", client, prevChar)
    end

    local try, catch = hook.Run("CanPlayerLoadCharacter", client, character)
    if ( try == false ) then
        if ( isstring(catch) and #catch > 0 ) then
            client:Notify(catch, "error")
        end

        return
    end

    ax.character:Load(client, character)
end)

util.AddNetworkString( "ax.character.delete" )
net.Receive( "ax.character.delete", function( length, client )
    local id = net.ReadUInt( 32 )
    if ( !isnumber( id ) or id < 1 ) then return end

    local character = ax.character.instances[ id ]
    if ( !istable( character ) ) then
        ax.util:PrintError( "Character with ID " .. id .. " does not exist." )
        return
    end

    if ( character:GetSteamID64() != client:SteamID64() ) then
        ax.util:PrintError( "Character ID " .. id .. " does not belong to " .. client:SteamID64() )
        return
    end

    local try, catch = hook.Run( "CanPlayerDeleteCharacter", client, character )
    if ( try == false ) then
        if ( isstring(catch) and #catch > 0 ) then
            client:Notify(catch, "error")
        end

        return
    end

    ax.character:Delete( id, function( bSuccess )
        if ( bSuccess ) then
            local clientData = client:GetTable()
            local clientCharacters = clientData.axCharacters or {}
            if ( istable( clientData.axCharacters ) ) then
                for i = #clientCharacters, 1, -1 do
                    if ( clientCharacters[i].id == id ) then
                        table.remove( clientCharacters, i )
                        break
                    end
                end
            end

            if ( clientData.axCharacter and clientData.axCharacter.id == id ) then
                clientData.axCharacter = nil
                client:SetNoDraw(true)
                client:SetNotSolid(true)
                client:SetMoveType(MOVETYPE_NONE)
                client:KillSilent()

                client:SendLua( [[vgui.Create( "ax.main" )]] )
            end

            net.Start( "ax.character.delete" )
                net.WriteUInt( id, 32 )
            net.Send( client )

            hook.Run( "PlayerDeletedCharacter", client, id )

            ax.character.instances[ id ] = nil
        end
    end )
end)
