--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:ShowUsergroupPanel(panel)
    panel:Clear()

    -- Title
    local titleLabel = vgui.Create("DLabel", panel)
    titleLabel:SetPos(10, 10)
    titleLabel:SetSize(300, 20)
    titleLabel:SetText("Usergroup Management")
    titleLabel:SetFont("DermaDefaultBold")

    -- Usergroup list
    local groupsList = vgui.Create("DListView", panel)
    groupsList:SetPos(10, 40)
    groupsList:SetSize(350, 200)
    groupsList:SetMultiSelect(false)
    groupsList:AddColumn("Name")
    groupsList:AddColumn("Inherits")
    groupsList:AddColumn("Level")
    groupsList:AddColumn("Immunity")

    -- Populate usergroups
    local function RefreshGroupsList()
        groupsList:Clear()
        for name, group in pairs(MODULE.ClientGroups) do
            local line = groupsList:AddLine(name, group.Inherits or "user", group.Level or 0, group.Immunity or 0)
            line.groupName = name
            line.groupData = group

            -- Color custom groups differently
            if (group.Custom) then
                line.Paint = function(this, width, height)
                    surface.SetDrawColor(this:IsLineSelected() and ax.color:Get("blue.dark") or ax.color:Get("blue.soft"))
                    surface.DrawRect(0, 0, width, height)
                end
            end
        end
    end

    RefreshGroupsList()

    -- Create Group button
    local createButton = vgui.Create("DButton", panel)
    createButton:SetPos(10, 250)
    createButton:SetSize(80, 25)
    createButton:SetText("Create")
    createButton.DoClick = function()
        MODULE:ShowCreateGroupDialog()
    end

    -- Edit Group button
    local editButton = vgui.Create("DButton", panel)
    editButton:SetPos(100, 250)
    editButton:SetSize(80, 25)
    editButton:SetText("Edit")
    editButton.DoClick = function()
        local selected = groupsList:GetSelectedLine()
        if (selected) then
            MODULE:ShowEditGroupDialog(selected.groupName, selected.groupData)
        else
            ax.notification:Send(ax.client, "Please select a usergroup to edit.")
        end
    end

    -- Delete Group button
    local deleteButton = vgui.Create("DButton", panel)
    deleteButton:SetPos(190, 250)
    deleteButton:SetSize(80, 25)
    deleteButton:SetText("Delete")
    deleteButton.DoClick = function()
        local selected = groupsList:GetSelectedLine()
        if (selected and selected.groupData.Custom) then
            Derma_Query("Are you sure you want to delete the usergroup '" .. selected.groupName .. "'?", "Delete Usergroup", "Yes", function()
                net.Start("ax.admin.usergroup.delete")
                    net.WriteString(selected.groupName)
                net.SendToServer()
            end, "No", function() end)
        else
            ax.notification:Send(ax.client, "Please select a custom usergroup to delete.")
        end
    end

    -- Player usergroup management
    local playerLabel = vgui.Create("DLabel", panel)
    playerLabel:SetPos(10, 290)
    playerLabel:SetSize(300, 20)
    playerLabel:SetText("Player Usergroup Management")
    playerLabel:SetFont("DermaDefaultBold")

    -- Player list
    local playersList = vgui.Create("DListView", panel)
    playersList:SetPos(10, 320)
    playersList:SetSize(350, 150)
    playersList:SetMultiSelect(false)
    playersList:AddColumn("Name")
    playersList:AddColumn("Current Group")
    playersList:AddColumn("Temp Group")

    -- Populate players
    local function RefreshPlayersList()
        playersList:Clear()
        for _, ply in player.Iterator() do
            local tempInfo = ""
            local tempData = MODULE.ClientTempUsergroups and MODULE.ClientTempUsergroups[ply:SteamID64()]
            if (tempData) then
                local remaining = tempData.expires - os.time()
                if (remaining > 0) then
                    tempInfo = "(" .. string.FormattedTime(remaining) .. ")"
                end
            end

            local line = playersList:AddLine(ply:SteamName(), ply:GetUserGroup(), tempInfo)
            line.player = ply
        end
    end

    RefreshPlayersList()

    -- Set Group button
    local setGroupButton = vgui.Create("DButton", panel)
    setGroupButton:SetPos(10, 480)
    setGroupButton:SetSize(100, 25)
    setGroupButton:SetText("Set Group")
    setGroupButton.DoClick = function()
        local _, selected = playersList:GetSelectedLine()
        if (selected and selected.player) then
            MODULE:ShowSetGroupDialog(selected.player)
        else
            ax.notification:Send(ax.client, "Please select a player.")
        end
    end

    -- Refresh button
    local refreshButton = vgui.Create("DButton", panel)
    refreshButton:SetPos(120, 480)
    refreshButton:SetSize(80, 25)
    refreshButton:SetText("Refresh")
    refreshButton.DoClick = function()
        RefreshGroupsList()
        RefreshPlayersList()
    end

    -- Store refresh functions for external updates
    panel.RefreshGroupsList = RefreshGroupsList
    panel.RefreshPlayersList = RefreshPlayersList
end