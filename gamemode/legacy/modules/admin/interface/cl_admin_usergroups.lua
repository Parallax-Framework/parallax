--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

local DEFAULT_USERGROUP_COLOR = Color(170, 170, 170)

local function GetUsergroupColor(usergroup)
    if ( istable(usergroup) and IsColor(usergroup.color) ) then
        return usergroup.color
    end

    return DEFAULT_USERGROUP_COLOR
end

local function NotifyClient(message, notificationType)
    message = tostring(message or "")
    if ( message == "" ) then return end

    local client = ax.client
    if ( ax.util:IsValidPlayer(client) ) then
        client:Notify(message, notificationType)
        return
    end

    ax.util:Print(message)
end

function PANEL:Init()
    ax.gui.admin_usergroups = self

    self:Dock(FILL)
    self:InvalidateParent(true)

    self.usergroups = {}
    self.players = {}
    self.selectedUsergroup = nil

    self:BuildToolbar()
    self:BuildMainPanels()
    self:RefreshData()
end

function PANEL:BuildToolbar()
    self.toolbar = self:Add("EditablePanel")
    self.toolbar:Dock(TOP)
    self.toolbar:SetTall(ax.util:ScreenScaleH(26))
    self.toolbar:DockMargin(0, 0, 0, ax.util:ScreenScaleH(6))
    self.toolbar.Paint = nil

    self.refreshButton = self.toolbar:Add("ax.button")
    self.refreshButton:Dock(RIGHT)
    self.refreshButton:DockMargin(ax.util:ScreenScale(4), 0, 0, 0)
    self.refreshButton:SetWide(ax.util:ScreenScale(56))
    self.refreshButton:SetText("Refresh", true)
    self.refreshButton.DoClick = function()
        self:RefreshData()
    end

    self.manageButton = self.toolbar:Add("ax.button")
    self.manageButton:Dock(RIGHT)
    self.manageButton:DockMargin(ax.util:ScreenScale(4), 0, 0, 0)
    self.manageButton:SetWide(ax.util:ScreenScale(96))
    self.manageButton:SetText("Set Usergroup", true)
    self.manageButton.DoClick = function()
        self:PromptSetUsergroup()
    end

    self.statusLabel = self.toolbar:Add("ax.text")
    self.statusLabel:Dock(FILL)
    self.statusLabel:SetFont("ax.small")
    self.statusLabel:SetText("Loading usergroups...", true)
    self.statusLabel:SetContentAlignment(4)

    self.toolbar:SetTall(math.max(self.refreshButton:GetTall(), self.statusLabel:GetTall()))
end

function PANEL:BuildMainPanels()
    self.content = self:Add("EditablePanel")
    self.content:Dock(FILL)
    self.content.Paint = nil

    self.listPanel = self.content:Add("EditablePanel")
    self.listPanel:Dock(LEFT)
    self.listPanel:SetWide(ax.util:ScreenScale(260))
    self.listPanel:DockMargin(0, 0, ax.util:ScreenScale(6), 0)
    self.listPanel.Paint = function(this, width, height)
        ax.theme:DrawGlassPanel(0, 0, width, height, {
            radius = 8,
            blur = 0.7,
            flags = ax.render.SHAPE_IOS
        })
    end

    self.listTitle = self.listPanel:Add("ax.text")
    self.listTitle:Dock(TOP)
    self.listTitle:DockMargin(ax.util:ScreenScale(8), ax.util:ScreenScaleH(6), ax.util:ScreenScale(8), ax.util:ScreenScaleH(2))
    self.listTitle:SetFont("ax.regular.bold")
    self.listTitle:SetText("Usergroups", true)
    self.listTitle:SetContentAlignment(4)

    self.listScroll = self.listPanel:Add("DScrollPanel")
    self.listScroll:Dock(FILL)
    self.listScroll:DockMargin(ax.util:ScreenScale(6), 0, ax.util:ScreenScale(6), ax.util:ScreenScaleH(6))
    self.listScroll:GetVBar():SetWide(0)

    self.detailPanel = self.content:Add("EditablePanel")
    self.detailPanel:Dock(FILL)
    self.detailPanel.Paint = function(this, width, height)
        ax.theme:DrawGlassPanel(0, 0, width, height, {
            radius = 8,
            blur = 0.7,
            flags = ax.render.SHAPE_IOS
        })
    end

    self.detailScroll = self.detailPanel:Add("DScrollPanel")
    self.detailScroll:Dock(FILL)
    self.detailScroll:DockMargin(ax.util:ScreenScale(8), ax.util:ScreenScaleH(6), ax.util:ScreenScale(8), ax.util:ScreenScaleH(6))
    self.detailScroll:GetVBar():SetWide(0)
