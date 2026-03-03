--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- @module ax.zones.editor

if ( CLIENT ) then return end

ax.zones = ax.zones or {}
ax.zones.editor = ax.zones.editor or {}

local editor = ax.zones.editor

editor.sessions = editor.sessions or {}

local function SendEditorState(client, active)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    ax.net:Start(client, "zones.editor.state", {
        active = active == true
    })
end

function editor:IsSessionActive(client)
    if ( !ax.util:IsValidPlayer(client) ) then return false end
    return self.sessions[client:SteamID64()] == true
end

function editor:SetSessionActive(client, active)
    if ( !ax.util:IsValidPlayer(client) ) then return false end

    local steamID64 = client:SteamID64()

    if ( active == true ) then
        self.sessions[steamID64] = true
        ax.zones:SyncToPlayer(client)
        SendEditorState(client, true)
        return true
    end

    self.sessions[steamID64] = nil
    SendEditorState(client, false)

    return false
end

function editor:ToggleSession(client)
    if ( !self:CanUse(client) ) then
        return false, "You must be an administrator to use the zone editor."
    end

    local nowActive = !self:IsSessionActive(client)
    self:SetSessionActive(client, nowActive)

    if ( nowActive ) then
        return true, "Zone editor enabled."
    end

    return false, "Zone editor disabled."
end

local function RequireEditorSession(client)
    if ( !editor:CanUse(client) ) then
        client:Notify("You do not have permission to edit zones.", "error")
        return false
    end

    if ( !editor:IsSessionActive(client) ) then
        client:Notify("Open /ZoneEditor before sending editor actions.", "error")
        return false
    end

    return true
end

local function SendCommit(client, payload, message, notifyType)
    if ( !ax.util:IsValidPlayer(client) ) then return end
    if ( istable(payload) ) then
        ax.net:Start(client, "zones.editor.commit", payload)
    end

    if ( isstring(message) and message != "" ) then
        client:Notify(message, notifyType or "success")
    end
end

local function FindEditableZone(client, identifier, allowStatic)
    local zone = ax.zones:Get(identifier)
    if ( !zone ) then
        client:Notify("That zone no longer exists.", "error")
        return nil
    end

    if ( !allowStatic and zone.source == "static" ) then
        client:Notify("Static zones are read-only. Duplicate it first if you want a runtime copy.", "error")
        return nil
    end

    return zone
end

local function GetZoneSpawnPosition(zone)
    local anchor = editor:GetZoneAnchor(zone)
    if ( !isvector(anchor) ) then return nil end

    return anchor + Vector(0, 0, 16)
end

local function DuplicateZone(zone)
    local duplicate = editor:CopyZone(zone)
    if ( !duplicate ) then return nil, "Failed to copy zone." end

    duplicate.id = nil
    duplicate.source = nil
    duplicate.map = nil
    duplicate.name = string.format("%s Copy", duplicate.name or "Zone")

    if ( duplicate.type == "box" ) then
        duplicate.mins = duplicate.mins or duplicate.cornerA
        duplicate.maxs = duplicate.maxs or duplicate.cornerB
    end

    return ax.zones:Add(duplicate)
end

ax.net:Hook("zones.editor.action", function(client, payload)
    if ( !RequireEditorSession(client) ) then return end
    if ( !istable(payload) ) then
        client:Notify("Invalid zone editor request.", "error")
        return
    end

    local action = isstring(payload.action) and string.lower(payload.action) or ""

    if ( action == "save" ) then
        local draft, err = editor:SanitizeDraft(payload.draft)
        if ( !draft ) then
            client:Notify(err or "Failed to validate the zone draft.", "error")
            return
        end

        local zoneId = tonumber(payload.zoneId)
        if ( zoneId ) then
            local zone = FindEditableZone(client, zoneId, false)
            if ( !zone ) then return end

            local ok = ax.zones:Update(zone.id, editor:ToUpdatePatch(draft))
            if ( !ok ) then
                client:Notify("Failed to update the zone. Check the server console for details.", "error")
                return
            end

            SendCommit(client, {
                action = "save",
                zoneId = zone.id,
            }, string.format("Updated zone #%d (%s).", zone.id, zone.name))
            return
        end

        local id, addErr = ax.zones:Add(draft)
        if ( !id ) then
            client:Notify(addErr or "Failed to create the zone.", "error")
            return
        end

        SendCommit(client, {
            action = "save",
            zoneId = id,
        }, string.format("Created zone #%d (%s).", id, draft.name))
        return
    end

    if ( action == "delete" ) then
        local zone = FindEditableZone(client, tonumber(payload.zoneId), false)
        if ( !zone ) then return end

        local zoneName = zone.name
        local zoneId = zone.id

        if ( !ax.zones:Remove(zone.id) ) then
            client:Notify("Failed to delete the zone.", "error")
            return
        end

        SendCommit(client, {
            action = "delete",
            zoneId = zoneId,
        }, string.format("Deleted zone #%d (%s).", zoneId, zoneName))
        return
    end

    if ( action == "duplicate" ) then
        local zone = FindEditableZone(client, tonumber(payload.zoneId), true)
        if ( !zone ) then return end

        local duplicateId, err = DuplicateZone(zone)
        if ( !duplicateId ) then
            client:Notify(err or "Failed to duplicate the zone.", "error")
            return
        end

        SendCommit(client, {
            action = "duplicate",
            zoneId = duplicateId,
        }, string.format("Duplicated zone #%d into runtime zone #%d.", zone.id, duplicateId))
        return
    end

    if ( action == "teleport" ) then
        local zone = FindEditableZone(client, tonumber(payload.zoneId), true)
        if ( !zone ) then return end

        local pos = GetZoneSpawnPosition(zone)
        if ( !isvector(pos) ) then
            client:Notify("This zone does not have a valid anchor point.", "error")
            return
        end

        client:SetPos(pos)
        SendCommit(client, {
            action = "teleport",
            zoneId = zone.id,
        }, string.format("Teleported to zone #%d (%s).", zone.id, zone.name))
        return
    end

    client:Notify("Unknown zone editor action: " .. tostring(action), "error")
end)

hook.Add("PlayerDisconnected", "ax.zones.editor.sessions", function(client)
    if ( !ax.util:IsValidPlayer(client) ) then return end
    editor.sessions[client:SteamID64()] = nil
end)

hook.Add("OnReloaded", "ax.zones.editor.sessions", function()
    editor.sessions = {}
end)
