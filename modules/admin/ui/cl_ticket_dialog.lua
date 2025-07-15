--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:ShowCreateTicketDialog()
    local createDialog = vgui.Create("DFrame")
    createDialog:SetSize(400, 300)
    createDialog:Center()
    createDialog:SetTitle("Create Ticket")
    createDialog:MakePopup()

    local titleLabel = vgui.Create("DLabel", createDialog)
    titleLabel:SetPos(10, 30)
    titleLabel:SetSize(380, 20)
    titleLabel:SetText("Title:")

    local titleEntry = vgui.Create("DTextEntry", createDialog)
    titleEntry:SetPos(10, 50)
    titleEntry:SetSize(380, 25)
    titleEntry:SetPlaceholderText("Enter ticket title...")

    local descLabel = vgui.Create("DLabel", createDialog)
    descLabel:SetPos(10, 85)
    descLabel:SetSize(380, 20)
    descLabel:SetText("Description:")

    local descEntry = vgui.Create("DTextEntry", createDialog)
    descEntry:SetPos(10, 105)
    descEntry:SetSize(380, 120)
    descEntry:SetMultiline(true)
    descEntry:SetPlaceholderText("Enter detailed description...")

    local submitButton = vgui.Create("DButton", createDialog)
    submitButton:SetPos(10, 235)
    submitButton:SetSize(185, 30)
    submitButton:SetText("Create Ticket")
    submitButton.DoClick = function()
        local title = titleEntry:GetValue()
        local description = descEntry:GetValue()

        if (title == "" or description == "") then
            ax.notification:Send(ax.client, "Title and description cannot be empty.")
            return
        end

        net.Start("ax.admin.ticket.create")
            net.WriteString(title)
            net.WriteString(description)
        net.SendToServer()

        createDialog:Close()
    end

    local cancelButton = vgui.Create("DButton", createDialog)
    cancelButton:SetPos(205, 235)
    cancelButton:SetSize(185, 30)
    cancelButton:SetText("Cancel")
    cancelButton.DoClick = function()
        createDialog:Close()
    end
end