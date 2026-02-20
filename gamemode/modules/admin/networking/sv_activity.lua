--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE or {}

local MAX_SEARCH_LENGTH = 96

local function TrimSearch(search)
    search = string.Trim(tostring(search or ""))
    if ( #search > MAX_SEARCH_LENGTH ) then
        search = string.sub(search, 1, MAX_SEARCH_LENGTH)
    end

    return search
end

local function BuildListRowPayload(row, filteredRank)
    return {
        steamid64 = row.steamid64,
        name = row.name,
        usergroup = row.usergroup,
        is_online = row.is_online == true,
        current_ping = math.Round(tonumber(row.current_ping) or 0),
        average_ping = math.Round(tonumber(row.average_ping) or 0),
        total_playtime = math.floor(tonumber(row.total_playtime) or 0),
        session_playtime = math.floor(tonumber(row.session_playtime) or 0),
        total_sessions = math.floor(tonumber(row.total_sessions) or 0),
        average_join_hour = tonumber(row.average_join_hour),
        average_join_interval = tonumber(row.average_join_interval),
        last_join = tonumber(row.last_join) or 0,
        last_leave = tonumber(row.last_leave) or 0,
        rank_global = tonumber(row.rank_global) or 0,
        rank_filtered = tonumber(filteredRank) or 0
    }
end

local function BuildDetailPayload(row, filteredRank)
    local activity = MODULE:NormalizeActivityData(row.activity)

    return {
        steamid64 = row.steamid64,
        name = row.name,
        usergroup = row.usergroup,
        is_online = row.is_online == true,
        current_ping = math.Round(tonumber(row.current_ping) or 0),
        average_ping = tonumber(row.average_ping) or 0,
        total_playtime = math.floor(tonumber(row.total_playtime) or 0),
        session_playtime = math.floor(tonumber(row.session_playtime) or 0),
        total_sessions = math.floor(tonumber(row.total_sessions) or 0),
        average_join_hour = tonumber(row.average_join_hour),
        average_join_interval = tonumber(row.average_join_interval),
        last_join = tonumber(row.last_join) or 0,
        last_leave = tonumber(row.last_leave) or 0,
        rank_global = tonumber(row.rank_global) or 0,
        rank_filtered = tonumber(filteredRank) or 0,
        ping_samples = math.floor(tonumber(activity.ping_samples) or 0),
        total_ping = tonumber(activity.total_ping) or 0,
        join_hour_samples = math.floor(tonumber(activity.join_hour_samples) or 0),
        join_interval_samples = math.floor(tonumber(activity.join_interval_samples) or 0)
    }
end

local function SendError(client, message, nonce)
    ax.net:Start(client, "admin.activity.error", {
        message = tostring(message or "Unknown error"),
        nonce = tonumber(nonce) or 0
    })
end

ax.net:Hook("admin.activity.request_list", function(client, payload)
    if ( !MODULE:CanAccessActivity(client) ) then
        return
    end

    payload = istable(payload) and payload or {}

    local nonce = tonumber(payload.nonce) or 0
    local page, pageSize = MODULE:NormalizeActivityPaging(payload.page, payload.page_size)
    local search = TrimSearch(payload.search)

    MODULE:GetActivityRows(function(rows, err)
        if ( !istable(rows) ) then
            SendError(client, err or "Failed to fetch activity rows.", nonce)
            return
        end

        local filtered = MODULE:FilterActivityRows(rows, search)
        local pageRows, totalRows, pageCount, startIndex = MODULE:PaginateActivityRows(filtered, page, pageSize)

        local outRows = {}
        for i = 1, #pageRows do
            outRows[#outRows + 1] = BuildListRowPayload(pageRows[i], startIndex + i - 1)
        end

        ax.net:Start(client, "admin.activity.list", {
            nonce = nonce,
            search = search,
            page = page,
            page_size = pageSize,
            page_count = pageCount,
            total_rows = totalRows,
            rows = outRows,
            generated_at = os.time()
        })
    end)
end)

ax.net:Hook("admin.activity.request_detail", function(client, payload)
    if ( !MODULE:CanAccessActivity(client) ) then
        return
    end

    payload = istable(payload) and payload or {}

    local nonce = tonumber(payload.nonce) or 0
    local steamID64 = tostring(payload.steamid64 or "")
    local search = TrimSearch(payload.search)

    if ( !ax.type:Sanitise(ax.type.steamid64, steamID64) ) then
        SendError(client, "Invalid SteamID64.", nonce)
        return
    end

    MODULE:GetActivityRows(function(rows, err)
        if ( !istable(rows) ) then
            SendError(client, err or "Failed to fetch player detail.", nonce)
            return
        end

        local filtered = MODULE:FilterActivityRows(rows, search)

        local selected, filteredRank
        for i = 1, #filtered do
            if ( filtered[i].steamid64 == steamID64 ) then
                selected = filtered[i]
                filteredRank = i
                break
            end
        end

        if ( !selected ) then
            for i = 1, #rows do
                if ( rows[i].steamid64 == steamID64 ) then
                    selected = rows[i]
                    break
                end
            end
        end

        if ( !selected ) then
            SendError(client, "Player not found in activity database.", nonce)
            return
        end

        ax.net:Start(client, "admin.activity.detail", {
            nonce = nonce,
            search = search,
            player = BuildDetailPayload(selected, filteredRank or 0)
        })
    end)
end)
