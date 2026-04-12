local MODULE = MODULE

MODULE.name = "Join Security"
MODULE.author = "bloodycop6385"

ax.config:Add("joinsecurity.antifamilyshare", ax.type.bool, true, {
    description = "joinsecurity.antifamilyshare.help",
    category = "joinsecurity"
})

ax.config:Add("joinsecurity.versionmismatch", ax.type.bool, true, {
    description = "joinsecurity.versionmismatch.help",
    category = "joinsecurity"
})

ax.localization:Register("en", {
    ["category.joinsecurity"] = "Join Security",

    ["config.joinsecurity.antifamilyshare"] = "Anti-Family Share",
    ["config.joinsecurity.antifamilyshare.help"] = "Kicks players that have the game via family sharing.",

    ["joinsecurity.antifamilyshare.kick_msg"] = "You must own the game, not play it via family sharing.",

    ["config.joinsecurity.versionmismatch"] = "Version Mismatch",
    ["config.joinsecurity.versionmismatch.help"] = "Kicks players with mismatched client versions.",

    ["joinsecurity.versionmismatch.kick_msg"] = "Your client version does not match the server's version.\nYours: %s\nServer: %s",
})

if ( SERVER ) then
    concommand.Add("ax_joinsecurity_toggle_familyshare", function(client, cmd, args)
        local value = ax.config:Get("joinsecurity.antifamilyshare", true)
        ax.config:Set("joinsecurity.antifamilyshare", !value)

        print("Anti-Family Share toggled to: " .. tostring(!value))
    end)

    concommand.Add("ax_joinsecurity_toggle_versionmismatch", function(client, cmd, args)
        local value = ax.config:Get("joinsecurity.versionmismatch", true)
        ax.config:Set("joinsecurity.versionmismatch", !value)
        print("Version Mismatch toggled to: " .. tostring(!value))
    end)

    MODULE.GMODVERSION = VERSION

    function MODULE:PlayerAuthed(client, steamid, _)
        if ( !ax.config:Get("joinsecurity.antifamilyshare", true) ) then return end

        local sid64Owner = client:OwnerSteamID64()
        local sid64 = util.SteamIDTo64(steamid)

        if ( sid64Owner != sid64 ) then
            client:Kick(ax.localization:GetPhrase("joinsecurity.antifamilyshare.kick_msg") or "You must own the game, not play it via family sharing.")
            print("Player " .. client:SteamName() .. "(" .. client:SteamID64() .. ")" .. " has been kicked for anti-family share violation.")
        end
    end

    ax.net:Hook("joinsecurity.versioncheck", function(client, clientVersion)
        if ( !ax.config:Get("joinsecurity.versionmismatch", true) ) then return end

        if ( clientVersion != MODULE.GMODVERSION ) then
            client:Kick(string.format(ax.localization:GetPhrase("joinsecurity.versionmismatch.kick_msg", clientVersion, MODULE.GMODVERSION) or "Your client version does not match the server's version.\nYours: %s\nServer: %s", clientVersion, MODULE.GMODVERSION))
        end

        print("Player " .. client:SteamName() .. "(" .. client:SteamID64() .. ")" .. " has been kicked for version mismatch.")
    end)
else
    function MODULE:OnClientCached()
        ax.net:Start("joinsecurity.versioncheck", VERSION)
    end
end
