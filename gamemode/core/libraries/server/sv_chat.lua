--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Chat library
-- @module ax.chat

function ax.chat:SendSpeaker(speaker, uniqueID, text)
    local players = {}
    for k, v in player.Iterator() do
        if ( !IsValid(v) or !v:Alive() ) then continue end

        if ( hook.Run("PlayerCanHearChat", speaker, v, uniqueID, text) != false ) then
            table.insert(players, v)
        end
    end

    ax.net:Start(players, "chat.send", {
        Speaker = speaker:EntIndex(),
        UniqueID = uniqueID,
        Text = text
    })

    hook.Run("OnChatMessageSent", speaker, players, uniqueID, text)
end

function ax.chat:SendTo(players, uniqueID, text)
    players = players or select(2, player.Iterator())

    ax.net:Start(players, "chat.send", {
        UniqueID = uniqueID,
        Text = text
    })
end

ax.chat = ax.chat