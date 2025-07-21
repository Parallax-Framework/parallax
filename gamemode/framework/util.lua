--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

function ax.util:DetectFileRealm(file)
    if ( !file or type(file) != "string" ) then
        return "shared"
    end

    local fileName = string.lower(file)

    -- Client-side patterns
    if ( string.match(fileName, "^cl_") or
        string.match(fileName, "/cl_") ) then
        self:PrintDebug("Detected client-side file: " .. fileName)
        return "client"
    end

    -- Server-side patterns
    if ( string.match(fileName, "^sv_") or
        string.match(fileName, "/sv_") ) then
        self:PrintDebug("Detected server-side file: " .. fileName)
        return "server"
    end

    self:PrintDebug("Detected shared file: " .. fileName)

    -- Shared patterns (default for sh_ prefix or no clear indication)
    return "shared"
end

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

-- Recursively include all files in a directory
function ax.util:IncludeDirectory(directory, fromLua)
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
        if ( string.EndsWith(fileName, ".lua") ) then
            ax.util:Include(filePath)
        else
            ax.util:PrintWarning("Skipping non-Lua file in directory: " .. filePath)
        end
    end

    -- Recursively include all subdirectories
    for i = 1, #directories do
        ax.util:PrintDebug("Recursively including directory: " .. directories[i])
        ax.util:IncludeDirectory(directory .. directories[i])
    end

    -- Print debug information if developer mode is enabled
    ax.util:PrintDebug("Included directory: " .. directory)
    return true
end

-- Prepares a package of arguments for printing.
-- @realm shared
-- @param ... any The package to prepare.
-- @return any The prepared package.
function ax.util:PreparePackage(...)
    local arguments = {...}
    local package = {}

    for i = 1, #arguments do
        local arg = arguments[i]
        if ( isentity(arg) and IsValid(arg) ) then
            package[#package + 1] = tostring(arg)

            if ( arg:IsPlayer() ) then
                package[#package + 1] = "[" .. arg:SteamID64() .. "]"
            end
        else
            package[#package + 1] = arg
        end
    end

    package[#package + 1] =  "\n"

    return package
end

local color_print = Color(100, 150, 255)
local color_warning = Color(255, 200, 100)
local color_success = Color(100, 255, 100)
local color_debug = Color(150, 150, 150)

-- Print a regular message with framework styling
function ax.util:Print(...)
    local args = self:PreparePackage(...)

    MsgC(color_print, "[PARALLAX] ", unpack(args))

    return args
end

-- Print an error message
function ax.util:PrintError(...)
    local args = self:PreparePackage(...)

    ErrorNoHaltWithStack("[PARALLAX] [ERROR] " .. string.Trim(table.concat(args, " ")))

    return args
end

-- Print a warning message
function ax.util:PrintWarning(...)
    local args = self:PreparePackage(...)

    MsgC(color_warning, "[PARALLAX] [WARNING] ", unpack(args))

    return args
end

-- Print a success message
function ax.util:PrintSuccess(...)
    local args = self:PreparePackage(...)

    MsgC(color_success, "[PARALLAX] [SUCCESS] ", unpack(args))

    return args
end

-- Print a debug message (only when developer mode is enabled)
local developer = GetConVar("developer")
function ax.util:PrintDebug(...)
    if ( developer:GetInt() < 1 ) then return end

    local args = self:PreparePackage(...)

    MsgC(color_debug, "[PARALLAX] [DEBUG] ", unpack(args))

    return args
end

function ax.util:FindString(str, find)
    if ( str == nil or find == nil ) then
        ax.util:PrintError("Attempted to find a string with no value to find for! (" .. tostring(str) .. ", " .. tostring(find) .. ")")
        return false
    end

    str = string.lower(str)
    find = string.lower(find)

    return string.find(str, find) != nil
end

function ax.util:FindText(txt, find)
    if ( txt == nil or find == nil ) then return false end

    local words = string.Explode(" ", txt)
    for i = 1, #words do
        if ( self:FindString(words[i], find) ) then
            return true
        end
    end

    return false
end

function ax.util:FindPlayer(identifier)
    if ( identifier == nil ) then return NULL end

    if ( isentity(identifier) and IsValid(identifier) and identifier:IsPlayer() ) then
        return identifier
    end

    if ( isnumber(identifier) ) then
        return Entity(identifier)
    end

    if ( isstring(identifier) ) then
        if ( ax.util:CoerceType(ax.types.steamid, identifier) ) then
            return player.GetBySteamID(identifier)
        elseif ( ax.util:CoerceType(ax.types.steamid64, identifier) ) then
            return player.GetBySteamID64(identifier)
        end

        for _, v in player.Iterator() do
            if ( self:FindString(v:Name(), identifier) or self:FindString(v:SteamName(), identifier) or self:FindString(v:SteamID(), identifier) or self:FindString(v:SteamID64(), identifier) ) then
                return v
            end
        end
    end

    if ( istable(identifier) ) then
        for i = 1, #identifier do
            local foundPlayer = self:FindPlayer(identifier[i])

            if ( IsValid(foundPlayer) ) then
                return foundPlayer
            end
        end
    end

    return NULL
end