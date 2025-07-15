--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

--- Creates a new ticket
-- @param client Player - The player creating the ticket
-- @param title string - Ticket title
-- @param description string - Ticket description
-- @return number - Ticket ID
function MODULE:CreateTicket(client, title, description)
    local ticketID = self.NextTicketID
    self.NextTicketID = self.NextTicketID + 1

    self.Tickets[ticketID] = {
        id = ticketID,
        title = title,
        description = description,
        creator = client:SteamID64(),
        creatorName = client:SteamName(),
        status = "open",
        claimer = nil,
        claimerName = nil,
        timestamp = os.time(),
        lastActivity = os.time()
    }

    self.TicketComments[ticketID] = {}

    self:SaveData()
    self:LogAction(client, "created ticket", nil, "Title: " .. title)

    net.Start("ax.admin.ticket.update")
        net.WriteTable(self.Tickets)
        net.WriteTable(self.TicketComments)
    net.Send(client)

    return ticketID
end

--- Adds a comment to a ticket
-- @param ticketID number - Ticket ID
-- @param client Player - The player adding the comment
-- @param message string - Comment message
function MODULE:AddTicketComment(ticketID, client, message)
    if (!self.TicketComments[ticketID]) then
        self.TicketComments[ticketID] = {}
    end

    local comment = {
        author = client:SteamID64(),
        authorName = client:SteamName(),
        message = message,
        timestamp = os.time(),
        isAdmin = CAMI.PlayerHasAccess(client, "Parallax - Admin Menu", nil)
    }

    table.insert(self.TicketComments[ticketID], comment)

    -- Update ticket activity
    if (self.Tickets[ticketID]) then
        self.Tickets[ticketID].lastActivity = os.time()
    end

    self:SaveData()
    self:LogAction(client, "commented on ticket", nil, "Ticket ID: " .. ticketID)

    net.Start("ax.admin.ticket.update")
        net.WriteTable(self.Tickets)
        net.WriteTable(self.TicketComments)
    net.Send(client)
end

--- Gets all tickets for a player
-- @param client Player - The player
-- @return table - Player's tickets
function MODULE:GetPlayerTickets(client)
    local playerTickets = {}

    for id, ticket in pairs(self.Tickets) do
        if (ticket.creator == client:SteamID64() and ticket.status != "closed") then
            table.insert(playerTickets, ticket)
        end
    end

    return playerTickets
end

--- Gets all active tickets
-- @return table - All active tickets
function MODULE:GetActiveTickets()
    local activeTickets = {}

    for id, ticket in pairs(self.Tickets) do
        if (ticket.status != "closed") then
            table.insert(activeTickets, ticket)
        end
    end

    return activeTickets
end

--- Auto-closes inactive tickets
function MODULE:CleanupInactiveTickets()
    local autoCloseHours = ax.config:Get("admin.tickets.autoClose", 24)
    local cutoffTime = os.time() - (autoCloseHours * 3600)

    for id, ticket in pairs(self.Tickets) do
        if (ticket.status != "closed" and ticket.lastActivity < cutoffTime) then
            ticket.status = "closed"
            self:LogAction(nil, "auto-closed ticket", nil, "Ticket ID: " .. id .. " (inactive)")
        end
    end

    self:SaveData()

    net.Start("ax.admin.ticket.update")
        net.WriteTable(self.Tickets)
        net.WriteTable(self.TicketComments)
    net.Send(client)
end