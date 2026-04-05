--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Utility helpers used across the Parallax framework (printing, file handling, text utilities, etc.).
-- @module ax.util

--- File and JSON helpers.
-- @section file_utilities

--- Determines the intended realm of a Lua file from its filename prefix.
-- Inspects only the filename component (not the directory path). The check is case-insensitive. Recognised prefixes:
-- - `cl_` → `"client"`
-- - `sv_` → `"server"`
-- - `sh_` or anything else → `"shared"` (default)
-- This is used internally by `Include` and `IncludeDirectory` to route files to the correct side automatically when no explicit realm is provided.
-- @realm shared
-- @param file string A filename or path. Only the final filename segment is examined (e.g. `"framework/cl_init.lua"` → inspects `"cl_init.lua"`).
-- @return string `"client"`, `"server"`, or `"shared"`.
-- @usage ax.util:DetectFileRealm("cl_hud.lua")         -- "client"
-- ax.util:DetectFileRealm("sv_database.lua")           -- "server"
-- ax.util:DetectFileRealm("sh_config.lua")             -- "shared"
-- ax.util:DetectFileRealm("framework/init.lua")        -- "shared"
function ax.util:DetectFileRealm(file)
    local fileName = string.GetFileFromFilename(file)
    if ( !fileName or !isstring(fileName) ) then
        return "shared"
    end

    if ( utf8 and utf8.lower ) then
        fileName = utf8.lower(fileName)
    else
        fileName = string.lower(fileName)
    end

    -- Client-side patterns
    if ( string.StartWith(fileName, "cl_") ) then
        return "client"
    end

    -- Server-side patterns
    if ( string.StartWith(fileName, "sv_") ) then
        return "server"
    end

    -- Shared patterns (default for sh_ prefix or no clear indication)
    return "shared"
end

local function SafeInclude(path)
    local success, result = pcall(include, path)
    if ( !success ) then
        ax.util:PrintWarning("Failed to include file: " .. path .. " - Error: " .. result)
        return nil
    end
    return result
end

local function SafeIncludeCS(path)
    local success, err = pcall(AddCSLuaFile, path)
    if ( !success ) then
        ax.util:PrintWarning("Failed to AddCSLuaFile for: " .. path .. " - Error: " .. err)
    end
end

--- Includes a Lua file with automatic realm-based routing.
-- Normalises path separators and strips leading slashes, then detects the realm via `DetectFileRealm` if no hint is provided. Routing rules:
-- - `"client"`: on the server, calls `AddCSLuaFile` only (sends to clients). On the client, calls `include`.
-- - `"server"`: calls `include` on the server only. No-op on the client.
-- - `"shared"`: on the server, calls both `AddCSLuaFile` and `include`. On the client, calls `include`.
-- Both `AddCSLuaFile` and `include` are wrapped with `pcall` internally to prevent one bad file from halting the entire boot sequence. A warning is printed on failure. Returns false for invalid or non-`.lua` paths.
-- @realm shared
-- @param path string Path to the Lua file, relative to the `LUA` mount point.
-- @param realm string|nil Realm override: `"client"`, `"server"`, or `"shared"`. Detected automatically from the filename prefix when omitted.
-- @return boolean True if an include or AddCSLuaFile was attempted, false on invalid input.
-- @usage ax.util:Include("framework/sh_util.lua")
-- ax.util:Include("framework/sv_database.lua", "server")
function ax.util:Include(path, realm)
    if ( !isstring(path) or path == "" ) then
        ax.util:PrintError("Include: Invalid path parameter provided")
        return false
    end

    if ( !string.EndsWith(path, ".lua") ) then
        ax.util:PrintWarning("Include: Path does not end with .lua: " .. path)
        return false
    end

    -- Normalize path separators
    path = string.gsub(path, "\\", "/")
    path = string.gsub(path, "^/+", "") -- Remove leading slashes

    -- Determine the realm if not provided
    if ( !isstring(realm) or realm == "" ) then
        realm = self:DetectFileRealm(path)
    end

    -- Include the file based on the realm
    if ( realm == "client" ) then
        if ( SERVER ) then
            SafeIncludeCS(path)
            return true
        else
            return SafeInclude(path)
        end
    elseif ( SERVER and realm == "server" ) then
        return SafeInclude(path)
    else
        if ( SERVER ) then
            SafeIncludeCS(path)
        end

        return SafeInclude(path)
    end
