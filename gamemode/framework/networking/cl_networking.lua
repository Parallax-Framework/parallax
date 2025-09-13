--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

net.Receive("ax.player.ready", function(len)
    local clientTable = LocalPlayer():GetTable()
    if ( clientTable.axReady ) then return end

    clientTable.axReady = true

    vgui.Create("ax.main")

    -- Run any queued EnsurePlayer callbacks
    local client = LocalPlayer()
    local t = client:GetTable()
    if ( istable(t.axEnsureCallbacks) ) then
        for i = 1, #t.axEnsureCallbacks do
            local cb = t.axEnsureCallbacks[i]
            if ( isfunction(cb) ) then
                pcall(cb, true)
            end
        end

        t.axEnsureCallbacks = nil
    end
end)

net.Receive("ax.character.create", function(len)
    local client = ax.client
    if ( !IsValid(client) ) then
        ax.util:PrintError("Invalid client received for character creation.")
        return
    end

    local clientTable = client:GetTable()
    if ( !istable(clientTable) ) then
        ax.util:PrintError("Invalid client table for character creation.")
        return
    end

    local characterID = net.ReadUInt(32)
    if ( !isnumber(characterID) or characterID <= 0 ) then
        ax.util:PrintError("Invalid character ID received for creation.")
        return
    end

    local character = ax.character:Get(characterID)
    if ( !istable(character) ) then
        ax.util:PrintError("Character with ID " .. characterID .. " not found.")
        return
    end

    if ( !clientTable.axCharacter ) then
        net.Start("ax.character.load")
            net.WriteUInt(characterID, 32)
        net.Send(client)

        if ( IsValid(ax.gui.main) ) then
            ax.gui.main:Remove()
        end
    end

    local clientData = ax.client:GetTable()
    clientData.axCharacters = {}

    local characters = net.ReadTable()
    for i = 1, #characters do
        local charData = characters[i]
        character = setmetatable(charData, ax.character.meta)
        ax.character.instances[character.id] = character
        clientData.axCharacters[#clientData.axCharacters + 1] = character
    end

    hook.Run("PlayerCreatedCharacter", client, character)
end)

net.Receive("ax.character.load", function()
    local characterID = net.ReadUInt(32)
    local client = ax.client
    if ( !IsValid(client) ) then return end

    local character = ax.character:Get(characterID)
    if ( !istable(character) ) then
        ax.util:PrintError("Character with ID " .. characterID .. " not found.")
        return
    end

    local clientData = client:GetTable()
    clientData.axCharacter = character

    if ( IsValid(ax.gui.main) ) then
        ax.gui.main:Remove()
    end

    client:ScreenFade(SCREENFADE.IN, color_black, 4, 1)

    hook.Run("PlayerLoadedCharacter", client, character)
end)

net.Receive("ax.character.sync", function()
    local client = net.ReadPlayer()
    if ( !IsValid(client) ) then return end

    local character = net.ReadTable()
    if ( !istable(character) ) then
        ax.util:PrintError("Invalid character data received from server")
        return
    end

    client:GetTable().axCharacter = character

    ax.character.instances[character.id] = setmetatable(character, ax.character.meta)
end)

net.Receive("ax.character.restore", function()
    local characters = net.ReadTable()
    if ( !istable(characters) ) then
        ax.util:PrintError("Invalid characters table received from server")
        return
    end

    local clientData = ax.client:GetTable()
    clientData.axCharacters = {}

    for i = 1, #characters do
        local charData = characters[i]
        local character = setmetatable(charData, ax.character.meta)
        ax.character.instances[character.id] = character
        clientData.axCharacters[ #clientData.axCharacters + 1 ] = character
    end

    hook.Run("OnCharactersRestored", characters)
end)

net.Receive( "ax.character.delete", function()
    local id = net.ReadUInt( 32 )
    if ( !isnumber( id ) or id < 1 ) then return end

    local character = ax.character.instances[ id ]
    if ( !istable( character ) ) then
        ax.util:PrintError( "Character with ID " .. id .. " does not exist." )
        return
    end

    local clientData = ax.client:GetTable()
    if ( clientData.axCharacter and clientData.axCharacter.id == id ) then
        clientData.axCharacter = nil
    end

    if ( istable( clientData.axCharacters ) ) then
        for i = #clientData.axCharacters, 1, -1 do
            if ( clientData.axCharacters[i].id == id ) then
                table.remove( clientData.axCharacters, i )
                break
            end
        end
    end

    hook.Run( "PlayerDeletedCharacter", id )

    ax.character.instances[ id ] = nil

    if ( IsValid( ax.gui.main ) and IsValid( ax.gui.main.load ) ) then
        ax.gui.main.load:PopulateCharacterList()
    end
end)

net.Receive("ax.character.var", function()
    local characterId = net.ReadUInt(32)
    local name = net.ReadString()
    local value = net.ReadType()

    local character = ax.character:Get(characterId)
    if ( !character ) then
        ax.util:PrintError("Character with ID " .. characterId .. " not found")
        return
    end

    if ( !istable(character.vars) ) then
        character.vars = {}
    end

    character.vars[name] = value
end)

net.Receive("ax.player.var", function()
    local client = net.ReadPlayer()
    if ( !IsValid(client) ) then return end

    local name = net.ReadString()
    local value = net.ReadType()

    local clientTable = client:GetTable()
    if ( !istable(clientTable.vars) ) then
        clientTable.vars = {}
    end

    clientTable.vars[name] = value
end)

net.Receive("ax.inventory.sync", function()
    local inv_id = net.ReadUInt( 32 )
    local inv_items = net.ReadTable( true )
    local inv_maxWeight = net.ReadFloat()

    ax.inventory.instances[inv_id] = setmetatable({
        id = inv_id,
        items = inv_items,
        maxWeight = inv_maxWeight
    }, ax.inventory.meta)
end)

net.Receive("ax.inventory.receiver.add", function()
    local inv_id = net.ReadUInt(32)
    local receiver = net.ReadPlayer()

    local inventory = ax.inventory.instances[inv_id]
    if ( !istable(inventory) ) then return end

    inventory:AddReceiver(receiver)
end)

net.Receive("ax.inventory.receiver.remove", function()
    local inventory = net.ReadUInt(32)
    local receiver = net.ReadPlayer()

    inventory:RemoveReceiver(receiver)
end)

net.Receive("ax.inventory.item.add", function()
    local inv_id = net.ReadUInt( 32 )
    local item_id = net.ReadUInt( 32 )
    local item_data = net.ReadTable()

    local inv = ax.inventory.instances[inv_id]
    if ( !istable(inv) ) then
        ax.util:PrintError("Invalid inventory ID received for item add.")
        return
    end

    local item = setmetatable( {
        id = item_id,
        data = item_data
    }, ax.item.meta )

    inv.items[#inv.items + 1] = item.id
    ax.item.instances[item.id] = item
end)

net.Receive("ax.inventory.item.remove", function()
    local inv_id = net.ReadUInt(32)
    local item_id = net.ReadUInt(32)

    local inv = ax.inventory.instances[inv_id]
    if ( !istable(inv) ) then
        ax.util:PrintError("Invalid inventory ID received for item remove.")
        return
    end

    for i = 1, #inv.items do
        if ( inv.items[i].id == item_id ) then
            table.remove(inv.items, i)
            ax.item.instances[item_id] = nil
            break
        end
    end
end)

net.Receive( "ax.relay.update", function()
    local index = net.ReadString()
    local name = net.ReadString()
    local value = net.ReadType()

    ax.relay.data[index] = ax.relay.data[index] or {}
    ax.relay.data[index][name] = value
end )