end

function PANEL:PerformLayout(width)
    local minWidth = ax.util:ScreenScale(220)
    local maxWidth = math.max(minWidth, width - ax.util:ScreenScale(240))
    local wantedWidth = math.Clamp(math.floor(width * 0.42), minWidth, maxWidth)

    if ( IsValid(self.listPanel) ) then
        self.listPanel:SetWide(wantedWidth)
    end
end

function PANEL:RefreshData()
    self.usergroups = ax.admin:GetSortedUsergroups()
    self.players = player.GetAll()

    if ( !self.selectedUsergroup and self.usergroups[1] ) then
        self.selectedUsergroup = self.usergroups[1].uniqueID
    elseif ( self.selectedUsergroup and !ax.admin:GetUsergroup(self.selectedUsergroup) ) then
        self.selectedUsergroup = self.usergroups[1] and self.usergroups[1].uniqueID or nil
    end

    self:UpdateStatus()
    self:RebuildList()
    self:RebuildDetail()
end

function PANEL:UpdateStatus()
    if ( !IsValid(self.statusLabel) ) then return end

    local groupCount = #self.usergroups
    local playerCount = #self.players
    local text = "Showing " .. tostring(groupCount) .. " usergroups and " .. tostring(playerCount) .. " online players."
    self.statusLabel:SetText(text, true)
end

function PANEL:SelectUsergroup(uniqueID)
    if ( !isstring(uniqueID) or uniqueID == "" ) then return end

    self.selectedUsergroup = uniqueID
    self:RebuildList()
    self:RebuildDetail()
end

