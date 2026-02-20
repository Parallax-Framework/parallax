--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE or {}

MODULE.activityCache = MODULE.activityCache or {
    rows = nil,
    timestamp = 0,
    pending = {},
    querying = false
}

MODULE.activityCacheTTL = MODULE.activityCacheTTL or 15
MODULE.activityPageSizeDefault = MODULE.activityPageSizeDefault or 20
MODULE.activityPageSizeMax = MODULE.activityPageSizeMax or 64

local function NormalizeActivityData(data)
    data = istable(data) and table.Copy(data) or {}

    data.total_playtime = math.max(0, tonumber(data.total_playtime) or 0)
    data.total_sessions = math.max(0, tonumber(data.total_sessions) or 0)
    data.total_ping = math.max(0, tonumber(data.total_ping) or 0)
    data.ping_samples = math.max(0, tonumber(data.ping_samples) or 0)
    data.join_hour_sum = tonumber(data.join_hour_sum) or 0
    data.join_hour_samples = math.max(0, tonumber(data.join_hour_samples) or 0)
    data.join_interval_sum = math.max(0, tonumber(data.join_interval_sum) or 0)
    data.join_interval_samples = math.max(0, tonumber(data.join_interval_samples) or 0)

    return data
end

local function SortActivityRows(a, b)
    local playtimeA = tonumber(a.total_playtime) or 0
    local playtimeB = tonumber(b.total_playtime) or 0
    if ( playtimeA != playtimeB ) then
        return playtimeA > playtimeB
    end

    local joinA = tonumber(a.last_join) or 0
    local joinB = tonumber(b.last_join) or 0
    if ( joinA != joinB ) then
        return joinA > joinB
    end

    return tostring(a.name or "") < tostring(b.name or "")
end

function MODULE:CanAccessActivity(client)
    if ( !ax.util:IsValidPlayer(client) ) then
        return false
    end

    if ( istable(CAMI) and isfunction(CAMI.PlayerHasAccess) ) then
        local hasAccess = CAMI.PlayerHasAccess(client, "Parallax - Admin Activity", nil)
        if ( hasAccess == true ) then
            return true
        end
    end

    return client:IsAdmin()
end

function MODULE:NormalizeActivityData(data)
    return NormalizeActivityData(data)
end

function MODULE:GetPlayerActivityData(client)
    if ( !ax.util:IsValidPlayer(client) ) then
        return NormalizeActivityData({})
    end

    return NormalizeActivityData(client:GetData("admin_activity", {}))
end

function MODULE:SetPlayerActivityData(client, data, bNoDBUpdate)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    client:SetData("admin_activity", NormalizeActivityData(data), {
        bNoDBUpdate = bNoDBUpdate == true
    })
end

function MODULE:InvalidateActivityCache()
    self.activityCache.rows = nil
    self.activityCache.timestamp = 0
end

