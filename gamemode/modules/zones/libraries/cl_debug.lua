--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

if ( SERVER ) then return end

-- @module ax.zones

ax.zones = ax.zones or {}
local cache = {
    nextRefresh = 0,
    snapshot = nil,
}

local COLOR_RUNTIME = Color(72, 196, 150, 95)
local COLOR_STATIC = Color(92, 146, 255, 95)
local COLOR_VISIBLE = Color(80, 200, 255, 150)
local COLOR_TRACE = Color(255, 220, 92, 170)
local COLOR_PHYSICAL = Color(110, 230, 125, 185)
local COLOR_DOMINANT = Color(255, 162, 72, 230)
local COLOR_TARGET = Color(255, 255, 255, 230)
local COLOR_TEXT_SHADOW = Color(0, 0, 0, 220)
local COLOR_PANEL = Color(6, 10, 18, 210)
local COLOR_PANEL_BORDER = Color(120, 170, 255, 45)
local COLOR_PANEL_TITLE = Color(255, 255, 255)
local COLOR_PANEL_TEXT = Color(225, 230, 236)
local COLOR_PANEL_MUTED = Color(156, 168, 182)

local function Phrase(key, ...)
    return ax.localization:GetPhrase(key, ...)
end

local function GetSourceLabel(source)
    local key = "zones.source." .. string.lower(tostring(source or "runtime"))

    return Phrase(key)
end

local function GetClient()
    return ax.client or LocalPlayer()
end

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

local function GetConfigBool(key, fallback)
    if ( ax and ax.config and ax.config.Get ) then
        return ax.config:Get(key, fallback) != false
    end

    return fallback != false
end

local function GetOptionNumber(key, fallback, minValue, maxValue)
    local value = tonumber(fallback) or 0

    if ( ax and ax.option and ax.option.Get ) then
        value = tonumber(ax.option:Get(key, fallback)) or value
    end

    if ( minValue != nil ) then
        value = math.max(value, minValue)
    end

    if ( maxValue != nil ) then
        value = math.min(value, maxValue)
    end

    return value
end

local function GetOptionBool(key, fallback)
    if ( ax and ax.option and ax.option.Get ) then
        return ax.option:Get(key, fallback) != false
    end

    return fallback != false
end

local function IsDebugActive()
    local client = GetClient()
    if ( !ax.util:IsValidPlayer(client) or !client:IsAdmin() ) then return false end
    if ( !GetConfigBool("zones.debug.enabled", true) ) then return false end

    return GetOptionBool("zones.debug.active", false)
end

local function CountEntries(container)
    if ( !istable(container) ) then return 0 end

    local count = 0
    for _ in pairs(container) do
        count = count + 1
    end

    return count
end

local function BuildLookup(list)
    local lookup = {}

    for i = 1, #list do
        local zone = list[i]
        if ( zone and zone.id ) then
            lookup[zone.id] = zone
        end
    end

    return lookup
end

local function GetZoneAnchor(zone)
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

local function DistanceToZone(zone, pos)
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

    local anchor = GetZoneAnchor(zone)
    return anchor and pos:Distance(anchor) or math.huge
end

local function DrawZoneGeometry(zone, color, outlineAlpha)
    if ( zone.type == "box" and isvector(zone.mins) and isvector(zone.maxs) ) then
        local center = (zone.mins + zone.maxs) / 2
        render.DrawWireframeBox(center, angle_zero, zone.mins - center, zone.maxs - center, color, true)
        return
    end

    if ( zone.type == "sphere" and isvector(zone.center) and isnumber(zone.radius) ) then
        render.DrawWireframeSphere(zone.center, zone.radius, 18, 18, color, true)
        return
    end

    if ( (zone.type == "pvs" or zone.type == "trace") and isvector(zone.origin) ) then
        render.DrawWireframeSphere(zone.origin, 22, 10, 10, color, true)

        if ( zone.radius and zone.radius > 0 ) then
            render.DrawWireframeSphere(zone.origin, zone.radius, 16, 16, Color(color.r, color.g, color.b, outlineAlpha or 48), true)
        end

        if ( zone.type == "trace" ) then
            local crossSize = 18
            render.DrawLine(zone.origin + Vector(crossSize, 0, 0), zone.origin - Vector(crossSize, 0, 0), color, true)
            render.DrawLine(zone.origin + Vector(0, crossSize, 0), zone.origin - Vector(0, crossSize, 0), color, true)
            render.DrawLine(zone.origin + Vector(0, 0, crossSize), zone.origin - Vector(0, 0, crossSize), color, true)
        end
    end
