--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- @module ax.zones

util.AddNetworkString("ax.zones.sync")

--- Synchronize zones to all clients.
-- @realm server
function ax.zones:Sync()
    net.Start("ax.zones.sync")
        -- Send nextId
        net.WriteUInt(self.nextId, 32)

        -- Send zone count
        local count = table.Count(self.stored)
        net.WriteUInt(count, 16)

        -- Send each zone
        for id, zone in pairs(self.stored) do
            net.WriteUInt(zone.id, 32)
            net.WriteString(zone.name)
            net.WriteString(zone.type)
            net.WriteInt(zone.priority, 32)
            net.WriteTable(zone.flags)
            net.WriteTable(zone.data)
            net.WriteString(zone.map)
            net.WriteString(zone.source)

            -- Send geometry based on type
            if ( zone.type == "box" ) then
                net.WriteVector(zone.mins)
                net.WriteVector(zone.maxs)
            elseif ( zone.type == "sphere" ) then
                net.WriteVector(zone.center)
                net.WriteFloat(zone.radius)
            elseif ( zone.type == "pvs" or zone.type == "trace" ) then
                net.WriteVector(zone.origin)
                net.WriteBool(zone.radius != nil)
                if ( zone.radius ) then
                    net.WriteFloat(zone.radius)
                end
            end
        end

    net.Broadcast()

    ax.util:PrintDebug("Zones synchronized to all clients (" .. count .. " zones)")
end

--- Synchronize zones to a specific player.
-- @realm server
-- @tparam Player ply Player to sync to
function ax.zones:SyncToPlayer(ply)
    if ( !IsValid(ply) ) then return end

    net.Start("ax.zones.sync")
        -- Send nextId
        net.WriteUInt(self.nextId, 32)

        -- Send zone count
        local count = table.Count(self.stored)
        net.WriteUInt(count, 16)

        -- Send each zone
        for id, zone in pairs(self.stored) do
            net.WriteUInt(zone.id, 32)
            net.WriteString(zone.name)
            net.WriteString(zone.type)
            net.WriteInt(zone.priority, 32)
            net.WriteTable(zone.flags)
            net.WriteTable(zone.data)
            net.WriteString(zone.map)
            net.WriteString(zone.source)

            -- Send geometry based on type
            if ( zone.type == "box" ) then
                net.WriteVector(zone.mins)
                net.WriteVector(zone.maxs)
            elseif ( zone.type == "sphere" ) then
                net.WriteVector(zone.center)
                net.WriteFloat(zone.radius)
            elseif ( zone.type == "pvs" or zone.type == "trace" ) then
                net.WriteVector(zone.origin)
                net.WriteBool(zone.radius != nil)
                if ( zone.radius ) then
                    net.WriteFloat(zone.radius)
                end
            end
        end

    net.Send(ply)

    ax.util:PrintDebug("Zones synchronized to " .. ply:Nick() .. " (" .. count .. " zones)")
end

--- Sync to players when they join.
hook.Add("PlayerInitialSpawn", "ax.zones.sync", function(ply)
    timer.Simple(1, function()
        if ( IsValid(ply) ) then
            ax.zones:SyncToPlayer(ply)
        end
    end)
end)
