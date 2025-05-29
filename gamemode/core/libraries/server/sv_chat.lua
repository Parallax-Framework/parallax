--- Chat library
-- @module ax.chat

function ax.chat:SendSpeaker(speaker, uniqueID, text)
    local players = {speaker}
    for k, v in player.Iterator() do
        if ( !IsValid(v) or !v:Alive() ) then continue end

        if ( hook.Run("PlayerCanHearChat", speaker, v, uniqueID, text) != false ) then
            table.insert(players, v)
        end
    end

    if ( players[1] == nil ) then return end

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