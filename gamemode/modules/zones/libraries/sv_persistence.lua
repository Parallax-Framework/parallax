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

--- Load zones from disk for the current map.
-- @realm server
function ax.zones:Load()
    local mapName = game.GetMap()
    local dataKey = "zones_" .. mapName

    -- Reset state
    self.stored = {}
    self.nextId = 1

    local data = ax.data:Get(dataKey, nil)

    if ( !data ) then
        ax.util:PrintDebug("No zone data found for map " .. mapName .. ", starting fresh.")
        return
    end

    -- Restore nextId
    if ( data.nextId ) then
        self.nextId = data.nextId
    end

    -- Restore zones
    if ( data.items ) then
        for _, zone in ipairs(data.items) do
            if ( zone.id and zone.map == mapName ) then
                self.stored[zone.id] = zone
            end
        end
    end

    ax.util:PrintSuccess("Loaded " .. table.Count(self.stored) .. " zones for map " .. mapName)
end

--- Save runtime zones to disk for the current map.
-- @realm server
function ax.zones:Save()
    local mapName = game.GetMap()
    local dataKey = "zones_" .. mapName

    -- Collect only runtime zones for current map
    local items = {}
    for id, zone in pairs(self.stored) do
        if ( zone.source == "runtime" and zone.map == mapName ) then
            table.insert(items, zone)
        end
    end

    local data = {
        nextId = self.nextId,
        items = items,
    }

    ax.data:Set(dataKey, data, {
        scope = "map"
    })
    ax.util:PrintDebug("Saved " .. #items .. " runtime zones for map " .. mapName)
end

--- Load static zones from a list (not persisted).
-- @realm server
-- @tparam table zoneList Array of zone specs
function ax.zones:LoadStatic(zoneList)
    if ( !zoneList ) then return end

    local count = 0
    for _, spec in ipairs(zoneList) do
        -- Mark as static
        spec.source = "static"

        -- Use Add but skip save
        local ok, err = self:ValidateSpec(spec)
        if ( ok ) then
            local id = self.nextId
            self.nextId = self.nextId + 1

            local zone = {
                id = id,
                name = spec.name,
                type = spec.type,
                priority = spec.priority or 0,
                flags = spec.flags or {},
                data = spec.data or {},
                source = "static",
                map = game.GetMap(),
            }

            -- Copy geometry fields
            if ( spec.type == "box" ) then
                zone.mins = spec.mins
                zone.maxs = spec.maxs
            elseif ( spec.type == "sphere" ) then
                zone.center = spec.center
                zone.radius = spec.radius
            elseif ( spec.type == "pvs" or spec.type == "trace" ) then
                zone.origin = spec.origin
                zone.radius = spec.radius
            end

            self.stored[id] = zone
            count = count + 1
        else
            ax.util:PrintError("Failed to load static zone '" .. (spec.name or "unknown") .. "': " .. err)
        end
    end

    if ( count > 0 ) then
        ax.util:PrintSuccess("Loaded " .. count .. " static zones")
    end
end

--- Initialize zone system on server start.
hook.Add("InitPostEntity", "ax.zones.load", function()
    ax.zones:Load()
    ax.zones:Sync()
end)

--- Reload zones when gamemode is reloaded.
hook.Add("OnReloaded", "ax.zones.load", function()
    ax.zones:Load()
    ax.zones:Sync()
end)

ax.util:PrintDebug("Zone persistence system loaded")