end

--- Recursively includes all `.lua` files found under a directory.
-- On the first call (not from recursion), the calling file's directory is detected via `debug.getinfo` and prepended to `directory` to resolve relative paths correctly. Subsequent recursive calls pass `fromLua = true` to skip that detection step.
-- Each `.lua` file is passed to `Include`, which handles realm detection and `AddCSLuaFile`/`include` routing. Subdirectories are processed depth-first.
-- Files and directories listed in `toSkip` (as keys, e.g. `{ ["boot.lua"] = true }`) are silently skipped. The optional `timeFilter` (in seconds) skips files that have not been modified within that time window — useful for selective hot-reload workflows.
-- @realm shared
-- @param directory string Path to the directory to scan, relative to the LUA mount or the calling file's directory.
-- @param fromLua boolean|nil Internal recursion flag. Pass nil or false on the first call; true is set automatically during recursion.
-- @param toSkip table|nil Table of filenames/directory names to skip, keyed by name (e.g. `{ ["ignore_me.lua"] = true }`).
-- @param timeFilter number|nil When provided, files modified more than this many seconds ago are skipped.
-- @return boolean True after the directory has been processed, false on invalid input.
-- @usage ax.util:IncludeDirectory("framework/libraries/")
-- ax.util:IncludeDirectory("modules/", nil, { ["old_module.lua"] = true })
function ax.util:IncludeDirectory(directory, fromLua, toSkip, timeFilter)
    if ( !isstring(directory) or directory == "" ) then
        ax.util:PrintError("IncludeDirectory: Invalid directory parameter provided")
        return false
    end

    -- Normalize path separators
    directory = string.gsub(directory, "\\", "/")
    directory = string.gsub(directory, "^/+", "") -- Remove leading slashes

    -- Get the active path if we are not doing it from lua
    local path = ""
    if ( !fromLua ) then
        path = debug.getinfo(2).source
        path = string.sub(path, 2, string.find(path, "/[^/]*$"))
        path = string.gsub(path, "gamemodes/", "")
    end

    -- Combine the path with the directory
    if ( !string.match(directory, "^/") ) then
        directory = path .. directory
    end

    if ( !string.EndsWith(directory, "/") ) then
        directory = directory .. "/"
    end

    -- Get all files in the directory
    local files, directories = file.Find(directory .. "*", "LUA")

    -- Include all files found in the directory
    for i = 1, #files do
        local fileName = files[i]
        local filePath = directory .. fileName

        -- Skip files in the toSkip list
        if ( toSkip and toSkip[fileName] ) then
            continue
        end

        -- Check file modification time if timeFilter is provided
        if ( isnumber(timeFilter) and timeFilter > 0 ) then
            local fileTime = file.Time(filePath, "LUA")
            local currentTime = os.time()

            if ( fileTime and (currentTime - fileTime) < timeFilter ) then
                ax.util:PrintWarning("Skipping unchanged file (modified " .. (currentTime - fileTime) .. "s ago): " .. fileName)
                continue
            end
        end

        ax.util:Include(filePath)
    end

    -- Recursively include all subdirectories
    for i = 1, #directories do
        local dirName = directories[i]
        if ( toSkip and toSkip[dirName] ) then
            continue
        end

        ax.util:IncludeDirectory(directory .. dirName .. "/", true, toSkip, timeFilter)
    end

    return true
