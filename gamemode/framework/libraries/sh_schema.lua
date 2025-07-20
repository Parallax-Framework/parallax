--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.schema = ax.schema or {}

function ax.schema:Initialize()
    SCHEMA = SCHEMA or {}

    local active = engine.ActiveGamemode()
    local boot = ax.util:Include(active .. "/gamemode/schema/boot.lua", "shared")
    if ( !boot ) then
        ax.util:PrintError("Failed to load schema boot file for \"" .. active .. "\". Please ensure your schema is set up correctly.")
        return false
    end

    -- Initialize the schema
    ax.util:PrintSuccess("Schema \"" .. active .. "\" initialized successfully.")
end