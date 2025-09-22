local cfg = ax.discord.config or {}
function MODULE:Initialize()
    ax.discord.relay:CheckDependencies()
    ax.discord.relay:ConnectWebSocket()
end

function MODULE:PlayerReady(client)
    if ( !cfg.enabled ) then return end

    local sid = client:SteamID64()
    local name = client:Nick()
    ax.discord.relay:Transmit("public",
        string.format(":arrow_right: %s joined the server", name),
        "Player Joined",
        string.format("Player: %s\nSteam ID 64: %s\nTime: <t:%d:f>", name, sid, os.time())
    )

    local issues = {}
    if ( cfg.useWebSocket and !ax.discord.relay.hasGWSockets ) then
        issues[#issues + 1] = "gwsockets is not installed"
    end

    if ( !ax.discord.relay.hasCHTTP ) then
        issues[#issues + 1] = "gm_chttp is not installed"
    end

    if ( cfg.privateWebhook == "" and cfg.privateWebhook == "" and !(cfg.useWebSocket and cfg.webSocketURL != "") ) then
        issues[#issues + 1] = "no webhook/websocket configured"
    end

    if ( #issues > 0 ) then
        ax.util:PrintError("Discord Relay Setup issue(s): " .. table.concat(issues, ", "))
    end
end

function MODULE:PlayerSpawnProp(client, model)
    if ( !IsValid(client) ) then return end

    local name = client:Nick()
    local sid = client:SteamID64()
    ax.discord.relay:Transmit("private",
        string.format(":package: %s spawned a prop", name),
        "Prop Spawned",
        string.format("Player: %s (%s)\nModel: %s\nTime: <t:%d:f>", name, sid, tostring(model), os.time())
    )
end

concommand.Add("parallax_discord_test", function(client, _, args)
    if ( IsValid(client) and !client:IsAdmin() ) then return end

    local kind = (args and args[1]) or "public"
    if ( kind and cfg.channels and cfg.channels[kind] ) then
        ax.discord.relay:Transmit(kind, "", "Relay Test", "This is a " .. kind .. " test message.")
        ax.util:PrintSuccess("Sent " .. kind .. " test message.")
    else
        ax.util:PrintWarning("No valid kind specified.")
    end
end, nil, "Send a test relay to Discord.")