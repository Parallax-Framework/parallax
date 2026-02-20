--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE or {}

local PING_SAMPLE_INTERVAL = 20

local function EnsureSession(client)
    if ( !ax.util:IsValidPlayer(client) ) then return nil end

    local clientTable = client:GetTable()
    local session = clientTable.axAdminActivitySession
    if ( !istable(session) ) then
        session = {
            joinUnix = os.time(),
            pingSum = 0,
            pingSamples = 0,
            joinHour = os.date("*t").hour or 0
        }

        clientTable.axAdminActivitySession = session
    end

    return session
end

local function RecordSessionStart(module, client)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    local session = EnsureSession(client)
    if ( !istable(session) or session.started == true ) then
        return
    end

    local now = os.time()
    local dateData = os.date("*t", now) or {}
    local joinHour = math.Clamp(tonumber(dateData.hour) or 0, 0, 23)

    session.joinUnix = now
    session.joinHour = joinHour
    session.started = true

    local activityData = module:GetPlayerActivityData(client)
    activityData.total_sessions = math.max(0, tonumber(activityData.total_sessions) or 0) + 1
    activityData.join_hour_sum = (tonumber(activityData.join_hour_sum) or 0) + joinHour
    activityData.join_hour_samples = math.max(0, tonumber(activityData.join_hour_samples) or 0) + 1

    local lastLeave = tonumber(client:GetLastLeave()) or 0
    if ( lastLeave > 0 and now > lastLeave ) then
        activityData.join_interval_sum = math.max(0, tonumber(activityData.join_interval_sum) or 0) + (now - lastLeave)
        activityData.join_interval_samples = math.max(0, tonumber(activityData.join_interval_samples) or 0) + 1
    end

    module:SetPlayerActivityData(client, activityData)
    module:InvalidateActivityCache()
end

function MODULE:PlayerReady(client)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    RecordSessionStart(self, client)
end

function MODULE:PlayerDisconnected(client)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    local clientTable = client:GetTable()
    local session = EnsureSession(client)
    if ( !istable(session) ) then return end

    local now = os.time()
    local joinUnix = tonumber(session.joinUnix) or tonumber(client:GetLastJoin()) or now
    local sessionSeconds = math.max(0, now - joinUnix)

    local activityData = self:GetPlayerActivityData(client)
    local basePlaytime = math.max(0, tonumber(activityData.total_playtime) or tonumber(client:GetPlayTime()) or 0)
    activityData.total_playtime = basePlaytime + sessionSeconds
    activityData.total_ping = math.max(0, tonumber(activityData.total_ping) or 0) + math.max(0, tonumber(session.pingSum) or 0)
    activityData.ping_samples = math.max(0, tonumber(activityData.ping_samples) or 0) + math.max(0, tonumber(session.pingSamples) or 0)
    activityData.last_session_duration = sessionSeconds

    self:SetPlayerActivityData(client, activityData)

    clientTable.axAdminActivitySession = nil

    self:InvalidateActivityCache()
end

timer.Create("ax.admin.activity.ping", PING_SAMPLE_INTERVAL, 0, function()
    for _, client in ipairs(player.GetAll()) do
        if ( !ax.util:IsValidPlayer(client) ) then continue end

        local session = EnsureSession(client)
        if ( !istable(session) ) then continue end

        session.pingSum = math.max(0, tonumber(session.pingSum) or 0) + math.max(0, tonumber(client:Ping()) or 0)
        session.pingSamples = math.max(0, tonumber(session.pingSamples) or 0) + 1
    end
end)

hook.Add("OnReloaded", "ax.admin.activity.bootstrap", function()
    for _, client in ipairs(player.GetAll()) do
        if ( !ax.util:IsValidPlayer(client) ) then continue end
        if ( !client:GetCharacter() ) then continue end

        RecordSessionStart(MODULE, client)
    end
end)
