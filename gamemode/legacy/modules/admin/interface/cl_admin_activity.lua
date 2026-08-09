--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

local function SafeNumber(value, fallback)
    local number = tonumber(value)
    if ( number == nil ) then
        return fallback or 0
    end

    return number
end

local function FormatDuration(seconds)
    seconds = math.max(0, math.floor(SafeNumber(seconds, 0)))

    if ( seconds < 60 ) then
        return tostring(seconds) .. "s"
    end

    local days = math.floor(seconds / 86400)
    seconds = seconds % 86400

    local hours = math.floor(seconds / 3600)
    seconds = seconds % 3600

    local minutes = math.floor(seconds / 60)

    local parts = {}
    if ( days > 0 ) then
        parts[#parts + 1] = tostring(days) .. "d"
    end

    if ( hours > 0 ) then
        parts[#parts + 1] = tostring(hours) .. "h"
    end

    if ( minutes > 0 ) then
        parts[#parts + 1] = tostring(minutes) .. "m"
    end

    if ( #parts < 1 ) then
        return "<1m"
    end

    return table.concat(parts, " ")
end

local function FormatTimestamp(unix)
    local timeNumber = math.floor(SafeNumber(unix, 0))
    if ( timeNumber <= 0 ) then
        return "Never"
    end

    return os.date("%Y-%m-%d %H:%M:%S", timeNumber)
end

local function FormatPing(ping)
    local value = math.max(0, math.Round(SafeNumber(ping, 0)))
    return tostring(value) .. " ms"
end

local function FormatJoinHour(hour)
    if ( hour == nil ) then
        return "N/A"
    end

    local value = SafeNumber(hour, -1)
    if ( value < 0 ) then
        return "N/A"
    end

    local totalMinutes = math.floor(value * 60)
    local wrappedMinutes = ((totalMinutes % 1440) + 1440) % 1440
    local h = math.floor(wrappedMinutes / 60)
    local m = wrappedMinutes % 60

    return ax.util:PadNumber(h, 2) .. ":" .. ax.util:PadNumber(m, 2)
end

local function HasOnlineActions(data)
    return istable(data) and data.is_online == true
end

local function IsValidPayload(payload)
    return istable(payload)
end

function PANEL:Init()
    ax.gui.admin_activity = self

    self:Dock(FILL)
    self:InvalidateParent(true)

    self.page = 1
    self.pageSize = 20
    self.pageCount = 1
    self.totalRows = 0
    self.searchQuery = ""

    self.rows = {}

    self.selectedSteamID64 = nil
    self.selectedSummary = nil
    self.selectedDetail = nil

    self.listNonce = 0
    self.detailNonce = 0

    self.requestingList = false
    self.requestingDetail = false

    self.pendingSearch = false
    self.pendingSearchAt = 0
    self.ignoreSearchCallback = false

    self:BuildToolbar()
    self:BuildMainPanels()
    self:RequestList()
end

function PANEL:BuildToolbar()
    self.toolbar = self:Add("EditablePanel")
    self.toolbar:Dock(TOP)
    self.toolbar:SetTall(ax.util:ScreenScaleH(22))
    self.toolbar:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
    self.toolbar.Paint = nil

    self.statusLabel = self.toolbar:Add("ax.text")
    self.statusLabel:Dock(FILL)
    self.statusLabel:SetFont("ax.small")
    self.statusLabel:SetText("Loading activity...", true)
    self.statusLabel:SetContentAlignment(4)

    self.controls = self:Add("EditablePanel")
    self.controls:Dock(TOP)
    self.controls:SetTall(ax.util:ScreenScaleH(26))
    self.controls:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
    self.controls.Paint = nil

    self.refreshButton = self.controls:Add("ax.button")
    self.refreshButton:Dock(RIGHT)
    self.refreshButton:DockMargin(ax.util:ScreenScale(4), 0, 0, 0)
    self.refreshButton:SetWide(ax.util:ScreenScale(56))
    self.refreshButton:SetText("Refresh", true)
    self.refreshButton.DoClick = function()
        self:RequestList()
    end

    self.searchEntry = self.controls:Add("ax.text.entry")
    self.searchEntry:Dock(FILL)
    self.searchEntry:SetPlaceholderText("Search by name, SteamID64, or usergroup...")
    self.searchEntry.OnValueChange = function(entry, value)
        if ( self.ignoreSearchCallback ) then return end

        self.searchQuery = string.Trim(value or entry:GetValue() or "")
        self.page = 1
        self.pendingSearch = true
        self.pendingSearchAt = CurTime() + 0.30
    end
    self.searchEntry.OnEnter = function(entry)
        if ( self.ignoreSearchCallback ) then return end

        self.searchQuery = string.Trim(entry:GetValue() or "")
        self.page = 1
        self.pendingSearch = false
        self:RequestList()
    end

    self.controls:SetTall(math.max(self.refreshButton:GetTall(), self.searchEntry:GetTall()))

    self.pagination = self:Add("EditablePanel")
    self.pagination:Dock(TOP)
    self.pagination:SetTall(ax.util:ScreenScaleH(22))
    self.pagination:DockMargin(0, 0, 0, ax.util:ScreenScaleH(6))
    self.pagination.Paint = nil

    self.pagePrev = self.pagination:Add("ax.button")
    self.pagePrev:Dock(LEFT)
    self.pagePrev:SetWide(ax.util:ScreenScale(24))
    self.pagePrev:SetText("<", true)
    self.pagePrev.DoClick = function()
        if ( self.page <= 1 ) then return end
        self.page = self.page - 1
        self:RequestList()
    end

    self.pageNext = self.pagination:Add("ax.button")
    self.pageNext:Dock(RIGHT)
    self.pageNext:SetWide(ax.util:ScreenScale(24))
    self.pageNext:SetText(">", true)
    self.pageNext.DoClick = function()
        if ( self.page >= self.pageCount ) then return end
        self.page = self.page + 1
        self:RequestList()
    end

    self.pageCounter = self.pagination:Add("ax.text")
    self.pageCounter:Dock(FILL)
    self.pageCounter:SetFont("ax.small")
    self.pageCounter:SetContentAlignment(5)
    self.pageCounter:SetText("Page 1 / 1", true)
end

function PANEL:BuildMainPanels()
    self.content = self:Add("EditablePanel")
    self.content:Dock(FILL)
    self.content.Paint = nil

    self.listPanel = self.content:Add("EditablePanel")
    self.listPanel:Dock(LEFT)
    self.listPanel:SetWide(ax.util:ScreenScale(220))
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
    self.listTitle:SetText("Players", true)
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

function PANEL:PerformLayout(width, height)
    local minWidth = ax.util:ScreenScale(180)
    local maxWidth = math.max(minWidth, width - ax.util:ScreenScale(220))
    local wantedWidth = math.Clamp(math.floor(width * 0.46), minWidth, maxWidth)

    if ( IsValid(self.listPanel) ) then
        self.listPanel:SetWide(wantedWidth)
    end
end

function PANEL:Think()
    if ( self.pendingSearch and CurTime() >= self.pendingSearchAt ) then
        self.pendingSearch = false
        self:RequestList()
    end
end

function PANEL:UpdateStatus()
    if ( !IsValid(self.statusLabel) ) then return end

    local text
    if ( self.requestingList ) then
        text = "Loading player activity..."
    elseif ( self.totalRows <= 0 ) then
        if ( self.searchQuery != "" ) then
            text = "No players matched \"" .. self.searchQuery .. "\"."
        else
            text = "No players found in activity database."
        end
    else
        text = "Showing " .. tostring(#self.rows) .. " of " .. tostring(self.totalRows) .. " players"
        if ( self.searchQuery != "" ) then
            text = text .. " for \"" .. self.searchQuery .. "\""
        end
    end

    self.statusLabel:SetText(text, true)
end

function PANEL:UpdatePagingState()
    if ( IsValid(self.pageCounter) ) then
        self.pageCounter:SetText("Page " .. tostring(self.page) .. " / " .. tostring(self.pageCount), true)
    end

    if ( IsValid(self.pagePrev) ) then
        self.pagePrev:SetEnabled(self.page > 1)
    end

    if ( IsValid(self.pageNext) ) then
        self.pageNext:SetEnabled(self.page < self.pageCount)
    end
end

function PANEL:RequestList()
    self.listNonce = self.listNonce + 1
    self.requestingList = true
    self:UpdateStatus()
    self:UpdatePagingState()

    ax.net:Start("admin.activity.request_list", {
        nonce = self.listNonce,
        page = self.page,
        page_size = self.pageSize,
        search = self.searchQuery
    })
end

function PANEL:RequestDetail(steamID64)
    if ( !steamID64 or steamID64 == "" ) then return end

    self.detailNonce = self.detailNonce + 1
    self.requestingDetail = true
    self.selectedDetail = nil
    self:RebuildDetail()

    ax.net:Start("admin.activity.request_detail", {
        nonce = self.detailNonce,
        steamid64 = steamID64,
        search = self.searchQuery
    })
end

function PANEL:SelectSummary(summary)
    if ( !istable(summary) ) then return end
    if ( !summary.steamid64 ) then return end

    local changed = self.selectedSteamID64 != summary.steamid64
    self.selectedSteamID64 = summary.steamid64
    self.selectedSummary = summary

    if ( changed ) then
        self:RequestDetail(summary.steamid64)
    else
        self:RebuildDetail()
    end

    self:RebuildList()
end

function PANEL:RunAdminCommand(command, steamID64)
    if ( !isstring(command) or command == "" ) then return end

    local cmd = "/" .. string.Trim(command)
    if ( isstring(steamID64) and steamID64 != "" ) then
        cmd = cmd .. " " .. steamID64
    end

    ax.command:Send(cmd)
end

function PANEL:AddSectionTitle(text)
    local title = self.detailScroll:Add("ax.text")
    title:Dock(TOP)
    title:DockMargin(0, ax.util:ScreenScaleH(4), 0, ax.util:ScreenScaleH(2))
    title:SetFont("ax.regular.bold")
    title:SetText(text, true)
    title:SetContentAlignment(4)
end

function PANEL:AddDetailRow(label, value)
    local row = self.detailScroll:Add("EditablePanel")
    row:Dock(TOP)

    local left = row:Add("ax.text")
    left:Dock(LEFT)
    left:SetFont("ax.small")
    left:SetText(label .. ":", true)
    left:SetContentAlignment(4)

    local right = row:Add("ax.text")
    right:Dock(FILL)
    right:SetFont("ax.small")
    right:SetText(tostring(value), true)
    right:SetContentAlignment(6)

    row:SetTall(math.max(left:GetTall(), right:GetTall()))
end

function PANEL:AddActionButton(text, callback, enabled)
    local button = self.detailScroll:Add("ax.button")
    button:Dock(TOP)
    button:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
    button:SetTextInset(ax.util:ScreenScale(4), 0)
    button:SetText(text, true)
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

    if ( self.rows[1] == nil ) then
        local noResults = self.listScroll:Add("ax.text")
        noResults:Dock(TOP)
        noResults:DockMargin(ax.util:ScreenScale(8), ax.util:ScreenScaleH(8), ax.util:ScreenScale(8), 0)
        noResults:SetFont("ax.regular.italic")
        noResults:SetText("No players to display.", true)
        noResults:SetContentAlignment(4)
        return
    end

    local panel = self
    for i = 1, #self.rows do
        local rowData = self.rows[i]

        local row = self.listScroll:Add("EditablePanel")
        row:Dock(TOP)
        row:SetTall(ax.util:ScreenScaleH(32))
        row:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
        row:SetMouseInputEnabled(true)
        row:SetCursor("hand")
        row.data = rowData

        row.Paint = function(this, width, height)
            local glass = ax.theme:GetGlass()
            local fill = glass.button

            if ( this.data and this.data.steamid64 == self.selectedSteamID64 ) then
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
        end

        function row:OnMousePressed(code)
            if ( code != MOUSE_LEFT ) then return end
            panel:SelectSummary(self.data)
        end

        local title = row:Add("ax.text")
        title:Dock(TOP)
        title:DockMargin(ax.util:ScreenScale(4), ax.util:ScreenScaleH(4), ax.util:ScreenScale(4), 0)
        title:SetFont("ax.regular.bold")
        title:SetText((rowData.name or "Unknown") .. "  (#" .. tostring(rowData.rank_global or "?") .. ")", true)
        title:SetContentAlignment(4)

        local status = row:Add("ax.text")
        status:Dock(FILL)
        status:DockMargin(ax.util:ScreenScale(4), 0, ax.util:ScreenScale(4), ax.util:ScreenScaleH(2))
        status:SetFont("ax.small")

        local state = rowData.is_online and "ONLINE" or "OFFLINE"
        local pingText = rowData.is_online and FormatPing(rowData.current_ping) or ("avg " .. FormatPing(rowData.average_ping))
        status:SetText(state .. " | " .. FormatDuration(rowData.total_playtime) .. " | " .. pingText, true)
        status:SetContentAlignment(4)
    end
end

function PANEL:RebuildDetail()
    if ( !IsValid(self.detailScroll) ) then return end

    self.detailScroll:Clear()

    if ( !self.selectedSteamID64 ) then
        local info = self.detailScroll:Add("ax.text")
        info:Dock(TOP)
        info:DockMargin(ax.util:ScreenScale(4), ax.util:ScreenScaleH(6), 0, 0)
        info:SetFont("ax.regular.italic")
        info:SetText("Select a player to view activity details.", true)
        info:SetContentAlignment(4)
        return
    end

    local detail = self.selectedDetail or self.selectedSummary
    if ( !istable(detail) ) then
        return
    end

    local name = detail.name or "Unknown"
    local steamID64 = detail.steamid64 or "Unknown"
    local online = HasOnlineActions(detail)

    local header = self.detailScroll:Add("ax.text")
    header:Dock(TOP)
    header:DockMargin(0, 0, 0, ax.util:ScreenScaleH(2))
    header:SetFont("ax.regular.bold")
    header:SetText(name, true)
    header:SetContentAlignment(4)

    local subHeader = self.detailScroll:Add("ax.text")
    subHeader:Dock(TOP)
    subHeader:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
    subHeader:SetFont("ax.small")
    subHeader:SetText(steamID64, true)
    subHeader:SetContentAlignment(4)

    self:AddSectionTitle("Actions")
    self:AddActionButton("Open Steam Profile", function()
        gui.OpenURL("https://steamcommunity.com/profiles/" .. steamID64)
    end, steamID64 != nil and steamID64 != "")
    self:AddActionButton("Copy SteamID64", function()
        if ( SetClipboardText ) then
            SetClipboardText(steamID64)
        end
    end, steamID64 != nil and steamID64 != "")
    self:AddActionButton("Goto Player", function() self:RunAdminCommand("plygoto", steamID64) end, online)
    self:AddActionButton("Bring Player", function() self:RunAdminCommand("plybring", steamID64) end, online)
    self:AddActionButton("Return Player", function() self:RunAdminCommand("plyreturn", steamID64) end, online)
    self:AddActionButton("Freeze / Unfreeze", function() self:RunAdminCommand("plyfreeze", steamID64) end, online)
    self:AddActionButton("Respawn Player", function() self:RunAdminCommand("plyrespawn", steamID64) end, online)
    self:AddActionButton("Slay Player", function() self:RunAdminCommand("plyslay", steamID64) end, online)

    self:AddSectionTitle("Details")
    self:AddDetailRow("Status", online and "Online" or "Offline")
    self:AddDetailRow("Usergroup", detail.usergroup or "user")
    self:AddDetailRow("Global Rank", "#" .. tostring(detail.rank_global or 0))
    if ( SafeNumber(detail.rank_filtered, 0) > 0 ) then
        self:AddDetailRow("Filtered Rank", "#" .. tostring(detail.rank_filtered))
    end
    self:AddDetailRow("Last Join", FormatTimestamp(detail.last_join))
    self:AddDetailRow("Last Leave", FormatTimestamp(detail.last_leave))

    self:AddSectionTitle("Activity")
    self:AddDetailRow("Total Playtime", FormatDuration(detail.total_playtime))
    self:AddDetailRow("Current Session", online and FormatDuration(detail.session_playtime) or "Offline")
    self:AddDetailRow("Total Sessions", tostring(math.floor(SafeNumber(detail.total_sessions, 0))))
    self:AddDetailRow("Average Ping", FormatPing(detail.average_ping))
    self:AddDetailRow("Current Ping", online and FormatPing(detail.current_ping) or "N/A")
    self:AddDetailRow("Average Join Time", FormatJoinHour(detail.average_join_hour))
    self:AddDetailRow("Average Rejoin Delay", detail.average_join_interval and FormatDuration(detail.average_join_interval) or "N/A")

    if ( self.requestingDetail and !istable(self.selectedDetail) ) then
        local loading = self.detailScroll:Add("ax.text")
        loading:Dock(TOP)
        loading:DockMargin(0, ax.util:ScreenScaleH(6), 0, 0)
        loading:SetFont("ax.small.italic")
        loading:SetText("Loading detailed metrics...", true)
        loading:SetContentAlignment(4)
    end
end

function PANEL:HandleListPayload(payload)
    if ( !IsValidPayload(payload) ) then return end
    if ( SafeNumber(payload.nonce, 0) != self.listNonce ) then
        return
    end

    self.requestingList = false
    self.page = math.max(1, math.floor(SafeNumber(payload.page, self.page)))
    self.pageCount = math.max(1, math.floor(SafeNumber(payload.page_count, self.pageCount)))
    self.totalRows = math.max(0, math.floor(SafeNumber(payload.total_rows, self.totalRows)))
    self.rows = istable(payload.rows) and payload.rows or {}

    local selectedFound = nil
    if ( self.selectedSteamID64 ) then
        for i = 1, #self.rows do
            if ( self.rows[i].steamid64 == self.selectedSteamID64 ) then
                selectedFound = self.rows[i]
                break
            end
        end
    end

    if ( selectedFound ) then
        self.selectedSummary = selectedFound
    elseif ( self.selectedSteamID64 ) then
        self.selectedSteamID64 = nil
        self.selectedSummary = nil
        self.selectedDetail = nil
    elseif ( self.rows[1] ) then
        self.selectedSteamID64 = self.rows[1].steamid64
        self.selectedSummary = self.rows[1]
        self:RequestDetail(self.selectedSteamID64)
    end

    self:UpdateStatus()
    self:UpdatePagingState()
    self:RebuildList()
    self:RebuildDetail()
end

function PANEL:HandleDetailPayload(payload)
    if ( !IsValidPayload(payload) ) then return end
    if ( SafeNumber(payload.nonce, 0) != self.detailNonce ) then
        return
    end

    self.requestingDetail = false

    local detail = payload.player
    if ( !istable(detail) ) then
        self.selectedDetail = nil
        self:RebuildDetail()
        return
    end

    if ( !self.selectedSteamID64 or detail.steamid64 != self.selectedSteamID64 ) then
        return
    end

    self.selectedDetail = detail
    self:RebuildDetail()
end

function PANEL:HandleErrorPayload(payload)
    if ( !IsValidPayload(payload) ) then return end

    local message = tostring(payload.message or "Unknown admin activity error.")
    self.requestingList = false
    self.requestingDetail = false
    self:UpdateStatus()
    if ( IsValid(self.statusLabel) ) then
        self.statusLabel:SetText(message, true)
    end
    self:RebuildDetail()

    if ( ax.util and ax.util.PrintError ) then
        ax.util:PrintError("[admin.activity] " .. message)
    end
end

function PANEL:OnRemove()
    if ( ax.gui.admin_activity == self ) then
        ax.gui.admin_activity = nil
    end
end

vgui.Register("ax.tab.admin.activity", PANEL, "EditablePanel")

ax.net:Hook("admin.activity.list", function(payload)
    if ( !IsValid(ax.gui.admin_activity) ) then return end
    ax.gui.admin_activity:HandleListPayload(payload)
end)

ax.net:Hook("admin.activity.detail", function(payload)
    if ( !IsValid(ax.gui.admin_activity) ) then return end
    ax.gui.admin_activity:HandleDetailPayload(payload)
end)

ax.net:Hook("admin.activity.error", function(payload)
    if ( !IsValid(ax.gui.admin_activity) ) then return end
    ax.gui.admin_activity:HandleErrorPayload(payload)
end)
