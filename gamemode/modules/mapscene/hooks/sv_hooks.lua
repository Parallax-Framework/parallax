--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local function HandlePlayerReady(client)
    if ( !ax.mapscene ) then return end
    ax.mapscene:Sync(client)
end

local function HandleInitPostEntity()
    if ( !ax.mapscene ) then return end
    ax.mapscene:Load()
    ax.mapscene:Sync(nil)
end

local function HandleOnReloaded()
    if ( !ax.mapscene ) then return end
    ax.mapscene:Load()
    ax.mapscene:Sync(nil)
end

local function HandleSetupPlayerVisibility(client, viewEntity)
    if ( !ax.mapscene ) then return end
    ax.mapscene:SetupPlayerVisibility(client)
end

local function HandlePlayerDisconnected(client)
    if ( !ax.mapscene ) then return end

    local steamID = client:SteamID64()
    ax.mapscene.pendingPairs[steamID] = nil
end

hook.Add("PlayerReady", "ax.mapscene.Sync", HandlePlayerReady)
hook.Add("InitPostEntity", "ax.mapscene.Load", HandleInitPostEntity)
hook.Add("OnReloaded", "ax.mapscene.Reload", HandleOnReloaded)
hook.Add("SetupPlayerVisibility", "ax.mapscene.PVS", HandleSetupPlayerVisibility)
hook.Add("PlayerDisconnected", "ax.mapscene.PairCleanup", HandlePlayerDisconnected)
