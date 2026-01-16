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

--- Print a list of all zones to the console.
-- @realm server
function ax.zones:List()
    local mapName = game.GetMap()
    print("\n=== Zones for map: " .. mapName .. " ===")

    local count = 0
    for id, zone in SortedPairsByMemberValue(self.stored, "id") do
        count = count + 1
        local geom = ""

        if ( zone.type == "box" ) then
            geom = string.format("mins=%s maxs=%s", tostring(zone.mins), tostring(zone.maxs))
        elseif ( zone.type == "sphere" ) then
            geom = string.format("center=%s radius=%.1f", tostring(zone.center), zone.radius)
        elseif ( zone.type == "pvs" or zone.type == "trace" ) then
            geom = string.format("origin=%s", tostring(zone.origin))
            if ( zone.radius ) then
                geom = geom .. string.format(" radius=%.1f", zone.radius)
            end
        end

        print(string.format(
            "[%d] %s (type=%s, priority=%d, source=%s) %s",
            zone.id,
            zone.name,
            zone.type,
            zone.priority,
            zone.source,
            geom
        ))
    end

    print("=== Total: " .. count .. " zones ===\n")
end

--- Enable debug visualization for a player.
-- @realm server
-- @tparam Player client Player to enable debug drawing for
function ax.zones:DrawDebug(client)
    if ( !IsValid(client) ) then return end

    -- Send zone data to client for drawing
    ax.net:Start(client, "ax.zones.drawdebug", true)

    ax.util:PrintDebug("Zone debug drawing enabled for " .. client:Nick())
end

--- Disable debug visualization for a player.
-- @realm server
-- @tparam Player client Player to disable debug drawing for
function ax.zones:StopDrawDebug(client)
    if ( !IsValid(client) ) then return end

    ax.net:Start(client, "ax.zones.drawdebug", false)

    ax.util:PrintDebug("Zone debug drawing disabled for " .. client:Nick())
end
