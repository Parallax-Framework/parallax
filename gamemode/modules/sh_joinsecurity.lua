local MODULE = MODULE

MODULE.name = "Join Security"
MODULE.author = "bloodycop6385"

ax.config:Add("joinsecurity.antifamilyshare", ax.type.bool, true, {
    description = "joinsecurity.antifamilyshare.help",
    subCategory = "joinsecurity",
    category = "general",
})

ax.config:Add("joinsecurity.versionmismatch", ax.type.bool, false, {
    description = "joinsecurity.versionmismatch.help",
    subCategory = "joinsecurity",
    category = "general",
})

ax.config:Add("joinsecurity.versionmismatch.branchmatch", ax.type.bool, false, {
    description = "joinsecurity.versionmismatch.branchmatch.help",
    subCategory = "joinsecurity",
    category = "general",
})

ax.config:Add("joinsecurity.antivpn", ax.type.bool, false, {
    description = "joinsecurity.antivpn.help",
    subCategory = "joinsecurity",
    category = "general",
})

ax.localization:Register("en", {
    ["subcategory.joinsecurity"] = "Join Security",

    ["config.joinsecurity.antifamilyshare"] = "Anti-Family Share",
    ["config.joinsecurity.antifamilyshare.help"] = "Kicks players that have the game via family sharing.",

    ["joinsecurity.antifamilyshare.kick_msg"] = "You must own the game, not play it via family sharing.",

    ["config.joinsecurity.versionmismatch"] = "Version Mismatch",
    ["config.joinsecurity.versionmismatch.help"] = "Kicks players with mismatched client versions.",

    ["config.joinsecurity.antivpn"] = "Anti-VPN",
    ["config.joinsecurity.antivpn.help"] = "Kicks players using VPN services.",

    ["config.joinsecurity.versionmismatch.branchmatch"] = "Branch Match",
    ["config.joinsecurity.versionmismatch.branchmatch.help"] = "Only kicks players with mismatched client versions on the same branch as the server.",

    ["joinsecurity.versionmismatch.kick_msg"] = "Your client version does not match the server's version.\nYours: %s\nServer: %s",
})

ax.localization:Register("fr", {
    ["subcategory.joinsecurity"] = "Sécurité de connexion",

    ["config.joinsecurity.antifamilyshare"] = "Anti-Family Share",
    ["config.joinsecurity.antifamilyshare.help"] = "Expulse les joueurs qui possèdent le jeu via le partage familial.",

    ["joinsecurity.antifamilyshare.kick_msg"] = "Vous devez posséder le jeu, et non le jouer via le partage familial.",

    ["config.joinsecurity.versionmismatch"] = "Version incompatible",
    ["config.joinsecurity.versionmismatch.help"] = "Expulse les joueurs avec des versions client différentes.",

    ["config.joinsecurity.antivpn"] = "Anti-VPN",
    ["config.joinsecurity.antivpn.help"] = "Expulse les joueurs utilisant des services VPN.",

    ["config.joinsecurity.versionmismatch.branchmatch"] = "Correspondance de branche",
    ["config.joinsecurity.versionmismatch.branchmatch.help"] = "N'expulse que les joueurs avec des versions client différentes sur la même branche que le serveur.",

    ["joinsecurity.versionmismatch.kick_msg"] = "La version de votre client ne correspond pas à celle du serveur.\nVotre version : %s\nServeur : %s",
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

    concommand.Add("ax_joinsecurity_toggle_versionmismatch_branchmatch", function(client, cmd, args)
        local value = ax.config:Get("joinsecurity.versionmismatch.branchmatch", true)
        ax.config:Set("joinsecurity.versionmismatch.branchmatch", !value)
        print("Version Mismatch Branch Match toggled to: " .. tostring(!value))
    end)

    MODULE.GMODVERSION  = VERSION
    MODULE.GMODBRANCH   = BRANCH
    MODULE.ProxyURL = "https://proxycheck.io/v3/"
    function MODULE:PlayerAuthed(client, steamid, _)
        if ( game.SinglePlayer() ) then return end

        if ( ax.config:Get("joinsecurity.antivpn", true) ) then
            local ip = client:IPAddress()
            http.Fetch(self.ProxyURL .. ip, function(body, size, headers, responseCode)
                if ( responseCode != 200 ) then return end

                local data = util.JSONToTable(body)
                local result = data[ip]
                if ( data and result and result.detections.vpn == true ) then
                    client:Kick(ax.localization:GetPhrase("joinsecurity.antivpn.kick_msg") or "You are not allowed to use a VPN.")
                    print("Player " .. client:SteamName() .. "(" .. client:SteamID64() .. ")" .. " has been kicked for using a VPN.")
                end
            end, function(error)
                print("Error fetching proxy check data for player " .. client:SteamName() .. ": " .. error)
            end)
        end

        if ( ax.config:Get("joinsecurity.antifamilyshare", true) ) then
            local sid64Owner = client:OwnerSteamID64()
            local sid64 = util.SteamIDTo64(steamid)

            if ( sid64Owner != sid64 ) then
                client:Kick(ax.localization:GetPhrase("joinsecurity.antifamilyshare.kick_msg") or "You must own the game, not play it via family sharing.")
                print("Player " .. client:SteamName() .. "(" .. client:SteamID64() .. ")" .. " has been kicked for anti-family share violation.")
                return
            end
        end
    end

    ax.net:Hook("joinsecurity.versioncheck", function(client, clientVersion, clientBranch)
        if ( game.SinglePlayer() ) then return end
        if ( !ax.config:Get("joinsecurity.versionmismatch", true) ) then return end

        if ( ( ax.config:Get("config.joinsecurity.versionmismatch.branchmatch", true) and clientBranch == MODULE.GMODBRANCH ) and clientVersion != MODULE.GMODVERSION ) then
            client:Kick(string.format(ax.localization:GetPhrase("joinsecurity.versionmismatch.kick_msg", clientVersion, MODULE.GMODVERSION) or "Your client version does not match the server's version.\nYours: %s\nServer: %s", clientVersion, MODULE.GMODVERSION))
            print("Player " .. client:SteamName() .. "(" .. client:SteamID64() .. ")" .. " has been kicked for version mismatch.")
            return
        end
    end)
else
    function MODULE:OnClientCached()
        if ( game.SinglePlayer() ) then return end

        ax.net:Start("joinsecurity.versioncheck", VERSION, BRANCH)
    end
end
