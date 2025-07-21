--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

net.Receive("ax.player.ready", function(len)
    local clientTable = ax.client:GetTable()
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
    ax.inventory.instances[#ax.inventory.instances + 1] = setmetatable({
        id = character.id_inv,
    }, ax.meta.inventory)

    -- Shitty
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