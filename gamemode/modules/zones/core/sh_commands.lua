--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- @module ax.zones

-- Helper function to get target position based on player's trace
local function GetTargetPosition(client)
    local trace = client:GetEyeTrace()
    return trace.HitPos
end

--[[
    Zone Box Command
    Usage: /ZoneBox <name> <priority> [size]
    Creates a box zone centered at the player's look position
]]
ax.command:Add("ZoneBox", {
    description = "Create a box zone at your look position",
    arguments = {
        { name = "name", type = ax.type.string },
        { name = "priority", type = ax.type.number },
        { name = "size", type = ax.type.number, optional = true },
    },
    OnRun = function(client, name, priority, size)
        size = size or 128
        local pos = GetTargetPosition(client)
        local halfSize = size / 2

        local id = ax.zones:Add({
            name = name,
            type = "box",
            priority = priority,
            mins = pos - Vector(halfSize, halfSize, halfSize),
            maxs = pos + Vector(halfSize, halfSize, halfSize),
            flags = {},
            data = { creator = client:SteamID() },
        })

        if ( id ) then
            return "Created box zone #" .. id .. " (" .. name .. ") at " .. tostring(pos)
        else
            return "Failed to create zone. Check console for errors."
        end
    end,
})

--[[
    Zone Box Custom Command
    Usage: /ZoneBoxCustom <name> <priority>
    Creates a box zone with custom bounds (uses two positions)
    First use sets min corner, second use sets max corner
]]
local boxCorners = {}
ax.command:Add("ZoneBoxCustom", {
    description = "Create a box zone with custom corners (use twice)",
    arguments = {
        { name = "name", type = ax.type.string, optional = true },
        { name = "priority", type = ax.type.number, optional = true },
    },
    OnRun = function(client, name, priority)
        local steamID = client:SteamID()
        local pos = GetTargetPosition(client)

        if ( !boxCorners[steamID] ) then
            -- First corner - require name
            if ( !name or name == "" ) then
                return "Error: Name is required for the first corner. Usage: /zoneboxcustom <name> <priority>"
            end

            boxCorners[steamID] = {
                name = name,
                priority = priority or 0,
                corner1 = pos,
            }
            return "First corner set at " .. tostring(pos) .. ". Use the command again to set the second corner."
        else
            -- Second corner - use stored data
            local data = boxCorners[steamID]
            local mins = Vector(
                math.min(data.corner1.x, pos.x),
                math.min(data.corner1.y, pos.y),
                math.min(data.corner1.z, pos.z)
            )
            local maxs = Vector(
                math.max(data.corner1.x, pos.x),
                math.max(data.corner1.y, pos.y),
                math.max(data.corner1.z, pos.z)
            )

            local id = ax.zones:Add({
                name = data.name,
                type = "box",
                priority = data.priority,
                mins = mins,
                maxs = maxs,
                flags = {},
                data = { creator = steamID },
            })

            boxCorners[steamID] = nil

            if ( id ) then
                return "Created box zone #" .. id .. " (" .. data.name .. ") from " .. tostring(mins) .. " to " .. tostring(maxs)
            else
                return "Failed to create zone. Check console for errors."
            end
        end
    end,
})

--[[
    Zone Sphere Command
    Usage: /ZoneSphere <name> <priority> <radius>
    Creates a sphere zone at the player's look position
]]
ax.command:Add("ZoneSphere", {
    description = "Create a sphere zone at your look position",
    arguments = {
        { name = "name", type = ax.type.string },
        { name = "priority", type = ax.type.number },
        { name = "radius", type = ax.type.number, optional = true },
    },
    OnRun = function(client, name, priority, radius)
        radius = radius or 128

        if ( radius <= 0 ) then
            return "Radius must be greater than 0."
        end

        local pos = GetTargetPosition(client)

        local id = ax.zones:Add({
            name = name,
            type = "sphere",
            priority = priority,
            center = pos,
            radius = radius,
            flags = {},
            data = { creator = client:SteamID() },
        })

        if ( id ) then
            return "Created sphere zone #" .. id .. " (" .. name .. ") at " .. tostring(pos) .. " with radius " .. radius
        else
            return "Failed to create zone. Check console for errors."
        end
    end,
})

