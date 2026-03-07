--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

if ( SERVER ) then return end

ax.zones = ax.zones or {}
ax.zones.editor = ax.zones.editor or {}

local editor = ax.zones.editor

editor.active = editor.active or false
editor.contextOpen = editor.contextOpen or false
editor.selectedId = editor.selectedId or nil
editor.lookTargetId = editor.lookTargetId or nil
editor.draft = editor.draft or nil
editor.dirty = editor.dirty or false
editor.panel = editor.panel or nil
editor.drawDistance = editor.drawDistance or 6000
editor.drawDistanceSqr = editor.drawDistanceSqr or (editor.drawDistance * editor.drawDistance)
editor.zoneRows = editor.zoneRows or {}
editor.gridSnapEnabled = editor.gridSnapEnabled or false
editor.gridSnapSize = editor.gridSnapSize or 16
editor.gridSnapMin = editor.gridSnapMin or 1
editor.gridSnapMax = editor.gridSnapMax or 256

local COLOR_RUNTIME = Color(58, 211, 172, 110)
local COLOR_STATIC = Color(91, 166, 255, 90)
local COLOR_SELECTED = Color(255, 200, 90, 210)
local COLOR_LOOK = Color(255, 255, 255, 180)
local COLOR_DRAFT = Color(255, 136, 78, 220)
local COLOR_DRAFT_FADE = Color(255, 136, 78, 48)
local COLOR_TEXT_SHADOW = Color(0, 0, 0, 180)

local function Phrase(key, ...)
    return ax.localization:GetPhrase(key, ...)
end

local function GetClient()
    return ax.client or LocalPlayer()
end

local function Notify(text, notificationType)
    local client = GetClient()
    if ( ax.util:IsValidPlayer(client) ) then
        client:Notify(text, notificationType)
    end
end

local function IsSupportedPropertyValue(value)
    return isstring(value) or isnumber(value) or isbool(value) or isvector(value)
end

local ROOM_GUESS_TRACE_DISTANCE = 4096
local ROOM_GUESS_MASK = MASK_PLAYERSOLID_BRUSHONLY or MASK_SOLID_BRUSHONLY or MASK_SOLID
local ROOM_GUESS_SAMPLES = {
    x = {
        vector_origin,
        Vector(0, 18, 0),
        Vector(0, -18, 0),
        Vector(0, 0, 28),
        Vector(0, 0, -28),
        Vector(0, 18, 28),
        Vector(0, -18, 28),
        Vector(0, 18, -28),
        Vector(0, -18, -28),
    },
    y = {
        vector_origin,
        Vector(18, 0, 0),
        Vector(-18, 0, 0),
        Vector(0, 0, 28),
        Vector(0, 0, -28),
        Vector(18, 0, 28),
        Vector(-18, 0, 28),
        Vector(18, 0, -28),
        Vector(-18, 0, -28),
    },
    z = {
        vector_origin,
        Vector(18, 0, 0),
        Vector(-18, 0, 0),
        Vector(0, 18, 0),
        Vector(0, -18, 0),
        Vector(18, 18, 0),
        Vector(-18, 18, 0),
        Vector(18, -18, 0),
        Vector(-18, -18, 0),
    },
}

local function GetRoomGuessSampleKey(direction)
    if ( direction.x != 0 ) then
        return "x"
    end

    if ( direction.y != 0 ) then
        return "y"
    end

    return "z"
end

