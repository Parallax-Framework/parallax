--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

-- Player Management Commands

-- Kick Command
ax.command:Register("PlyKick", {
    Description = "Kick a player from the server",
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to kick!"
        },
        {
            Type = ax.types.text,
            Optional = true,
            Default = "No reason provided",
            ErrorMsg = "You must provide a reason for kicking the player!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Kick Players", nil) ) then
            ax.notification:Send(client, "You don't have permission to kick players.")
            return
        end

        local target = arguments[1]
        local reason = arguments[2] or "No reason provided"

        if ( !IsValid(target) ) then
            ax.notification:Send(client, "Invalid target player.")
            return
        end

        if ( !MODULE:CanTarget(client, target) ) then
            ax.notification:Send(client, "You cannot target this player.")
            return
        end

        MODULE:LogAction(client, "kicked", target, reason)

        ax.notification:Send(nil, client:SteamName() .. " has kicked " .. target:SteamName() .. ". Reason: " .. reason)

        target:Kick(reason)
    end
})

-- Ban Command
ax.command:Register("PlyBan", {
    Description = "Ban a player from the server",
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to ban!"
        },
        {
            Type = ax.types.number,
            Optional = true,
            Default = 0, -- 0 means permanent ban
            ErrorMsg = "You must provide a duration for the ban (in minutes)!"
        },
        {
            Type = ax.types.text,
            Optional = true,
            Default = "No reason provided",
            ErrorMsg = "You must provide a reason for banning the player!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Ban Players", nil) ) then
            ax.notification:Send(client, "You don't have permission to ban players.")
            return
        end

        local target = arguments[1]
        local duration = arguments[2] or 0
        local reason = arguments[3] or "No reason provided"

        if ( !IsValid(target) ) then
            ax.notification:Send(client, "Invalid target player.")
            return
        end

        if ( !MODULE:CanTarget(client, target) ) then
            ax.notification:Send(client, "You cannot target this player.")
            return
        end

        if ( duration > 0 and !CAMI.PlayerHasAccess(client, "Parallax - Permanent Ban", nil) ) then
            duration = math.min(duration, 10080) -- Max 7 days for non-admins
        end

        MODULE:LogAction(client, "banned", target, reason, duration)

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

        ax.notification:Send(nil, client:SteamName() .. " has banned " .. target:SteamName() .. ". Reason: " .. reason .. (duration > 0 and " for " .. duration .. " minutes." or " permanently."))

        target:Kick("Banned: " .. reason)
    end
})

-- Unban Command
ax.command:Register("PlyUnban", {
    Description = "Unban a player by SteamID",
    Arguments = {
        {
            Type = ax.types.steamid,
            ErrorMsg = "You must provide a valid SteamID to unban!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Unban Players", nil) ) then
            ax.notification:Send(client, "You don't have permission to unban players.")
            return
        end

        local steamid = arguments[1]
        if ( !MODULE.BannedPlayers[steamid] ) then
            ax.notification:Send(client, "Player is not banned.")
            return
        end

        local banData = MODULE.BannedPlayers[steamid]
        MODULE.BannedPlayers[steamid] = nil
        MODULE:SaveData()

        MODULE:LogAction(client, "unbanned", nil, "Unbanned " .. banData.name)
        ax.notification:Send(client, "Successfully unbanned " .. banData.name)
    end
})

-- Teleportation Commands

-- Teleport to Player
ax.command:Register("PlyGoto", {
    Description = "Teleport to a player",
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to teleport to!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Teleport", nil) ) then
            ax.notification:Send(client, "You don't have permission to teleport.")
            return
        end

        local target = arguments[1]
        if ( !IsValid(target) ) then
            ax.notification:Send(client, "Invalid target player.")
            return
        end

        if ( target == client ) then
            ax.notification:Send(client, "You cannot teleport to yourself.")
            return
        end

        local pos = target:GetPos()
        local ang = target:GetAngles()

        client:SetPos(pos + Vector(50, 0, 0))
        client:SetAngles(ang)

        MODULE:LogAction(client, "teleported to", target)
        ax.notification:Send(client, "Teleported to " .. target:SteamName())
    end
})

-- Bring Player
ax.command:Register("PlyBring", {
    Description = "Bring a player to you",
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to bring!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Bring Players", nil) ) then
            ax.notification:Send(client, "You don't have permission to bring players.")
            return
        end

        local target = arguments[1]
        if ( !IsValid(target) ) then
            ax.notification:Send(client, "Invalid target player.")
            return
        end

        if ( target == client ) then
            ax.notification:Send(client, "You cannot bring yourself.")
            return
        end

        if ( !MODULE:CanTarget(client, target) ) then
            ax.notification:Send(client, "You cannot target this player.")
            return
        end

        local pos = client:GetPos()
        local ang = client:GetAngles()

        target:SetPos(pos + client:GetForward() * 100)
        target:SetAngles(ang)

        MODULE:LogAction(client, "brought", target)
        ax.notification:Send(client, "Brought " .. target:SteamName())
        ax.notification:Send(target, "You were brought by " .. client:SteamName())
    end
})

