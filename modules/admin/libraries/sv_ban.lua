--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

-- Handle admin commands from console
concommand.Add("ax_admin_kick", function(client, cmd, args)
    if ( IsValid(client) and !CAMI.PlayerHasAccess(client, "Parallax - Kick Players", nil) ) then
        return
    end

    local target = player.GetByUniqueID(args[1])
    local reason = args[2] or "No reason provided"

    if ( IsValid(target) ) then
        MODULE:LogAction(client, "kicked", target, reason)
        target:Kick(reason)
    end
end)

concommand.Add("ax_admin_ban", function(client, cmd, args)
    if ( IsValid(client) and !CAMI.PlayerHasAccess(client, "Parallax - Ban Players", nil) ) then
        return
    end

    local target = ax.util:FindPlayer(args[1])
    local duration = tonumber(args[2]) or 0
    local reason = args[3] or "No reason provided"

    if ( IsValid(target) ) then
        local banData = {
            steamid = target:SteamID64(),
            name = target:SteamName(),
            admin = client:SteamID64(),
            adminName = client:SteamName(),
            reason = reason,
            timestamp = os.time(),
            duration = duration,
            expires = duration > 0 and (os.time() + duration * 60) or 0
        }

        MODULE.BannedPlayers[target:SteamID64()] = banData
        MODULE:SaveData()
        MODULE:LogAction(client, "banned", target, reason, duration)

        target:Kick("Banned: " .. reason)
    end
end)

if ( timer.Exists("Parallax.Admin.BanCleanup") ) then
    timer.Remove("Parallax.Admin.BanCleanup")
end

-- Periodic ban list cleanup
timer.Create("Parallax.Admin.BanCleanup", 3600, 0, function()
    local cleaned = 0
    for steamid, banData in pairs(MODULE.BannedPlayers) do
        if ( banData.expires > 0 and os.time() > banData.expires ) then
            MODULE.BannedPlayers[steamid] = nil
            cleaned = cleaned + 1
        end
    end

    if ( cleaned > 0 ) then
        MODULE:SaveData()
        ax.util:Print("Cleaned up " .. cleaned .. " expired bans.")
    end
end)