function MODULE:GetRawActivityRows(callback, bBypassCache)
    if ( !isfunction(callback) ) then return end

    local cache = self.activityCache
    local shouldUseCache = bBypassCache != true
    local cacheAge = CurTime() - (tonumber(cache.timestamp) or 0)
    if ( shouldUseCache and istable(cache.rows) and cacheAge <= self.activityCacheTTL ) then
        callback(cache.rows)
        return
    end

    cache.pending = cache.pending or {}
    cache.pending[#cache.pending + 1] = callback

    if ( cache.querying ) then
        return
    end

    cache.querying = true

    local query = mysql:Select("ax_players")
    query:Callback(function(result)
        cache.querying = false

        local pending = cache.pending or {}
        cache.pending = {}

        if ( result == false ) then
            for i = 1, #pending do
                pending[i](nil, "db_query_failed")
            end
            return
        end

        cache.rows = istable(result) and result or {}
        cache.timestamp = CurTime()

        for i = 1, #pending do
            pending[i](cache.rows)
        end
    end)
    query:Execute()
end

function MODULE:BuildActivityRow(rawRow)
    if ( !istable(rawRow) ) then return nil end

    local steamID64 = tostring(rawRow.steamid64 or "")
    if ( steamID64 == "" ) then return nil end

    local onlineClient = player.GetBySteamID64(steamID64)
    if ( !ax.util:IsValidPlayer(onlineClient) ) then
        onlineClient = nil
    end

    local session = onlineClient and onlineClient:GetTable().axAdminActivitySession or nil

    local activityData
    if ( onlineClient ) then
        activityData = self:GetPlayerActivityData(onlineClient)
    else
        local parsed = ax.util:SafeParseTable(rawRow.data)
        if ( !istable(parsed) ) then
            parsed = {}
        end

        activityData = NormalizeActivityData(parsed.admin_activity)
    end

    local sessionPlaytime = 0
    if ( istable(session) and session.joinUnix ) then
        sessionPlaytime = math.max(0, os.time() - (tonumber(session.joinUnix) or os.time()))
    end

    local persistedPlaytime = math.max(0, tonumber(activityData.total_playtime) or tonumber(rawRow.play_time) or 0)
    local totalPlaytime = persistedPlaytime + sessionPlaytime

    local pingTotal = math.max(0, tonumber(activityData.total_ping) or 0)
    local pingSamples = math.max(0, tonumber(activityData.ping_samples) or 0)

    if ( istable(session) ) then
        pingTotal = pingTotal + math.max(0, tonumber(session.pingSum) or 0)
        pingSamples = pingSamples + math.max(0, tonumber(session.pingSamples) or 0)
    end

    local averagePing = 0
    if ( pingSamples > 0 ) then
        averagePing = pingTotal / pingSamples
    elseif ( onlineClient ) then
        averagePing = math.max(0, tonumber(onlineClient:Ping()) or 0)
    end

    local totalSessions = math.max(0, tonumber(activityData.total_sessions) or 0)
    if ( totalSessions < 1 and istable(session) ) then
        totalSessions = 1
    end

    local joinHourSum = tonumber(activityData.join_hour_sum) or 0
    local joinHourSamples = math.max(0, tonumber(activityData.join_hour_samples) or 0)
    local averageJoinHour = joinHourSamples > 0 and (joinHourSum / joinHourSamples) or nil

    local joinIntervalSum = math.max(0, tonumber(activityData.join_interval_sum) or 0)
    local joinIntervalSamples = math.max(0, tonumber(activityData.join_interval_samples) or 0)
    local averageJoinInterval = joinIntervalSamples > 0 and (joinIntervalSum / joinIntervalSamples) or nil

    local usergroup = tostring(rawRow.usergroup or "")
    if ( usergroup == "" and onlineClient ) then
        usergroup = tostring(onlineClient:GetUserGroup() or "user")
    end
    if ( usergroup == "" ) then
        usergroup = "user"
    end

    local name = tostring(rawRow.name or "")
    if ( onlineClient ) then
        name = onlineClient:SteamName()
    end
    if ( name == "" ) then
        name = "Unknown"
    end

    return {
        steamid64 = steamID64,
        name = name,
        usergroup = usergroup,
        last_join = tonumber(rawRow.last_join) or 0,
        last_leave = tonumber(rawRow.last_leave) or 0,
        is_online = onlineClient != nil,
        current_ping = onlineClient and math.max(0, tonumber(onlineClient:Ping()) or 0) or 0,
        session_playtime = sessionPlaytime,
        total_playtime = totalPlaytime,
        average_ping = averagePing,
        total_sessions = totalSessions,
        average_join_hour = averageJoinHour,
        average_join_interval = averageJoinInterval,
        activity = activityData,
        rank_global = 0
    }
end

function MODULE:BuildActivityRows(rawRows)
    local rows = {}
    if ( !istable(rawRows) ) then
        return rows
    end

    for i = 1, #rawRows do
        local row = self:BuildActivityRow(rawRows[i])
        if ( istable(row) ) then
            rows[#rows + 1] = row
        end
    end

    table.sort(rows, SortActivityRows)

    for i = 1, #rows do
        rows[i].rank_global = i
    end

    return rows
end

function MODULE:GetActivityRows(callback, bBypassCache)
    if ( !isfunction(callback) ) then return end

    self:GetRawActivityRows(function(rawRows, err)
        if ( !istable(rawRows) ) then
            callback(nil, err or "unknown_error")
            return
        end

        callback(self:BuildActivityRows(rawRows))
    end, bBypassCache)
end

function MODULE:FilterActivityRows(rows, searchQuery)
    local filtered = {}
    if ( !istable(rows) ) then
        return filtered
    end

    local search = string.Trim(tostring(searchQuery or ""))
    if ( search == "" ) then
        for i = 1, #rows do
            filtered[#filtered + 1] = rows[i]
        end

        return filtered
    end

    for i = 1, #rows do
        local row = rows[i]
        if ( !istable(row) ) then continue end

        local name = tostring(row.name or "")
        local steamID64 = tostring(row.steamid64 or "")
        local usergroup = tostring(row.usergroup or "")

        if (
            ax.util:FindString(name, search)
            or ax.util:FindString(steamID64, search)
            or ax.util:FindString(usergroup, search)
        ) then
            filtered[#filtered + 1] = row
        end
    end

    return filtered
end

function MODULE:NormalizeActivityPaging(page, pageSize)
    page = math.max(math.floor(tonumber(page) or 1), 1)
    pageSize = math.floor(tonumber(pageSize) or self.activityPageSizeDefault)
    pageSize = math.Clamp(pageSize, 1, self.activityPageSizeMax)

    return page, pageSize
end

function MODULE:PaginateActivityRows(rows, page, pageSize)
    local total = istable(rows) and #rows or 0
    local pageCount = math.max(math.ceil(math.max(total, 1) / pageSize), 1)
    page = math.Clamp(page, 1, pageCount)

    local startIndex = ((page - 1) * pageSize) + 1
    local endIndex = math.min(startIndex + pageSize - 1, total)

    local output = {}
    if ( total > 0 ) then
        for i = startIndex, endIndex do
            output[#output + 1] = rows[i]
        end
    end

    return output, total, pageCount, startIndex, endIndex
end