function PANEL:GetPlayersInUsergroup(uniqueID)
    local players = {}

    for i = 1, #self.players do
        local client = self.players[i]
        if ( ax.util:IsValidPlayer(client) and ax.admin:GetPlayerUsergroup(client) == uniqueID ) then
            players[#players + 1] = client
        end
    end

    table.sort(players, function(a, b)
        return a:SteamName() < b:SteamName()
    end)

    return players
end

function PANEL:RunAdminCommand(command)
    command = string.Trim(tostring(command or ""))
    if ( command == "" ) then return end

    ax.command:Send("/" .. command)
end

function PANEL:PromptSetUsergroup()
    Derma_StringRequest("Set Usergroup", "Enter a SteamID64 or SteamID:", "", function(identifier)
        if ( !IsValid(self) ) then return end

        identifier = string.Trim(tostring(identifier or ""))
        if ( identifier == "" ) then
            NotifyClient("Please enter a valid SteamID64 or SteamID.", "error")
            return
        end

        local defaultGroup = self.selectedUsergroup or "user"
        Derma_StringRequest("Set Usergroup", "Enter the target usergroup:", defaultGroup, function(usergroup)
            if ( !IsValid(self) ) then return end

            usergroup = string.Trim(tostring(usergroup or ""))
            if ( usergroup == "" ) then
                NotifyClient("Please enter a valid usergroup.", "error")
                return
            end

            self:RunAdminCommand("PlySetUsergroupID " .. identifier .. " " .. usergroup)
            timer.Simple(0.25, function()
                if ( IsValid(self) ) then
                    self:RefreshData()
                end
            end)
        end)
    end)
end

function PANEL:AddSectionTitle(text)
    local title = self.detailScroll:Add("ax.text")
    title:Dock(TOP)
    title:DockMargin(0, ax.util:ScreenScaleH(4), 0, ax.util:ScreenScaleH(2))
    title:SetFont("ax.regular.bold")
    title:SetText(tostring(text or ""), true)
    title:SetContentAlignment(4)
end

function PANEL:AddDetailRow(label, value)
    local row = self.detailScroll:Add("EditablePanel")
    row:Dock(TOP)

    local left = row:Add("ax.text")
    left:Dock(LEFT)
    left:SetWide(ax.util:ScreenScale(112))
    left:SetFont("ax.small")
    left:SetText(tostring(label or "") .. ":", true)
    left:SetContentAlignment(4)

    local right = row:Add("ax.text")
    right:Dock(FILL)
    right:SetFont("ax.small")
    right:SetText(tostring(value or ""), true)
    right:SetContentAlignment(6)

    row:SetTall(math.max(left:GetTall(), right:GetTall()))
end

function PANEL:AddActionButton(text, callback, enabled)
    local button = self.detailScroll:Add("ax.button")
    button:Dock(TOP)
    button:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
    button:SetTextInset(ax.util:ScreenScale(4), 0)
    button:SetText(tostring(text or ""), true)
    button:SetFont("ax.small")
    button:SetFontDefault("ax.small")
    button:SetFontHovered("ax.small")
    button:SetContentAlignment(4)
    button:SetEnabled(enabled != false)
    button.DoClick = function()
        if ( enabled == false ) then return end

        if ( isfunction(callback) ) then
            callback()
        end
    end
end

function PANEL:RebuildList()
    if ( !IsValid(self.listScroll) ) then return end

    self.listScroll:Clear()

    if ( self.usergroups[1] == nil ) then
        local noResults = self.listScroll:Add("ax.text")
        noResults:Dock(TOP)
        noResults:DockMargin(ax.util:ScreenScale(8), ax.util:ScreenScaleH(8), ax.util:ScreenScale(8), 0)
        noResults:SetFont("ax.regular.italic")
        noResults:SetText("No usergroups registered.", true)
        noResults:SetContentAlignment(4)
        return
    end

    local panel = self
    for i = 1, #self.usergroups do
        local usergroup = self.usergroups[i]
        local uniqueID = tostring(usergroup.uniqueID or "")
        local onlineCount = #self:GetPlayersInUsergroup(uniqueID)

        local row = self.listScroll:Add("EditablePanel")
        row:Dock(TOP)
        row:SetTall(ax.util:ScreenScaleH(42))
        row:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
        row:SetMouseInputEnabled(true)
        row:SetCursor("hand")
        row.usergroup = usergroup

        row.Paint = function(this, width, height)
            local glass = ax.theme:GetGlass()
            local fill = glass.button

            if ( this.usergroup and this.usergroup.uniqueID == panel.selectedUsergroup ) then
                fill = glass.buttonActive
            elseif ( this:IsHovered() ) then
                fill = glass.buttonHover
            end

            ax.theme:DrawGlassPanel(0, 0, width, height, {
                radius = 8,
                blur = 0.5,
                fill = fill,
                flags = ax.render.SHAPE_IOS
            })

            surface.SetDrawColor(GetUsergroupColor(this.usergroup))
            surface.DrawRect(0, 0, math.max(2, ax.util:ScreenScale(2)), height)
        end

        function row:OnMousePressed(code)
            if ( code != MOUSE_LEFT ) then return end
            panel:SelectUsergroup(self.usergroup.uniqueID)
        end

        local title = row:Add("ax.text")
        title:Dock(TOP)
        title:DockMargin(ax.util:ScreenScale(6), ax.util:ScreenScaleH(4), ax.util:ScreenScale(6), 0)
        title:SetFont("ax.regular.bold")
        title:SetText(tostring(usergroup.name or uniqueID) .. "  (" .. uniqueID .. ")", true)
        title:SetContentAlignment(4)

        local meta = row:Add("ax.text")
        meta:Dock(FILL)
        meta:DockMargin(ax.util:ScreenScale(6), 0, ax.util:ScreenScale(6), ax.util:ScreenScaleH(2))
        meta:SetFont("ax.small")
        meta:SetText("Level " .. tostring(usergroup.level or 0) .. " | Immunity " .. tostring(usergroup.immunity or usergroup.level or 0) .. " | Online " .. tostring(onlineCount), true)
        meta:SetContentAlignment(4)
    end
end

function PANEL:RebuildDetail()
    if ( !IsValid(self.detailScroll) ) then return end

    self.detailScroll:Clear()

    local usergroup = self.selectedUsergroup and ax.admin:GetUsergroup(self.selectedUsergroup) or nil
    if ( !istable(usergroup) ) then
        local info = self.detailScroll:Add("ax.text")
        info:Dock(TOP)
        info:DockMargin(ax.util:ScreenScale(4), ax.util:ScreenScaleH(6), 0, 0)
        info:SetFont("ax.regular.italic")
        info:SetText("Select a usergroup to inspect details.", true)
        info:SetContentAlignment(4)
        return
    end

    local uniqueID = tostring(usergroup.uniqueID or self.selectedUsergroup)
    local playersInGroup = self:GetPlayersInUsergroup(uniqueID)

    local header = self.detailScroll:Add("ax.text")
    header:Dock(TOP)
    header:DockMargin(0, 0, 0, ax.util:ScreenScaleH(2))
    header:SetFont("ax.regular.bold")
    header:SetText(tostring(usergroup.name or uniqueID), true)
    header:SetContentAlignment(4)

    local subHeader = self.detailScroll:Add("ax.text")
    subHeader:Dock(TOP)
    subHeader:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
    subHeader:SetFont("ax.small")
    subHeader:SetText(uniqueID, true)
    subHeader:SetContentAlignment(4)

    self:AddSectionTitle("Actions")
    self:AddActionButton("Set Player Usergroup", function()
        self:PromptSetUsergroup()
    end, true)
    self:AddActionButton("Copy Usergroup ID", function()
        if ( SetClipboardText ) then
            SetClipboardText(uniqueID)
        end
    end, uniqueID != "")
    self:AddActionButton("Print Usergroup Info", function()
        self:RunAdminCommand("UsergroupInfo " .. uniqueID)
    end, uniqueID != "")

    self:AddSectionTitle("Details")
    self:AddDetailRow("Name", usergroup.name or uniqueID)
    self:AddDetailRow("Description", usergroup.description != "" and usergroup.description or "No description.")
    self:AddDetailRow("Level", usergroup.level or 0)
    self:AddDetailRow("Immunity", usergroup.immunity or usergroup.level or 0)
    self:AddDetailRow("Inherits", usergroup.inherits or "none")
    self:AddDetailRow("Protected", usergroup.bProtected and "Yes" or "No")
    self:AddDetailRow("Hidden", usergroup.bHidden and "Yes" or "No")
    self:AddDetailRow("Default", usergroup.bDefault and "Yes" or "No")
    self:AddDetailRow("Online Players", #playersInGroup)

    self:AddSectionTitle("Online Members")
    if ( playersInGroup[1] == nil ) then
        local empty = self.detailScroll:Add("ax.text")
        empty:Dock(TOP)
        empty:SetFont("ax.small.italic")
        empty:SetText("No online players are currently assigned to this usergroup.", true)
        empty:SetContentAlignment(4)
        return
    end

    for i = 1, #playersInGroup do
        local client = playersInGroup[i]
        local steamID64 = client:SteamID64()

        local member = self.detailScroll:Add("ax.button")
        member:Dock(TOP)
        member:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
        member:SetTextInset(ax.util:ScreenScale(4), 0)
        member:SetText(client:SteamName() .. "  (" .. steamID64 .. ")", true)
        member:SetFont("ax.small")
        member:SetFontDefault("ax.small")
        member:SetFontHovered("ax.small")
        member:SetContentAlignment(4)
        member.DoClick = function()
            if ( SetClipboardText ) then
                SetClipboardText(steamID64)
                NotifyClient("Copied " .. client:SteamName() .. "'s SteamID64.", "success")
            end
        end
    end
end

function PANEL:OnRemove()
    if ( ax.gui.admin_usergroups == self ) then
        ax.gui.admin_usergroups = nil
    end
end

vgui.Register("ax.tab.admin.usergroups", PANEL, "EditablePanel")
