--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

-- Client-side admin data
MODULE.ClientGroups = {}
MODULE.ClientBans = {}
MODULE.ClientLogs = {}

-- Receive admin logs from server
net.Receive("ax.admin.logs.response", function()
    local logs = net.ReadTable()
    MODULE.ClientLogs = logs

    -- Update logs display if admin menu is open
    if ( IsValid(MODULE.AdminMenu) and MODULE.AdminMenu.LogsList ) then
        MODULE.AdminMenu.LogsList:Clear()

        for _, log in pairs(logs) do
            local timeStr = os.date("%H:%M:%S", log.timestamp)
            local line = MODULE.AdminMenu.LogsList:AddLine(
                timeStr,
                log.adminName,
                log.action,
                log.targetName or "",
                log.reason or ""
            )
            line.log = log
        end
    end
end)

-- Receive group updates from server
net.Receive("ax.admin.group.update", function()
    local steamid = net.ReadString()
    local group = net.ReadString()

    if ( steamid == "" ) then
        -- Full group data update
        MODULE.ClientGroups = net.ReadTable()
    else
        -- Single player group update
        local client = player.GetBySteamID64(steamid)
        if ( IsValid(client) ) then
            client:SetUserGroup(group)
        end
    end
end)

-- Receive ban updates from server
net.Receive("ax.admin.ban.update", function()
    local steamid = net.ReadString()
    local banData = net.ReadTable()

    MODULE.ClientBans[steamid] = banData

    -- Update ban display if admin menu is open
    if ( IsValid(MODULE.AdminMenu) and MODULE.AdminMenu.BansList ) then
        MODULE.AdminMenu.BansList:Clear()

        for id, ban in pairs(MODULE.ClientBans) do
            local timeStr = os.date("%Y-%m-%d %H:%M:%S", ban.timestamp)
            local expiresStr = ban.expires > 0 and os.date("%Y-%m-%d %H:%M:%S", ban.expires) or "Never"

            local line = MODULE.AdminMenu.BansList:AddLine(
                ban.name,
                ban.adminName,
                ban.reason,
                timeStr,
                expiresStr
            )
            line.ban = ban
        end
    end
end)