--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "Networking Watcher"
MODULE.description = "Tracks what netmessages are being sent and received."
MODULE.author = "Riggs"

net.ReceiveInternal = net.ReceiveInternal or net.Receive
net.StartInternal = net.StartInternal or net.Start

AX_WATCHER = CreateConVar("ax_netwatcher", "0", FCVAR_ARCHIVE, "Enable or disable the logger.")
AX_WATCHER_LEVEL = CreateConVar("ax_netwatcher_level", "0", FCVAR_ARCHIVE, "Set the logger level. 0 = disabled, 1 = log only the message name, 2 = log the message name and path details.")
AX_WATCHER_REALM = CreateConVar("ax_netwatcher_realm", "0", FCVAR_ARCHIVE, "Set the logger realm. 0 = both, 1 = client only, 2 = server only.")
AX_WATCHER_COOLDOWN = CreateConVar("ax_netwatcher_cooldown", "1", FCVAR_ARCHIVE, "Set the logger cooldown in seconds.")

local cache = {}
function net.Receive(messageName, callback)
    if ( !AX_WATCHER:GetBool() or AX_WATCHER_LEVEL:GetInt() == 0 ) then
        return net.ReceiveInternal(messageName, callback)
    end

    if ( AX_WATCHER_REALM:GetInt() == 1 and SERVER ) then
        return net.ReceiveInternal(messageName, callback)
    elseif ( AX_WATCHER_REALM:GetInt() == 2 and CLIENT ) then
        return net.ReceiveInternal(messageName, callback)
    end

    if ( cache[messageName] ) then
        return net.ReceiveInternal(messageName, callback)
    end

    cache[messageName] = CurTime() + AX_WATCHER_COOLDOWN:GetInt()

    local function newCallback(len, client)
        local name = IsValid(client) and ( client:Nick() .. " (" .. client:SteamID64() .. ")" ) or "unknown player"
        local phrase = "Net message \"" .. messageName .. "\" has been received by " .. name .. " in the " .. ((CLIENT and "client") or (SERVER and "server") or "unknown") .. " realm."
        if ( AX_WATCHER_LEVEL:GetInt() == 2 ) then
            local path = debug.getinfo(2)
            phrase = "Net message \"" .. messageName .. "\" has been sent by " .. name .. " within \"" .. path.short_src .. "\" on line " .. path.currentline .. " in the " .. ((CLIENT and "client") or (SERVER and "server") or "unknown") .. " realm."
        end

        ax.util:Print(Color(255, 255 / 4, 0), phrase)

        return callback(len, client)
    end

    return net.ReceiveInternal(messageName, newCallback)
end

function net.Start(messageName)
    if ( !AX_WATCHER:GetBool() or AX_WATCHER_LEVEL:GetInt() == 0 ) then
        return net.StartInternal(messageName)
    end

    if ( AX_WATCHER_REALM:GetInt() == 1 and SERVER ) then
        return net.StartInternal(messageName)
    elseif ( AX_WATCHER_REALM:GetInt() == 2 and CLIENT ) then
        return net.StartInternal(messageName)
    end

    if ( cache[messageName] ) then
        return net.StartInternal(messageName)
    end

    cache[messageName] = CurTime() + AX_WATCHER_COOLDOWN:GetInt()

    local phrase = "Net message \"" .. messageName .. "\" started within the " .. ((CLIENT and "client") or (SERVER and "server") or "unknown") .. " realm."
    if ( AX_WATCHER_LEVEL:GetInt() == 2 ) then
        local path = debug.getinfo(2)
        phrase = "Net message \"" .. messageName .. "\" started within the " .. ((CLIENT and "client") or (SERVER and "server") or "unknown") .. " realm on line " .. path.currentline .. " in \"" .. path.short_src .. "\"."
    end

    ax.util:Print(Color(255, 255 / 1.5, 0), phrase)

    return net.StartInternal(messageName)
end

local nextThink = 0
function MODULE:Think()
    if ( !AX_WATCHER:GetBool() or AX_WATCHER_LEVEL:GetInt() == 0 ) then return end
    if ( AX_WATCHER_REALM:GetInt() == 1 and SERVER ) then return end
    if ( AX_WATCHER_REALM:GetInt() == 2 and CLIENT ) then return end

    if ( CurTime() < nextThink ) then return end
    nextThink = CurTime() + 0.33

    for k, v in pairs(cache) do
        if ( v < CurTime() ) then
            cache[k] = nil
        end
    end
end
