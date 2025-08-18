--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Simple data persistence helpers.
-- Stores files under the Garry's Mod `data/` folder with options for
-- global, project, or map-scoped storage. Returns cached values by
-- default and supports human-readable JSON output.
-- @realm shared
-- @module ax.data

ax.data = ax.data or {}
ax.data._cache = ax.data._cache or {}

local function sanitizeKey( key )
    if ( !key ) then return "" end

    -- Replace any path unfriendly characters with underscore
    return string.gsub(tostring(key), "[^%w%-_.]", "_")
end

local function getProjectName()
    -- Try to detect active gamemode folder; fall back to 'parallax'
    if ( engine and engine.ActiveGamemode ) then
        return engine.ActiveGamemode() or "parallax"
    end

    return "parallax"
end

local function buildPath( key, options )
    options = options or {}
    local scope = options.scope or "project" -- "global", "project", "map"
    local name = sanitizeKey( key )
    local ext = options.human and ".json" or ".dat"

    if ( scope == "global" ) then
        return "global/" .. name .. ext
    elseif ( scope == "map" ) then
        local mapname = ( game and game.GetMap and game.GetMap() ) or "nomap"
        return getProjectName() .. "/maps/" .. mapname .. "/" .. name .. ext
    else
        return getProjectName() .. "/" .. name .. ext
    end
end

local function ensureDirForPath( path )
    -- Create any parent directories needed for a data path
    local parts = {}
    for p in string.gmatch( path, "([^/]+/)" ) do
        parts[#parts + 1] = p
    end

    local cur = ""
    for _, p in ipairs(parts) do
        cur = cur .. p
        if ( !file.IsDir(cur, "DATA") ) then
            file.CreateDir(cur)
        end
    end
end

--- Save a value to disk.
-- @param key string Unique key used to name the file.
-- @param value any Value to persist. Tables are serialized as JSON.
-- @param options table Optional. Fields:
--  - scope: "global"|"project"|"map" (default: "project")
--  - human: boolean If true, writes pretty JSON (.json extension)
--  - noCache: boolean If true, clears cache after writing
-- @usage ax.data:Set("settings_player", { volume = 0.8 }, { scope = "project", human = true })
function ax.data:Set( key, value, options )
    options = options or {}
    local path = buildPath(key, options)

    -- Ensure directory exists
    ensureDirForPath(path)

    local payload
    if ( istable(value) ) then
        payload = util.TableToJSON(value, options.human)
    else
        -- For other types, store a JSON representation for consistency
        payload = util.TableToJSON({ __value = value }, options.human)
    end

    file.Write(path, payload)

    if ( !options.noCache ) then
        -- Populate cache with parsed value for quick reads
        local parsed = nil
        if ( istable(value) ) then
            parsed = value
        else
            parsed = value
        end

        self._cache[path] = parsed
    else
        self._cache[path] = nil
    end

    return true
end

--- Load a value from disk.
-- @param key string
-- @param default any Value returned if the file does not exist.
-- @param options table Optional. Fields:
--  - scope: "global"|"project"|"map" (default: "project")
--  - force: boolean If true, bypass cache and read from disk
-- @return any
-- @usage local cfg = ax.data:Get("settings_player", {}, { force = false })
function ax.data:Get( key, default, options )
    options = options or {}
    local path = buildPath( key, options )

    if ( !options.force ) then
        local cached = self._cache[path]
        if ( cached != nil ) then
            return cached
        end
    end

    if ( !file.Exists(path, "DATA" )) then
        return default
    end

    local raw = file.Read(path, "DATA") or ""
    if ( raw == "" ) then return default end

    -- Try to parse JSON. If it looks like our wrapper for primitives, unwrap it.
    local ok, decoded = pcall(util.JSONToTable, raw)
    if ( ok and decoded ) then
        -- If decoded is a table with __value wrapper, return raw value
        if ( istable(decoded) and decoded.__value != nil and table.Count(decoded) == 1 ) then
            self._cache[path] = decoded.__value
            return decoded.__value
        end

        self._cache[path] = decoded

        return decoded
    end

    -- Fallback: return raw string
    self._cache[path] = raw

    return raw
end

--- Delete a stored file.
-- @param key string
-- @param options table Optional. Fields:
--  - scope: "global"|"project"|"map" (default: "project")
-- @usage ax.data:Delete("settings_player", { scope = "project" })
function ax.data:Delete( key, options )
    options = options or {}

    local path = buildPath( key, options )
    if ( file.Exists(path, "DATA") ) then
        file.Delete(path)
    end

    self._cache[path] = nil

    return true
end