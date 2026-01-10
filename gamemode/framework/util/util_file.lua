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
    local success, err = pcall(include, path)
    if ( !success ) then
        ax.util:PrintWarning("Failed to include file: " .. path .. " - Error: " .. err)
    end
end

local function SafeIncludeCS(path)
    local success, err = pcall(AddCSLuaFile, path)
    if ( !success ) then
        ax.util:PrintWarning("Failed to AddCSLuaFile for: " .. path .. " - Error: " .. err)
    end
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
        else
            SafeInclude(path)
        end
    elseif ( SERVER and realm == "server" ) then
        SafeInclude(path)
    else
        if ( SERVER ) then
            SafeIncludeCS(path)
        end

        SafeInclude(path)
    end

    return true
end

--- Recursively includes all Lua files found under a directory.
-- @param directory string Directory path to include (relative to gamemode)
-- @param fromLua boolean|nil Internal flag used when recursing from Lua
-- @param toSkip table|nil Optional set of filenames or directory names to skip
-- @return boolean True if directory processed
-- @usage ax.util:IncludeDirectory("framework/libraries/")
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

-- Adapted and borrowed from Nutscript, tool inclusion has been borrowed from Helix.
-- https://github.com/NutScript/NutScript/blob/1.2-stable/gamemode/core/libs/sh_plugin.lua#L112
-- https://github.com/NebulousCloud/helix/blob/master/gamemode/core/libs/sh_plugin.lua#L192

function ax.util:LoadEntities(path) -- TODO: Implement timeFilter and skipping unchanged files
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