end

local function DrawZoneLabel(zone, color)
    local anchor = GetZoneAnchor(zone)
    if ( !isvector(anchor) ) then return end

    local screen = anchor:ToScreen()
    if ( !screen.visible ) then return end

    local lineOne = string.format("%s  #%d", zone.name or Phrase("zones.common.zone"), zone.id or 0)
    local lineTwo = Phrase("zones.common.type_priority", ax.zones.editor:GetTypeLabel(zone.type), zone.priority or 0)

    draw.SimpleText(lineOne, "ax.small.bold", screen.x + 1, screen.y + 1, COLOR_TEXT_SHADOW, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    draw.SimpleText(lineOne, "ax.small.bold", screen.x, screen.y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    draw.SimpleText(lineTwo, "ax.small", screen.x + 1, screen.y + 16, COLOR_TEXT_SHADOW, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText(lineTwo, "ax.small", screen.x, screen.y + 15, Color(238, 242, 247, math.min(color.a + 20, 255)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

local function GetEffectiveDrawDistance()
    local configDistance = GetConfigNumber("zones.debug.draw_distance", 3500, 256, 20000)
    local optionDistance = GetOptionNumber("zones.debug.distance", 2500, 256, 20000)

    return math.min(configDistance, optionDistance)
end

local function GetEffectiveMaxEntries()
    local configEntries = math.floor(GetConfigNumber("zones.debug.max_entries", 6, 1, 16))
    local optionEntries = math.floor(GetOptionNumber("zones.debug.entries", 4, 1, 16))

    return math.min(configEntries, optionEntries)
end

local function FindTargetZone(eyePos, hitPos, drawDistanceSqr, includeStatic)
    if ( !isvector(hitPos) ) then return nil end

    local bestZone = nil
    local bestScore = math.huge
    local tolerance = GetConfigNumber("zones.debug.target_tolerance", 192, 16, 1024)

    for _, zone in pairs(ax.zones.stored or {}) do
        if ( !includeStatic and zone.source == "static" ) then
            continue
        end

        local anchor = GetZoneAnchor(zone)
        if ( !isvector(anchor) ) then
            continue
        end

        local distToEye = anchor:DistToSqr(eyePos)
        if ( distToEye > drawDistanceSqr ) then
            continue
        end

        local distance = DistanceToZone(zone, hitPos)
        if ( distance > tolerance ) then
            continue
        end

        local score = distance + math.sqrt(distToEye) * 0.05

        if ( score < bestScore ) then
            bestScore = score
            bestZone = zone
        end
    end

    return bestZone
end

local function GetZoneColor(zone, snapshot)
    if ( snapshot.target and snapshot.target.id == zone.id ) then
        return COLOR_TARGET
    end

    if ( snapshot.dominant and snapshot.dominant.id == zone.id ) then
        return COLOR_DOMINANT
    end

    if ( snapshot.physicalLookup[zone.id] ) then
        return COLOR_PHYSICAL
    end

    if ( snapshot.visibleLookup[zone.id] ) then
        return zone.type == "trace" and COLOR_TRACE or COLOR_VISIBLE
    end

    return zone.source == "static" and COLOR_STATIC or COLOR_RUNTIME
end

local function BuildSnapshot()
    local client = GetClient()
    if ( !ax.util:IsValidPlayer(client) ) then return nil end

    local tracking = ax.zones:GetClientTracking() or {}
    local physical = tracking.physical or {}
    local visible = tracking.visible or {}
    local dominant = tracking.dominant
    local includeStatic = GetOptionBool("zones.debug.static", true)
    local drawDistance = GetEffectiveDrawDistance()
    local drawDistanceSqr = drawDistance * drawDistance
    local trace = client:GetEyeTrace()
    local target = nil

    if ( GetOptionBool("zones.debug.target", true) ) then
        target = FindTargetZone(client:EyePos(), trace and trace.HitPos or nil, drawDistanceSqr, includeStatic)
    end

    local total = 0
    local runtime = 0
    local static = 0

    for _, zone in pairs(ax.zones.stored or {}) do
        total = total + 1

        if ( zone.source == "static" ) then
            static = static + 1
        else
            runtime = runtime + 1
        end
    end

    return {
        client = client,
        eyePos = client:EyePos(),
        physical = physical,
        visible = visible,
        dominant = dominant,
        target = target,
        physicalLookup = BuildLookup(physical),
        visibleLookup = BuildLookup(visible),
        drawDistanceSqr = drawDistanceSqr,
        includeStatic = includeStatic,
        counts = {
            total = total,
            runtime = runtime,
            static = static,
        },
    }
end

local function GetSnapshot(forceRefresh)
    if ( !IsDebugActive() ) then
        cache.snapshot = nil
        cache.nextRefresh = 0
        return nil
    end

    if ( !forceRefresh and cache.snapshot and cache.nextRefresh > CurTime() ) then
        return cache.snapshot
    end

    cache.snapshot = BuildSnapshot()
    cache.nextRefresh = CurTime() + 0.1

    return cache.snapshot
end

local function FormatZoneSummary(zone, includeWeight)
    if ( !istable(zone) ) then
        return Phrase("zones.common.none")
    end

    local summary = Phrase(
        "zones.debug.summary",
        zone.id or 0,
        zone.name or Phrase("zones.common.unnamed"),
        ax.zones.editor:GetTypeLabel(zone.type),
        zone.priority or 0,
        GetSourceLabel(zone.source),
        CountEntries(zone.flags),
        CountEntries(zone.data)
    )

    if ( includeWeight and zone._weight != nil ) then
        summary = summary .. Phrase("zones.debug.weight", tonumber(zone._weight) or 0)
    end

    return summary
end

local function AddLine(lines, text, color, font)
    lines[#lines + 1] = {
        text = text,
        color = color or COLOR_PANEL_TEXT,
        font = font or "ax.small",
    }
end

local function DrawDebugHUD(snapshot)
    if ( !GetOptionBool("zones.debug.hud", true) ) then return end

    local maxEntries = GetEffectiveMaxEntries()
    local lines = {}

    AddLine(lines, Phrase("zones.debug.counts", snapshot.counts.total, snapshot.counts.runtime, snapshot.counts.static), COLOR_PANEL_MUTED)
    AddLine(lines, Phrase("zones.debug.dominant", FormatZoneSummary(snapshot.dominant, false)), snapshot.dominant and COLOR_DOMINANT or COLOR_PANEL_MUTED, snapshot.dominant and "ax.small.bold" or "ax.small")
    AddLine(lines, Phrase("zones.debug.target", FormatZoneSummary(snapshot.target, false)), snapshot.target and COLOR_TARGET or COLOR_PANEL_MUTED, snapshot.target and "ax.small.bold" or "ax.small")

    AddLine(lines, Phrase("zones.debug.physical", #snapshot.physical), COLOR_PHYSICAL, "ax.small.bold")
    if ( #snapshot.physical == 0 ) then
        AddLine(lines, Phrase("zones.debug.empty_entry"), COLOR_PANEL_MUTED)
    else
        for i = 1, math.min(#snapshot.physical, maxEntries) do
            AddLine(lines, "  " .. FormatZoneSummary(snapshot.physical[i], false), COLOR_PHYSICAL)
        end
    end

    AddLine(lines, Phrase("zones.debug.visible", #snapshot.visible), COLOR_VISIBLE, "ax.small.bold")
    if ( #snapshot.visible == 0 ) then
        AddLine(lines, Phrase("zones.debug.empty_entry"), COLOR_PANEL_MUTED)
    else
        for i = 1, math.min(#snapshot.visible, maxEntries) do
            local zone = snapshot.visible[i]
            local color = zone.type == "trace" and COLOR_TRACE or COLOR_VISIBLE
            AddLine(lines, "  " .. FormatZoneSummary(zone, true), color)
        end
    end

    local width = 470
    local x = ax.util:ScreenScale(8)
    local padding = 12
    local titleHeight = 22
    local lineHeight = 18
    local height = padding * 2 + titleHeight + (#lines * lineHeight) + 4
    local y = ScrH() - height - ax.util:ScreenScaleH(8)

    -- Not a fan of the panel background, but it helps with readability sometimes. Maybe add an option to disable it? Also the width isnt accurate sometimes.
    -- surface.SetDrawColor(COLOR_PANEL)
    -- surface.DrawRect(x, y, width, height)

    -- surface.SetDrawColor(COLOR_PANEL_BORDER)
    -- surface.DrawOutlinedRect(x, y, width, height, 1)

    draw.SimpleText(Phrase("zones.debug.title"), "ax.medium.bold", x + padding, y + padding - 2, COLOR_PANEL_TITLE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local lineY = y + padding + titleHeight
    for i = 1, #lines do
        local entry = lines[i]

        draw.SimpleText(entry.text, entry.font, x + padding + 1, lineY + 1, COLOR_TEXT_SHADOW, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(entry.text, entry.font, x + padding, lineY, entry.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        lineY = lineY + lineHeight
    end
end

hook.Add("PostDrawOpaqueRenderables", "ax.zones.debug.world", function()
    if ( !IsDebugActive() ) then return end
    if ( !GetOptionBool("zones.debug.world", true) ) then return end

    local snapshot = GetSnapshot()
    if ( !snapshot ) then return end

    for _, zone in pairs(ax.zones.stored or {}) do
        if ( !snapshot.includeStatic and zone.source == "static" ) then
            continue
        end

        local anchor = GetZoneAnchor(zone)
        if ( !isvector(anchor) or anchor:DistToSqr(snapshot.eyePos) > snapshot.drawDistanceSqr ) then
            continue
        end

        DrawZoneGeometry(zone, GetZoneColor(zone, snapshot), 52)
    end

    if ( snapshot.target ) then
        local anchor = GetZoneAnchor(snapshot.target)
        if ( isvector(anchor) ) then
            render.DrawLine(snapshot.eyePos, anchor, Color(255, 255, 255, 120), true)
        end
    end
end)

hook.Add("HUDPaint", "ax.zones.debug.hud", function()
    if ( !IsDebugActive() ) then return end

    local snapshot = GetSnapshot()
    if ( !snapshot ) then return end

    if ( GetOptionBool("zones.debug.labels", true) ) then
        for _, zone in pairs(ax.zones.stored or {}) do
            if ( !snapshot.includeStatic and zone.source == "static" ) then
                continue
            end

            local anchor = GetZoneAnchor(zone)
            if ( !isvector(anchor) or anchor:DistToSqr(snapshot.eyePos) > snapshot.drawDistanceSqr ) then
                continue
            end

            DrawZoneLabel(zone, GetZoneColor(zone, snapshot))
        end
    end

    DrawDebugHUD(snapshot)
end)

hook.Add("ax.zones.synced", "ax.zones.debug.sync", function()
    cache.nextRefresh = 0
    cache.snapshot = nil
end)

hook.Add("OnOptionChanged", "ax.zones.debug.options", function(key)
    if ( !isstring(key) ) then return end
    if ( !string.StartWith(key, "zones.debug.") ) then return end

    cache.nextRefresh = 0
    cache.snapshot = nil
end)

hook.Add("OnReloaded", "ax.zones.debug.reload", function()
    cache.nextRefresh = 0
    cache.snapshot = nil
end)
