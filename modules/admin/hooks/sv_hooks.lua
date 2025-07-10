--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

-- Player connection handling
function MODULE:PlayerReady(client)
    -- Check if player is banned
    local steamid = client:SteamID64()
    local banData = self.BannedPlayers[steamid]
    if ( banData ) then
        -- Check if ban has expired
        if ( banData.expires > 0 and os.time() > banData.expires ) then
            self.BannedPlayers[steamid] = nil
            self:SaveData()
        else
            local reason = banData.reason or "No reason provided"
            local timeLeft = ""

            if ( banData.expires > 0 ) then
                local remaining = banData.expires - os.time()
                timeLeft = string.format(" (Time remaining: %s)", string.FormattedTime(remaining))
            end

            client:Kick("You are banned from this server. Reason: " .. reason .. timeLeft)
            return
        end
    end

    -- Send group colors and data
    net.Start("ax.admin.group.update")
        net.WriteString("")
        net.WriteString("")
        net.WriteTable(MODULE:GetGroups())
    net.Send(client)

    -- Set default usergroup if not set
    if ( client:GetUserGroup() == "user" and !game.IsDedicated() and client == Player(1) ) then
        client:SetUserGroup("superadmin")
        self:LogAction(nil, "auto-promoted", client, "First player on listen server")
    end

    self:LogAction(nil, "connected", client, "Connected to server")
end

function MODULE:PlayerDisconnected(client)
    self:LogAction(nil, "disconnected", client, "Disconnected from server")
end

-- Handle player spawn after spectating
function MODULE:PlayerSpawn(client)
    if ( client:GetObserverMode() != OBS_MODE_NONE ) then
        client:UnSpectate()
    end
end

-- Anti-spam and chat filtering
function MODULE:PlayerSay(client, text, teamChat)
    -- Log chat messages from admins
    if ( CAMI.PlayerHasAccess(client, "Parallax - Admin Menu", nil) ) then
        self:LogAction(client, "said", nil, text)
    end
end

-- Cleanup disconnected players' entities
function MODULE:PlayerDisconnected(client)
    timer.Simple(1, function()
        -- Clean up props owned by disconnected players
        for _, ent in ents.Iterator() do
            if ( IsValid(ent) and ent:GetOwner() == client ) then
                ent:Remove()
            end
        end
    end)
end

-- Initialize ban system
function MODULE:CheckPassword(steamid64, ipaddress, svpassword, clpassword, name)
    local banData = MODULE.BannedPlayers[steamid64]
    if ( banData ) then
        -- Check if ban has expired
        if ( banData.expires > 0 and os.time() > banData.expires ) then
            MODULE.BannedPlayers[steamid64] = nil
            MODULE:SaveData()
            return
        end

        local reason = banData.reason or "No reason provided"
        local timeLeft = ""

        if ( banData.expires > 0 ) then
            local remaining = banData.expires - os.time()
            timeLeft = string.format(" (Time remaining: %s)", string.FormattedTime(remaining))
        end

        return false, "You are banned from this server. Reason: " .. reason .. timeLeft
    end
end

function MODULE:PlayerSpawn(client)
    if ( CAMI.PlayerHasAccess(client, "Parallax - Admin Menu", nil) ) then
        MODULE:LogAction(client, "spawned")
    end
end

function MODULE:PlayerDeath(client, inflictor, attacker)
    if ( CAMI.PlayerHasAccess(client, "Parallax - Admin Menu", nil) ) then
        local attackerName = IsValid(attacker) and attacker:IsPlayer() and attacker:SteamName() or "Unknown"
        MODULE:LogAction(client, "died", nil, "Killed by: " .. attackerName)
    end
end

function MODULE:SaveData()
    local data = {
        banned_players = self.BannedPlayers,
        admin_logs = self.AdminLogs
    }

    ax.data:Set("ax.admin.data", data, true, true)
end

function MODULE:LoadData()
    local data = ax.data:Get("ax.admin.data", {}, true, true)
    if ( data.banned_players ) then
        self.BannedPlayers = data.banned_players
    end

    if ( data.admin_logs ) then
        self.AdminLogs = data.admin_logs
    end
end