--[[
    Zone PVS Command
    Usage: /ZonePVS <name> <priority> [radius]
    Creates a PVS (visibility) zone at the player's look position
]]
ax.command:Add("ZonePVS", {
    description = "Create a PVS zone at your look position",
    arguments = {
        { name = "name", type = ax.type.string },
        { name = "priority", type = ax.type.number },
        { name = "radius", type = ax.type.number, optional = true },
    },
    OnRun = function(client, name, priority, radius)
        local pos = GetTargetPosition(client)

        local spec = {
            name = name,
            type = "pvs",
            priority = priority,
            origin = pos,
            flags = {},
            data = { creator = client:SteamID() },
        }

        if ( radius and radius > 0 ) then
            spec.radius = radius
        end

        local id = ax.zones:Add(spec)

        if ( id ) then
            local radiusText = spec.radius and (" with radius " .. spec.radius) or ""
            return "Created PVS zone #" .. id .. " (" .. name .. ") at " .. tostring(pos) .. radiusText
        else
            return "Failed to create zone. Check console for errors."
        end
    end,
})

--[[
    Zone Trace Command
    Usage: /ZoneTrace <name> <priority> [radius]
    Creates a trace (line-of-sight) zone at the player's look position
]]
ax.command:Add("ZoneTrace", {
    description = "Create a trace zone at your look position",
    arguments = {
        { name = "name", type = ax.type.string },
        { name = "priority", type = ax.type.number },
        { name = "radius", type = ax.type.number, optional = true },
    },
    OnRun = function(client, name, priority, radius)
        local pos = GetTargetPosition(client)

        local spec = {
            name = name,
            type = "trace",
            priority = priority,
            origin = pos,
            flags = {},
            data = { creator = client:SteamID() },
        }

        if ( radius and radius > 0 ) then
            spec.radius = radius
        end

        local id = ax.zones:Add(spec)

        if ( id ) then
            local radiusText = spec.radius and (" with radius " .. spec.radius) or ""
            return "Created trace zone #" .. id .. " (" .. name .. ") at " .. tostring(pos) .. radiusText
        else
            return "Failed to create zone. Check console for errors."
        end
    end,
})

--[[
    Zone Remove Command
    Usage: /ZoneRemove <id or name>
    Removes a zone by ID or name
]]
ax.command:Add("ZoneRemove", {
    description = "Remove a zone by ID or name",
    arguments = {
        { name = "identifier", type = ax.type.string },
    },
    OnRun = function(client, identifier)
        local id = tonumber(identifier) or identifier
        local zone = ax.zones:Get(id)

        if ( !zone ) then
            return "Zone not found: " .. identifier
        end

        local zoneName = zone.name
        local zoneId = zone.id

        if ( ax.zones:Remove(id) ) then
            return "Removed zone #" .. zoneId .. " (" .. zoneName .. ")"
        else
            return "Failed to remove zone. Check console for errors."
        end
    end,
})

--[[
    Zone List Command
    Usage: /ZoneList
    Lists all zones to console
]]
ax.command:Add("ZoneList", {
    description = "List all zones to console",
    OnRun = function(client)
        ax.zones:List()
        return "Zone list printed to console."
    end,
})

--[[
    Zone Info Command
    Usage: /ZoneInfo <id or name>
    Shows detailed information about a zone
]]
ax.command:Add("ZoneInfo", {
    description = "Show detailed information about a zone",
    arguments = {
        { name = "identifier", type = ax.type.string },
    },
    OnRun = function(client, identifier)
        local id = tonumber(identifier) or identifier
        local zone = ax.zones:Get(id)

        if ( !zone ) then
            return "Zone not found: " .. identifier
        end

        print("\n=== Zone #" .. zone.id .. " ===")
        print("Name: " .. zone.name)
        print("Type: " .. zone.type)
        print("Priority: " .. zone.priority)
        print("Source: " .. zone.source)
        print("Map: " .. zone.map)

        if ( zone.type == "box" ) then
            print("Mins: " .. tostring(zone.mins))
            print("Maxs: " .. tostring(zone.maxs))
        elseif ( zone.type == "sphere" ) then
            print("Center: " .. tostring(zone.center))
            print("Radius: " .. zone.radius)
        elseif ( zone.type == "pvs" or zone.type == "trace" ) then
            print("Origin: " .. tostring(zone.origin))
            if ( zone.radius ) then
                print("Radius: " .. zone.radius)
            end
        end

        print("Flags: " .. table.ToString(zone.flags, "Flags", true))
        print("Data: " .. table.ToString(zone.data, "Data", true))
        print("==================\n")

        return "Zone info printed to console."
    end,
})

