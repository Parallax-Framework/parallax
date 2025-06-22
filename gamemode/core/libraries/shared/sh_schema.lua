--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Schema library.
-- @module ax.schema

ax.schema = {}

local default = {
    Name = "Unknown",
    Description = "No description available.",
    Author = "Unknown"
}

--- Initializes the schema.
-- @realm shared
-- @return boolean Returns true if the schema was successfully initialized, false otherwise.
-- @internal
function ax.schema:Initialize()
    SCHEMA = SCHEMA or {}

    local folder = engine.ActiveGamemode()
    local schema = folder .. "/schema/boot.lua"

    file.CreateDir("parallax/" .. folder)

    ax.util:Print("Searching for schema...")

    local bSuccess = file.Exists(schema, "LUA")
    if ( !bSuccess ) then
        ax.util:PrintError("Schema not found!")
        return false
    else
        SCHEMA.Folder = folder

        ax.util:Print("Schema found, loading \"" .. SCHEMA.Folder .. "\"...")
    end

    hook.Run("PreInitializeSchema", SCHEMA, schema)

    for k, v in pairs(default) do
        if ( !SCHEMA[k] ) then
            SCHEMA[k] = v
        end
    end

    ax.hooks:Register("SCHEMA")
    ax.util:LoadFolder(folder .. "/schema/libraries/external", true)
    ax.util:LoadFolder(folder .. "/schema/libraries/client", true)
    ax.util:LoadFolder(folder .. "/schema/libraries/shared", true)
    ax.util:LoadFolder(folder .. "/schema/libraries/server", true)
    ax.util:LoadFolder(folder .. "/schema/factions", true)
    ax.util:LoadFolder(folder .. "/schema/classes", true)
    ax.util:LoadFolder(folder .. "/schema/definitions", true)
    ax.util:LoadFolder(folder .. "/schema/meta", true)
    ax.util:LoadFolder(folder .. "/schema/ui", true)
    ax.util:LoadFolder(folder .. "/schema/hooks", true)
    ax.util:LoadFolder(folder .. "/schema/net", true)
    ax.util:LoadFolder(folder .. "/schema/languages", true)
    ax.item:LoadFolder(folder .. "/schema/items")
    ax.util:LoadFolder(folder .. "/schema/config", true)

    -- Load the current map config if it exists
    local map = game.GetMap()
    local path = folder .. "/schema/config/maps/" .. map .. ".lua"
    if ( file.Exists(path, "LUA") ) then
        hook.Run("PreInitializeMapConfig", SCHEMA, path, map)
        ax.util:Print("Loading map config for \"" .. map .. "\"...")
        ax.util:LoadFile(path, "shared")
        ax.util:Print("Loaded map config for \"" .. map .. "\".")
        hook.Run("PostInitializeMapConfig", SCHEMA, path, map)
    else
        ax.util:PrintWarning("Failed to find map config for \"" .. map .. "\".")
    end

    if ( SERVER ) then
        ax.config:Load()
    end

    -- Load the sh_schema.lua file after we load all necessary files
    ax.util:LoadFile(schema, "shared")

    -- Load the modules after the schema file is loaded
    ax.module:LoadFolder(folder .. "/modules")

    -- Load the database configuration
    if ( SERVER ) then
        local database = folder .. "/schema/database.lua"
        if ( file.Exists(database, "LUA") ) then
            ax.util:Print("Loading database config...")
            ax.util:LoadFile(folder .. "/schema/database.lua", "server")
            ax.util:Print("Loaded database config.")
        else
            ax.util:PrintWarning("Failed to find database config, using SQLite.")
            ax.database:Initialize()
        end
    end

    ax.util:Print("Loaded schema " .. SCHEMA.Name)

    hook.Run("PostInitializeSchema", SCHEMA, path)

    return true
end

ax.schema = ax.schema