local function ResolveRoomGuessDistance(distances, fallback)
    if ( #distances < 1 ) then
        return fallback
    end

    table.sort(distances)

    if ( #distances == 1 ) then
        return distances[1]
    end

    local index = math.Clamp(math.floor((#distances - 1) * 0.35) + 1, 1, #distances)
    return distances[index]
end

function editor:IsOpen()
    return self.active == true
end

function editor:GetSelectedZone()
    if ( !self.selectedId ) then return nil end
    return ax.zones:Get(self.selectedId)
end

function editor:GetDraft()
    return self.draft
end

function editor:IsDirty()
    return self.dirty == true
end

function editor:MarkDirty()
    self.dirty = true
    self:RefreshPanel()
end

function editor:ClearDirty()
    self.dirty = false
    self:RefreshPanel()
end

function editor:IsGridSnapEnabled()
    return self.gridSnapEnabled == true
end

function editor:NormalizeGridSnapSize(size)
    size = math.Clamp(math.Round(tonumber(size) or 16), self.gridSnapMin, self.gridSnapMax)

    local best = math.max(self.gridSnapMin, 1)
    local bestDistance = math.abs(size - best)
    local value = best

    while ( value <= self.gridSnapMax ) do
        local distance = math.abs(size - value)
        if ( distance <= bestDistance ) then
            best = value
            bestDistance = distance
        end

        if ( value >= self.gridSnapMax ) then
            break
        end

        value = math.min(value * 2, self.gridSnapMax)
    end

    return best
end

function editor:GetGridSnapSize()
    return self:NormalizeGridSnapSize(self.gridSnapSize)
end

function editor:SetGridSnapEnabled(enabled)
    enabled = enabled == true
    if ( self.gridSnapEnabled == enabled ) then return end

    self.gridSnapEnabled = enabled
    self:RefreshPanel()
end

function editor:ToggleGridSnap()
    self:SetGridSnapEnabled(!self:IsGridSnapEnabled())
end

function editor:SetGridSnapSize(size)
    size = self:NormalizeGridSnapSize(size)
    if ( self.gridSnapSize == size ) then return end

    self.gridSnapSize = size
    self:RefreshPanel()
end

function editor:StepGridSnapSize(direction)
    direction = tonumber(direction) or 0
    if ( direction == 0 ) then return end

    local current = self:GetGridSnapSize()
    local nextSize = current

    if ( direction > 0 ) then
        nextSize = math.min(current * 2, self.gridSnapMax)
    else
        nextSize = math.max(math.floor(current / 2), self.gridSnapMin)
    end

    self:SetGridSnapSize(nextSize)
end

function editor:SnapNumber(value, force)
    value = tonumber(value)
    if ( !isnumber(value) ) then return value end
    if ( !force and !self:IsGridSnapEnabled() ) then return math.Round(value, 2) end

    local step = self:GetGridSnapSize()
    return math.Round(math.Round(value / step) * step, 2)
end

function editor:SnapVector(value, force)
    if ( !isvector(value) ) then return value end
    if ( !force and !self:IsGridSnapEnabled() ) then return value end

    return Vector(
        self:SnapNumber(value.x, true),
        self:SnapNumber(value.y, true),
        self:SnapNumber(value.z, true)
    )
end

local function VectorsDiffer(a, b)
    if ( !isvector(a) or !isvector(b) ) then
        return a != b
    end

    return a.x != b.x or a.y != b.y or a.z != b.z
end

function editor:SnapDraftToGrid()
    local draft = self.draft
    if ( !istable(draft) ) then return end

    local changed = false

    if ( draft.type == "box" ) then
        local snappedA = self:SnapVector(draft.cornerA or draft.mins, true)
        local snappedB = self:SnapVector(draft.cornerB or draft.maxs, true)

        if ( isvector(snappedA) and VectorsDiffer(draft.cornerA or draft.mins, snappedA) ) then
            draft.cornerA = snappedA
            changed = true
        end

        if ( isvector(snappedB) and VectorsDiffer(draft.cornerB or draft.maxs, snappedB) ) then
            draft.cornerB = snappedB
            changed = true
        end

        self:SyncBoxGeometry()
    elseif ( draft.type == "sphere" ) then
        local snappedCenter = self:SnapVector(draft.center, true)
        local snappedRadius = self:SnapNumber(draft.radius, true)

        if ( isvector(snappedCenter) and VectorsDiffer(draft.center, snappedCenter) ) then
            draft.center = snappedCenter
            changed = true
        end

        if ( snappedRadius != nil ) then
            snappedRadius = math.Clamp(snappedRadius, 1, self:GetMaxRadius())
            if ( tonumber(draft.radius) != snappedRadius ) then
                draft.radius = snappedRadius
                changed = true
            end
        end
    elseif ( draft.type == "pvs" or draft.type == "trace" ) then
        local snappedOrigin = self:SnapVector(draft.origin, true)
        local snappedRadius = self:SnapNumber(draft.radius, true)

        if ( isvector(snappedOrigin) and VectorsDiffer(draft.origin, snappedOrigin) ) then
            draft.origin = snappedOrigin
            changed = true
        end

        if ( snappedRadius != nil ) then
            snappedRadius = math.Clamp(snappedRadius, 0, self:GetMaxRadius())
            if ( tonumber(draft.radius) != snappedRadius ) then
                draft.radius = snappedRadius
                changed = true
            end
        end
    end

    if ( changed ) then
        self:MarkDirty()
    else
        self:RefreshPanel()
    end
end

function editor:CollectRoomGuessDistances(origin, direction, filterEntity)
    local distances = {}
    local samples = ROOM_GUESS_SAMPLES[GetRoomGuessSampleKey(direction)] or ROOM_GUESS_SAMPLES.x

    for i = 1, #samples do
        local startPos = origin + samples[i]
        local trace = util.TraceLine({
            start = startPos,
            endpos = startPos + direction * ROOM_GUESS_TRACE_DISTANCE,
            filter = filterEntity,
            mask = ROOM_GUESS_MASK
        })

        if ( trace.Hit and !trace.StartSolid and isvector(trace.HitPos) ) then
            local distance = math.abs((trace.HitPos - startPos):Dot(direction))
            if ( distance > 1 ) then
                distances[#distances + 1] = distance
            end
        end
    end

    return distances
end

function editor:GuessBoxFromRoom()
    if ( !istable(self.draft) or self.draft.type != "box" ) then return end

    local client = GetClient()
    if ( !ax.util:IsValidPlayer(client) ) then return end

    local origin = client:WorldSpaceCenter()
    local extent = self:GetDefaultBoxExtent()
    local positiveX = ResolveRoomGuessDistance(self:CollectRoomGuessDistances(origin, Vector(1, 0, 0), client), extent)
    local negativeX = ResolveRoomGuessDistance(self:CollectRoomGuessDistances(origin, Vector(-1, 0, 0), client), extent)
    local positiveY = ResolveRoomGuessDistance(self:CollectRoomGuessDistances(origin, Vector(0, 1, 0), client), extent)
    local negativeY = ResolveRoomGuessDistance(self:CollectRoomGuessDistances(origin, Vector(0, -1, 0), client), extent)
    local positiveZ = ResolveRoomGuessDistance(self:CollectRoomGuessDistances(origin, Vector(0, 0, 1), client), extent)
    local negativeZ = ResolveRoomGuessDistance(self:CollectRoomGuessDistances(origin, Vector(0, 0, -1), client), extent)

    self.draft.cornerA = self:SnapVector(Vector(
        origin.x - negativeX,
        origin.y - negativeY,
        origin.z - negativeZ
    ))
    self.draft.cornerB = self:SnapVector(Vector(
        origin.x + positiveX,
        origin.y + positiveY,
        origin.z + positiveZ
    ))
    self:SyncBoxGeometry()
    self:MarkDirty()
end

function editor:RefreshPanel()
    if ( IsValid(self.panel) and self.panel.RefreshContents ) then
        self.panel:RefreshContents()
    end
end

function editor:UpdatePanelInputState()
    if ( !IsValid(self.panel) ) then return end

    local enabled = self.active and self.contextOpen

    if ( enabled ) then
        self.panel:MakePopup()
        self.panel:MoveToFront()
        self.panel:SetKeyboardInputEnabled(false)
    end

    self.panel:SetMouseInputEnabled(enabled)
    self.panel:SetKeyboardInputEnabled(false)

    if ( self.panel.UpdateContextState ) then
        self.panel:UpdateContextState(enabled)
    end
end

function editor:EnsurePanel()
    if ( !self.active ) then return nil end

    if ( IsValid(self.panel) ) then
        self:UpdatePanelInputState()
        self:RefreshPanel()
        return self.panel
    end

    self.panel = vgui.Create("ax.zone.editor")
    self:UpdatePanelInputState()
    self:RefreshPanel()

    return self.panel
end

function editor:RemovePanel()
    if ( IsValid(self.panel) ) then
        self.panel.axSilentClose = true
        self.panel:Remove()
    end

    self.panel = nil
end

function editor:Close()
    self.active = false
    self.contextOpen = false
    self.lookTargetId = nil
    self.selectedId = nil
    self.draft = nil
    self.dirty = false

    gui.EnableScreenClicker(false)

    self:RemovePanel()
end

function editor:Open()
    self.active = true
    self.contextOpen = false
    self:EnsurePanel()
    self:RefreshPanel()
end

function editor:HandleStatePayload(payload)
    if ( !istable(payload) ) then return end

    if ( payload.active == true ) then
        self:Open()
        return
    end

    self:Close()
end

function editor:SetContextOpen(enabled)
    enabled = enabled == true

    if ( self.contextOpen == enabled ) then
        self:UpdatePanelInputState()
        return
    end

    self.contextOpen = enabled
    gui.EnableScreenClicker(enabled)
    self:UpdatePanelInputState()
end

function editor:ConfirmDiscard(callback)
    if ( !self:IsDirty() ) then
        if ( isfunction(callback) ) then
            callback()
        end

        return
    end

    Derma_Query(
        "You have unsaved zone changes. Discard them?",
        "Zone Editor",
        "Discard",
        function()
            if ( isfunction(callback) ) then
                callback()
            end
        end,
        "Cancel"
    )
end

function editor:GetZones()
    local zones = {}

    for _, zone in pairs(ax.zones.stored or {}) do
        zones[#zones + 1] = zone
    end

    table.sort(zones, function(a, b)
        if ( a.id == b.id ) then
            return string.lower(a.name or "") < string.lower(b.name or "")
        end

        return a.id < b.id
    end)

    return zones
end

function editor:GetCapturePosition(source)
    local client = GetClient()
    if ( !ax.util:IsValidPlayer(client) ) then return nil end

    if ( source == "player" ) then
        return client:WorldSpaceCenter()
    end

    local trace = client:GetEyeTrace()
    if ( trace and isvector(trace.HitPos) ) then
        return trace.HitPos
    end

    return client:EyePos() + client:GetAimVector() * 256
end

function editor:GetPlacementOrigin()
    local origin = self:GetCapturePosition("look")

    if ( !isvector(origin) ) then
        origin = self:GetCapturePosition("player")
    end

    return self:SnapVector(origin or vector_origin) or vector_origin
end

function editor:CreateDraft(typeName)
    local draft = self:BuildEmptyDraft(typeName)
    local origin = self:GetPlacementOrigin()

    if ( draft.type == "box" ) then
        local extent = self:GetDefaultBoxExtent()
        draft.cornerA = self:SnapVector(origin - Vector(extent, extent, extent))
        draft.cornerB = self:SnapVector(origin + Vector(extent, extent, extent))
        draft.mins, draft.maxs = self:NormalizeBoxCorners(draft.cornerA, draft.cornerB)
    elseif ( draft.type == "sphere" ) then
        draft.center = origin
    elseif ( draft.type == "pvs" or draft.type == "trace" ) then
        draft.origin = origin
    end

    return draft
end

function editor:BuildPreviewZone()
    local draft = self.draft
    if ( !istable(draft) ) then return nil end

    local preview = self:CopyZone(draft) or table.Copy(draft)
    preview.id = preview.id or -1
    preview.source = "runtime"

    if ( preview.type == "box" ) then
        preview.mins, preview.maxs = self:NormalizeBoxCorners(preview.cornerA or preview.mins, preview.cornerB or preview.maxs)
    end

    return preview
end

function editor:LoadZone(zoneId, skipConfirm)
    local function apply()
        local zone = ax.zones:Get(zoneId)
        if ( !zone ) then
            Notify("That zone no longer exists.", "error")
            return
        end

        self.selectedId = zone.id
        self.draft = self:CopyZone(zone)
        self.dirty = false
        self:RefreshPanel()
    end

    if ( skipConfirm == true ) then
        apply()
        return
    end

    self:ConfirmDiscard(apply)
end

function editor:BeginNew(typeName, skipConfirm)
    local function apply()
        self.selectedId = nil
        self.draft = self:CreateDraft(typeName)
        self.dirty = false
        self:RefreshPanel()
    end

    if ( skipConfirm == true ) then
        apply()
        return
    end

    self:ConfirmDiscard(apply)
end

function editor:SyncBoxGeometry()
    if ( !istable(self.draft) or self.draft.type != "box" ) then return end
    self.draft.mins, self.draft.maxs = self:NormalizeBoxCorners(self.draft.cornerA or self.draft.mins, self.draft.cornerB or self.draft.maxs)
end

function editor:GetDraftAnchor()
    local draft = self:BuildPreviewZone()
    return draft and self:GetZoneAnchor(draft) or nil
end

function editor:SetDraftType(typeName)
    typeName = self:NormalizeType(typeName)
    if ( !typeName ) then return end
    if ( !istable(self.draft) ) then
        self:BeginNew(typeName, true)
        return
    end

    if ( self.draft.type == typeName ) then return end

    local anchor = self:SnapVector(self:GetDraftAnchor() or self:GetPlacementOrigin())
    local nextDraft = self:BuildEmptyDraft(typeName)

    nextDraft.id = self.draft.id
    nextDraft.name = self.draft.name
    nextDraft.priority = self.draft.priority
    nextDraft.flags = table.Copy(self.draft.flags or {})
    nextDraft.data = table.Copy(self.draft.data or {})

    if ( typeName == "box" ) then
        local extent = self:GetDefaultBoxExtent()
        nextDraft.cornerA = self:SnapVector(anchor - Vector(extent, extent, extent))
        nextDraft.cornerB = self:SnapVector(anchor + Vector(extent, extent, extent))
        nextDraft.mins, nextDraft.maxs = self:NormalizeBoxCorners(nextDraft.cornerA, nextDraft.cornerB)
    elseif ( typeName == "sphere" ) then
        nextDraft.center = anchor
        nextDraft.radius = self:SnapNumber(self.draft.radius or self:GetDefaultRadius())
    elseif ( typeName == "pvs" or typeName == "trace" ) then
        nextDraft.origin = anchor
        nextDraft.radius = self:SnapNumber(self.draft.radius or self:GetDefaultRadius())
    end

    self.draft = nextDraft
    self:MarkDirty()
end

function editor:CaptureBoxCorner(cornerName, source)
    if ( !istable(self.draft) or self.draft.type != "box" ) then return end

    local position = self:SnapVector(self:GetCapturePosition(source))
    if ( !isvector(position) ) then
        Notify("Could not read a valid world position.", "error")
        return
    end

    if ( cornerName == "A" ) then
        self.draft.cornerA = position
    else
        self.draft.cornerB = position
    end

    self:SyncBoxGeometry()
    self:MarkDirty()
end

function editor:ResetBoxAroundPlayer()
    if ( !istable(self.draft) or self.draft.type != "box" ) then return end

    local origin = self:SnapVector(self:GetCapturePosition("player") or vector_origin)
    local extent = self:GetDefaultBoxExtent()

    self.draft.cornerA = self:SnapVector(origin - Vector(extent, extent, extent))
    self.draft.cornerB = self:SnapVector(origin + Vector(extent, extent, extent))
    self:SyncBoxGeometry()
    self:MarkDirty()
end

function editor:CaptureOrigin(source)
    if ( !istable(self.draft) ) then return end

    local position = self:SnapVector(self:GetCapturePosition(source))
    if ( !isvector(position) ) then
        Notify("Could not read a valid world position.", "error")
        return
    end

    if ( self.draft.type == "sphere" ) then
        self.draft.center = position
    elseif ( self.draft.type == "pvs" or self.draft.type == "trace" ) then
        self.draft.origin = position
    else
        return
    end

    self:MarkDirty()
end

function editor:AdjustRadius(delta)
    if ( !istable(self.draft) ) then return end
    if ( self.draft.type != "sphere" and self.draft.type != "pvs" and self.draft.type != "trace" ) then return end

    local radius = tonumber(self.draft.radius) or self:GetDefaultRadius()
    radius = math.Clamp(radius + delta, self.draft.type == "sphere" and 1 or 0, self:GetMaxRadius())
    radius = self:SnapNumber(radius)
    radius = math.Clamp(radius, self.draft.type == "sphere" and 1 or 0, self:GetMaxRadius())
    self.draft.radius = math.Round(radius, 2)
    self:MarkDirty()
end

function editor:PromptForText(title, subtitle, defaultValue, callback)
    Derma_StringRequest(title, subtitle, defaultValue or "", function(text)
        if ( isfunction(callback) ) then
            callback(text)
        end
    end, nil, "Apply", "Cancel")
end

function editor:PromptName()
    if ( !istable(self.draft) ) then return end

    self:PromptForText("Zone Name", "Set the visible name for this zone.", self.draft.name or "", function(text)
        text = self:SanitizeString(text, self.maxStringLength)
        if ( !text ) then
            Notify("Zone name can not be empty.", "error")
            return
        end

        self.draft.name = text
        self:MarkDirty()
    end)
end

function editor:PromptPriority()
    if ( !istable(self.draft) ) then return end

    self:PromptForText("Zone Priority", "Higher numbers win when multiple zones overlap.", tostring(self.draft.priority or 0), function(text)
        local number = tonumber(text)
        if ( !number ) then
            Notify("Priority must be a number.", "error")
            return
        end

        self.draft.priority = self:SanitizePriority(number)
        self:MarkDirty()
    end)
end

function editor:PromptRadius()
    if ( !istable(self.draft) ) then return end
    if ( self.draft.type != "sphere" and self.draft.type != "pvs" and self.draft.type != "trace" ) then return end

    self:PromptForText("Zone Radius", "Set the zone radius in Hammer units.", tostring(self.draft.radius or self:GetDefaultRadius()), function(text)
        local number = tonumber(text)
        if ( !number ) then
            Notify("Radius must be a number.", "error")
            return
        end

        local radius = self:SanitizeRadius(number, self.draft.type != "sphere")
        if ( !radius ) then
            Notify("Radius is outside the supported range.", "error")
            return
        end

        radius = self:SnapNumber(radius)
        radius = math.Clamp(radius, self.draft.type == "sphere" and 1 or 0, self:GetMaxRadius())
        self.draft.radius = radius
        self:MarkDirty()
    end)
end

function editor:GetValueType(value)
    if ( isstring(value) ) then return "string" end
    if ( isnumber(value) ) then return "number" end
    if ( isbool(value) ) then return "boolean" end
    if ( isvector(value) ) then return "vector" end
    if ( isangle(value) ) then return "angle" end
    if ( istable(value) ) then return "table" end
    return "unknown"
end

function editor:FormatVector(value)
    if ( !isvector(value) ) then return "0 0 0" end
    return string.format("%.2f %.2f %.2f", value.x, value.y, value.z)
end

function editor:FormatValue(value)
    local valueType = self:GetValueType(value)

    if ( valueType == "string" ) then
        return value
    end

    if ( valueType == "number" ) then
        return tostring(value)
    end

    if ( valueType == "boolean" ) then
        return value and "true" or "false"
    end

    if ( valueType == "vector" ) then
        return self:FormatVector(value)
    end

    return "[" .. valueType .. "]"
end

function editor:ParseVector(text)
    if ( !isstring(text) ) then return nil end

    text = string.Trim(text)
    text = string.gsub(text, "[(),]", " ")

    local parts = {}
    for number in string.gmatch(text, "[%-]?[%d%.]+") do
        parts[#parts + 1] = tonumber(number)
    end

    if ( #parts < 3 ) then
        return nil
    end

    return Vector(parts[1] or 0, parts[2] or 0, parts[3] or 0)
end

function editor:SetProperty(kind, key, value, previousKey)
    if ( !istable(self.draft) ) then return end

    kind = string.lower(kind or "")
    if ( kind != "flags" and kind != "data" ) then return end

    local sanitizedKey = self:SanitizeString(key, self.maxKeyLength)
    if ( !sanitizedKey ) then
        Notify("Property keys can not be empty.", "error")
        return
    end

    self.draft[kind] = self.draft[kind] or {}

    if ( previousKey and previousKey != sanitizedKey ) then
        self.draft[kind][previousKey] = nil
    end

    self.draft[kind][sanitizedKey] = value
    self:MarkDirty()
end

function editor:RemoveProperty(kind, key)
    if ( !istable(self.draft) or !istable(self.draft[kind]) ) then return end

    self.draft[kind][key] = nil
    self:MarkDirty()
end

function editor:PromptPropertyKey(kind, currentKey, callback)
    self:PromptForText("Zone " .. string.upper(kind), "Enter the key name.", currentKey or "", function(text)
        local key = self:SanitizeString(text, self.maxKeyLength)
        if ( !key ) then
            Notify("Property keys can not be empty.", "error")
            return
        end

        if ( isfunction(callback) ) then
            callback(key)
        end
    end)
end

function editor:PromptPropertyValue(kind, valueType, key, previousKey, currentValue)
    local title = string.format("%s.%s", kind, key)

    if ( valueType == "boolean" ) then
        Derma_Query(
            "Choose the boolean value for this property.",
            title,
            "True",
            function()
                self:SetProperty(kind, key, true, previousKey)
            end,
            "False",
            function()
                self:SetProperty(kind, key, false, previousKey)
            end,
            "Cancel"
        )
        return
    end

    local defaultValue = currentValue != nil and self:FormatValue(currentValue) or ""
    local subtitle = "Enter the property value."

    if ( valueType == "vector" ) then
        subtitle = "Enter three numbers separated by spaces or commas."
    elseif ( valueType == "number" ) then
        subtitle = "Enter a numeric value."
    end

    self:PromptForText(title, subtitle, defaultValue, function(text)
        local value = nil

        if ( valueType == "string" ) then
            value = text
        elseif ( valueType == "number" ) then
            value = tonumber(text)
            if ( !value ) then
                Notify("That is not a valid number.", "error")
                return
            end
        elseif ( valueType == "vector" ) then
            value = self:ParseVector(text)
            if ( !value ) then
                Notify("Vector values must look like: 0 0 0", "error")
                return
            end
        end

        self:SetProperty(kind, key, value, previousKey)
    end)
end

function editor:ChoosePropertyType(kind, previousKey, currentValue)
    local function startWithType(valueType)
        self:PromptPropertyKey(kind, previousKey, function(key)
            self:PromptPropertyValue(kind, valueType, key, previousKey, currentValue)
        end)
    end

    Derma_Query(
        "Choose which kind of value you want to store.",
        "Zone " .. string.upper(kind),
        "Text",
        function() startWithType("string") end,
        "Number",
        function() startWithType("number") end,
        "Boolean",
        function() startWithType("boolean") end,
        "Vector",
        function() startWithType("vector") end,
        "Cancel"
    )
end

function editor:OpenPropertyMenu(kind, key)
    if ( !istable(self.draft) ) then return end
    self.draft[kind] = self.draft[kind] or {}

    if ( !key ) then
        self:ChoosePropertyType(kind)
        return
    end

    local currentValue = self.draft[kind][key]
    local valueType = self:GetValueType(currentValue)

    if ( valueType != "string" and valueType != "number" and valueType != "boolean" and valueType != "vector" ) then
        Derma_Query(
            "This value type can be preserved, but it can not be edited from the zone editor.",
            string.format("%s.%s", kind, key),
            "Remove",
            function()
                self:RemoveProperty(kind, key)
            end,
            "Cancel"
        )
        return
    end

    Derma_Query(
        "Choose what to do with this property.",
        string.format("%s.%s", kind, key),
        "Edit",
        function()
            self:PromptPropertyKey(kind, key, function(newKey)
                self:PromptPropertyValue(kind, valueType, newKey, key, currentValue)
            end)
        end,
        "Delete",
        function()
            self:RemoveProperty(kind, key)
        end,
        "Cancel"
    )
end

function editor:GetPropertyRows(kind)
    local rows = {}
    local container = istable(self.draft) and self.draft[kind] or nil

    if ( !istable(container) ) then
        return rows
    end

    for key, value in pairs(container) do
        rows[#rows + 1] = {
            key = tostring(key),
            value = value,
            formatted = self:FormatValue(value),
            valueType = self:GetValueType(value),
        }
    end

    table.sort(rows, function(a, b)
        return string.lower(a.key) < string.lower(b.key)
    end)

    return rows
end

function editor:CanSaveDraft()
    return istable(self.draft)
end

function editor:SaveDraft()
    if ( !self:CanSaveDraft() ) then return end

    if ( self.draft.type == "box" ) then
        self:SyncBoxGeometry()
    end

    ax.net:Start("zones.editor.action", {
        action = "save",
        zoneId = self.draft.id,
        draft = self.draft,
    })
end

function editor:DeleteSelected()
    local zone = self:GetSelectedZone()
    if ( !zone ) then
        Notify("Select a saved zone before trying to delete it.", "error")
        return
    end

    Derma_Query(
        string.format("Delete zone #%d (%s)?", zone.id, zone.name or "Unnamed"),
        "Zone Editor",
        "Delete",
        function()
            ax.net:Start("zones.editor.action", {
                action = "delete",
                zoneId = zone.id,
            })
        end,
        "Cancel"
    )
end

function editor:DuplicateSelected()
    local zone = self:GetSelectedZone()
    if ( !zone ) then
        Notify("Select a saved zone before duplicating it.", "error")
        return
    end

    ax.net:Start("zones.editor.action", {
        action = "duplicate",
        zoneId = zone.id,
    })
end

function editor:TeleportSelected()
    local zone = self:GetSelectedZone()
    if ( !zone ) then
        Notify("Select a saved zone before teleporting to it.", "error")
        return
    end

    ax.net:Start("zones.editor.action", {
        action = "teleport",
        zoneId = zone.id,
    })
end

function editor:ComputeLookTarget()
    local client = GetClient()
    if ( !self.active or !ax.util:IsValidPlayer(client) ) then
        self.lookTargetId = nil
        return
    end

    local position = self:GetCapturePosition("look")
    if ( !isvector(position) ) then
        self.lookTargetId = nil
        return
    end

    local bestZone = nil
    local bestScore = math.huge
    local eyePos = client:EyePos()

    for _, zone in pairs(ax.zones.stored or {}) do
        local anchor = self:GetZoneAnchor(zone)
        if ( !isvector(anchor) ) then
            continue
        end

        local distToEye = anchor:DistToSqr(eyePos)
        if ( distToEye > self.drawDistanceSqr ) then
            continue
        end

        local distance = self:DistanceToZone(zone, position)
        local score = distance + math.sqrt(distToEye) * 0.05

        if ( score < bestScore and distance < 192 ) then
            bestScore = score
            bestZone = zone
        end
    end

    self.lookTargetId = bestZone and bestZone.id or nil
end

function editor:SelectLookTarget()
    if ( !self.lookTargetId ) then
        Notify("Look at a nearby zone first.", "error")
        return
    end

    self:LoadZone(self.lookTargetId, false)
end

function editor:HandleCommit(payload)
    if ( !istable(payload) ) then return end

    local action = isstring(payload.action) and string.lower(payload.action) or ""
    local zoneId = tonumber(payload.zoneId)

    if ( action == "save" or action == "duplicate" ) then
        if ( zoneId and ax.zones:Get(zoneId) ) then
            self:LoadZone(zoneId, true)
        end
        return
    end

    if ( action == "delete" ) then
        if ( self.selectedId == zoneId ) then
            self.selectedId = nil
        end

        self.draft = nil
        self.dirty = false
        self:RefreshPanel()
        return
    end

    self:RefreshPanel()
end

function editor:HandleZonesSynced()
    if ( self.selectedId and !ax.zones:Get(self.selectedId) ) then
        self.selectedId = nil
    end

    if ( self.draft and self.draft.id and !ax.zones:Get(self.draft.id) and !self.dirty ) then
        self.draft = nil
    end

    if ( self.active ) then
        self:EnsurePanel()
        self:RefreshPanel()
    end
end

local function DrawZoneLabel(zone, color)
    local anchor = editor:GetZoneAnchor(zone)
    if ( !isvector(anchor) ) then return end

    local screen = anchor:ToScreen()
    if ( !screen.visible ) then return end

    local lineOne = string.format("%s  #%d", zone.name or Phrase("zones.common.zone"), zone.id or 0)
    local lineTwo = Phrase("zones.common.type_priority", editor:GetTypeLabel(zone.type), zone.priority or 0)

    draw.SimpleText(lineOne, "ax.small.bold", screen.x + 1, screen.y + 1, COLOR_TEXT_SHADOW, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    draw.SimpleText(lineOne, "ax.small.bold", screen.x, screen.y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    draw.SimpleText(lineTwo, "ax.small", screen.x + 1, screen.y + 16, COLOR_TEXT_SHADOW, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.SimpleText(lineTwo, "ax.small", screen.x, screen.y + 15, Color(240, 240, 240, math.min(color.a + 20, 255)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

local function DrawBoxCornerLabel(position, text, color)
    if ( !isvector(position) ) then return end

    local screen = position:ToScreen()
    if ( !screen.visible ) then return end

    draw.SimpleText(text, "ax.small.bold", screen.x + 1, screen.y + 1, COLOR_TEXT_SHADOW, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(text, "ax.small.bold", screen.x, screen.y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function DrawBoxCornerLabels(zone, color)
    if ( zone.type != "box" ) then return end

    DrawBoxCornerLabel(zone.cornerA or zone.mins, Phrase("zones.common.corner_a_name"), color)
    DrawBoxCornerLabel(zone.cornerB or zone.maxs, Phrase("zones.common.corner_b_name"), color)
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
        render.DrawWireframeSphere(zone.origin, 24, 10, 10, color, true)

        if ( zone.radius and zone.radius > 0 ) then
            render.DrawWireframeSphere(zone.origin, zone.radius, 16, 16, Color(color.r, color.g, color.b, outlineAlpha or 64), true)
        end

        if ( zone.type == "trace" ) then
            local crossSize = 20
            render.DrawLine(zone.origin + Vector(crossSize, 0, 0), zone.origin - Vector(crossSize, 0, 0), color, true)
            render.DrawLine(zone.origin + Vector(0, crossSize, 0), zone.origin - Vector(0, crossSize, 0), color, true)
            render.DrawLine(zone.origin + Vector(0, 0, crossSize), zone.origin - Vector(0, 0, crossSize), color, true)
        end
    end
end

hook.Add("Think", "ax.zones.editor.looktarget", function()
    if ( !editor.active ) then return end
    editor:ComputeLookTarget()
end)

hook.Add("PostDrawOpaqueRenderables", "ax.zones.editor.preview", function()
    if ( !editor.active ) then return end

    local client = GetClient()
    if ( !ax.util:IsValidPlayer(client) ) then return end

    local eyePos = client:EyePos()

    for _, zone in pairs(ax.zones.stored or {}) do
        local anchor = editor:GetZoneAnchor(zone)
        if ( !isvector(anchor) or anchor:DistToSqr(eyePos) > editor.drawDistanceSqr ) then
            continue
        end

        local color = zone.source == "static" and COLOR_STATIC or COLOR_RUNTIME
        if ( editor.lookTargetId == zone.id ) then
            color = COLOR_LOOK
        end
        if ( editor.selectedId == zone.id ) then
            color = COLOR_SELECTED
        end

        DrawZoneGeometry(zone, color, 48)
    end

    local preview = editor:BuildPreviewZone()
    if ( preview ) then
        local pulse = 0.65 + math.abs(math.sin(CurTime() * 3)) * 0.35
        local color = Color(
            COLOR_DRAFT.r,
            COLOR_DRAFT.g,
            COLOR_DRAFT.b,
            math.floor(COLOR_DRAFT.a * pulse)
        )

        DrawZoneGeometry(preview, color, COLOR_DRAFT_FADE.a)
    end
end)

hook.Add("HUDPaint", "ax.zones.editor.hud", function()
    if ( !editor.active ) then return end

    local draft = editor:BuildPreviewZone()
    if ( draft ) then
        DrawZoneLabel(draft, COLOR_DRAFT)
        DrawBoxCornerLabels(draft, COLOR_DRAFT)
    end

    local selectedZone = editor:GetSelectedZone()
    if ( selectedZone and (!draft or draft.id != selectedZone.id) ) then
        DrawZoneLabel(selectedZone, COLOR_SELECTED)
        DrawBoxCornerLabels(selectedZone, COLOR_SELECTED)
    end

    local width = 420
    local x = ax.util:ScreenScale(8)
    local y = ax.util:ScreenScaleH(8)
    local lineHeight = 20

    surface.SetDrawColor(0, 0, 0, 170)
    surface.DrawRect(x, y, width, 118)

    draw.SimpleText(Phrase("zones.editor.hud.title"), "ax.medium.bold", x + 12, y + 10, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(Phrase("zones.editor.hud.subtitle"), "ax.small", x + 12, y + 34, Color(230, 230, 230, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local lineY = y + 58
    local selectedText = selectedZone and Phrase("zones.editor.hud.selected", selectedZone.id, selectedZone.name or Phrase("zones.common.unnamed")) or Phrase("zones.editor.hud.selected_none")
    local lookText = editor.lookTargetId and Phrase("zones.editor.hud.look_target", editor.lookTargetId) or Phrase("zones.editor.hud.look_target_none")
    local draftText = draft and Phrase("zones.editor.hud.draft", editor:GetTypeSummary(draft), editor:IsDirty() and ("  |  " .. Phrase("zones.common.unsaved")) or "") or Phrase("zones.editor.hud.draft_none")

    draw.SimpleText(selectedText, "ax.small.bold", x + 12, lineY, COLOR_SELECTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(lookText, "ax.small", x + 12, lineY + lineHeight, COLOR_LOOK, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(draftText, "ax.small", x + 12, lineY + lineHeight * 2, COLOR_DRAFT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    -- Draw a simple crosshair
    local crossSize = 4
    local centerX = ScrW() / 2
    local centerY = ScrH() / 2
    surface.SetDrawColor(255, 255, 255, 200)
    surface.DrawLine(centerX - crossSize, centerY, centerX + crossSize, centerY)
    surface.DrawLine(centerX, centerY - crossSize, centerX, centerY + crossSize)
end)

hook.Add("OverrideBuildMenuBind", "ax.zones.editor.context", function(client, bind, pressed, code)
    if ( !editor.active ) then return end
    if ( bind != "+menu_context" ) then return end

    editor:SetContextOpen(pressed)

    return true
end)

hook.Add("OnReloaded", "ax.zones.editor.reload", function()
    gui.EnableScreenClicker(false)
    editor:RemovePanel()
end)

hook.Add("ax.zones.synced", "ax.zones.editor.sync", function()
    editor:HandleZonesSynced()
end)

ax.net:Hook("zones.editor.state", function(payload)
    editor:HandleStatePayload(payload)
end)

ax.net:Hook("zones.editor.commit", function(payload)
    editor:HandleCommit(payload)
end)