-- Send Player to Another Player
ax.command:Register("PlySend", {
    Description = "Send a player to another player",
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid target player to send!"
        },
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid destination player to send to!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Send Players", nil) ) then
            ax.notification:Send(client, "You don't have permission to send players.")
            return
        end

        local target = arguments[1]
        local destination = arguments[2]

        if ( !IsValid(target) or !IsValid(destination) ) then
            ax.notification:Send(client, "Invalid target or destination player.")
            return
        end

        if ( target == destination ) then
            ax.notification:Send(client, "Target and destination cannot be the same.")
            return
        end

        if ( !MODULE:CanTarget(client, target) ) then
            ax.notification:Send(client, "You cannot target this player.")
            return
        end

        local pos = destination:GetPos()
        local ang = destination:GetAngles()

        target:SetPos(pos + Vector(50, 0, 0))
        target:SetAngles(ang)

        MODULE:LogAction(client, "sent", target, "Sent to " .. destination:SteamName())
        ax.notification:Send(client, "Sent " .. target:SteamName() .. " to " .. destination:SteamName())
        ax.notification:Send(target, "You were sent to " .. destination:SteamName() .. " by " .. client:SteamName())
    end
})

-- Player Control Commands

-- Freeze Player
ax.command:Register("PlyFreeze", {
    Description = "Freeze/unfreeze a player",
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to freeze!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Freeze Players", nil) ) then
            ax.notification:Send(client, "You don't have permission to freeze players.")
            return
        end

        local target = arguments[1]
        if ( !IsValid(target) ) then
            ax.notification:Send(client, "Invalid target player.")
            return
        end

        if ( !MODULE:CanTarget(client, target) ) then
            ax.notification:Send(client, "You cannot target this player.")
            return
        end

        local frozen = target:GetMoveType() == MOVETYPE_NONE
        if ( frozen ) then
            target:SetMoveType(MOVETYPE_WALK)
            MODULE:LogAction(client, "unfroze", target)
            ax.notification:Send(client, "Unfroze " .. target:SteamName())
            ax.notification:Send(target, "You were unfrozen by " .. client:SteamName())
        else
            target:SetMoveType(MOVETYPE_NONE)
            MODULE:LogAction(client, "froze", target)
            ax.notification:Send(client, "Froze " .. target:SteamName())
            ax.notification:Send(target, "You were frozen by " .. client:SteamName())
        end
    end
})

-- Slay Player
ax.command:Register("PlySlay", {
    Description = "Kill a player",
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to slay!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Slay Players", nil) ) then
            ax.notification:Send(client, "You don't have permission to slay players.")
            return
        end

        local target = arguments[1]
        if ( !IsValid(target) ) then
            ax.notification:Send(client, "Invalid target player.")
            return
        end

        if ( !MODULE:CanTarget(client, target) ) then
            ax.notification:Send(client, "You cannot target this player.")
            return
        end

        if ( !target:Alive() ) then
            ax.notification:Send(client, "Player is already dead.")
            return
        end

        target:Kill()

        MODULE:LogAction(client, "slayed", target)
        ax.notification:Send(client, "Slayed " .. target:SteamName())
        ax.notification:Send(target, "You were slayed by " .. client:SteamName())
    end
})

-- Respawn Player
ax.command:Register("PlyRespawn", {
    Description = "Respawn a player",
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to respawn!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Respawn Players", nil) ) then
            ax.notification:Send(client, "You don't have permission to respawn players.")
            return
        end

        local target = arguments[1]
        if ( !IsValid(target) ) then
            ax.notification:Send(client, "Invalid target player.")
            return
        end

        if ( !MODULE:CanTarget(client, target) ) then
            ax.notification:Send(client, "You cannot target this player.")
            return
        end

        target:Spawn()

        MODULE:LogAction(client, "respawned", target)
        ax.notification:Send(client, "Respawned " .. target:SteamName())
        ax.notification:Send(target, "You were respawned by " .. client:SteamName())
    end
})

-- Self Admin Commands

-- Noclip Toggle
ax.command:Register("ToggleNoclip", {
    Description = "Toggle noclip mode",
    Arguments = {},
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Noclip", nil) ) then
            ax.notification:Send(client, "You don't have permission to use noclip.")
            return
        end

        local noclip = client:GetMoveType() == MOVETYPE_NOCLIP
        if ( noclip ) then
            client:SetMoveType(MOVETYPE_WALK)
            ax.notification:Send(client, "Noclip disabled.")
        else
            client:SetMoveType(MOVETYPE_NOCLIP)
            ax.notification:Send(client, "Noclip enabled.")
        end

        MODULE:LogAction(client, noclip and "disabled noclip" or "enabled noclip")
    end
})

