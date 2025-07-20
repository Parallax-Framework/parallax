--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

gameevent.Listen("OnRequestFullUpdate")
hook.Add("OnRequestFullUpdate", "ax.OnRequestFullUpdate", function(data)
    if ( !istable(data) or !isnumber(data.userid) ) then return end

    local client = Player(data.userid)
    if ( !IsValid(client) ) then return end

    local clientTable = client:GetTable()
    if ( clientTable.axReady ) then return end

    clientTable.axReady = true

    timer.Simple(0, function()
        if ( !IsValid(client) ) then return end

        hook.Run("PlayerReady", client)
    end)
end)

function GM:PlayerDeathThink(client)
    local character = client:GetCharacter()
    if ( !character ) then return true end

end

function GM:PlayerReady(client)
    net.Start("ax.player.ready")
    net.Send(client)

    local inventory = setmetatable({
        id = #ax.inventory.instances + 1,
    }, ax.meta.inventory)

    local character = setmetatable({
        steamid = client:SteamID64(),
        name = "John Doe",
        id = #ax.character.instances + 1,
        id_inv = inventory.id,
    }, ax.meta.character)

    ax.inventory.instances[inventory.id] = inventory
    ax.character.instances[character.id] = character

    client:GetTable().axCharacter = character

    net.Start("ax.character.sync")
        net.WritePlayer(client)
        net.WriteTable(character)
    net.Broadcast()
end