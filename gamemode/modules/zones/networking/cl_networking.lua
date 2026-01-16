--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Receive zone sync from server.
-- @realm client
ax.net:Hook("ax.zones.sync", function(payload)
    if ( !istable(payload) ) then return end

    ax.zones.nextId = payload.nextId or ax.zones.nextId or 1

    local zones = payload.zones or {}
    ax.zones.stored = {}

    for i = 1, #zones do
        local zone = zones[i]
        if ( istable(zone) and isnumber(zone.id) ) then
            ax.zones.stored[zone.id] = zone
        end
    end

    ax.util:PrintDebug("Received " .. tostring(#zones) .. " zones from server")
end)
