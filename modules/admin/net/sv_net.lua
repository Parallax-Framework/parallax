--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

-- Network strings for admin system
util.AddNetworkString("ax.admin.logs.request")
util.AddNetworkString("ax.admin.logs.response")
util.AddNetworkString("ax.admin.group.update")
util.AddNetworkString("ax.admin.ban.update")
util.AddNetworkString("ax.admin.ban.offline")

-- Ticket system network strings
util.AddNetworkString("ax.admin.ticket.create")
util.AddNetworkString("ax.admin.ticket.comment")
util.AddNetworkString("ax.admin.ticket.claim")
util.AddNetworkString("ax.admin.ticket.close")
util.AddNetworkString("ax.admin.ticket.update")
util.AddNetworkString("ax.admin.ticket.list")
util.AddNetworkString("ax.admin.ticket.notification")
util.AddNetworkString("ax.admin.ticket.live_update")

-- Network strings for usergroup management
util.AddNetworkString("ax.admin.usergroup.create")
util.AddNetworkString("ax.admin.usergroup.edit")
util.AddNetworkString("ax.admin.usergroup.delete")
util.AddNetworkString("ax.admin.usergroup.set")
util.AddNetworkString("ax.admin.usergroup.list")
util.AddNetworkString("ax.admin.usergroup.update")

