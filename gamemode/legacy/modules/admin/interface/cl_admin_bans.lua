--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

local FILTERS = {
    { id = "active", label = "Active" },
    { id = "permanent", label = "Permanent" },
    { id = "expired", label = "Expired" },
    { id = "revoked", label = "Revoked" },
    { id = "all", label = "All" },
}

local VALID_FILTERS = {}
for i = 1, #FILTERS do
    VALID_FILTERS[FILTERS[i].id] = true
end

local STATUS_COLORS = {
    active = Color(94, 196, 110),
    permanent = Color(203, 109, 255),
    expired = Color(170, 170, 170),
    revoked = Color(226, 124, 96),
    unknown = Color(128, 164, 226),
}

local function SafeNumber(value, fallback)
    local number = tonumber(value)
    if ( number == nil ) then
        return fallback or 0
    end

    return number
end

local function IsValidPayload(payload)
    return istable(payload)
end

local function NormalizeFilter(filterID)
    filterID = tostring(filterID or "active")
    if ( VALID_FILTERS[filterID] ) then
        return filterID
    end

    return "active"
end

local function TruncateText(value, maxLength)
    value = tostring(value or "")
    maxLength = math.max(8, math.floor(SafeNumber(maxLength, 160)))

    if ( #value > maxLength ) then
        return string.sub(value, 1, maxLength - 3) .. "..."
    end

    return value
end

local function FormatTimestamp(unixTime)
    unixTime = math.floor(SafeNumber(unixTime, 0))
    if ( unixTime <= 0 ) then
        return "Never"
    end

    return os.date("%Y-%m-%d %H:%M:%S", unixTime)
end

local function FormatDuration(seconds)
    seconds = math.max(0, math.floor(SafeNumber(seconds, 0)))
    if ( seconds == 0 ) then
        return "Permanent"
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

    if ( #parts == 0 ) then
        return "<1m"
    end

    return table.concat(parts, " ")
end

local function FormatStatus(statusID)
    statusID = tostring(statusID or "unknown")
    return string.upper(statusID)
end

local function GetStatusColor(statusID)
    statusID = tostring(statusID or "unknown")
    return STATUS_COLORS[statusID] or STATUS_COLORS.unknown
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

local function IsBanActive(banData)
    return istable(banData) and banData.is_active == true
end

local function BuildHistoryLine(row)
    if ( !istable(row) ) then
        return "Invalid history row."
    end

    local banID = math.floor(SafeNumber(row.id, 0))
    local status = FormatStatus(row.status)
    local created = FormatTimestamp(row.created_at)
    local expires = SafeNumber(row.expires_at, 0) == 0 and "Never" or FormatTimestamp(row.expires_at)
    local reason = TruncateText(row.reason or "No reason provided.", 96)

    return string.format(
        "#%d [%s] created %s, expires %s, reason: %s",
        banID,
        status,
        created,
        expires,
        reason
    )
end

function PANEL:Init()
    ax.gui.admin_bans = self

    self:Dock(FILL)
    self:InvalidateParent(true)

    self.page = 1
    self.pageSize = 18
    self.pageCount = 1
    self.totalRows = 0
    self.searchQuery = ""
    self.selectedFilter = "active"

    self.stats = {
        total = 0,
        active = 0,
        permanent = 0,
        expired = 0,
        revoked = 0,
    }

    self.rows = {}

    self.selectedBanID = nil
    self.selectedSummary = nil
    self.selectedDetail = nil
    self.pendingSelectBanID = nil

    self.listNonce = 0
    self.detailNonce = 0
    self.actionNonce = 0

    self.requestingList = false
    self.requestingDetail = false

    self.pendingSearch = false
    self.pendingSearchAt = 0
    self.ignoreSearchCallback = false

    self:BuildToolbar()
    self:BuildMainPanels()
    self:UpdateFilterButtons()
    self:UpdateStats()
    self:UpdatePagingState()
    self:UpdateStatus()
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
    self.statusLabel:SetText("Loading ban records...", true)
    self.statusLabel:SetContentAlignment(4)

    self.controls = self:Add("EditablePanel")
    self.controls:Dock(TOP)
    self.controls:SetTall(ax.util:ScreenScaleH(26))
    self.controls:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
    self.controls.Paint = nil

    self.createButton = self.controls:Add("ax.button")
    self.createButton:Dock(RIGHT)
    self.createButton:DockMargin(ax.util:ScreenScale(4), 0, 0, 0)
    self.createButton:SetWide(ax.util:ScreenScale(88))
    self.createButton:SetText("Create Ban", true)
    self.createButton.DoClick = function()
        self:PromptCreateBan()
    end

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
    self.searchEntry:SetPlaceholderText("Search by ID, player, SteamID, admin, or reason...")
    self.searchEntry.OnValueChange = function(entry, value)
        if ( self.ignoreSearchCallback ) then return end

        self.searchQuery = string.Trim(tostring(value or entry:GetValue() or ""))
        self.page = 1
        self.pendingSearch = true
        self.pendingSearchAt = CurTime() + 0.30
    end
    self.searchEntry.OnEnter = function(entry)
        if ( self.ignoreSearchCallback ) then return end

        self.searchQuery = string.Trim(tostring(entry:GetValue() or ""))
        self.page = 1
        self.pendingSearch = false
        self:RequestList()
    end

    self.controls:SetTall(math.max(self.createButton:GetTall(), self.searchEntry:GetTall()))

    self.filterBar = self:Add("EditablePanel")
    self.filterBar:Dock(TOP)
    self.filterBar:SetTall(ax.util:ScreenScaleH(22))
    self.filterBar:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
    self.filterBar.Paint = nil

    self.filterButtons = {}

    for i = 1, #FILTERS do
        local filterData = FILTERS[i]

        local button = self.filterBar:Add("ax.button")
        button:Dock(LEFT)
        button:DockMargin(0, 0, ax.util:ScreenScale(4), 0)
        button:SetText(filterData.label, true)
        button.bActive = false
        button.filterID = filterData.id

        button.PaintAdditional = function(this, width, height)
            if ( !this.bActive ) then return end

            local glass = ax.theme:GetGlass()
            local metrics = ax.theme:GetMetrics()
            local barHeight = math.max(2, ax.util:ScreenScaleH(2))
            surface.SetDrawColor(ax.theme:ScaleAlpha(glass.progress, metrics.opacity))
            surface.DrawRect(0, height - barHeight, width, barHeight)
        end

        button.DoClick = function()
            if ( self.selectedFilter == filterData.id ) then return end

            self.selectedFilter = filterData.id
            self.page = 1
            self:UpdateFilterButtons()
            self:RequestList()
        end

        self.filterButtons[filterData.id] = button
    end

    self.statsPanel = self:Add("EditablePanel")
    self.statsPanel:Dock(TOP)
    self.statsPanel:SetTall(ax.util:ScreenScaleH(20))
    self.statsPanel:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
    self.statsPanel.Paint = nil

    local function AddStatLabel()
        local label = self.statsPanel:Add("ax.text")
        label:Dock(LEFT)
        label:DockMargin(0, 0, ax.util:ScreenScale(8), 0)
        label:SetFont("ax.small")
        label:SetText("", true)
        label:SetContentAlignment(4)

        return label
    end

    self.statTotal = AddStatLabel()
    self.statActive = AddStatLabel()
    self.statPermanent = AddStatLabel()
    self.statExpired = AddStatLabel()
    self.statRevoked = AddStatLabel()

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
    self.listTitle:SetText("Ban Records", true)
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
    local wantedWidth = math.Clamp(math.floor(width * 0.48), minWidth, maxWidth)

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

function PANEL:UpdateFilterButtons()
    for i = 1, #FILTERS do
        local filterID = FILTERS[i].id
        local button = self.filterButtons[filterID]
        if ( IsValid(button) ) then
            button.bActive = (filterID == self.selectedFilter)
        end
    end
end

function PANEL:UpdateStats()
    local stats = self.stats or {}

    if ( IsValid(self.statTotal) ) then
        self.statTotal:SetText("Total: " .. tostring(math.floor(SafeNumber(stats.total, 0))), true)
    end

    if ( IsValid(self.statActive) ) then
        self.statActive:SetText("Active: " .. tostring(math.floor(SafeNumber(stats.active, 0))), true)
    end

    if ( IsValid(self.statPermanent) ) then
        self.statPermanent:SetText("Permanent: " .. tostring(math.floor(SafeNumber(stats.permanent, 0))), true)
    end

    if ( IsValid(self.statExpired) ) then
        self.statExpired:SetText("Expired: " .. tostring(math.floor(SafeNumber(stats.expired, 0))), true)
    end

    if ( IsValid(self.statRevoked) ) then
        self.statRevoked:SetText("Revoked: " .. tostring(math.floor(SafeNumber(stats.revoked, 0))), true)
    end
end

function PANEL:UpdateStatus()
    if ( !IsValid(self.statusLabel) ) then return end

    local statusText
    if ( self.requestingList ) then
        statusText = "Loading ban records..."
    elseif ( self.totalRows <= 0 ) then
        if ( self.searchQuery != "" ) then
            statusText = "No bans matched \"" .. self.searchQuery .. "\"."
        else
            statusText = "No bans were found for this filter."
        end
    else
        statusText = "Showing " .. tostring(#self.rows) .. " of " .. tostring(self.totalRows) .. " bans"
        if ( self.searchQuery != "" ) then
            statusText = statusText .. " for \"" .. self.searchQuery .. "\""
        end
    end

    self.statusLabel:SetText(statusText, true)
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

    ax.net:Start("admin.bans.request_list", {
        nonce = self.listNonce,
        page = self.page,
        page_size = self.pageSize,
        search = self.searchQuery,
        filter = self.selectedFilter
    })
end

function PANEL:RequestDetail(banID)
    banID = math.floor(SafeNumber(banID, 0))
    if ( banID <= 0 ) then return end

    self.detailNonce = self.detailNonce + 1
    self.requestingDetail = true

    if ( !istable(self.selectedDetail) or self.selectedDetail.id != banID ) then
        self.selectedDetail = nil
    end

    self:RebuildDetail()

    ax.net:Start("admin.bans.request_detail", {
        nonce = self.detailNonce,
        id = banID
    })
end

function PANEL:SelectSummary(summary)
    if ( !istable(summary) ) then return end

    local banID = math.floor(SafeNumber(summary.id, 0))
    if ( banID <= 0 ) then return end

    local changed = self.selectedBanID != banID

    self.selectedBanID = banID
    self.selectedSummary = summary
    if ( changed ) then
        self.selectedDetail = nil
        self:RequestDetail(banID)
    else
        self:RebuildDetail()
    end

    self:RebuildList()
end

function PANEL:GetSelectedBanData()
    if ( istable(self.selectedDetail) and self.selectedDetail.id == self.selectedBanID ) then
        return self.selectedDetail
    end

    if ( istable(self.selectedSummary) and self.selectedSummary.id == self.selectedBanID ) then
        return self.selectedSummary
    end

    return nil
end

function PANEL:SendActionRequest(netName, payload)
    if ( !isstring(netName) or netName == "" ) then return end

    self.actionNonce = self.actionNonce + 1
    payload = istable(payload) and table.Copy(payload) or {}
    payload.nonce = self.actionNonce

    ax.net:Start(netName, payload)
end

function PANEL:PromptCreateBan()
    Derma_StringRequest("Create Ban", "Enter SteamID64 or SteamID:", "", function(identifier)
        if ( !IsValid(self) ) then return end

        identifier = string.Trim(tostring(identifier or ""))
        if ( identifier == "" ) then
            NotifyClient("Please enter a valid SteamID64 or SteamID.", "error")
            return
        end

        Derma_StringRequest("Create Ban", "Duration in minutes (0 = permanent):", "0", function(minutesText)
            if ( !IsValid(self) ) then return end

            local minutes = math.floor(tonumber(minutesText) or -1)
            if ( minutes < 0 ) then
                NotifyClient("Duration must be 0 or greater.", "error")
                return
            end

            Derma_StringRequest("Create Ban", "Reason (optional):", "", function(reason)
                if ( !IsValid(self) ) then return end

                self:SendActionRequest("admin.bans.create", {
                    steamid64 = identifier,
                    minutes = minutes,
                    reason = string.Trim(tostring(reason or ""))
                })
            end)
        end)
    end)
end

function PANEL:PromptModifyBan()
    local banData = self:GetSelectedBanData()
    if ( !istable(banData) ) then
        NotifyClient("Select a ban first.", "error")
        return
    end

    local banID = math.floor(SafeNumber(banData.id, 0))
    if ( banID <= 0 ) then
        NotifyClient("Invalid ban selected.", "error")
        return
    end

    if ( !IsBanActive(banData) ) then
        NotifyClient("Only active bans can be modified.", "error")
        return
    end

    local defaultMinutes = tostring(math.max(0, math.floor(SafeNumber(banData.duration, 0) / 60)))
    local defaultReason = tostring(banData.reason or "")

    Derma_StringRequest("Modify Ban #" .. tostring(banID), "Duration in minutes (0 = permanent):", defaultMinutes, function(minutesText)
        if ( !IsValid(self) ) then return end

        local minutes = math.floor(tonumber(minutesText) or -1)
        if ( minutes < 0 ) then
            NotifyClient("Duration must be 0 or greater.", "error")
            return
        end

        Derma_StringRequest("Modify Ban #" .. tostring(banID), "Reason (leave blank to keep current reason):", defaultReason, function(reason)
            if ( !IsValid(self) ) then return end

            self:SendActionRequest("admin.bans.modify", {
                id = banID,
                minutes = minutes,
                reason = string.Trim(tostring(reason or ""))
            })
        end)
    end)
end

function PANEL:PromptRevokeBan()
    local banData = self:GetSelectedBanData()
    if ( !istable(banData) ) then
        NotifyClient("Select a ban first.", "error")
        return
    end

    local banID = math.floor(SafeNumber(banData.id, 0))
    if ( banID <= 0 ) then
        NotifyClient("Invalid ban selected.", "error")
        return
    end

    if ( !IsBanActive(banData) ) then
        NotifyClient("That ban is not active.", "error")
        return
    end

    Derma_StringRequest("Revoke Ban #" .. tostring(banID), "Revoke reason (optional):", "Unbanned by admin.", function(reason)
        if ( !IsValid(self) ) then return end

        self:SendActionRequest("admin.bans.revoke", {
            id = banID,
            reason = string.Trim(tostring(reason or ""))
        })
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

function PANEL:AddReasonBlock(titleText, reasonText)
    local block = self.detailScroll:Add("EditablePanel")
    block:Dock(TOP)
    block:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
    block.Paint = nil

    local title = block:Add("ax.text")
    title:Dock(TOP)
    title:SetFont("ax.small")
    title:SetText(tostring(titleText or "Reason") .. ":", true)
    title:SetContentAlignment(4)

    local value = block:Add("ax.text")
    value:Dock(TOP)
    value:DockMargin(ax.util:ScreenScale(4), 0, 0, 0)
    value:SetFont("ax.small")
    value:SetText(tostring(reasonText or ""), true)
    value:SetContentAlignment(4)

    block:SetTall(title:GetTall() + value:GetTall())
end

function PANEL:RebuildList()
    if ( !IsValid(self.listScroll) ) then return end

    self.listScroll:Clear()

    if ( self.rows[1] == nil ) then
        local noResults = self.listScroll:Add("ax.text")
        noResults:Dock(TOP)
        noResults:DockMargin(ax.util:ScreenScale(8), ax.util:ScreenScaleH(8), ax.util:ScreenScale(8), 0)
        noResults:SetFont("ax.regular.italic")
        noResults:SetText("No bans to display.", true)
        noResults:SetContentAlignment(4)
        return
    end

    local panel = self
    for i = 1, #self.rows do
        local rowData = self.rows[i]

        local row = self.listScroll:Add("EditablePanel")
        row:Dock(TOP)
        row:SetTall(ax.util:ScreenScaleH(46))
        row:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
        row:SetMouseInputEnabled(true)
        row:SetCursor("hand")
        row.data = rowData

        row.Paint = function(this, width, height)
            local glass = ax.theme:GetGlass()
            local fill = glass.button

            if ( this.data and math.floor(SafeNumber(this.data.id, 0)) == panel.selectedBanID ) then
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

            local accent = GetStatusColor(this.data and this.data.status or "unknown")
            surface.SetDrawColor(accent)
            surface.DrawRect(0, 0, math.max(2, ax.util:ScreenScale(2)), height)
        end

        function row:OnMousePressed(code)
            if ( code != MOUSE_LEFT ) then return end
            panel:SelectSummary(self.data)
        end

        local title = row:Add("ax.text")
        title:Dock(TOP)
        title:DockMargin(ax.util:ScreenScale(6), ax.util:ScreenScaleH(3), ax.util:ScreenScale(6), 0)
        title:SetFont("ax.regular.bold")
        title:SetText("#" .. tostring(rowData.id or 0) .. "  " .. tostring(rowData.name or "Unknown"), true)
        title:SetContentAlignment(4)

        local meta = row:Add("ax.text")
        meta:Dock(TOP)
        meta:DockMargin(ax.util:ScreenScale(6), 0, ax.util:ScreenScale(6), 0)
        meta:SetFont("ax.small")

        local status = FormatStatus(rowData.status)
        local online = rowData.is_online == true and "ONLINE" or "OFFLINE"
        local duration = FormatDuration(rowData.duration)
        meta:SetText(status .. " | " .. online .. " | " .. duration .. " | " .. tostring(rowData.admin_name or "Console"), true)
        meta:SetContentAlignment(4)

        local reason = row:Add("ax.text")
        reason:Dock(FILL)
        reason:DockMargin(ax.util:ScreenScale(6), 0, ax.util:ScreenScale(6), ax.util:ScreenScaleH(2))
        reason:SetFont("ax.small.italic")
        reason:SetText(TruncateText(rowData.reason or "No reason provided.", 96), true)
        reason:SetContentAlignment(4)
    end
end

function PANEL:RebuildDetail()
    if ( !IsValid(self.detailScroll) ) then return end

    self.detailScroll:Clear()

    if ( !self.selectedBanID ) then
        local info = self.detailScroll:Add("ax.text")
        info:Dock(TOP)
        info:DockMargin(ax.util:ScreenScale(4), ax.util:ScreenScaleH(6), 0, 0)
        info:SetFont("ax.regular.italic")
        info:SetText("Select a ban to inspect details.", true)
        info:SetContentAlignment(4)
        return
    end

    local detail = self:GetSelectedBanData()
    if ( !istable(detail) ) then
        return
    end

    local banID = math.floor(SafeNumber(detail.id, 0))
    local name = tostring(detail.name or "Unknown")
    local steamID64 = tostring(detail.steamid64 or "Unknown")
    local status = tostring(detail.status or "unknown")
    local statusText = FormatStatus(status)
    local bActive = IsBanActive(detail)

    local header = self.detailScroll:Add("ax.text")
    header:Dock(TOP)
    header:DockMargin(0, 0, 0, ax.util:ScreenScaleH(2))
    header:SetFont("ax.regular.bold")
    header:SetText(name .. "  (#" .. tostring(banID) .. ")", true)
    header:SetContentAlignment(4)

    local subHeader = self.detailScroll:Add("ax.text")
    subHeader:Dock(TOP)
    subHeader:DockMargin(0, 0, 0, ax.util:ScreenScaleH(4))
    subHeader:SetFont("ax.small")
    subHeader:SetText(steamID64, true)
    subHeader:SetContentAlignment(4)

    self:AddSectionTitle("Actions")
    self:AddActionButton("Create Offline Ban", function()
        self:PromptCreateBan()
    end, true)
    self:AddActionButton("Refresh Ban Detail", function()
        self:RequestDetail(banID)
    end, banID > 0)
    self:AddActionButton("Modify Selected Ban", function()
        self:PromptModifyBan()
    end, bActive)
    self:AddActionButton("Revoke Selected Ban", function()
        self:PromptRevokeBan()
    end, bActive)
    self:AddActionButton("Open Steam Profile", function()
        gui.OpenURL("https://steamcommunity.com/profiles/" .. steamID64)
    end, steamID64 != "" and steamID64 != "Unknown")
    self:AddActionButton("Copy SteamID64", function()
        if ( SetClipboardText ) then
            SetClipboardText(steamID64)
        end
    end, steamID64 != "" and steamID64 != "Unknown")

    self:AddSectionTitle("Ban Details")
    self:AddDetailRow("Status", statusText)
    self:AddDetailRow("Duration", FormatDuration(detail.duration))
    self:AddDetailRow("Created", FormatTimestamp(detail.created_at))
    self:AddDetailRow("Expires", SafeNumber(detail.expires_at, 0) == 0 and "Never" or FormatTimestamp(detail.expires_at))
    self:AddDetailRow("Admin", tostring(detail.admin_name or "Console"))
    self:AddDetailRow("Admin SteamID64", tostring(detail.admin_steamid64 or "0"))
    self:AddDetailRow("SteamID", tostring(detail.steamid or ""))
    self:AddDetailRow("Is Online", detail.is_online == true and "Yes" or "No")

    self:AddDetailRow("Revoked", FormatTimestamp(detail.revoked_at))
    self:AddDetailRow("Revoked By", tostring(detail.revoked_by_name or "N/A"))
    self:AddDetailRow("Modified", FormatTimestamp(detail.modified_at))
    self:AddDetailRow("Modified By", tostring(detail.modified_by_name or "N/A"))

    self:AddReasonBlock("Ban Reason", tostring(detail.reason or "No reason provided."))

    local revokedReason = string.Trim(tostring(detail.revoked_reason or ""))
    if ( revokedReason != "" ) then
        self:AddReasonBlock("Revocation Reason", revokedReason)
    end

    local modifyReason = string.Trim(tostring(detail.modify_reason or ""))
    if ( modifyReason != "" ) then
        self:AddReasonBlock("Modification Note", modifyReason)
    end

    if ( istable(detail.history) and #detail.history > 0 ) then
        self:AddSectionTitle("Recent History")

        for i = 1, #detail.history do
            local line = self.detailScroll:Add("ax.text")
            line:Dock(TOP)
            line:DockMargin(0, 0, 0, ax.util:ScreenScaleH(2))
            line:SetFont("ax.small")
            line:SetText(BuildHistoryLine(detail.history[i]), true)
            line:SetContentAlignment(4)
        end
    end

    if ( self.requestingDetail and !istable(self.selectedDetail) ) then
        local loading = self.detailScroll:Add("ax.text")
        loading:Dock(TOP)
        loading:DockMargin(0, ax.util:ScreenScaleH(6), 0, 0)
        loading:SetFont("ax.small.italic")
        loading:SetText("Loading detailed ban data...", true)
        loading:SetContentAlignment(4)
    end
end

function PANEL:HandleListPayload(payload)
    if ( !IsValidPayload(payload) ) then return end
    if ( math.floor(SafeNumber(payload.nonce, 0)) != self.listNonce ) then
        return
    end

    self.requestingList = false
    self.page = math.max(1, math.floor(SafeNumber(payload.page, self.page)))
    self.pageSize = math.max(1, math.floor(SafeNumber(payload.page_size, self.pageSize)))
    self.pageCount = math.max(1, math.floor(SafeNumber(payload.page_count, self.pageCount)))
    self.totalRows = math.max(0, math.floor(SafeNumber(payload.total_rows, self.totalRows)))
    self.rows = istable(payload.rows) and payload.rows or {}
    self.selectedFilter = NormalizeFilter(payload.filter or self.selectedFilter)
    self.searchQuery = string.Trim(tostring(payload.search or self.searchQuery))

    self.stats = istable(payload.stats) and payload.stats or {
        total = 0,
        active = 0,
        permanent = 0,
        expired = 0,
        revoked = 0,
    }

    if ( IsValid(self.searchEntry) and self.searchEntry:GetValue() != self.searchQuery ) then
        self.ignoreSearchCallback = true
        self.searchEntry:SetValue(self.searchQuery)
        self.ignoreSearchCallback = false
    end

    local desiredID = self.pendingSelectBanID or self.selectedBanID
    self.pendingSelectBanID = nil

    local selectedRow
    if ( desiredID ) then
        for i = 1, #self.rows do
            if ( math.floor(SafeNumber(self.rows[i].id, 0)) == desiredID ) then
                selectedRow = self.rows[i]
                break
            end
        end
    end

    local shouldRequestDetail = false

    if ( selectedRow ) then
        local bChanged = self.selectedBanID != math.floor(SafeNumber(selectedRow.id, 0))
        self.selectedBanID = math.floor(SafeNumber(selectedRow.id, 0))
        self.selectedSummary = selectedRow

        if ( bChanged or !istable(self.selectedDetail) or self.selectedDetail.id != self.selectedBanID ) then
            self.selectedDetail = nil
            shouldRequestDetail = true
        end
    elseif ( self.rows[1] != nil ) then
        self.selectedBanID = math.floor(SafeNumber(self.rows[1].id, 0))
        self.selectedSummary = self.rows[1]
        self.selectedDetail = nil
        shouldRequestDetail = true
    else
        self.selectedBanID = nil
        self.selectedSummary = nil
        self.selectedDetail = nil
    end

    if ( shouldRequestDetail and self.selectedBanID and self.selectedBanID > 0 ) then
        self:RequestDetail(self.selectedBanID)
    end

    self:UpdateFilterButtons()
    self:UpdateStats()
    self:UpdateStatus()
    self:UpdatePagingState()
    self:RebuildList()
    self:RebuildDetail()
end

function PANEL:HandleDetailPayload(payload)
    if ( !IsValidPayload(payload) ) then return end
    if ( math.floor(SafeNumber(payload.nonce, 0)) != self.detailNonce ) then
        return
    end

    self.requestingDetail = false

    local ban = payload.ban
    if ( !istable(ban) ) then
        self.selectedDetail = nil
        self:RebuildDetail()
        return
    end

    local banID = math.floor(SafeNumber(ban.id, 0))
    if ( !self.selectedBanID or banID != self.selectedBanID ) then
        return
    end

    self.selectedDetail = ban
    self:RebuildDetail()
end

function PANEL:HandleActionPayload(payload)
    if ( !IsValidPayload(payload) ) then return end
    if ( math.floor(SafeNumber(payload.nonce, 0)) != self.actionNonce ) then
        return
    end

    local ok = payload.ok == true
    local message = tostring(payload.message or (ok and "Action completed." or "Action failed."))
    local ban = istable(payload.ban) and payload.ban or nil

    NotifyClient(message, ok and "success" or "error")

    if ( istable(ban) and math.floor(SafeNumber(ban.id, 0)) > 0 ) then
        self.pendingSelectBanID = math.floor(SafeNumber(ban.id, 0))
    end

    if ( ok or self.pendingSelectBanID != nil ) then
        self:RequestList()
    end
end

function PANEL:HandleErrorPayload(payload)
    if ( !IsValidPayload(payload) ) then return end

    local message = tostring(payload.message or "Unknown ban management error.")
    self.requestingList = false
    self.requestingDetail = false

    self:UpdateStatus()
    self:UpdatePagingState()
    self:RebuildDetail()

    if ( IsValid(self.statusLabel) ) then
        self.statusLabel:SetText(message, true)
    end

    NotifyClient(message, "error")

    if ( ax.util and ax.util.PrintError ) then
        ax.util:PrintError("[admin.bans] " .. message)
    end
end

function PANEL:OnRemove()
    if ( ax.gui.admin_bans == self ) then
        ax.gui.admin_bans = nil
    end
end

vgui.Register("ax.tab.admin.bans", PANEL, "EditablePanel")

ax.net:Hook("admin.bans.list", function(payload)
    if ( !IsValid(ax.gui.admin_bans) ) then return end
    ax.gui.admin_bans:HandleListPayload(payload)
end)

ax.net:Hook("admin.bans.detail", function(payload)
    if ( !IsValid(ax.gui.admin_bans) ) then return end
    ax.gui.admin_bans:HandleDetailPayload(payload)
end)

ax.net:Hook("admin.bans.action_result", function(payload)
    if ( !IsValid(ax.gui.admin_bans) ) then return end
    ax.gui.admin_bans:HandleActionPayload(payload)
end)

ax.net:Hook("admin.bans.error", function(payload)
    if ( !IsValid(ax.gui.admin_bans) ) then return end
    ax.gui.admin_bans:HandleErrorPayload(payload)
end)