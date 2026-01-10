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
-- @module ax.data

ax.data = ax.data or {}
ax.data.cache = ax.data.cache or {}

--- Save a value to disk.
-- @param key string Unique key used to name the file.
-- @param value any Value to persist. Tables are serialized as JSON.
-- @param options table Optional. Fields:
--  - scope: "global"|"project"|"map" (default: "project")
--  - human: boolean If true, writes pretty JSON (.json extension)
--  - noCache: boolean If true, clears cache after writing
-- @usage ax.data:Set("settings_player", { volume = 0.8 }, { scope = "project", human = true })
function ax.data:Set(key, value, options)
    options = options or {}

    local path = ax.util:BuildDataPath(key, options)
    ax.util:EnsureDataDir(path)

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

        self.cache[path] = parsed
    else
        self.cache[path] = nil
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
function ax.data:Get(key, default, options)
    options = options or {}

    local path = ax.util:BuildDataPath(key, options)
    if ( !options.force ) then
        local cached = self.cache[path]
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
            self.cache[path] = decoded.__value
            return decoded.__value
        end

        self.cache[path] = decoded

        return decoded
    end

    -- Fallback: return raw string
    self.cache[path] = raw

    return raw
end

--- Delete a stored file.
-- @param key string
-- @param options table Optional. Fields:
--  - scope: "global"|"project"|"map" (default: "project")
-- @usage ax.data:Delete("settings_player", { scope = "project" })
function ax.data:Delete(key, options)
    options = options or {}

    local path = ax.util:BuildDataPath(key, options)
    if ( file.Exists(path, "DATA") ) then
        file.Delete(path)
    end

    self.cache[path] = nil

    return true
end
