--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Option system for per-client preferences with optional server synchronization.
-- Client-owned settings that can optionally sync to server for gameplay features.
-- Supports local persistence and automatic networking for multiplayer consistency.
-- @module ax.option
-- @usage ax.option:Add("headbob", ax.type.bool, true, { category = "camera" })
-- @usage ax.option:Set("headbob", false)  -- saves client-side; networks if bNoNetworking=false
-- @usage local lang = ax.option:Get(player, "language", "english")  -- server reading player option

--[[
    Option System - Per-client preferences with optional server sync

    Examples:
    ax.option:Add("headbob", ax.type.bool, true, { category = "camera", subCategory = "view" })
    ax.option:Add("language", ax.type.array, "english", {
        category = "general",
        subCategory = "basic",
        populate = function() return { english = "English", german = "German", french = "French" } end
    })

    if ( CLIENT ) then
        print(ax.option:Get("headbob", true))
        ax.option:Set("headbob", false)  -- saves client-side; networks only if bNoNetworking=false
        ax.option:Sync()                 -- push all networked options now
    end

    if ( SERVER ) then
        -- Read a player's networked option
        local client = somePlayer
        print(ax.option:Get(client, "language", "english"))
    end
]]

-- Create the option store (preserve existing store during hot-reload)
local optionSpec = {
    name = "option",
    data = {
        key = "parallax_options",
        options = {
            scope = "global",
            human = true
        }
    },
    path = function()
        return ax.util:BuildDataPath("parallax_options", { scope = "global" })
    end,
    legacyPaths = {
        "parallax/options.json"
    },
    authority = "client",
    net = {
        sync = "option.sync",
        set = "option.set",
        request = "option.request"
    },
    perPlayer = true
}

-- Check if store library was updated or if store doesn't exist yet
local storeLibTime = file.Time("gamemodes/parallax/gamemode/framework/util/util_store.lua", "GAME") or 0
local needsRebuild = !ax.option or !ax.option.Add or (ax.option._libTime and ax.option._libTime != storeLibTime)

if ( needsRebuild ) then
    local oldStore = (ax.option and ax.option.Add) and ax.option or nil
    ax.option = ax.util:CreateStore(optionSpec, oldStore)
    ax.option:_setupNetworking()

    -- Load options on client startup (only if not migrating from old store)
    if ( CLIENT and !oldStore ) then
        ax.option:Load()
    end
end
