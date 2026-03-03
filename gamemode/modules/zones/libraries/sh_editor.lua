--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- @module ax.zones.editor

ax.zones = ax.zones or {}
ax.zones.editor = ax.zones.editor or {}

local editor = ax.zones.editor

local function Phrase(key, ...)
    if ( ax and ax.localization and ax.localization.GetPhrase ) then
        return ax.localization:GetPhrase(key, ...)
    end

    if ( select("#", ...) > 0 ) then
        return string.format(tostring(key), ...)
    end

    return tostring(key)
end

editor.types = editor.types or {
    box = {
        label = "zones.type.box",
        summary = "zones.type.box.summary",
        radius = false,
    },
    sphere = {
        label = "zones.type.sphere",
        summary = "zones.type.sphere.summary",
        radius = true,
    },
    pvs = {
        label = "zones.type.pvs",
        summary = "zones.type.pvs.summary",
        radius = true,
    },
    trace = {
        label = "zones.type.trace",
        summary = "zones.type.trace.summary",
        radius = true,
    },
}

editor.typeOrder = editor.typeOrder or { "box", "sphere", "pvs", "trace" }
editor.maxStringLength = editor.maxStringLength or 96
editor.maxKeyLength = editor.maxKeyLength or 48
editor.maxEntries = editor.maxEntries or 48
editor.maxDepth = editor.maxDepth or 4
editor.maxRadius = editor.maxRadius or 32768
editor.maxCoordinate = editor.maxCoordinate or 131072
editor.defaultPriority = editor.defaultPriority or 0
editor.defaultRadius = editor.defaultRadius or 128
editor.defaultBoxExtent = editor.defaultBoxExtent or 64

local function GetConfigNumber(key, fallback, minValue, maxValue)
    local value = tonumber(fallback) or 0

    if ( ax and ax.config and ax.config.Get ) then
        value = tonumber(ax.config:Get(key, fallback)) or value
    end

    if ( minValue != nil ) then
        value = math.max(value, minValue)
    end

    if ( maxValue != nil ) then
        value = math.min(value, maxValue)
    end

    return value
end

local function ClampCoordinate(value)
    return math.Clamp(math.Round(value or 0, 2), -editor.maxCoordinate, editor.maxCoordinate)
end

local function ClampNumber(value, minValue, maxValue)
    value = tonumber(value)
    if ( !isnumber(value) ) then return nil end
    if ( value != value ) then return nil end

    value = math.Round(value, 2)

    if ( minValue != nil ) then
        value = math.max(value, minValue)
    end

    if ( maxValue != nil ) then
        value = math.min(value, maxValue)
    end

    return value
end

function editor:CanUse(client)
    return ax.util:IsValidPlayer(client) and client:IsAdmin()
end

function editor:GetType(typeName)
    if ( !isstring(typeName) ) then return nil end
    return self.types[string.lower(string.Trim(typeName))]
end

function editor:GetTypeLabel(typeName)
    local data = self:GetType(typeName)
    return data and Phrase(data.label) or tostring(typeName or "Unknown")
end

function editor:GetSortedTypes()
    return self.typeOrder
end

function editor:NormalizeType(typeName)
    if ( !isstring(typeName) ) then return nil end

    typeName = string.lower(string.Trim(typeName))

    if ( !self.types[typeName] ) then
        return nil
    end

    return typeName
end

function editor:SanitizeString(value, maxLength)
    if ( value == nil ) then return nil end

    value = tostring(value)
    value = string.Trim(value)

    if ( value == "" ) then
        return nil
    end

    return string.sub(value, 1, maxLength or self.maxStringLength)
end

function editor:SanitizeVector(value)
    if ( !isvector(value) ) then return nil end

    return Vector(
        ClampCoordinate(value.x),
        ClampCoordinate(value.y),
        ClampCoordinate(value.z)
    )
end

function editor:SanitizeAngle(value)
    if ( !isangle(value) ) then return nil end

    return Angle(
        math.Round(value.p or 0, 2),
        math.Round(value.y or 0, 2),
        math.Round(value.r or 0, 2)
    )
end

