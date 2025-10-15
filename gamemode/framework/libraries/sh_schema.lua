--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Schema management system for initializing and loading schemas.
-- Handles inclusion of schema-specific files and directories.
-- @module ax.schema

ax.schema = ax.schema or {}

--- Initialize the active schema and load all its components.
-- Loads the schema's boot file, includes all directories in proper order,
-- and initializes factions, classes, items, and modules.
-- @realm shared
-- @return boolean True if initialization succeeded, false if boot file failed to load
-- @usage ax.schema:Initialize()
function ax.schema:Initialize()
    SCHEMA = SCHEMA or { Folder = engine.ActiveGamemode() }

    ax.hook:Register("SCHEMA")

    local active = SCHEMA.Folder
    local boot = ax.util:Include(active .. "/gamemode/schema/boot.lua", "shared")
    if ( !boot ) then
        ax.util:PrintError("Failed to load schema boot file for \"" .. active .. "\". Please ensure your schema is set up correctly.")
        return false
    end

    ax.util:IncludeDirectory(active .. "/gamemode/schema/libraries", true)
    ax.util:IncludeDirectory(active .. "/gamemode/schema/meta", true)
    ax.util:IncludeDirectory(active .. "/gamemode/schema/core", true)
    ax.util:IncludeDirectory(active .. "/gamemode/schema/hooks", true)
    ax.util:IncludeDirectory(active .. "/gamemode/schema/networking", true)
    ax.util:IncludeDirectory(active .. "/gamemode/schema/interface", true)

    ax.util:IncludeDirectory(active .. "/gamemode/schema", true, {
        ["libraries"] = true,
        ["meta"] = true,
        ["core"] = true,
        ["hooks"] = true,
        ["networking"] = true,
        ["interface"] = true,
        ["factions"] = true,
        ["classes"] = true,
        ["items"] = true,
        ["boot.lua"] = true
    })

    ax.faction:Include(active .. "/gamemode/schema/factions")
    ax.class:Include(active .. "/gamemode/schema/classes")
    ax.item:Include(active .. "/gamemode/schema/items")

    ax.module:Include(active .. "/gamemode/modules")

    -- Initialize the schema
    ax.util:PrintSuccess("Schema \"" .. active .. "\" initialized successfully.")

    hook.Run("PostInitializeSchema")
end