-- Godmode Toggle
ax.command:Register("ToggleGodmode", {
    Description = "Toggle godmode",
    Arguments = {},
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Godmode", nil) ) then
            ax.notification:Send(client, "You don't have permission to use godmode.")
            return
        end

        local god = client:HasGodMode()
        if ( god ) then
            client:GodDisable()
            ax.notification:Send(client, "Godmode disabled.")
        else
            client:GodEnable()
            ax.notification:Send(client, "Godmode enabled.")
        end

        MODULE:LogAction(client, god and "disabled godmode" or "enabled godmode")
    end
})

-- Spectate Command
ax.command:Register("PlySpectate", {
    Description = "Enter spectator mode",
    Arguments = {},
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Spectate", nil) ) then
            ax.notification:Send(client, "You don't have permission to spectate.")
            return
        end

        local spectating = client:GetObserverMode() != OBS_MODE_NONE
        if ( spectating ) then
            client:UnSpectate()
            client:Spawn()
            ax.notification:Send(client, "Stopped spectating.")
        else
            client:Spectate(OBS_MODE_ROAMING)
            ax.notification:Send(client, "Started spectating.")
        end

        MODULE:LogAction(client, spectating and "stopped spectating" or "started spectating")
    end
})

-- Utility Commands

-- Clean Up Map
ax.command:Register("CleanupMap", {
    Description = "Clean up map entities",
    Arguments = {
        {
            Type = ax.types.text,
            Optional = true,
            Default = "No reason provided",
            ErrorMsg = "You must provide a reason for cleanup!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Cleanup", nil) ) then
            ax.notification:Send(client, "You don't have permission to cleanup.")
            return
        end

        game.CleanUpMap()

        MODULE:LogAction(client, "cleaned up map", nil, arguments[1] or "No reason provided")

        ax.notification:Send(nil, client:SteamName() .. " has cleaned up the map. Reason: " .. (arguments[1] or "No reason provided"))
    end
})

-- Change Map
ax.command:Register("ChangeMap", {
    Description = "Change the map",
    Arguments = {
        {
            Type = ax.types.string,
            ErrorMsg = "You must provide a valid map name!"
        },
        {
            Type = ax.types.text,
            Optional = true,
            Default = "No reason provided",
            ErrorMsg = "You must provide a reason for changing the map!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Map Control", nil) ) then
            ax.notification:Send(client, "You don't have permission to change maps.")
            return
        end

        local mapName = arguments[1]
        if ( !file.Exists("maps/" .. mapName .. ".bsp", "GAME") ) then
            ax.notification:Send(client, "Map does not exist.")
            return
        end

        MODULE:LogAction(client, "changed map", nil, "Changed to " .. mapName .. " - " .. (arguments[2] or "No reason provided"))

        ax.notification:Send(nil, client:SteamName() .. " is changing maps from " .. game.GetMap() .. " to " .. mapName .. " in 5 seconds. Reason: " .. (arguments[2] or "No reason provided"))

        timer.Simple(5, function()
            RunConsoleCommand("changelevel", mapName)
        end)
    end
})

-- View Admin Logs, TODO: Move this to the admin menu rather than a command
ax.command:Register("ViewLogs", {
    Description = "View logs",
    Arguments = {
        {
            Type = ax.types.number,
            Optional = true,
            Default = 10,
            ErrorMsg = "You must provide the number of logs to view (max 50)!"
        }
    },
    Callback = function(self, client, arguments)
        if ( !CAMI.PlayerHasAccess(client, "Parallax - View Logs", nil) ) then
            ax.notification:Send(client, "You don't have permission to view logs.")
            return
        end

        local count = arguments[1] or 10
        count = math.min(count, 50) -- Max 50 logs at once

        local logs = MODULE:GetLogs()
        local startIndex = math.max(1, #logs - count + 1)

        ax.notification:Send(client, "=== Admin Logs (Last " .. count .. ") ===")

        for i = startIndex, #logs do
            local log = logs[i]
            local timeStr = os.date("%H:%M:%S", log.timestamp)
            local logStr = string.format("[%s] %s %s", timeStr, log.adminName, log.action)

            if ( log.targetName ) then
                logStr = logStr .. " " .. log.targetName
            end

            if ( log.reason and log.reason != "" ) then
                logStr = logStr .. " - " .. log.reason
            end

            ax.notification:Send(client, logStr)
        end
    end
})
