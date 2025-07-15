--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:CreateTicketMenu()
    if (!ax.config:Get("admin.tickets.enabled", true)) then
        ax.notification:Send(ax.client, "Ticket system is disabled.")
        return
    end

    if (IsValid(ax.gui.tickets)) then
        ax.gui.tickets:Remove()
    end

    local ticketMenu = vgui.Create("DFrame")
    ticketMenu:SetSize(800, 600)
    ticketMenu:Center()
    ticketMenu:SetTitle("Ticket System")
    ticketMenu:SetDeleteOnClose(true)
    ticketMenu:SetDraggable(true)
    ticketMenu:SetScreenLock(true)
    ticketMenu:SetBackgroundBlur(true)
    ticketMenu:MakePopup()

    -- Request ticket list
    net.Start("ax.admin.ticket.list")
    net.SendToServer()

    -- Create main panel
    local mainPanel = vgui.Create("DPanel", ticketMenu)
    mainPanel:Dock(FILL)
    mainPanel:DockMargin(5, 5, 5, 5)

    -- Create ticket button
    local createButton = vgui.Create("DButton", mainPanel)
    createButton:SetText("Create New Ticket")
    createButton:SetSize(150, 30)
    createButton:SetPos(10, 10)
    createButton.DoClick = function()
        MODULE:ShowCreateTicketDialog()
    end

    -- Tickets list
    local ticketsList = vgui.Create("DListView", mainPanel)
    ticketsList:SetPos(10, 50)
    ticketsList:SetSize(375, 500)
    ticketsList:SetMultiSelect(false)
    ticketsList:AddColumn("ID")
    ticketsList:AddColumn("Title")
    ticketsList:AddColumn("Status")
    ticketsList:AddColumn("Created")

    -- Ticket details panel
    local detailsPanel = vgui.Create("DPanel", mainPanel)
    detailsPanel:SetPos(395, 50)
    detailsPanel:SetSize(375, 500)
    detailsPanel.Paint = function(this, width, height)
        surface.SetDrawColor(50, 50, 50, 200)
        surface.DrawRect(0, 0, width, height)
    end

    -- Ticket selection handler
    ticketsList.OnRowSelected = function(lst, index, pnl)
        local ticket = pnl.ticket
        if (!ticket) then return end

        MODULE:ShowTicketDetails(detailsPanel, ticket)
    end

    -- Refresh function
    ticketMenu.RefreshTickets = function()
        ticketsList:Clear()
        detailsPanel:Clear()

        for id, ticket in pairs(MODULE.ClientTickets) do
            local timeStr = os.date("%m/%d %H:%M", ticket.timestamp)
            local line = ticketsList:AddLine(ticket.id, ticket.title, ticket.status, timeStr)
            line.ticket = ticket

            -- Color code by status
            line.Paint = function(this, width, height)
                local color = ax.color:Get("white")
                if ( ticket.status == "open" ) then
                    color = this:IsLineSelected() and ax.color:Get("green.dark") or ax.color:Get("green.soft")
                elseif ( ticket.status == "claimed" ) then
                    color = this:IsLineSelected() and ax.color:Get("yellow.dark") or ax.color:Get("yellow.soft")
                elseif ( ticket.status == "closed" ) then
                    color = this:IsLineSelected() and ax.color:Get("red.dark") or ax.color:Get("red.soft")
                end

                surface.SetDrawColor(color)
                surface.DrawRect(0, 0, width, height)
            end

            ticketsList:SortByColumn(4, true)

            if ( ticket.id == MODULE.SelectedTicketID ) then
                MODULE:ShowTicketDetails(detailsPanel, ticket)
            end
        end
    end

    ticketMenu.RefreshTickets()

    ax.gui.tickets = ticketMenu
    MODULE.TicketMenu = ticketMenu
end

if ( IsValid(ax.gui.tickets) ) then
    ax.gui.tickets:Remove()
end

concommand.Add("ax_ticket_menu", function()
    MODULE:CreateTicketMenu()
end)