--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Detect the realm of a file based on its name
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

-- Include a file with the specified path and realm
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
        if ( string.EndsWith(fileName, ".lua") ) then
            -- Skip files in the toSkip list
            if ( toSkip and toSkip[fileName] ) then
                ax.util:PrintDebug("Skipping file in toSkip list: " .. fileName)
                continue
            end

            ax.util:Include(filePath)
        else
            ax.util:PrintWarning("Skipping non-Lua file in directory: " .. filePath)
        end
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

-- Prepares a package of arguments for printing.
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

-- Find a specific piece of text within a larger body of text
function ax.util:FindString(str, find)
    if ( str == nil or find == nil ) then
        ax.util:PrintError("Attempted to find a string with no value to find for! (" .. tostring(str) .. ", " .. tostring(find) .. ")")
        return false
    end

    str = string.lower(str)
    find = string.lower(find)

    return string.find(str, find) != nil
end

-- Find a specific piece of text within a larger body of text
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

-- Find a player by their identifier (SteamID, SteamID64, or name)
function ax.util:FindPlayer(identifier)
    if ( identifier == nil ) then return NULL end

    if ( isentity(identifier) and IsValid(identifier) and identifier:IsPlayer() ) then
        return identifier
    end

    if ( isnumber(identifier) ) then
        return Entity(identifier)
    end

    if ( isstring(identifier) ) then
        if ( ax.type:Sanitise(ax.type.steamid, identifier) ) then
            return player.GetBySteamID(identifier)
        elseif ( ax.type:Sanitise(ax.type.steamid64, identifier) ) then
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

-- Safely parse a JSON table
function ax.util:SafeParseTable(tInput)
    if ( isstring(tInput) ) then
        return util.JSONToTable(tInput)
    end

    return tInput
end

-- Safely call a function and capture errors.
function ax.util:SafeCall(fn, ...)
    if ( !isfunction(fn) ) then
        return false
    end

    local results = { pcall(fn, ...) }
    local ok = results[1]

    if ( !ok ) then
        -- results[2] is the error message
        self:PrintError("SafeCall: function threw an error: ", results[2])
        return false
    end

    -- Remove the boolean success and return remaining values
    table.remove(results, 1)

    return true, table.unpack(results)
end

-- Convert a name to a unique ID
function ax.util:NameToUniqueID(name)
    -- Replace spaces with underscores
    name = name:gsub("%s+", "_")

    -- Remove everything not in A-Z, a-z, or underscore
    name = name:gsub("[^A-Za-z_]", "")

    -- Convert to lowercase
    return name:lower()
end

-- Convert a unique ID to a name
function ax.util:UniqueIDToName(id)
    -- Replace underscores with spaces
    local name = id:gsub("_", " ")

    -- Insert spaces before uppercase letters (for camelCase or PascalCase)
    name = name:gsub("([a-z])([A-Z])", "%1 %2")

    -- Capitalize the first letter of each word
    name = name:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)

    return name
end

