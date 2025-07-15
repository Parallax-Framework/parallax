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
MODULE.ClientGroups = MODULE.ClientGroups or {}
MODULE.ClientBans = MODULE.ClientBans or {}
MODULE.ClientLogs = MODULE.ClientLogs or {}

-- Ticket system client data
MODULE.ClientTickets = MODULE.ClientTickets or {}
MODULE.ClientTicketComments = MODULE.ClientTicketComments or {}

-- Client-side usergroup data
MODULE.ClientTempUsergroups = MODULE.ClientTempUsergroups or {}

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

    if (steamid == "" and group == "") then
        -- Full group data update
        MODULE.ClientGroups = net.ReadTable()

        -- Update usergroups panel if open
        if (IsValid(MODULE.AdminMenu)) then
            local usergroupsPanel = nil
            for _, child in pairs(MODULE.AdminMenu:GetChildren()) do
                if (child:GetName() == "DPropertySheet") then
                    for _, sheet in pairs(child:GetItems()) do
                        if (sheet.Name == "Usergroups") then
                            usergroupsPanel = sheet.Panel
                            break
                        end
                    end
                    break
                end
            end

            if (IsValid(usergroupsPanel) and usergroupsPanel.RefreshGroupsList) then
                usergroupsPanel:RefreshGroupsList()
                usergroupsPanel:RefreshPlayersList()
            end
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

-- Receive ticket updates
net.Receive("ax.admin.ticket.update", function()
    local tickets = net.ReadTable()
    local comments = net.ReadTable()

    MODULE.ClientTickets = tickets
    MODULE.ClientTicketComments = comments

    -- Update ticket UI if open
    if (IsValid(ax.gui.tickets)) then
        ax.gui.tickets:RefreshTickets()
    end

    -- Update admin menu if open
    if (IsValid(ax.gui.admin) and ax.gui.admin.ticketsList) then
        ax.gui.admin:RefreshTickets()
    end
end)

-- Receive ticket notifications
net.Receive("ax.admin.ticket.notification", function()
    local type = net.ReadString()
    local ticketID = net.ReadUInt(32)
    local playerName = net.ReadString()
    local message = net.ReadString()

    if (type == "new") then
        ax.notification:Send(ax.client, "New ticket created by " .. playerName .. ": " .. message)
        surface.PlaySound("buttons/button15.wav")
    elseif (type == "comment") then
        ax.notification:Send(ax.client, playerName .. " commented on ticket #" .. ticketID)
        surface.PlaySound("buttons/button17.wav")
    elseif (type == "claimed") then
        ax.notification:Send(ax.client, "Your ticket #" .. ticketID .. " was claimed by " .. playerName)
        surface.PlaySound("buttons/button14.wav")
    elseif (type == "closed") then
        ax.notification:Send(ax.client, "Ticket #" .. ticketID .. " was closed by " .. playerName)
        surface.PlaySound("buttons/button18.wav")
    end
end)