--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:ShowTicketDetails(panel, ticket)
    if (!IsValid(panel)) then return end

    print("Showing details for ticket ID:", ticket.id)

    self.SelectedTicketID = ticket.id

    -- Clear previous content
    for _, child in pairs(panel:GetChildren()) do
        child:Remove()
    end

    -- Store reference to current ticket
    if (IsValid(MODULE.TicketMenu)) then
        MODULE.TicketMenu.currentTicketID = ticket.id
    end

    -- Ticket info
    local titleLabel = vgui.Create("DLabel", panel)
    titleLabel:SetPos(10, 10)
    titleLabel:SetSize(355, 20)
    titleLabel:SetText("Title: " .. ticket.title)
    titleLabel:SetFont("DermaDefaultBold")

    local statusLabel = vgui.Create("DLabel", panel)
    statusLabel:SetPos(10, 35)
    statusLabel:SetSize(355, 20)
    statusLabel:SetText("Status: " .. ticket.status .. (ticket.claimerName and " (by " .. ticket.claimerName .. ")" or ""))

    local creatorLabel = vgui.Create("DLabel", panel)
    creatorLabel:SetPos(10, 60)
    creatorLabel:SetSize(355, 20)
    creatorLabel:SetText("Creator: " .. ticket.creatorName)

    local timeLabel = vgui.Create("DLabel", panel)
    timeLabel:SetPos(10, 85)
    timeLabel:SetSize(355, 20)
    timeLabel:SetText("Created: " .. os.date("%Y-%m-%d %H:%M:%S", ticket.timestamp))

    -- Description
    local descLabel = vgui.Create("DLabel", panel)
    descLabel:SetPos(10, 110)
    descLabel:SetSize(355, 20)
    descLabel:SetText("Description:")
    descLabel:SetFont("DermaDefaultBold")

    local descText = vgui.Create("DLabel", panel)
    descText:SetPos(10, 135)
    descText:SetSize(355, 60)
    descText:SetText(ticket.description)
    descText:SetWrap(true)
    descText:SetAutoStretchVertical(true)

    -- Comments section
    local commentsLabel = vgui.Create("DLabel", panel)
    commentsLabel:SetPos(10, 200)
    commentsLabel:SetSize(355, 20)
    commentsLabel:SetText("Comments:")
    commentsLabel:SetFont("DermaDefaultBold")

    local commentsList = vgui.Create("DListView", panel)
    commentsList:SetPos(10, 225)
    commentsList:SetSize(355, 120)
    commentsList:SetMultiSelect(false)
    commentsList:AddColumn("Author")
    commentsList:AddColumn("Message")
    commentsList:AddColumn("Time")
    commentsList:SetSortable(true)

    -- Populate comments
    local comments = MODULE.ClientTicketComments[ticket.id] or {}
    for _, comment in pairs(comments) do
        local timeStr = os.date("%m/%d %H:%M:%S", comment.timestamp)
        local line = commentsList:AddLine(comment.authorName, comment.message, timeStr)

        if ( comment.isAdmin ) then
            line.Paint = function(this, width, height)
                surface.SetDrawColor(this:IsLineSelected() and ax.color:Get("maroon.dark") or ax.color:Get("maroon.soft"))
                surface.DrawRect(0, 0, width, height)
            end
        end
    end

    commentsList:SortByColumn(3, true)

    -- Comment input
    local commentEntry = vgui.Create("DTextEntry", panel)
    commentEntry:SetPos(10, 355)
    commentEntry:SetSize(270, 25)
    commentEntry:SetPlaceholderText("Enter comment...")

    local commentButton = vgui.Create("DButton", panel)
    commentButton:SetPos(285, 355)
    commentButton:SetSize(80, 25)
    commentButton:SetText("Comment")
    commentButton.DoClick = function()
        local message = commentEntry:GetValue()
        if (message == "") then
            ax.notification:Send(ax.client, "Comment cannot be empty.")
            return
        end

        net.Start("ax.admin.ticket.comment")
            net.WriteUInt(ticket.id, 32)
            net.WriteString(message)
        net.SendToServer()

        commentEntry:SetValue("")
    end

    -- Store reference to comment entry for live updates
    if (IsValid(MODULE.TicketMenu)) then
        MODULE.TicketMenu.currentCommentEntry = commentEntry
    end

    -- Handle enter key for comment submission
    commentEntry.OnEnter = function()
        commentButton:DoClick()
    end

    -- Action buttons
    local isAdmin = CAMI.PlayerHasAccess(ax.client, "Parallax - Admin Menu", nil)
    local isCreator = ticket.creator == ax.client:SteamID64()
    local creator = player.GetBySteamID64(ticket.creator)

    local buttonY = 390
    local buttonSpacing = 5
    local buttonsPerRow = 5
    local currentButton = 0
    local buttonWidth = panel:GetWide() / buttonsPerRow - (buttonsPerRow - 1) * (buttonSpacing * 2) / buttonsPerRow
    local buttonHeight = 25

    local function CreateActionButton(text, permission, callback)
        if (!CAMI.PlayerHasAccess(ax.client, permission, nil)) then
            return
        end

        local x = 10 + (currentButton % buttonsPerRow) * (buttonWidth + buttonSpacing)
        local y = buttonY + math.floor(currentButton / buttonsPerRow) * (buttonHeight + buttonSpacing)

        local btn = vgui.Create("DButton", panel)
        btn:SetPos(x, y)
        btn:SetSize(buttonWidth, buttonHeight)
        btn:SetText(text)
        btn.DoClick = callback

        currentButton = currentButton + 1
        return btn
    end

    -- Ticket management buttons
    if (isAdmin and ticket.status == "open") then
        CreateActionButton("Claim", "Parallax - Admin Menu", function()
            net.Start("ax.admin.ticket.claim")
                net.WriteUInt(ticket.id, 32)
            net.SendToServer()
        end)
    end

    if ((isAdmin or isCreator) and ticket.status != "closed") then
        CreateActionButton("Close", "Parallax - Admin Menu", function()
            Derma_Query("Are you sure you want to close this ticket?", "Close Ticket", "Yes", function()
                net.Start("ax.admin.ticket.close")
                    net.WriteUInt(ticket.id, 32)
                net.SendToServer()
            end, "No", function() end)
        end)
    end

    -- Player action buttons (only for admins and if creator is online)
    if (isAdmin and IsValid(creator)) then
        CreateActionButton("Goto", "Parallax - Teleport", function()
            ax.command:Run("PlyGoto", creator:UserID())
        end)

        CreateActionButton("Bring", "Parallax - Bring Players", function()
            ax.command:Run("PlyBring", creator:UserID())
        end)

        CreateActionButton("Return", "Parallax - Teleport", function()
            ax.command:Run("PlyReturn", creator:UserID())
        end)

        CreateActionButton("Spectate", "Parallax - Spectate", function()
            ax.command:Run("PlySpectate", creator:UserID())
        end)

        CreateActionButton("Freeze", "Parallax - Freeze Players", function()
            ax.command:Run("PlyFreeze", creator:UserID())
        end)

        CreateActionButton("Heal", "Parallax - Admin Menu", function()
            Derma_StringRequest("Heal Player", "How much health do you want to give " .. creator:SteamName() .. "?", "25", function(health)
                ax.command:Run("PlyHeal", creator:UserID(), tonumber(health) or 25)
            end, "Cancel", function() end)
        end)

        CreateActionButton("Strip", "Parallax - Strip Weapons", function()
            Derma_Query("Are you sure you want to strip all weapons from " .. creator:SteamName() .. "?", "Strip Weapons", "Yes", function()
                ax.command:Run("PlyStrip", creator:UserID())
            end, "No", function() end)
        end)

        CreateActionButton("Slay", "Parallax - Slay Players", function()
            Derma_Query("Are you sure you want to slay " .. creator:SteamName() .. "?", "Slay Player", "Yes", function()
                ax.command:Run("PlySlay", creator:UserID())
            end, "No", function() end)
        end)

        CreateActionButton("Respawn", "Parallax - Respawn Players", function()
            ax.command:Run("PlyRespawn", creator:UserID())
        end)

        CreateActionButton("Kick", "Parallax - Kick Players", function()
            Derma_StringRequest("Kick Player", "Enter reason:", "Ticket #" .. ticket.id, function(reason)
                ax.command:Run("PlyKick", creator:UserID(), reason)
            end)
        end)

        CreateActionButton("Ban", "Parallax - Ban Players", function()
            local banFrame = vgui.Create("DFrame")
            banFrame:SetSize(300, 150)
            banFrame:Center()
            banFrame:SetTitle("Ban Player")
            banFrame:MakePopup()

            local reasonEntry = vgui.Create("DTextEntry", banFrame)
            reasonEntry:SetPos(10, 30)
            reasonEntry:SetSize(280, 25)
            reasonEntry:SetValue("Ticket #" .. ticket.id)

            local durationSlider = vgui.Create("DNumSlider", banFrame)
            durationSlider:SetPos(10, 60)
            durationSlider:SetSize(280, 25)
            durationSlider:SetText("Duration (minutes)")
            durationSlider:SetMin(0)
            durationSlider:SetMax(10080)
            durationSlider:SetValue(0)

            local banBtn = vgui.Create("DButton", banFrame)
            banBtn:SetPos(10, 100)
            banBtn:SetSize(135, 25)
            banBtn:SetText("Ban")
            banBtn.DoClick = function()
                local reason = reasonEntry:GetValue()
                local duration = durationSlider:GetValue()
                ax.command:Run("PlyBan", creator:UserID(), duration, reason)
                banFrame:Close()
            end

            local cancelBtn = vgui.Create("DButton", banFrame)
            cancelBtn:SetPos(155, 100)
            cancelBtn:SetSize(135, 25)
            cancelBtn:SetText("Cancel")
            cancelBtn.DoClick = function()
                banFrame:Close()
            end
        end)

        -- Admin utility buttons
        CreateActionButton("Noclip", "Parallax - Noclip", function()
            ax.command:Run("ToggleNoclip", creator:UserID())
        end)

        CreateActionButton("God", "Parallax - Godmode", function()
            ax.command:Run("ToggleGodmode", creator:UserID())
        end)
    elseif (isAdmin and !IsValid(creator)) then
        -- Show offline player info
        local offlineLabel = vgui.Create("DLabel", panel)
        offlineLabel:SetPos(10, buttonY)
        offlineLabel:SetSize(355, 20)
        offlineLabel:SetText("Player is offline - Limited actions available")
        offlineLabel:SetTextColor(ax.color:Get("orange"))

        -- Only show ban option for offline players
        CreateActionButton("Ban", "Parallax - Ban Offline", function()
            local banFrame = vgui.Create("DFrame")
            banFrame:SetSize(300, 150)
            banFrame:Center()
            banFrame:SetTitle("Ban Offline Player")
            banFrame:MakePopup()

            local reasonEntry = vgui.Create("DTextEntry", banFrame)
            reasonEntry:SetPos(10, 30)
            reasonEntry:SetSize(280, 25)
            reasonEntry:SetValue("Ticket #" .. ticket.id)

            local durationSlider = vgui.Create("DNumSlider", banFrame)
            durationSlider:SetPos(10, 60)
            durationSlider:SetSize(280, 25)
            durationSlider:SetText("Duration (minutes)")
            durationSlider:SetMin(0)
            durationSlider:SetMax(10080)
            durationSlider:SetValue(0)

            local banBtn = vgui.Create("DButton", banFrame)
            banBtn:SetPos(10, 100)
            banBtn:SetSize(135, 25)
            banBtn:SetText("Ban")
            banBtn.DoClick = function()
                local reason = reasonEntry:GetValue()
                local duration = durationSlider:GetValue()

                -- Create offline ban
                local banData = {
                    steamid = ticket.creator,
                    name = ticket.creatorName,
                    admin = ax.client:SteamID64(),
                    adminName = ax.client:SteamName(),
                    reason = reason,
                    timestamp = os.time(),
                    duration = duration,
                    expires = duration > 0 and (os.time() + duration * 60) or 0
                }

                net.Start("ax.admin.ban.offline")
                    net.WriteTable(banData)
                net.SendToServer()

                banFrame:Close()
            end

            local cancelBtn = vgui.Create("DButton", banFrame)
            cancelBtn:SetPos(155, 100)
            cancelBtn:SetSize(135, 25)
            cancelBtn:SetText("Cancel")
            cancelBtn.DoClick = function()
                banFrame:Close()
            end
        end)
    end
end