-- Cap the text to a certain number of characters
function ax.util:CapText(text, maxLength)
    if ( !isstring(text) or !isnumber(maxLength) or maxLength <= 0 ) then
        ax.util:PrintError("Attempted to cap text with invalid parameters", text, maxLength)
        return ""
    end

    if ( #text <= maxLength ) then
        return text
    end

    return string.sub(text, 1, maxLength - 3) .. "..."
end

-- Cap the text at a certain number of characters, but only at word boundaries
function ax.util:CapTextWord(text, maxLength)
    if ( !isstring(text) or !isnumber(maxLength) or maxLength <= 0 ) then
        ax.util:PrintError("Attempted to cap text with invalid parameters", text, maxLength)
        return ""
    end

    if ( #text <= maxLength ) then
        return text
    end

    local words = string.Explode(" ", text)
    local cappedText = ""

    for i = 1, #words do
        local word = words[i]
        if ( #cappedText + #word + 1 > maxLength ) then
            break
        end

        if ( cappedText != "" ) then
            cappedText = cappedText .. " "
        end

        cappedText = cappedText .. word
    end

    return cappedText .. "..."
end

-- Wrap text to fit within a specified width
function ax.util:GetWrappedText(text, font, maxWidth)
    if ( !isstring(text) or !isstring(font) or !isnumber(maxWidth) ) then
        ax.util:PrintError("Attempted to wrap text with no value", text, font, maxWidth)
        return false
    end

    local lines = {}
    local line = ""

    if ( self:GetTextWidth(font, text) <= maxWidth ) then
        return {text}
    end

    local words = string.Explode(" ", text)

    for i = 1, #words do
        local word = words[i]
        local wordWidth = self:GetTextWidth(font, word)

        if ( wordWidth > maxWidth ) then
            for j = 1, string.len(word) do
                local char = string.sub(word, j, j)
                local next = line .. char

                if ( self:GetTextWidth(font, next) > maxWidth ) then
                    lines[#lines + 1] = line
                    line = ""
                end

                line = line .. char
            end

            continue
        end

        local space = (line == "") and "" or " "
        local next = line .. space .. word

        if ( self:GetTextWidth(font, next) > maxWidth ) then
            lines[#lines + 1] = line
            line = word
        else
            line = next
        end
    end

    if ( line != "" ) then
        lines[#lines + 1] = line
    end

    return lines
end

-- Returns a material from the cache or creates a new one
local stored = {}
function ax.util:GetMaterial(path, parameters)
    if ( !tostring(path) ) then
        ax.util:PrintError("Attempted to get a material with no path", path, parameters)
        return false
    end

    parameters = tostring(parameters or "")
    local uniqueID = Format("material.%s.%s", path, parameters)

    if ( stored[uniqueID] ) then
        return stored[uniqueID]
    end

    local mat = Material(path, parameters)
    stored[uniqueID] = mat

    return mat
end

if ( CLIENT ) then
    -- Returns the given text's width.
    function ax.util:GetTextWidth(font, text)
        surface.SetFont(font)
        return select(1, surface.GetTextSize(text))
    end

    -- Returns the given text's height.
    function ax.util:GetTextHeight(font)
        surface.SetFont(font)
        return select(2, surface.GetTextSize("W"))
    end

    -- Returns the given text's size.
    function ax.util:GetTextSize(font, text)
        surface.SetFont(font)
        return surface.GetTextSize(text)
    end

    local BLUR_MAT = ax.util:GetMaterial("pp/blurscreen")
    local _ax_blur_last_update = 0
    function ax.util:DrawPanelBlur(panel, passes, density, alpha, throttle, clip)
        if ( !IsValid(panel) ) then return end

        passes = math.max(1, math.floor(passes or 3))
        density = density or 1.0
        alpha = math.Clamp(tonumber(alpha or 180) or 180, 0, 255)
        throttle = tonumber(throttle or 0) or 0
        clip = clip == nil and true or clip

        if ( alpha <= 0 ) then return end

        local sx, sy = panel:LocalToScreen(0, 0)
        local w, h = panel:GetWide(), panel:GetTall()

        local now = CurTime()
        local can_update = (throttle <= 0) or (now - _ax_blur_last_update >= throttle)

        surface.SetMaterial(BLUR_MAT)
        surface.SetDrawColor(255, 255, 255, alpha)

        if ( clip ) then
            render.SetScissorRect(sx, sy, sx + w, sy + h, true)
        end

        for i = 1, passes do
            BLUR_MAT:SetFloat("$blur", i * density)
            if ( can_update ) then
                render.UpdateScreenEffectTexture()
            end
            surface.DrawTexturedRect(-sx, -sy, ScrW(), ScrH())
        end

        if ( clip ) then
            render.SetScissorRect(0, 0, 0, 0, false)
        end

        if ( can_update ) then
            _ax_blur_last_update = now
        end
    end

    function ax.util:DrawRectBlur(x, y, w, h, passes, density, alpha, throttle)
        passes = math.max(1, math.floor(passes or 3))
        density = density or 1.0
        alpha = math.Clamp(tonumber(alpha or 180) or 180, 0, 255)
        throttle = tonumber(throttle or 0) or 0

        if ( alpha <= 0 ) then return end

        local now = CurTime()
        local can_update = ( throttle <= 0 ) or ( now - _ax_screen_blur_last >= throttle )

        surface.SetMaterial(BLUR_MAT)
        surface.SetDrawColor(255, 255, 255, alpha)

        render.SetScissorRect(x, y, x + w, y + h, true)

        for i = 1, passes do
            BLUR_MAT:SetFloat("$blur", i * density)
            if ( can_update ) then
                render.UpdateScreenEffectTexture()
            end
            surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        end

        render.SetScissorRect(0, 0, 0, 0, false)

        if ( can_update ) then
            _ax_screen_blur_last = now
        end
    end
end

-- Convert a key to UpperCamelCase
function ax.util:UpperCamel(key)
    if ( !isstring(key) ) then return "" end

    local result = key:gsub("_([a-z])", function(letter)
        return letter:upper()
    end)

    result = result:gsub("^([a-z])", function(letter)
        return letter:upper()
    end)

    return result
end

-- Safe function call wrapper
function ax.util:SafeCall(fn, ...)
    if ( !isfunction(fn) ) then
        return false, "Not a function"
    end

    local ok, result = pcall(fn, ...)
    return ok, result
end

-- Clamp and round a number
function ax.util:ClampRound(n, min, max, decimals)
    local num = tonumber(n) or 0

    if ( min and num < min ) then num = min end
    if ( max and num > max ) then num = max end

    if ( decimals and decimals > 0 ) then
        local mult = 10 ^ decimals
        num = math.Round(num * mult) / mult
    else
        num = math.Round(num)
    end

    return num
end

-- JSON file reading
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

-- JSON file writing
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

-- Validate player
function ax.util:IsValidPlayer(client)
    return IsValid(client) and client:IsPlayer()
end

-- Tokenize a string into arguments, respecting quoted strings.
function ax.util:TokenizeString(str)
    if ( !isstring(str) or str == "" ) then
        return {}
    end

    local tokens = {}
    local current = ""
    local inQuotes = false
    local escapeNext = false

    for i = 1, #str do
        local char = string.sub(str, i, i)

        if ( escapeNext ) then
            current = current .. char
            escapeNext = false
        elseif ( char == "\\" ) then
            escapeNext = true
        elseif ( char == "\"" ) then
            inQuotes = !inQuotes
        elseif ( char == " " and !inQuotes ) then
            if ( current != "" ) then
                tokens[ #tokens + 1 ] = current
                current = ""
            end
        else
            current = current .. char
        end
    end

    -- Add final token if exists
    if ( current != "" ) then
        tokens[ #tokens + 1 ] = current
    end

    return tokens
end

-- Sanitize a key for safe file naming.
function ax.util:SanitizeKey(key)
    if ( !key ) then return "" end

    -- Replace any path unfriendly characters with underscore
    return string.gsub(tostring(key), "[^%w%-_.]", "_")
end

-- Get the current project/gamemode name.
function ax.util:GetProjectName()
    -- Try to detect active gamemode folder; fall back to 'parallax'
    if ( engine and engine.ActiveGamemode ) then
        return engine.ActiveGamemode() or "parallax"
    end

    return "parallax"
end

-- Build a data file path based on key and scope options.
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

-- Ensure parent directories exist for a given data path.
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

ax.util:Include("store_factory.lua")