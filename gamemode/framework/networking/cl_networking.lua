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

    ax.character.instances[character.id] = setmetatable(character, ax.meta.character)
end)

net.Receive("ax.character.cache", function()
    local characters = net.ReadTable()
    if ( !istable(characters) ) then
        ax.util:PrintError("Invalid character cache received from server")
        return
    end

    local cData = LocalPlayer():GetTable()
    cData.axCharacters = cData.axCharacters or {}

    for i = 1, #characters do
        local charData = characters[i]
        local character = setmetatable({}, ax.meta.character)

        for k, v in pairs(charData) do
            if ( k == "vars" ) then
                character.vars = util.JSONToTable(v) or {}
            else
                character[k] = v
            end
        end

        ax.character.instances[character.id] = character
        cData.axCharacters[#cData.axCharacters + 1] = character
    end

    hook.Run("OnCharactersCached", characters)
end)

net.Receive("ax.character.SetVar", function()
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

net.Receive("ax.inventory.sync", function()
    local inventory = net.ReadTable()

    ax.inventory.instances[inventory.id] = setmetatable(inventory, ax.meta.inventory)
end)

net.Receive("ax.inventory.receiver.add", function()
    local inventory = net.ReadTable()
    local receiver = net.ReadPlayer()

    ax.inventory.instances[inventory.id] = inventory

    inventory:AddReceiver(receiver)
end)

net.Receive("ax.inventory.receiver.remove", function()
    local inventory = net.ReadUInt(32)
    local receiver = net.ReadPlayer()

    ax.inventory.instances[inventory] = nil

    inventory:RemoveReceiver(receiver)
end)

net.Receive("ax.inventory.item.add", function()
    local inventory = net.ReadUInt(32)
    local item = net.ReadTable()

    local inv = ax.inventory.instances[inventory]
    if ( !istable(inv) ) then
        ax.util:PrintError("Invalid inventory ID received for item add.")
        return
    end

    inv.items[#inv.items + 1] = item
    ax.item.instances[item.id] = setmetatable(item, ax.meta.item)
end)

net.Receive("ax.inventory.item.remove", function()
    local inventory = net.ReadUInt(32)
    local itemId = net.ReadUInt(32)

    local inv = ax.inventory.instances[inventory]
    if ( !istable(inv) ) then
        ax.util:PrintError("Invalid inventory ID received for item remove.")
        return
    end

    for i = 1, #inv.items do
        if ( inv.items[i].id == itemId ) then
            table.remove(inv.items, i)
            ax.item.instances[itemId] = nil
            break
        end
    end
end)