-- Handle admin logs request
net.Receive("ax.admin.logs.request", function(len, client)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - View Logs", nil) ) then
        return
    end

    local count = net.ReadUInt(8)
    local filter = net.ReadTable()

    local logs = MODULE:GetLogs(filter)
    local startIndex = math.max(1, #logs - count + 1)
    local sendLogs = {}

    for i = startIndex, #logs do
       sendLogs[#sendLogs + 1] = logs[i]
    end

    net.Start("ax.admin.logs.response")
        net.WriteTable(sendLogs, true)
    net.Send(client)
end)

-- Handle ticket creation
net.Receive("ax.admin.ticket.create", function(len, client)
    if (!ax.config:Get("admin.tickets.enabled", true)) then return end

    local title = net.ReadString()
    local description = net.ReadString()

    -- Validate input
    if (title == "" or description == "") then
        ax.notification:Send(client, "Title and description cannot be empty.")
        return
    end

    -- Check if player has reached ticket limit
    local playerTickets = MODULE:GetPlayerTickets(client)
    local maxTickets = ax.config:Get("admin.tickets.maxPerPlayer", 3)

    if (#playerTickets >= maxTickets) then
        ax.notification:Send(client, "You have reached the maximum number of tickets (" .. maxTickets .. ").")
        return
    end

    -- Create ticket
    local ticketID = MODULE:CreateTicket(client, title, description)

    -- Notify admins
    for _, admin in player.Iterator() do
        if (CAMI.PlayerHasAccess(admin, "Parallax - Admin Menu", nil)) then
            net.Start("ax.admin.ticket.notification")
                net.WriteString("new")
                net.WriteUInt(ticketID, 32)
                net.WriteString(client:SteamName())
                net.WriteString(title)
            net.Send(admin)
        end
    end

    ax.notification:Send(client, "Ticket created successfully! ID: " .. ticketID)
end)

-- Handle ticket comments
net.Receive("ax.admin.ticket.comment", function(len, client)
    local ticketID = net.ReadUInt(32)
    local message = net.ReadString()

    if (message == "") then
        ax.notification:Send(client, "Comment cannot be empty.")
        return
    end

    local ticket = MODULE.Tickets[ticketID]
    if (!ticket) then
        ax.notification:Send(client, "Ticket not found.")
        return
    end

    -- Check permissions
    local isAdmin = CAMI.PlayerHasAccess(client, "Parallax - Admin Menu", nil)
    local isCreator = ticket.creator == client:SteamID64()

    if (!isAdmin and !isCreator) then
        ax.notification:Send(client, "You don't have permission to comment on this ticket.")
        return
    end

    -- Add comment
    MODULE:AddTicketComment(ticketID, client, message)

    -- Notify relevant parties
    local creator = player.GetBySteamID64(ticket.creator)
    if (IsValid(creator) and creator != client) then
        net.Start("ax.admin.ticket.notification")
            net.WriteString("comment")
            net.WriteUInt(ticket.id, 32)
            net.WriteString(client:SteamName())
            net.WriteString(message)
        net.Send(creator)
    end

    -- Notify claimer if different from commenter
    if (ticket.claimer and ticket.claimer != client:SteamID64()) then
        local claimer = player.GetBySteamID64(ticket.claimer)
        if (IsValid(claimer)) then
            net.Start("ax.admin.ticket.notification")
                net.WriteString("comment")
                net.WriteUInt(ticket.id, 32)
                net.WriteString(client:SteamName())
                net.WriteString(message)
            net.Send(claimer)
        end
    end

    ax.notification:Send(client, "Comment added successfully.")
end)

-- Handle ticket claiming
net.Receive("ax.admin.ticket.claim", function(len, client)
    if (!CAMI.PlayerHasAccess(client, "Parallax - Admin Menu", nil)) then return end

    local ticketID = net.ReadUInt(32)
    local ticket = MODULE.Tickets[ticketID]

    if (!ticket) then
        ax.notification:Send(client, "Ticket not found.")
        return
    end

    if (ticket.status == "claimed" and ticket.claimer != client:SteamID64()) then
        ax.notification:Send(client, "Ticket is already claimed by " .. (ticket.claimerName or "Unknown"))
        return
    end

    -- Claim ticket
    ticket.status = "claimed"
    ticket.claimer = client:SteamID64()
    ticket.claimerName = client:SteamName()
    ticket.lastActivity = os.time()

    MODULE:SaveData()

    net.Start("ax.admin.ticket.update")
        net.WriteTable(MODULE.Tickets)
        net.WriteTable(MODULE.TicketComments)
    net.Send(client)

    -- Notify creator
    local creator = player.GetBySteamID64(ticket.creator)
    if (IsValid(creator)) then
        net.Start("ax.admin.ticket.notification")
            net.WriteString("claimed")
            net.WriteUInt(ticket.id, 32)
            net.WriteString(client:SteamName())
            net.WriteString("")
        net.Send(creator)
    end

    MODULE:LogAction(client, "claimed ticket", nil, "Ticket ID: " .. ticketID)
    ax.notification:Send(client, "Ticket claimed successfully.")
end)

-- Handle ticket closure
net.Receive("ax.admin.ticket.close", function(len, client)
    local ticketID = net.ReadUInt(32)
    local ticket = MODULE.Tickets[ticketID]

    if (!ticket) then
        ax.notification:Send(client, "Ticket not found.")
        return
    end

    -- Check permissions
    local isAdmin = CAMI.PlayerHasAccess(client, "Parallax - Admin Menu", nil)
    local isCreator = ticket.creator == client:SteamID64()

    if (!isAdmin and !isCreator) then
        ax.notification:Send(client, "You don't have permission to close this ticket.")
        return
    end

    -- Close ticket
    ticket.status = "closed"
    ticket.lastActivity = os.time()

    MODULE:SaveData()

    net.Start("ax.admin.ticket.update")
        net.WriteTable(MODULE.Tickets)
        net.WriteTable(MODULE.TicketComments)
    net.Send(client)

    -- Notify relevant parties
    local creator = player.GetBySteamID64(ticket.creator)
    if (IsValid(creator) and creator != client) then
        net.Start("ax.admin.ticket.notification")
            net.WriteString("closed")
            net.WriteUInt(ticket.id, 32)
            net.WriteString(client:SteamName())
            net.WriteString("")
        net.Send(creator)
    end

    if (ticket.claimer and ticket.claimer != client:SteamID64()) then
        local claimer = player.GetBySteamID64(ticket.claimer)
        if (IsValid(claimer)) then
            net.Start("ax.admin.ticket.notification")
                net.WriteString("closed")
                net.WriteUInt(ticket.id, 32)
                net.WriteString(client:SteamName())
                net.WriteString("")
            net.Send(claimer)
        end
    end

    MODULE:LogAction(client, "closed ticket", nil, "Ticket ID: " .. ticketID)
    ax.notification:Send(client, "Ticket closed successfully.")
end)

-- Handle ticket list request
net.Receive("ax.admin.ticket.list", function(len, client)
    local isAdmin = CAMI.PlayerHasAccess(client, "Parallax - Admin Menu", nil)
    local tickets = {}

    for id, ticket in pairs(MODULE.Tickets) do
        if (isAdmin or ticket.creator == client:SteamID64()) then
            tickets[id] = ticket
        end
    end

    net.Start("ax.admin.ticket.update")
        net.WriteTable(tickets)
        net.WriteTable(MODULE.TicketComments)
    net.Send(client)
end)

-- Handle offline ban
net.Receive("ax.admin.ban.offline", function(len, client)
    if (!CAMI.PlayerHasAccess(client, "Parallax - Ban Offline", nil)) then
        return
    end

    local banData = net.ReadTable()

    MODULE.BannedPlayers[banData.steamid] = banData
    MODULE:SaveData()

    MODULE:LogAction(client, "banned (offline)", nil, "Banned " .. banData.name .. " - " .. banData.reason)
    ax.notification:Send(client, "Successfully banned offline player " .. banData.name)

    -- Broadcast ban update to all admins
    for _, admin in player.Iterator() do
        if (CAMI.PlayerHasAccess(admin, "Parallax - Admin Menu", nil)) then
            net.Start("ax.admin.ban.update")
                net.WriteString(banData.steamid)
                net.WriteTable(banData)
            net.Send(admin)
        end
    end
end)

-- Handle usergroup creation
net.Receive("ax.admin.usergroup.create", function(len, client)
    if (!CAMI.PlayerHasAccess(client, "Parallax - Manage Usergroups", nil)) then
        return
    end

    local data = net.ReadTable()

    if (CAMI.GetUsergroup(data.name)) then
        ax.notification:Send(client, "Usergroup '" .. data.name .. "' already exists.")
        return
    end

    if (!CAMI.GetUsergroup(data.inherits)) then
        ax.notification:Send(client, "Inherits group '" .. data.inherits .. "' does not exist.")
        return
    end

    MODULE:CreateUsergroup(data.name, data.inherits, data.level, data.color, data.immunity, client)
    ax.notification:Send(client, "Created usergroup '" .. data.name .. "'.")
end)

-- Handle usergroup editing
net.Receive("ax.admin.usergroup.edit", function(len, client)
    if (!CAMI.PlayerHasAccess(client, "Parallax - Manage Usergroups", nil)) then
        return
    end

    local groupName = net.ReadString()
    local data = net.ReadTable()

    if (MODULE:EditUsergroup(groupName, data, client)) then
        ax.notification:Send(client, "Edited usergroup '" .. groupName .. "'.")
    else
        ax.notification:Send(client, "Failed to edit usergroup '" .. groupName .. "'.")
    end
end)

-- Handle usergroup deletion
net.Receive("ax.admin.usergroup.delete", function(len, client)
    if (!CAMI.PlayerHasAccess(client, "Parallax - Manage Usergroups", nil)) then
        return
    end

    local groupName = net.ReadString()

    if (MODULE:DeleteUsergroup(groupName, client)) then
        ax.notification:Send(client, "Deleted usergroup '" .. groupName .. "'.")
    else
        ax.notification:Send(client, "Failed to delete usergroup '" .. groupName .. "'.")
    end
end)

-- Handle player usergroup setting
net.Receive("ax.admin.usergroup.set", function(len, client)
    if (!CAMI.PlayerHasAccess(client, "Parallax - Manage Usergroups", nil)) then
        return
    end

    local steamID = net.ReadString()
    local groupName = net.ReadString()
    local duration = net.ReadUInt(32)
    local reason = net.ReadString()

    local target = player.GetBySteamID64(steamID)
    if (!IsValid(target)) then
        ax.notification:Send(client, "Player not found.")
        return
    end

    if (!MODULE:CanTarget(client, target)) then
        ax.notification:Send(client, "You cannot target this player.")
        return
    end

    if (!CAMI.GetUsergroup(groupName)) then
        ax.notification:Send(client, "Usergroup '" .. groupName .. "' does not exist.")
        return
    end

    if (!MODULE:CanAssignGroup(client, groupName)) then
        ax.notification:Send(client, "You don't have permission to assign this usergroup.")
        return
    end

    MODULE:SetPlayerUsergroup(target, groupName, duration, reason, client)

    local durationStr = duration > 0 and " for " .. duration .. " minutes" or " permanently"
    ax.notification:Send(client, "Set " .. target:SteamName() .. "'s usergroup to " .. groupName .. durationStr)
end)

-- Handle usergroup list request
net.Receive("ax.admin.usergroup.list", function(len, client)
    if (!CAMI.PlayerHasAccess(client, "Parallax - Admin Menu", nil)) then
        return
    end

    net.Start("ax.admin.group.update")
        net.WriteString("")
        net.WriteString("")
        net.WriteTable(MODULE.Groups)
    net.Send(client)
end)