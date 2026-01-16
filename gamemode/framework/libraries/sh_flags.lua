--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Flag management system for character permissions and abilities.
-- Flags are single-letter permissions that can be assigned to characters.
-- Used for controlling access to items, commands, areas, and other features.
-- @module ax.flag

ax.flag = ax.flag or {}
ax.flag.stored = ax.flag.stored or {}

--- Create a new flag with associated data.
-- Registers a flag letter with its description and metadata.
-- @realm shared
-- @param letter string Single letter flag identifier (A-Z, a-z)
-- @param flagData table Flag metadata including name, description, etc.
-- @usage ax.flag:Create("a", {name = "Admin", description = "Administrative access"})
function ax.flag:Create(letter, flagData)
    if ( !isstring(letter) or #letter > 1 ) then
        ax.util:PrintError("Invalid flag letter provided to ax.flag:Create()")
        return
    end

    self.stored[letter] = flagData
end

--- Get all registered flags.
-- Returns the complete registry of flag letters and their data.
-- @realm shared
-- @return table Table of all flag definitions
-- @usage local allFlags = ax.flag:GetAll()
function ax.flag:GetAll()
    return self.stored
end

--- Get a flag definition by its letter.
-- Retrieves the flag data associated with a specific flag letter.
-- @realm shared
-- @param letter string Single letter flag identifier
-- @return table|nil Flag data if found, nil otherwise
-- @usage local adminFlag = ax.flag:Get("a")
function ax.flag:Get(letter)
    if ( !isstring(letter) or #letter > 1 ) then
        ax.util:PrintError("Invalid flag letter provided to ax.flag:Get()")
        return
    end

    return self.stored[letter]
end
