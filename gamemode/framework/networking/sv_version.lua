--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local function ReadVersionFile()
    -- Attempt to read from the gamemode root (installed with gamemode files)
    local content = file.Read("gamemodes/parallax/version.json", "GAME")
    if ( !content ) then
        ax.util:PrintWarning("version.json not found in gamemode folder")
        return nil
    end

    if ( !content ) then
        ax.util:PrintWarning("version.json not found; ax.version will be empty")
        return nil
    end

    local ok, data = pcall(util.JSONToTable, content)
    if ( ok and istable(data) ) then
        return data
    end

    ax.util:PrintWarning("Failed to parse version.json; ax.version will be empty")
    return nil
end

local function BroadcastVersion(data, recipients)
    if ( !data ) then return end

    if ( recipients ) then
        ax.net:Start(recipients, "version.init", data)
    else
        ax.net:Start(nil, "version.init", data)
    end
end

local function SetupVersion()
    local data = ReadVersionFile()

    -- Set server-side global for other server code
    ax.version = data or {}

    -- Broadcast to all connected clients
    BroadcastVersion(ax.version)
end

-- Clean up existing hooks to prevent duplicates on reload
hook.Remove("Initialize", "ax.version.setup")
hook.Remove("OnReloaded", "ax.version.reload")
hook.Remove("PlayerInitialSpawn", "ax.version.send_on_join")

-- Initialize on server start
hook.Add("Initialize", "ax.version.setup", function()
    SetupVersion()
end)

-- Re-setup on gamemode reload so clients get updated info
hook.Add("OnReloaded", "ax.version.reload", function()
    SetupVersion()
end)

-- When a player joins, send them the current version
hook.Add("PlayerInitialSpawn", "ax.version.send_on_join", function(client)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    BroadcastVersion(ax.version, client)
end)
