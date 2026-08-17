--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

---@class ax.zones
--- Zone system core library. Provides registration, CRUD operations, and type management for zones.

ax.zones = ax.zones or {}
ax.zones.types = ax.zones.types or {}
ax.zones.stored = ax.zones.stored or {}
ax.zones.nextId = ax.zones.nextId or 1

--- Register a zone type with validation and containment logic.
---@realm shared
---@param typeName string The unique identifier for this zone type (e.g., "box", "sphere", "pvs")
---@param impl table Implementation table with optional methods: Validate, AABB, Contains, Weight
---@usage ax.zones:RegisterType("box", { Validate = function(spec) ... end, Contains = function(spec, pos) ... end })
function ax.zones:RegisterType(typeName, impl)
    if ( !typeName or !impl ) then
        ax.util:PrintError("RegisterType requires typeName and impl.")
        return
    end

    self.types[typeName] = impl
    ax.util:PrintDebug("Registered zone type: " .. typeName)
end

--- Get a registered zone type implementation.
---@realm shared
---@param typeName string The zone type identifier
---@return table|nil # The type implementation or nil if not found
function ax.zones:GetType(typeName)
    return self.types[typeName]
end

--- Validate a zone spec against its type implementation.
---@realm shared
---@param spec table The zone specification to validate
---@return boolean success Whether validation passed
---@return string|nil error Error message if validation failed
function ax.zones:ValidateSpec(spec)
    if ( !spec ) then
        return false, "Zone spec is nil"
    end

    if ( !spec.name or spec.name == "" ) then
        return false, "Zone name is required and must be non-empty"
    end

    if ( !spec.type or !self.types[spec.type] ) then
        return false, "Invalid or missing zone type: " .. tostring(spec.type)
    end

    if ( !isnumber(spec.priority) ) then
        return false, "Priority must be a number"
    end

    local typeImpl = self.types[spec.type]
    if ( typeImpl.Validate ) then
        local ok, err = typeImpl.Validate(spec)
        if ( !ok ) then
            return false, err or "Type validation failed"
        end
    end

    return true
end

--- Add a new zone to the registry.
---@realm server
---@param spec table Zone specification with name, type, priority, flags, data, and geometry
---@return number|nil id The assigned zone ID, or nil on failure
---@return string|nil error Error message if addition failed
function ax.zones:Add(spec)
    if ( CLIENT ) then return end

    local ok, err = self:ValidateSpec(spec)
    if ( !ok ) then
        ax.util:PrintError("Zone validation failed: " .. err)
        return nil, err
    end

    -- Assign stable ID
    local id = self.nextId
    self.nextId = self.nextId + 1

    -- Build full zone record
    local zone = {
        id = id,
        name = spec.name,
        type = spec.type,
        priority = spec.priority or 0,
        flags = spec.flags or {},
        data = spec.data or {},
        source = spec.source or "runtime",
        map = game.GetMap(),
    }

    -- Copy geometry fields based on type
    if ( spec.type == "box" ) then
        zone.mins = spec.mins
        zone.maxs = spec.maxs
    elseif ( spec.type == "sphere" ) then
        zone.center = spec.center
        zone.radius = spec.radius
    elseif ( spec.type == "pvs" or spec.type == "trace" ) then
        zone.origin = spec.origin
        zone.radius = spec.radius -- optional
    end

    self.stored[id] = zone

    if ( SERVER ) then
        self:Save()
        self:Sync()
    end

    ax.util:PrintDebug("Added zone #" .. id .. " (" .. zone.name .. ")")
    return id
end

--- Update an existing zone.
---@realm server
---@param identifier number|string Zone ID or name
---@param patch table Fields to merge into the existing zone
---@return boolean success Whether the update succeeded
function ax.zones:Update(identifier, patch)
    if ( CLIENT ) then return false end
    if ( !identifier or !patch ) then return false end

    local zone = self:Get(identifier)
    if ( !zone ) then
        ax.util:PrintError("Zone not found: " .. tostring(identifier))
        return false
    end

    -- Merge patch (but not id or map)
    for k, v in pairs(patch) do
        if ( k != "id" and k != "map" ) then
            zone[k] = v
        end
    end

    -- Revalidate
    local ok, err = self:ValidateSpec(zone)
    if ( !ok ) then
        ax.util:PrintError("Zone update validation failed: " .. err)
        return false
    end

    if ( SERVER ) then
        self:Save()
        self:Sync()
    end

    ax.util:PrintDebug("Updated zone #" .. zone.id .. " (" .. zone.name .. ")")
    return true
end

--- Remove a zone from the registry.
---@realm server
---@param identifier number|string Zone ID or name
---@return boolean success Whether the removal succeeded
function ax.zones:Remove(identifier)
    if ( CLIENT ) then return false end
    if ( !identifier ) then return false end

    local zone = self:Get(identifier)
    if ( !zone ) then
        ax.util:PrintError("Zone not found: " .. tostring(identifier))
        return false
    end

    self.stored[zone.id] = nil

    if ( SERVER ) then
        self:Save()
        self:Sync()
    end

    ax.util:PrintDebug("Removed zone #" .. zone.id .. " (" .. zone.name .. ")")
    return true
end

--- Get a zone by ID or name.
---@realm shared
---@param identifier number|string Zone ID or name (supports partial match)
---@return table|nil # The zone spec or nil if not found
function ax.zones:Get(identifier)
    if ( !identifier ) then return nil end

    -- Try exact ID match first
    if ( isnumber(identifier) and self.stored[identifier] ) then
        return self.stored[identifier]
    end

    -- Try exact name match
    for id, zone in pairs(self.stored) do
        if ( zone.name == identifier ) then
            return zone
        end
    end

    -- Try partial name match
    if ( isstring(identifier) ) then
        for id, zone in pairs(self.stored) do
            if ( ax.util:FindString(zone.name, identifier) ) then
                return zone
            end
        end
    end

    return nil
end

--- Get all zones.
---@realm shared
---@return table # Table of zone IDs mapped to zone specs
function ax.zones:GetAll()
    return self.stored
end

--- Clear all zones (runtime only).
---@realm server
function ax.zones:Clear()
    if ( CLIENT ) then return end

    self.stored = {}
    self.nextId = 1

    if ( SERVER ) then
        self:Save()
        self:Sync()
    end

    ax.util:PrintDebug("All zones cleared.")
end