function editor:SanitizeValue(value, depth)
    depth = depth or 0

    if ( depth > self.maxDepth ) then
        return nil
    end

    if ( isbool(value) ) then
        return value
    end

    if ( isstring(value) ) then
        return string.sub(value, 1, self.maxStringLength)
    end

    if ( isnumber(value) ) then
        return ClampNumber(value, -self.maxCoordinate, self.maxCoordinate)
    end

    if ( isvector(value) ) then
        return self:SanitizeVector(value)
    end

    if ( isangle(value) ) then
        return self:SanitizeAngle(value)
    end

    if ( !istable(value) ) then
        return nil
    end

    local sanitized = {}
    local count = 0
    local sequential = true
    local maxIndex = 0

    for key in pairs(value) do
        if ( !isnumber(key) or key < 1 or math.floor(key) != key ) then
            sequential = false
            break
        end

        maxIndex = math.max(maxIndex, key)
    end

    if ( sequential ) then
        for i = 1, math.min(maxIndex, self.maxEntries) do
            local child = self:SanitizeValue(value[i], depth + 1)
            if ( child != nil ) then
                sanitized[#sanitized + 1] = child
                count = count + 1
            end
        end

        return sanitized
    end

    for key, childValue in pairs(value) do
        if ( count >= self.maxEntries ) then
            break
        end

        if ( !isstring(key) and !isnumber(key) ) then
            continue
        end

        local sanitizedKey = key
        if ( isstring(key) ) then
            sanitizedKey = self:SanitizeString(key, self.maxKeyLength)
        end

        if ( sanitizedKey == nil ) then
            continue
        end

        local sanitizedValue = self:SanitizeValue(childValue, depth + 1)
        if ( sanitizedValue != nil ) then
            sanitized[sanitizedKey] = sanitizedValue
            count = count + 1
        end
    end

    return sanitized
end

function editor:SanitizePriority(value)
    return ClampNumber(value, -999999, 999999) or self:GetDefaultPriority()
end

function editor:SanitizeRadius(value, allowZero)
    local minValue = allowZero and 0 or 0.01
    return ClampNumber(value, minValue, self:GetMaxRadius())
end

function editor:GetDefaultPriority()
    return GetConfigNumber("zones.editor.default_priority", self.defaultPriority, -999999, 999999)
end

function editor:GetDefaultRadius()
    return GetConfigNumber("zones.editor.default_radius", self.defaultRadius, 1, self:GetMaxRadius())
end

function editor:GetDefaultBoxExtent()
    return GetConfigNumber("zones.editor.default_box_extent", self.defaultBoxExtent, 1, self.maxCoordinate)
end

function editor:GetMaxRadius()
    return GetConfigNumber("zones.editor.max_radius", self.maxRadius, 1, self.maxCoordinate)
end

function editor:BuildEmptyDraft(typeName)
    typeName = self:NormalizeType(typeName) or "box"

    local draft = {
        id = nil,
        name = Phrase("zones.common.new_zone"),
        type = typeName,
        priority = self:GetDefaultPriority(),
        flags = {},
        data = {},
    }

    if ( typeName == "box" ) then
        local extent = self:GetDefaultBoxExtent()
        draft.cornerA = Vector(-extent, -extent, -extent)
        draft.cornerB = Vector(extent, extent, extent)
    elseif ( typeName == "sphere" ) then
        draft.center = vector_origin
        draft.radius = self:GetDefaultRadius()
    elseif ( typeName == "pvs" or typeName == "trace" ) then
        draft.origin = vector_origin
        draft.radius = self:GetDefaultRadius()
    end

    return draft
end

function editor:NormalizeBoxCorners(cornerA, cornerB)
    cornerA = self:SanitizeVector(cornerA)
    cornerB = self:SanitizeVector(cornerB)

    if ( !cornerA or !cornerB ) then
        return nil, nil
    end

    return Vector(
        math.min(cornerA.x, cornerB.x),
        math.min(cornerA.y, cornerB.y),
        math.min(cornerA.z, cornerB.z)
    ), Vector(
        math.max(cornerA.x, cornerB.x),
        math.max(cornerA.y, cornerB.y),
        math.max(cornerA.z, cornerB.z)
    )
end

function editor:SanitizeDraft(payload)
    if ( !istable(payload) ) then
        return nil, "Invalid zone payload."
    end

    local typeName = self:NormalizeType(payload.type)
    if ( !typeName ) then
        return nil, "Invalid zone type."
    end

    local sanitized = {
        name = self:SanitizeString(payload.name, self.maxStringLength),
        type = typeName,
        priority = self:SanitizePriority(payload.priority),
        flags = self:SanitizeValue(payload.flags or {}, 0) or {},
        data = self:SanitizeValue(payload.data or {}, 0) or {},
    }

    if ( !sanitized.name ) then
        return nil, "Zone name is required."
    end

    if ( typeName == "box" ) then
        local mins, maxs = self:NormalizeBoxCorners(payload.cornerA or payload.mins, payload.cornerB or payload.maxs)
        if ( !mins or !maxs ) then
            return nil, "Box zones require two valid corners."
        end

        sanitized.mins = mins
        sanitized.maxs = maxs
    elseif ( typeName == "sphere" ) then
        sanitized.center = self:SanitizeVector(payload.center)
        sanitized.radius = self:SanitizeRadius(payload.radius)

        if ( !sanitized.center ) then
            return nil, "Sphere zones require a valid center."
        end

        if ( !sanitized.radius ) then
            return nil, "Sphere zones require a radius greater than 0."
        end
    elseif ( typeName == "pvs" or typeName == "trace" ) then
        sanitized.origin = self:SanitizeVector(payload.origin)
        sanitized.radius = self:SanitizeRadius(payload.radius, true)

        if ( !sanitized.origin ) then
            return nil, string.format("%s zones require a valid origin.", self:GetTypeLabel(typeName))
        end
    end

    return sanitized
end

function editor:ToUpdatePatch(spec)
    if ( !istable(spec) ) then return nil end

    local patch = {
        name = spec.name,
        type = spec.type,
        priority = spec.priority,
        flags = table.Copy(spec.flags or {}),
        data = table.Copy(spec.data or {}),
        mins = nil,
        maxs = nil,
        center = nil,
        origin = nil,
        radius = nil,
    }

    if ( spec.type == "box" ) then
        patch.mins = spec.mins
        patch.maxs = spec.maxs
    elseif ( spec.type == "sphere" ) then
        patch.center = spec.center
        patch.radius = spec.radius
    elseif ( spec.type == "pvs" or spec.type == "trace" ) then
        patch.origin = spec.origin
        patch.radius = spec.radius
    end

    return patch
end

function editor:CopyZone(zone)
    if ( !istable(zone) ) then return nil end

    local copy = {
        id = zone.id,
        name = zone.name,
        type = zone.type,
        priority = zone.priority or 0,
        flags = table.Copy(zone.flags or {}),
        data = table.Copy(zone.data or {}),
        source = zone.source,
        map = zone.map,
    }

    if ( zone.type == "box" ) then
        copy.mins = zone.mins and Vector(zone.mins.x, zone.mins.y, zone.mins.z) or nil
        copy.maxs = zone.maxs and Vector(zone.maxs.x, zone.maxs.y, zone.maxs.z) or nil
        copy.cornerA = copy.mins and Vector(copy.mins.x, copy.mins.y, copy.mins.z) or nil
        copy.cornerB = copy.maxs and Vector(copy.maxs.x, copy.maxs.y, copy.maxs.z) or nil
    elseif ( zone.type == "sphere" ) then
        copy.center = zone.center and Vector(zone.center.x, zone.center.y, zone.center.z) or nil
        copy.radius = zone.radius
    elseif ( zone.type == "pvs" or zone.type == "trace" ) then
        copy.origin = zone.origin and Vector(zone.origin.x, zone.origin.y, zone.origin.z) or nil
        copy.radius = zone.radius
    end

    return copy
end

function editor:GetZoneAnchor(zone)
    if ( !istable(zone) ) then return nil end

    if ( zone.type == "box" and isvector(zone.mins) and isvector(zone.maxs) ) then
        return (zone.mins + zone.maxs) / 2
    end

    if ( zone.type == "sphere" and isvector(zone.center) ) then
        return zone.center
    end

    if ( (zone.type == "pvs" or zone.type == "trace") and isvector(zone.origin) ) then
        return zone.origin
    end

    return nil
end

function editor:GetZoneBounds(zone)
    if ( !istable(zone) ) then return nil, nil end

    if ( zone.type == "box" and isvector(zone.mins) and isvector(zone.maxs) ) then
        return zone.mins, zone.maxs
    end

    if ( zone.type == "sphere" and isvector(zone.center) and isnumber(zone.radius) ) then
        local radius = math.abs(zone.radius)
        local offset = Vector(radius, radius, radius)
        return zone.center - offset, zone.center + offset
    end

    if ( (zone.type == "pvs" or zone.type == "trace") and isvector(zone.origin) ) then
        local radius = math.max(tonumber(zone.radius) or 32, 32)
        local offset = Vector(radius, radius, radius)
        return zone.origin - offset, zone.origin + offset
    end

    return nil, nil
end

function editor:DistanceToZone(zone, pos)
    if ( !istable(zone) or !isvector(pos) ) then
        return math.huge
    end

    if ( zone.type == "box" and isvector(zone.mins) and isvector(zone.maxs) ) then
        local closest = Vector(
            math.Clamp(pos.x, zone.mins.x, zone.maxs.x),
            math.Clamp(pos.y, zone.mins.y, zone.maxs.y),
            math.Clamp(pos.z, zone.mins.z, zone.maxs.z)
        )

        return pos:Distance(closest)
    end

    if ( zone.type == "sphere" and isvector(zone.center) and isnumber(zone.radius) ) then
        return math.max(0, pos:Distance(zone.center) - zone.radius)
    end

    if ( (zone.type == "pvs" or zone.type == "trace") and isvector(zone.origin) ) then
        local radius = tonumber(zone.radius)
        if ( radius and radius > 0 ) then
            return math.max(0, pos:Distance(zone.origin) - radius)
        end

        return pos:Distance(zone.origin)
    end

    local anchor = self:GetZoneAnchor(zone)
    return anchor and pos:Distance(anchor) or math.huge
end

function editor:GetTypeSummary(zone)
    if ( !istable(zone) ) then return Phrase("zones.summary.none") end

    if ( zone.type == "box" and isvector(zone.mins) and isvector(zone.maxs) ) then
        local size = zone.maxs - zone.mins
        return Phrase("zones.summary.box", size.x, size.y, size.z)
    end

    if ( zone.type == "sphere" and isnumber(zone.radius) ) then
        return Phrase("zones.summary.sphere", zone.radius)
    end

    if ( zone.type == "pvs" or zone.type == "trace" ) then
        if ( zone.radius and zone.radius > 0 ) then
            return Phrase("zones.summary.radial", self:GetTypeLabel(zone.type), zone.radius)
        end

        return Phrase("zones.summary.origin_only", self:GetTypeLabel(zone.type))
    end

    return self:GetTypeLabel(zone.type)
end
