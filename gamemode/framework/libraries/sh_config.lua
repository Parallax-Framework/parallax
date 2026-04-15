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

--- Store-generated config accessors.
-- `ax.config` is created via `ax.util:CreateStore`, so these methods are added
-- dynamically at runtime rather than declared directly in this file.
-- @section accessors

--- Register a config key definition.
-- Set `data.bServerOnly = true` to keep the value strictly on the server: it is
-- never transmitted to clients, and the key is not registered in the client
-- registry at all (client `Get` calls return the caller's fallback).
-- @realm shared
-- @function ax.config:Add
-- @param key string Unique config key
-- @param type any `ax.type` value used for sanitization/coercion
-- @param default any Default value for the key
-- @param[opt] data table Metadata (description, category, min/max, decimals, `OnChanged`, `bServerOnly`, etc.)
-- @return boolean success True on success
-- @usage ax.config:Add("voice.distance", ax.type.number, 512, { min = 64, max = 4096, category = "voice" })
-- @usage ax.config:Add("admin.webhook", ax.type.string, "", { bServerOnly = true, category = "general" })

--- Get a config value.
-- On the client, this returns the replicated cache value when available.
-- @realm shared
-- @function ax.config:Get
-- @param key string Config key
-- @param[opt] fallback any Value returned when the key is missing
-- @return any value Resolved config value or fallback/default
-- @usage local dist = ax.config:Get("voice.distance", 512)

--- Set a config value.
-- Values are sanitized to the registered type and networked when the key is
-- configured for replication.
-- @realm shared
-- @function ax.config:Set
-- @param key string Config key
-- @param value any New value
-- @param[opt=false] bNoSave boolean Skip persistence when `true`
-- @param[opt=false] bNoCallback boolean Skip `OnChanged` and hook callbacks when `true`
-- @return boolean success True when the value changed and was accepted
-- @usage ax.config:Set("voice.distance", 768)

--- Get metadata for a registered config key.
-- Returns a copy of the definition metadata table.
-- @realm shared
-- @function ax.config:GetData
-- @param key string Config key
-- @return table|nil metadata
-- @usage local meta = ax.config:GetData("voice.distance")

--- Get the default value for a config key.
-- @realm shared
-- @function ax.config:GetDefault
-- @param key string Config key
-- @return any defaultValue
-- @usage local defaultDistance = ax.config:GetDefault("voice.distance")

--- Get all registered config definitions.
-- @realm shared
-- @function ax.config:GetAllDefinitions
-- @return table definitions Map of `key -> definition`
-- @usage local defs = ax.config:GetAllDefinitions()

--- Get all config categories present in the registry.
-- @realm shared
-- @function ax.config:GetAllCategories
-- @return table categories Array of category names
-- @usage local categories = ax.config:GetAllCategories()

--- Get config definitions matching a category string.
-- Performs case-insensitive partial matching on the category name.
-- @realm shared
-- @function ax.config:GetAllByCategory
-- @param category string Category filter text
-- @return table definitions Map of `key -> definition`
-- @usage local voiceDefs = ax.config:GetAllByCategory("voice")

--- Reload persisted config values from disk.
-- Only has effect on the authority side (server for `ax.config`).
-- @realm shared
-- @function ax.config:Load
-- @return boolean success
-- @usage ax.config:Load()

--- Persist the current config values to disk.
-- Only has effect on the authority side (server for `ax.config`).
-- @realm shared
-- @function ax.config:Save
-- @return boolean success
-- @usage ax.config:Save()

--- Sync networked config keys to clients.
-- When called on the server, a specific client (or list of clients) may be
-- provided to limit the initial sync target.
-- @realm shared
-- @function ax.config:Sync
-- @param[opt] target Player|table Optional client or recipients list
-- @usage ax.config:Sync(client)
-- @usage ax.config:Sync()

--[[
    Config System - Server-owned settings with optional client networking

    Examples:
    ax.config:Add("thirdperson", ax.type.bool, true, { description = "Enable third-person view.", category = "camera", subCategory = "thirdperson" })
    ax.config:Add("gravityScale", ax.type.number, 1, { min = 0.1, max = 3, decimals = 2, bNoNetworking = true, category = "gameplay", subCategory = "physics" })
    ax.config:Add("admin.webhook", ax.type.string, "", { description = "Discord webhook URL.", bServerOnly = true, category = "general", subCategory = "admin" })

    ax.config:Set("thirdperson", false)
    print(ax.config:Get("thirdperson", true))  -- server: source of truth; client: cached
]]

-- Create the config store (preserve existing store during hot-reload)
local configSpec = {
    name = "config",
    data = {
        key = "config",
        options = {
            scope = "project",
            human = true
        }
    },
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
