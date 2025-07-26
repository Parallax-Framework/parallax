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
    ax.inventory.instances[character.invID] = setmetatable({
        id = character.invID,
        items = {},
        maxWeight = 30.0
    }, ax.meta.inventory)

    -- Shitty
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

    ax.inventory.instances[inventory.id] = setmetatable({
        id = inventory.id,
        items = ax.util:SafeParseTable(inventory.items) or {},
        maxWeight = inventory.maxWeight or 30.0
    }, ax.meta.inventory)
end)

net.Receive("ax.inventory.receiver.add", function()
    local inventory = net.ReadTable()
    local receiver = net.ReadPlayer()

    inventory:AddReceiver(receiver)
end)

net.Receive("ax.inventory.receiver.remove", function()
    local inventory = net.ReadTable()
    local receiver = net.ReadPlayer()

    inventory:RemoveReceiver(receiver)
end)