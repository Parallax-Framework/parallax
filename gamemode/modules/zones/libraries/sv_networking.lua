--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- @module ax.zones

ax.zones = ax.zones or {}

util.AddNetworkString("ax.zones.sync")

local function BuildSyncPayload()
    local zones = {}
    for _, zone in pairs(ax.zones.stored) do
        local entry = {
            id = zone.id,
            name = zone.name,
            type = zone.type,
            priority = zone.priority,
            flags = zone.flags,
            data = zone.data,
            map = zone.map,
            source = zone.source
        }

        if ( zone.type == "box" ) then
            entry.mins = zone.mins
            entry.maxs = zone.maxs
        elseif ( zone.type == "sphere" ) then
            entry.center = zone.center
            entry.radius = zone.radius
        elseif ( zone.type == "pvs" or zone.type == "trace" ) then
            entry.origin = zone.origin
            entry.radius = zone.radius
        end

        zones[#zones + 1] = entry
    end

    return {
        nextId = ax.zones.nextId,
        zones = zones
    }
end

--- Synchronize zones to all clients.
-- @realm server
function ax.zones:Sync()
    local payload = BuildSyncPayload()
    ax.net:Start(nil, "ax.zones.sync", payload)

    ax.util:PrintDebug("Zones synchronized to all clients (" .. #payload.zones .. " zones)")
end

--- Synchronize zones to a specific player.
-- @realm server
-- @tparam Player client Player to sync to
function ax.zones:SyncToPlayer(client)
    if ( !IsValid(client) ) then return end
    local payload = BuildSyncPayload()
    ax.net:Start(client, "ax.zones.sync", payload)

    ax.util:PrintDebug("Zones synchronized to " .. client:Nick() .. " (" .. #payload.zones .. " zones)")
end

hook.Add("PlayerReady", "ax.zones.sync", function(client)
    ax.zones:SyncToPlayer(client)
end)
