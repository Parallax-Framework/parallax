--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Map scene networking (client).
-- @module ax.mapscene

ax.mapscene = ax.mapscene or {}
ax.mapscene.pendingSync = ax.mapscene.pendingSync or {}

--- Apply a decoded payload to client state.
-- @param payload table
function ax.mapscene:ApplyPayload(payload)
    if ( !istable(payload) ) then return end

    self.scenes = payload.scenes or {}
    self:ResetState()
end

--- Handle a compressed sync payload.
-- @param compressed string
function ax.mapscene:HandleSyncPayload(compressed)
    if ( !isstring(compressed) or compressed == "" ) then return end

    local decoded = util.Base64Decode(compressed)
    if ( !isstring(decoded) or decoded == "" ) then
        ax.util:PrintError("Failed to base64 decode map scene payload.")
        return
    end

    local uncompressed = util.Decompress(decoded)
    if ( !isstring(uncompressed) or uncompressed == "" ) then
        ax.util:PrintError("Failed to decompress map scene sync payload.")
        return
    end

    local ok, payload = pcall(sfs.decode, uncompressed)
    if ( !ok or !istable(payload) ) then
        ax.util:PrintError("Failed to decode map scene sync payload.")
        return
    end

    self:ApplyPayload(payload)
end

ax.net:Hook("mapscene.sync", function(compressed)
    ax.mapscene:HandleSyncPayload(compressed)
end)

ax.net:Hook("mapscene.sync.start", function(token, total, length)
    if ( !isstring(token) or token == "" ) then return end
    if ( !isnumber(total) or total < 1 ) then return end

    ax.mapscene.pendingSync[token] = {
        total = total,
        length = length or 0,
        chunks = {}
    }
end)

ax.net:Hook("mapscene.sync.chunk", function(token, index, chunk)
    if ( !isstring(token) or token == "" ) then return end
    if ( !isnumber(index) or index < 1 ) then return end
    if ( !isstring(chunk) ) then return end

    local pending = ax.mapscene.pendingSync[token]
    if ( !pending ) then return end

    pending.chunks[index] = chunk
end)

ax.net:Hook("mapscene.sync.finish", function(token)
    if ( !isstring(token) or token == "" ) then return end

    local pending = ax.mapscene.pendingSync[token]
    if ( !pending ) then return end

    local chunks = pending.chunks
    local total = pending.total
    local buffer = {}

    for i = 1, total do
        if ( !chunks[i] ) then
            ax.util:PrintWarning("Map scene sync missing chunk " .. tostring(i) .. " for " .. token)
            ax.mapscene.pendingSync[token] = nil
            return
        end

        buffer[#buffer + 1] = chunks[i]
    end

    ax.mapscene.pendingSync[token] = nil

    ax.mapscene:HandleSyncPayload(table.concat(buffer, ""))
end)

ax.net:Hook("mapscene.preview", function(identifier)
    if ( identifier == nil or identifier == "" ) then
        ax.mapscene:ClearPreview()
    else
        ax.mapscene:SetPreview(identifier)
    end
end)

ax.net:Hook("mapscene.export", function(json)
    if ( !isstring(json) ) then return end

    print("===== Map Scenes Export =====")
    print(json)
    print("=============================")

    if ( SetClipboardText ) then
        SetClipboardText(json)
    end
end)