end

--- Reads and parses a JSON file from the `DATA` directory.
-- Reads the file with `file.Read(path, "DATA")`, then deserialises it with `util.JSONToTable` (wrapped in `pcall`). Returns nil without throwing on any failure: missing file, empty file, or malformed JSON. Safe to call speculatively — a missing config file is not an error condition.
-- @realm shared
-- @param path string Path relative to the `DATA` directory (e.g. `"parallax/config.json"`).
-- @return table|nil The parsed Lua table, or nil on any failure.
-- @usage local cfg = ax.util:ReadJSON("parallax/config.json")
-- if ( cfg ) then print(cfg.version) end
function ax.util:ReadJSON(path)
    if ( !isstring(path) ) then return nil end

    local content = file.Read(path, "DATA")
    if ( !content ) then return nil end

    local success, data = pcall(util.JSONToTable, content)
    if ( success and istable(data) ) then
        return data
    end

    return nil
end

--- Serialises a table to JSON and writes it to a file in the `DATA` directory.
-- Creates any missing parent directories automatically before writing.
-- All failure cases (serialisation error, directory creation error, write error) print a warning and return false without throwing. Serialisation uses `util.TableToJSON` wrapped in `pcall`.
-- @realm shared
-- @param path string Path relative to the `DATA` directory where the file will be written (e.g. `"parallax/config.json"`).
-- @param tbl table The table to serialise and write.
-- @return boolean True on success, false on any failure.
-- @usage ax.util:WriteJSON("parallax/config.json", { version = "1.0" })
function ax.util:WriteJSON(path, tbl)
    if ( !isstring(path) or !istable(tbl) ) then return false end

    local success, json = pcall(util.TableToJSON, tbl)
    if ( !success or !isstring(json) or json == "" ) then
        ax.util:PrintWarning("WriteJSON: failed to encode table for path '" .. tostring(path) .. "'")
        return false
    end

    -- Ensure directory exists
    local dir = string.GetPathFromFilename(path)
    if ( dir and dir != "" ) then
        local okDir, errDir = pcall(file.CreateDir, dir)
        if ( !okDir ) then
            ax.util:PrintWarning("WriteJSON: failed to create directory '" .. tostring(dir) .. "' for path '" .. tostring(path) .. "': " .. tostring(errDir))
            return false
        end
    end

    local okWrite, errWrite = pcall(file.Write, path, json)
    if ( !okWrite ) then
        ax.util:PrintWarning("WriteJSON: failed to write path '" .. tostring(path) .. "': " .. tostring(errWrite))
        return false
    end

    return true
end

--- Builds a `DATA`-relative JSON file path for a given key and scope.
-- `key` is sanitised via `SanitizeKey` to remove filesystem-unsafe characters.
-- Three scope modes are supported via `options.scope`:
-- - `"global"` — `global/<key>.json`: shared across all gamemodes on the server.
-- - `"map"` — `<project>/maps/<mapname>/<key>.json`: per-map within the active gamemode. Uses `game.GetMap()` for the map name.
-- - `"project"` (default) — `<project>/<key>.json`: per-gamemode storage.
-- @realm shared
-- @param key string The data identifier. Will be sanitised.
-- @param options table|nil Optional settings:
--   - `scope` string: `"global"`, `"project"`, or `"map"` (default `"project"`).
-- @return string The constructed path relative to the `DATA` directory.
-- @usage ax.util:BuildDataPath("config")                          -- "parallax/config.json"
-- ax.util:BuildDataPath("config", { scope = "global" })          -- "global/config.json"
-- ax.util:BuildDataPath("zones", { scope = "map" })              -- "parallax/maps/gm_construct/zones.json"
function ax.util:BuildDataPath(key, options)
    options = options or {}

    local scope = options.scope or "project" -- "global", "project", "map"
    local name = self:SanitizeKey(key)
    local ext = ".json"
    if ( scope == "global" ) then
        return "global/" .. name .. ext
    elseif ( scope == "map" ) then
        local mapname = ( game and game.GetMap and game.GetMap() ) or "nomap"
        return self:GetProjectName() .. "/maps/" .. mapname .. "/" .. name .. ext
    else
        return self:GetProjectName() .. "/" .. name .. ext
    end
