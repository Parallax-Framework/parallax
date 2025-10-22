--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Receive zone sync from server.
-- @realm client
net.Receive("ax.zones.sync", function()
    -- Read nextId
    ax.zones.nextId = net.ReadUInt(32)

    -- Read zone count
    local count = net.ReadUInt(16)

    -- Clear existing zones
    ax.zones.stored = {}

    -- Read each zone
    for i = 1, count do
        local zone = {}
        zone.id = net.ReadUInt(32)
        zone.name = net.ReadString()
        zone.type = net.ReadString()
        zone.priority = net.ReadInt(32)
        zone.flags = net.ReadTable()
        zone.data = net.ReadTable()
        zone.map = net.ReadString()
        zone.source = net.ReadString()

        -- Read geometry based on type
        if ( zone.type == "box" ) then
            zone.mins = net.ReadVector()
            zone.maxs = net.ReadVector()
        elseif ( zone.type == "sphere" ) then
            zone.center = net.ReadVector()
            zone.radius = net.ReadFloat()
        elseif ( zone.type == "pvs" or zone.type == "trace" ) then
            zone.origin = net.ReadVector()
            if ( net.ReadBool() ) then
                zone.radius = net.ReadFloat()
            end
        end

        ax.zones.stored[zone.id] = zone
    end

    ax.util:PrintDebug("Received " .. count .. " zones from server")
end)
