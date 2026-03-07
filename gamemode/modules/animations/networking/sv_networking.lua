--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.net:Hook("sequence.resolved", function(client, serial, sequence, sequenceID, duration)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    serial = tonumber(serial)
    duration = math.max(tonumber(duration) or 0, 0)

    if ( !serial or serial < 1 ) then
        ax.util:PrintWarning("Received invalid forced sequence resolve serial from " .. tostring(client))
        return
    end

    local activeSequence = client:GetRelay("sequence.identifier")
    if ( activeSequence != sequence ) then
        ax.util:PrintDebug("Ignoring forced sequence resolve from " .. tostring(client) .. " because the active sequence changed.")
        return
    end

    if ( !isnumber(sequenceID) or sequenceID < 0 ) then
        ax.util:PrintWarning("Client " .. tostring(client) .. " failed to resolve forced sequence \"" .. tostring(sequence) .. "\".")
        client:LeaveSequence()
        return
    end

    if ( !istable(ax.animations.forcedSequencePending[client:SteamID64()]) ) then
        return
    end

    local ok, result = ax.animations:ResolveForcedSequencePending(client, serial, duration)
    if ( ok == false ) then
        ax.util:PrintDebug("Ignoring forced sequence resolve from " .. tostring(client) .. ": " .. tostring(result))
    end
end, true)