end

--- Creates all directories in a `DATA`-relative path that do not yet exist.
-- Splits `path` into segments by `/` and walks them cumulatively, calling `file.CreateDir` for each segment that is not already a directory. Idempotent — safe to call repeatedly even if the directories already exist.
-- Typically called before writing a file to guarantee its parent directories are present.
-- @realm shared
-- @param path string A `DATA`-relative path containing the directories to
--   create (e.g. `"parallax/maps/gm_construct/"`). The trailing slash is important — any final segment without a slash is treated as a filename and will not be created as a directory.
-- @usage ax.util:EnsureDataDir("parallax/settings/")
-- ax.util:EnsureDataDir("global/maps/rp_city/")
function ax.util:EnsureDataDir(path)
    -- Create any parent directories needed for a data path
    local parts = {}
    for p in string.gmatch(path, "([^/]+/)") do
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

-- Adapted and borrowed from Nutscript, tool inclusion has been borrowed from Helix.
-- https://github.com/NutScript/NutScript/blob/1.2-stable/gamemode/core/libs/sh_plugin.lua#L112
-- https://github.com/NebulousCloud/helix/blob/master/gamemode/core/libs/sh_plugin.lua#L192

--- Loads scripted entities, weapons, tools, and effects from a directory.
-- Scans four subdirectories under `path`: `entities/`, `weapons/`, `tools/`, and `effects/`. For each, both folder-based and single-file layouts are supported:
-- - **Folder layout**: a subdirectory per entity containing `init.lua` (server), `cl_init.lua` (client), and/or `shared.lua` (both).
-- - **Single-file layout**: a single `.lua` file per entity, included as shared.
-- Entities and weapons are registered with `scripted_ents.Register` and `weapons.Register` respectively. Tools are injected into `gmod_tool`'s Tool table. Effects are registered client-side only via `effects.Register`.
-- When any tools are loaded, `spawnmenu_reload` is issued on the client to refresh the spawnmenu. The optional `timeFilter` skips entities whose directory or file has not been modified within that many seconds — useful for selective hot-reload passes.
-- @realm shared
-- @param path string The base directory path (LUA-relative) to scan.
-- @param timeFilter number|nil When set, entities not modified within this many seconds are skipped.
-- @usage ax.util:LoadEntities("myaddon")
-- ax.util:LoadEntities("modules/weapons", 30) -- only reload recently changed
function ax.util:LoadEntities(path, timeFilter)
    local bLoadedTools
    local files, folders

    local function IncludeFiles(path2, bClientOnly)
        if ( SERVER and !bClientOnly ) then
            if ( file.Exists(path2 .. "init.lua", "LUA") ) then
                ax.util:Include(path2 .. "init.lua", "server")
            elseif ( file.Exists(path2 .. "shared.lua", "LUA") ) then
                ax.util:Include(path2 .. "shared.lua")
            end

            if ( file.Exists(path2 .. "cl_init.lua", "LUA") ) then
                ax.util:Include(path2 .. "cl_init.lua", "client")
            end
        elseif ( file.Exists(path2 .. "cl_init.lua", "LUA") ) then
            ax.util:Include(path2 .. "cl_init.lua", "client")
        elseif ( file.Exists(path2 .. "shared.lua", "LUA") ) then
            ax.util:Include(path2 .. "shared.lua")
        end
    end

    local function HandleEntityInclusion(folder, variable, register, default, clientOnly, create, complete)
        files, folders = file.Find(path .. "/" .. folder .. "/*", "LUA")
        default = default or {}

        for _, v in ipairs(folders) do
            local path2 = path .. "/" .. folder .. "/" .. v .. "/"
            v = string.lower(v)
            if ( string.StartWith(v, "sh_") or string.StartWith(v, "cl_") or string.StartWith(v, "sv_") ) then
                v = string.sub(v, 4)
            end

            if ( isnumber(timeFilter) and timeFilter > 0 ) then
                local fileTime = file.Time(path2, "LUA")
                local currentTime = os.time()

                if ( fileTime and (currentTime - fileTime) > timeFilter ) then
                    ax.util:PrintDebug("Skipping unchanged class file (modified " .. (currentTime - fileTime) .. "s ago): " .. v)
                    continue
                end
            end

            _G[variable] = table.Copy(default)

            if ( !isfunction(create) ) then
                _G[variable].ClassName = v
            else
                create(v)
            end

            IncludeFiles(path2, clientOnly)

            if ( clientOnly ) then
                if ( CLIENT ) then
                    register(_G[variable], v)
                end
            else
                register(_G[variable], v)
            end

            if ( isfunction(complete) ) then
                complete(_G[variable])
            end

            _G[variable] = nil
        end

        for _, v in ipairs(files) do
            local niceName = string.StripExtension(v)
            if ( string.StartWith(niceName, "sh_") or string.StartWith(niceName, "cl_") or string.StartWith(niceName, "sv_") ) then
                niceName = string.sub(niceName, 4)
            end

            if ( isnumber(timeFilter) and timeFilter > 0 ) then
                local fileTime = file.Time(path .. "/" .. folder .. "/" .. v, "LUA")
                local currentTime = os.time()

                if ( fileTime and (currentTime - fileTime) > timeFilter ) then
                    ax.util:PrintDebug("Skipping unchanged class file (modified " .. (currentTime - fileTime) .. "s ago): " .. v)
                    continue
                end
            end

            _G[variable] = table.Copy(default)

            if ( !isfunction(create) ) then
                _G[variable].ClassName = niceName
            else
                create(niceName)
            end

            ax.util:Include(path .. "/" .. folder .. "/" .. v, clientOnly and "client" or "shared")

            if ( clientOnly ) then
                if ( CLIENT ) then
                    register(_G[variable], niceName)
                end
            else
                register(_G[variable], niceName)
            end

            if ( isfunction(complete) ) then
                complete(_G[variable])
            end

            _G[variable] = nil
        end
    end

    local function RegisterTool(tool, className)
        local gmodTool = weapons.GetStored("gmod_tool")

        if ( className:sub(1, 3) == "sh_" ) then
            className = className:sub(4)
        end

        if ( gmodTool ) then
            gmodTool.Tool[className] = tool
        else
            -- this should never happen
            ErrorNoHalt(string.format("attempted to register tool '%s' with invalid gmod_tool weapon", className))
        end

        bLoadedTools = true
    end

    -- Include entities.
    HandleEntityInclusion("entities", "ENT", scripted_ents.Register, {
        Type = "anim",
        Base = "base_gmodentity",
        Spawnable = true
    })

    -- Include weapons.
    HandleEntityInclusion("weapons", "SWEP", weapons.Register, {
        Primary = {},
        Secondary = {},
        Base = "weapon_base"
    })

    HandleEntityInclusion("tools", "TOOL", RegisterTool, {}, false, function(className)
        if ( className:sub(1, 3) == "sh_" ) then
            className = className:sub(4)
        end

        TOOL = ax.tool.meta:Create()
        TOOL.Mode = className
        TOOL:CreateConVars()
    end)

    -- Include effects.
    HandleEntityInclusion("effects", "EFFECT", effects and effects.Register, nil, true)

    -- only reload spawn menu if any new tools were registered
    if ( CLIENT and bLoadedTools ) then
        RunConsoleCommand("spawnmenu_reload")
    end
end
