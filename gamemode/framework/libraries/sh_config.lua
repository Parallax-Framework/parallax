--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Configuration system for server-owned settings with optional client networking.
-- Server maintains the authoritative config values and can optionally sync them to clients.
-- Supports categorization, validation, and automatic persistence to JSON files.
-- @module ax.config
-- @usage ax.config:Add("thirdperson", ax.type.bool, true, { description = "Enable third-person view.", category = "camera" })
-- @usage ax.config:Set("thirdperson", false)
-- @usage print(ax.config:Get("thirdperson", true))  -- server: source of truth; client: cached

--[[
    Config System - Server-owned settings with optional client networking

    Examples:
    ax.config:Add("thirdperson", ax.type.bool, true, { description = "Enable third-person view.", category = "camera", subCategory = "thirdperson" })
    ax.config:Add("gravityScale", ax.type.number, 1, { min = 0.1, max = 3, decimals = 2, bNoNetworking = true, category = "gameplay", subCategory = "physics" })

    ax.config:Set("thirdperson", false)
    print(ax.config:Get("thirdperson", true))  -- server: source of truth; client: cached
]]

-- Create the config store (preserve existing store during hot-reload)
local configSpec = {
    name = "config",
    path = function()
        return ax.util:BuildDataPath("config", { scope = "project" })
    end,
    legacyPaths = {
        "parallax/config.json"
    },
    authority = "server",
    net = {
        init = "config.init",
        set = "config.set"
    },
    perPlayer = false
}

-- Check if store library was updated or if store doesn't exist yet
local storeLibTime = file.Time("gamemodes/parallax/gamemode/framework/util/util_store.lua", "GAME") or 0
local needsRebuild = !ax.config.Add or (ax.config._libTime and ax.config._libTime != storeLibTime)

if ( needsRebuild ) then
    local oldStore = ax.config.Add and ax.config or nil
    ax.config = ax.util:CreateStore(configSpec, oldStore)
    ax.config:_setupNetworking()

    -- Load config on server startup (only if not migrating from old store)
    if ( SERVER and !oldStore ) then
        ax.config:Load()
    end
end