--[[
    Zone Debug Command
    Usage: /ZoneDebug
    Toggles zone debug visualization
]]
local debugPlayers = {}
ax.command:Add("ZoneDebug", {
    description = "Toggle zone debug visualization",
    OnRun = function(client)
        local steamID = client:SteamID()

        if ( debugPlayers[steamID] ) then
            ax.zones:StopDrawDebug(client)
            debugPlayers[steamID] = nil
            return "Zone debug visualization disabled."
        else
            ax.zones:DrawDebug(client)
            debugPlayers[steamID] = true
            return "Zone debug visualization enabled."
        end
    end,
})

--[[
    Zone Update Priority Command
    Usage: /ZonePriority <id or name> <priority>
    Updates a zone's priority
]]
ax.command:Add("ZonePriority", {
    description = "Update a zone's priority",
    arguments = {
        { name = "identifier", type = ax.type.string },
        { name = "priority", type = ax.type.number },
    },
    OnRun = function(client, identifier, priority)
        local id = tonumber(identifier) or identifier
        local zone = ax.zones:Get(id)

        if ( !zone ) then
            return "Zone not found: " .. identifier
        end

        if ( ax.zones:Update(id, { priority = priority }) ) then
            return "Updated zone #" .. zone.id .. " (" .. zone.name .. ") priority to " .. priority
        else
            return "Failed to update zone. Check console for errors."
        end
    end,
})

--[[
    Zone Teleport Command
    Usage: /ZoneTp <id or name>
    Teleports the player to a zone's center
]]
ax.command:Add("ZoneTp", {
    description = "Teleport to a zone's center",
    arguments = {
        { name = "identifier", type = ax.type.string },
    },
    OnRun = function(client, identifier)
        local id = tonumber(identifier) or identifier
        local zone = ax.zones:Get(id)

        if ( !zone ) then
            return "Zone not found: " .. identifier
        end

        local pos
        if ( zone.type == "box" ) then
            pos = (zone.mins + zone.maxs) / 2
        elseif ( zone.type == "sphere" ) then
            pos = zone.center
        elseif ( zone.type == "pvs" or zone.type == "trace" ) then
            pos = zone.origin
        end

        if ( pos ) then
            client:SetPos(pos + Vector(0, 0, 10))
            return "Teleported to zone #" .. zone.id .. " (" .. zone.name .. ")"
        else
            return "Could not determine zone position."
        end
    end,
})

--[[
    Zone Clear Command
    Usage: /ZoneClear
    Clears all runtime zones (requires confirmation)
]]
local clearConfirm = {}
ax.command:Add("ZoneClear", {
    description = "Clear all runtime zones (use twice to confirm)",
    OnRun = function(client)
        local steamID = client:SteamID()

        if ( !clearConfirm[steamID] ) then
            clearConfirm[steamID] = CurTime()

            timer.Simple(5, function()
                if ( clearConfirm[steamID] ) then
                    clearConfirm[steamID] = nil
                end
            end)

            return "WARNING: This will delete all runtime zones! Use the command again within 5 seconds to confirm."
        else
            ax.zones:Clear()
            clearConfirm[steamID] = nil
            return "All runtime zones cleared."
        end
    end,
})

-- Console commands (for server console)
concommand.Add("ax_zone_list", function(client, cmd, args)
    if ( IsValid(client) ) then return end -- Server only
    ax.zones:List()
end, nil, "List all zones")

concommand.Add("ax_zone_clear", function(client, cmd, args)
    if ( IsValid(client) ) then return end -- Server only
    ax.zones:Clear()
    print("All runtime zones cleared.")
end, nil, "Clear all runtime zones")

concommand.Add("ax_zone_reload", function(client, cmd, args)
    if ( IsValid(client) ) then return end -- Server only
    ax.zones:Load()
    print("Zones reloaded from disk.")
end, nil, "Reload zones from disk")
