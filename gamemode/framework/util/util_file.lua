--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Utility helpers used across the Parallax framework (printing, file handling, text utilities, etc.).
-- @module ax.util

--- File and JSON helpers.
-- @section file_utilities

--- Detects the realm of a file based on its name.
-- @param file string Filename to inspect (may include path)
-- @return string One of "client", "server", or "shared"
-- @usage local realm = ax.util:DetectFileRealm("cl_init.lua") -- returns "client"
function ax.util:DetectFileRealm(file)
    local fileName = string.GetFileFromFilename(file)
    if ( !fileName or !isstring( fileName ) ) then
        return "shared"
    end

    fileName = string.lower(fileName)

    -- Client-side patterns
    if ( string.Left( fileName, 3 ) == "cl_" ) then
        self:PrintDebug("Detected client-side file: " .. fileName)
        return "client"
    end

    -- Server-side patterns
    if ( string.Left( fileName, 3 ) == "sv_" ) then
        self:PrintDebug("Detected server-side file: " .. fileName)
        return "server"
    end

    self:PrintDebug("Detected shared file: " .. fileName)

    -- Shared patterns (default for sh_ prefix or no clear indication)
    return "shared"
end

--- Includes a Lua file, handling AddCSLuaFile/include based on realm.
-- @param path string Path to the Lua file to include (relative to gamemode)
-- @param realm string|nil Optional realm hint: "client", "server", or "shared"
-- @return boolean True if include/AddCSLuaFile was attempted
-- @usage ax.util:Include("framework/util.lua")
function ax.util:Include(path, realm)
    if ( !isstring(path) or path == "" ) then
        ax.util:PrintError("Include: Invalid path parameter provided")
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
            AddCSLuaFile(path)
        else
            include(path)
        end
    elseif ( SERVER and realm == "server" ) then
        include(path)
    else
        if ( SERVER ) then
            AddCSLuaFile(path)
        end

        include(path)
    end

    -- Print debug information if developer mode is enabled
    ax.util:PrintDebug("Included file: " .. path .. " with realm: " .. realm)
    return true
end

--- Recursively includes all Lua files found under a directory.
-- @param directory string Directory path to include (relative to gamemode)
-- @param fromLua boolean|nil Internal flag used when recursing from Lua
-- @param toSkip table|nil Optional set of filenames or directory names to skip
-- @return boolean True if directory processed
-- @usage ax.util:IncludeDirectory("framework/libraries/")
function ax.util:IncludeDirectory(directory, fromLua, toSkip)
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
            ax.util:PrintDebug("Skipping file in toSkip list: " .. fileName)
            continue
        end

        ax.util:Include(filePath)
    end

    -- Recursively include all subdirectories
    for i = 1, #directories do
        local dirName = directories[i]
        if ( toSkip and toSkip[dirName] ) then
            ax.util:PrintDebug("Skipping directory in toSkip list: " .. dirName)
            continue
        end

        ax.util:PrintDebug("Recursively including directory: " .. dirName)
        ax.util:IncludeDirectory(directory .. dirName .. "/", true, toSkip)
    end

    -- Print debug information if developer mode is enabled
    ax.util:PrintDebug("Included directory: " .. directory)
    return true
end

--- Read and parse a JSON file from DATA safely.
-- @param path string Path in DATA to read
-- @return table|nil Parsed table or nil on error
-- @usage local cfg = ax.util:ReadJSON("parallax/config.json")
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

--- Write a table to a JSON file in DATA safely.
-- @param path string Path in DATA to write
-- @param tbl table Table to serialize
-- @return boolean True on success
-- @usage ax.util:WriteJSON("parallax/config.json", myTable)
function ax.util:WriteJSON(path, tbl)
    if ( !isstring(path) or !istable(tbl) ) then return false end

    local success, json = pcall(util.TableToJSON, tbl)
    if ( !success ) then return false end

    -- Ensure directory exists
    local dir = string.GetPathFromFilename(path)
    if ( dir and dir != "" ) then
        file.CreateDir(dir)
    end

    file.Write(path, json)

    return true
end

--- Build a data file path based on key and scope options.
-- @param key string The data key
-- @param options table|nil Options table (scope, human)
-- @return string The data file path relative to DATA
-- @usage local path = ax.util:BuildDataPath("settings_player", { scope = "project" })
function ax.util:BuildDataPath(key, options)
    options = options or {}
    local scope = options.scope or "project" -- "global", "project", "map"
    local name = self:SanitizeKey(key)
    local ext = options.human and ".json" or ".dat"

    if ( scope == "global" ) then
        return "global/" .. name .. ext
    elseif ( scope == "map" ) then
        local mapname = ( game and game.GetMap and game.GetMap() ) or "nomap"
        return self:GetProjectName() .. "/maps/" .. mapname .. "/" .. name .. ext
    else
        return self:GetProjectName() .. "/" .. name .. ext
    end
end

--- Ensure parent directories exist for a given data path.
-- @param path string Data path to ensure directories for (e.g. "parallax/foo/bar/")
-- @usage ax.util:EnsureDataDir("parallax/settings_player/")
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
