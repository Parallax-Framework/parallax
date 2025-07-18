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
function MODULE:PostPlayerReady(client)
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
            if ( ent:GetOwner() == client ) then
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
        admin_logs = self.AdminLogs,
        tickets = self.Tickets,
        ticket_comments = self.TicketComments,
        next_ticket_id = self.NextTicketID,
        custom_usergroups = self.CustomUsergroups,
        player_usergroups = self.PlayerUsergroups,
        temp_usergroups = self.TempUsergroups
    }

    ax.data:Set("admin", data, true, true)
end

function MODULE:LoadData()
    local data = ax.data:Get("admin", {}, true, true)
    if (data.banned_players) then
        self.BannedPlayers = data.banned_players
    end

    if (data.admin_logs) then
        self.AdminLogs = data.admin_logs
    end

    if (data.tickets) then
        self.Tickets = data.tickets
    end

    if (data.ticket_comments) then
        self.TicketComments = data.ticket_comments
    end

    if (data.next_ticket_id) then
        self.NextTicketID = data.next_ticket_id
    end

    if (data.custom_usergroups) then
        self.CustomUsergroups = data.custom_usergroups

        -- Re-register custom usergroups with CAMI
        for name, usergroup in pairs(self.CustomUsergroups) do
            CAMI.RegisterUsergroup({
                Name = name,
                Inherits = usergroup.Inherits
            }, "Parallax")

            self.Groups[name] = usergroup
        end
    end

    if (data.player_usergroups) then
        self.PlayerUsergroups = data.player_usergroups
    end

    if (data.temp_usergroups) then
        self.TempUsergroups = data.temp_usergroups

        -- Recreate temp usergroup timers
        for steamID, tempData in pairs(self.TempUsergroups) do
            local remainingTime = tempData.expires - os.time()
            if (remainingTime > 0) then
                timer.Create("TempUsergroup_" .. steamID, remainingTime, 1, function()
                    local player = player.GetBySteamID64(steamID)
                    if (IsValid(player)) then
                        player:SetUserGroup(tempData.originalGroup)
                        self:LogAction(nil, "temp usergroup expired", player, "Reverted from " .. tempData.tempGroup .. " to " .. tempData.originalGroup)
                        ax.notification:Send(player, "Your temporary usergroup has expired. Reverted to " .. tempData.originalGroup)
                    end
                    self.TempUsergroups[steamID] = nil
                end)
            else
                -- Expired, remove it
                self.TempUsergroups[steamID] = nil
            end
        end
    end
end

-- Ticket cleanup timer
if (timer.Exists("Parallax.Admin.TicketCleanup")) then
    timer.Remove("Parallax.Admin.TicketCleanup")
end

timer.Create("Parallax.Admin.TicketCleanup", 3600, 0, function()
    MODULE:CleanupInactiveTickets()
end)

-- Handle player connect for usergroup restoration
function MODULE:PlayerAuthed(client, steamid)
    -- Restore saved usergroup
    local savedGroup = self.PlayerUsergroups[steamid]
    if (savedGroup) then
        client:SetUserGroup(savedGroup.group)
    end

    -- Check for temporary usergroup
    local tempGroup = self.TempUsergroups[steamid]
    if (tempGroup) then
        local remainingTime = tempGroup.expires - os.time()
        if (remainingTime > 0) then
            client:SetUserGroup(tempGroup.tempGroup)

            -- Recreate timer
            timer.Create("TempUsergroup_" .. steamid, remainingTime, 1, function()
                if (IsValid(client)) then
                    client:SetUserGroup(tempGroup.originalGroup)
                    self:LogAction(nil, "temp usergroup expired", client, "Reverted from " .. tempGroup.tempGroup .. " to " .. tempGroup.originalGroup)
                    ax.notification:Send(client, "Your temporary usergroup has expired. Reverted to " .. tempGroup.originalGroup)
                end
                self.TempUsergroups[steamid] = nil
            end)
        else
            -- Expired, remove it
            self.TempUsergroups[steamid] = nil
        end
    end
end

function MODULE:PlayerSpawnNPC(ply, type, weapon)
    local character = ply:GetCharacter()
    if ( !character ) then return end

    if ( !CAMI.PlayerHasAccess(ply, "Parallax - Spawn NPCs", nil) ) then
        ax.notification:Send(ply, "You do not have permission to spawn NPCs.")
        return false
    end

    if ( !character:HasFlag("n") ) then
        ax.notification:Send(ply, "You do not have the 'n' flag to spawn NPCs.")
        return false
    end

    return true
end