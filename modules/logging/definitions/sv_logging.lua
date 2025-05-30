local MODULE = MODULE

function MODULE:Send(...)
    if ( !ax.config:Get("logging", true) ) then return end

    local receivers = {}
    for k, v in player.Iterator() do
        if ( !CAMI.PlayerHasAccess(v, "Parallax - Logging") ) then continue end

        table.insert(receivers, v)
    end

    -- Send to the remote console if we are in a dedicated server
    if ( game.IsDedicated() ) then
        ax.util:Print("[Logging] ", ...)
    end

    ax.net:Start(receivers, "logging.send", {...})
end