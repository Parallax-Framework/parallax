--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

if ( IsValid(ax.gui.admin) ) then
    ax.gui.admin:Remove()
end

if ( IsValid(ax.gui.adminContext) ) then
    ax.gui.adminContext:Remove()
end

-- Create admin menu
function MODULE:CreateAdminMenu()
    if ( IsValid(ax.gui.admin) ) then
        ax.gui.admin:Remove()
    end

    adminMenu = vgui.Create("DFrame")
    adminMenu:SetSize(800, 600)
    adminMenu:Center()
    adminMenu:SetTitle("Admin Menu")
    adminMenu:SetDeleteOnClose(true)
    adminMenu:SetDraggable(true)
    adminMenu:SetScreenLock(true)
    adminMenu:SetBackgroundBlur(true)
    adminMenu:MakePopup()

    -- Create tab panel
    local tabPanel = vgui.Create("DPropertySheet", adminMenu)
    tabPanel:Dock(FILL)

    -- Players tab
    local playersPanel = vgui.Create("DPanel")
    playersPanel:Dock(FILL)

    local playersList = vgui.Create("DListView", playersPanel)
    playersList:SetPos(10, 10)
    playersList:SetSize(350, 550)
    playersList:SetMultiSelect(false)
    playersList:AddColumn("Name")
    playersList:AddColumn("Group")
    playersList:AddColumn("SteamID")

    -- Populate players list
    for _, client in player.Iterator() do
        local line = playersList:AddLine(client:SteamName(), client:GetUserGroup(), client:SteamID())
        line.client = client
    end

    -- Player actions panel
    local actionsPanel = vgui.Create("DPanel", playersPanel)
    actionsPanel:SetPos(370, 10)
    actionsPanel:SetSize(400, 550)
    actionsPanel.Paint = function(this, width, height)
        surface.SetDrawColor(50, 50, 50, 200)
        surface.DrawRect(0, 0, width, height)
    end

    local selectedPlayer = nil

    -- Player selection handler
    playersList.OnRowSelected = function(lst, index, pnl)
        selectedPlayer = pnl.client

        -- Clear previous buttons
        for _, child in pairs(actionsPanel:GetChildren()) do
            child:Remove()
        end

        if ( !IsValid(selectedPlayer) ) then return end

        -- Create action buttons
        local y = 10
        local buttonHeight = 25
        local buttonSpacing = 5

        local function CreateButton(text, permission, callback)
            if ( !CAMI.PlayerHasAccess(ax.client, permission, nil) ) then
                return
            end

            local btn = vgui.Create("DButton", actionsPanel)
            btn:SetPos(10, y)
            btn:SetSize(380, buttonHeight)
            btn:SetText(text)
            btn.DoClick = callback

            y = y + buttonHeight + buttonSpacing

            return btn
        end

        -- Player info
        local infoLabel = vgui.Create("DLabel", actionsPanel)
        infoLabel:SetPos(10, y)
        infoLabel:SetSize(380, 60)
        infoLabel:SetText("Selected: " .. selectedPlayer:SteamName() .. "\nGroup: " .. selectedPlayer:GetUserGroup() .. "\nSteamID: " .. selectedPlayer:SteamID())
        infoLabel:SetWrap(true)
        infoLabel:SetAutoStretchVertical(true)
        y = y + 70

        -- Action buttons
        CreateButton("Kick", "Parallax - Kick Players", function()
            Derma_StringRequest("Kick Player", "Enter reason:", "No reason provided", function(text)
                ax.command:Run("PlyKick", selectedPlayer:UserID(), text)
            end)
        end)

        CreateButton("Ban", "Parallax - Ban Players", function()
            local reasonFrame = vgui.Create("DFrame")
            reasonFrame:SetSize(400, 200)
            reasonFrame:Center()
            reasonFrame:SetTitle("Ban Player")
            reasonFrame:MakePopup()

            local reasonEntry = vgui.Create("DTextEntry", reasonFrame)
            reasonEntry:SetPos(10, 30)
            reasonEntry:SetSize(380, 25)
            reasonEntry:SetPlaceholderText("Enter reason...")

            local durationEntry = vgui.Create("DNumSlider", reasonFrame)
            durationEntry:SetPos(10, 60)
            durationEntry:SetSize(380, 25)
            durationEntry:SetText("Duration (minutes, 0 = permanent)")
            durationEntry:SetMin(0)
            durationEntry:SetMax(10080)
            durationEntry:SetDecimals(0)

            local banBtn = vgui.Create("DButton", reasonFrame)
            banBtn:SetPos(10, 120)
            banBtn:SetSize(380, 30)
            banBtn:SetText("Ban Player")
            banBtn.DoClick = function()
                local reason = reasonEntry:GetValue()
                local duration = durationEntry:GetValue()
                ax.command:Run("PlyBan", selectedPlayer:UserID(), duration, reason)
                reasonFrame:Close()
            end

            local cancelBtn = vgui.Create("DButton", reasonFrame)
            cancelBtn:SetPos(10, 155)
            cancelBtn:SetSize(380, 30)
            cancelBtn:SetText("Cancel")
            cancelBtn.DoClick = function()
                reasonFrame:Close()
            end
        end)

        CreateButton("Goto", "Parallax - Teleport", function()
            ax.command:Run("PlyGoto", selectedPlayer:UserID())
        end)

        CreateButton("Bring", "Parallax - Bring Players", function()
            ax.command:Run("PlyBring", selectedPlayer:UserID())
        end)

        CreateButton("Freeze / Unfreeze", "Parallax - Freeze Players", function()
            ax.command:Run("PlyFreeze", selectedPlayer:UserID())
        end)

        CreateButton("Slay", "Parallax - Slay Players", function()
            ax.command:Run("PlySlay", selectedPlayer:UserID())
        end)

        CreateButton("Respawn", "Parallax - Respawn Players", function()
            ax.command:Run("PlyRespawn", selectedPlayer:UserID())
        end)
    end

    tabPanel:AddSheet("Players", playersPanel, "icon16/user.png")

    -- Server tab
    local serverPanel = vgui.Create("DPanel")
    serverPanel:Dock(FILL)

    local serverY = 10
    local function CreateServerButton(text, permission, callback)
        if ( !CAMI.PlayerHasAccess(ax.client, permission, nil) ) then
            return
        end

        local btn = vgui.Create("DButton", serverPanel)
        btn:SetPos(10, serverY)
        btn:SetSize(200, 30)
        btn:SetText(text)
        btn.DoClick = callback

        serverY = serverY + 35

        return btn
    end

    CreateServerButton("Cleanup Map", "Parallax - Cleanup", function()
        Derma_Query("Are you sure you want to cleanup the map?", "Cleanup Map", "Yes", function()
            Derma_StringRequest("Cleanup Map", "Enter reason for cleanup:", "No reason provided", function(text)
                ax.command:Run("CleanupMap", text)
            end)
        end, "No", function() end)
    end)

    CreateServerButton("Change Map", "Parallax - Map Control", function()
        Derma_StringRequest("Change Map", "Enter map name:", "", function(text)
            Derma_StringRequest("Change Map Reason", "Enter reason for changing the map:", "No reason provided", function(reason)
                ax.command:Run("ChangeMap", text, reason)
            end, function() end)
        end)
    end)

    CreateServerButton("View Logs", "Parallax - View Logs", function()
        ax.command:Run("ViewLogs", "20")
    end)

    tabPanel:AddSheet("Server", serverPanel, "icon16/server.png")

    -- Logs tab
    local logsPanel = vgui.Create("DPanel")
    logsPanel:Dock(FILL)

    local logsList = vgui.Create("DListView", logsPanel)
    logsList:Dock(FILL)
    logsList:SetMultiSelect(false)
    logsList:AddColumn("Time")
    logsList:AddColumn("Admin")
    logsList:AddColumn("Action")
    logsList:AddColumn("Target")
    logsList:AddColumn("Reason")

    -- Populate logs (this would need to be networked from server)
    -- For now, just show example
    logsList:AddLine("12:34:56", "Admin", "kicked", "Player", "Rule violation")

    tabPanel:AddSheet("Logs", logsPanel, "icon16/script.png")

    ax.gui.admin = adminMenu
end

-- Open admin menu command
concommand.Add("ax_admin_menu", function()
    if ( !CAMI.PlayerHasAccess(ax.client, "Parallax - Admin Menu", nil) ) then
        ax.notification:Send(ax.client, "You don't have permission to access the admin menu.")
        return
    end

    MODULE:CreateAdminMenu()
end)