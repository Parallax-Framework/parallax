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

--- Detects the realm of a file based on its name.
-- @param file string Filename to inspect (may include path)
-- @return string One of "client", "server", or "shared"
-- @usage local realm = ax.util:DetectFileRealm("cl_init.lua") -- returns "client"
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

--- Prepares a package of arguments for printing (converts entities to readable values).
-- @param ... any Any values to prepare for printing
-- @return table A table of values suitable for MsgC/Error printing
-- @usage local pkg = ax.util:PreparePackage("example", someEntity)
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

color_print = Color(100, 150, 255)
color_warning = Color(255, 200, 100)
color_success = Color(100, 255, 100)
color_debug = Color(150, 150, 150)

--- Print a regular message with framework styling.
-- @param ... any Values to print (strings, entities, etc.)
-- @return table The prepared arguments that were printed
-- @usage ax.util:Print("Server started")
function ax.util:Print(...)
    local args = self:PreparePackage(...)

    MsgC(color_print, "[PARALLAX] ", unpack(args))

    return args
end

--- Print an error message (Uses ErrorNoHaltWithStack).
-- @param ... any Values to print as an error
-- @return table The prepared arguments that were printed
-- @usage ax.util:PrintError("Failed to load module", moduleName)
function ax.util:PrintError(...)
    local args = self:PreparePackage(...)

    ErrorNoHaltWithStack("[PARALLAX] [ERROR] " .. string.Trim(table.concat(args, " ")))

    return args
end

--- Print a warning message.
-- @param ... any Values to print as a warning
-- @return table The prepared arguments that were printed
-- @usage ax.util:PrintWarning("Deprecated API used")
function ax.util:PrintWarning(...)
    local args = self:PreparePackage(...)

    MsgC(color_warning, "[PARALLAX] [WARNING] ", unpack(args))

    return args
end

--- Print a success message.
-- @param ... any Values to print as success output
-- @return table The prepared arguments that were printed
-- @usage ax.util:PrintSuccess("Configuration saved")
function ax.util:PrintSuccess(...)
    local args = self:PreparePackage(...)

    MsgC(color_success, "[PARALLAX] [SUCCESS] ", unpack(args))

    return args
end

local developer = GetConVar("developer")

--- Print a debug message
-- @param ... any Values to print for debugging
-- @return table|nil The prepared arguments when printed, nil otherwise
-- @usage ax.util:PrintDebug("Loaded module", moduleName)
function ax.util:PrintDebug(...)
    if ( developer:GetInt() < 1 ) then return end

    local args = self:PreparePackage(...)

    MsgC(color_debug, "[PARALLAX] [DEBUG] ", unpack(args))

    return args
end

--- Find a specific piece of text within a larger body of text (case-insensitive).
-- @param str string The string to search in
-- @param find string The substring to search for
-- @return boolean True if substring exists in string
-- @usage if ax.util:FindString("Hello World", "world") then print("found") end
function ax.util:FindString(str, find)
    if ( str == nil or find == nil ) then
        ax.util:PrintError("Attempted to find a string with no value to find for! (" .. tostring(str) .. ", " .. tostring(find) .. ")")
        return false
    end

    str = string.lower(str)
    find = string.lower(find)

    return string.find(str, find) != nil
end

--- Search each word in a text for a substring (case-insensitive).
-- @param txt string The text to search
-- @param find string The substring to search for across words
-- @return boolean True when any word in txt contains find
-- @usage ax.util:FindText("the quick brown fox", "quick")
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

--- Find a player by SteamID, SteamID64, name, entity or numeric index.
-- @param identifier number|string|Entity|table Player identifier or list of identifiers
-- @return Player|NULL The found player entity or NULL
-- @usage local client = ax.util:FindPlayer("7656119...")
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

--- Find a character by ID or name (case-insensitive, partial match).
-- @param identifier number|string Character ID or name to search for
-- @return ax.character.meta|nil The found character or nil
-- @usage local char = ax.util:FindCharacter("John")
function ax.util:FindCharacter(identifier)
    if ( identifier == nil ) then return nil end

    local identifierNumber = tonumber(identifier)
    if ( ax.character.instances[identifierNumber] ) then
        return ax.character.instances[identifierNumber]
    end

    if ( isstring(identifier) ) then
        for _, char in pairs(ax.character.instances) do
            local name = char:GetName()
            if ( name == identifier ) then
                return char -- exact match
            elseif ( string.lower(name) == string.lower(identifier) ) then
                return char -- case-insensitive exact match
            elseif ( self:FindString(name, identifier) ) then
                return char -- partial match
            end
        end
    end

    return nil
end

--- Safely parse a JSON string into a table, or return table input unchanged.
-- @param tInput string|table JSON string or already-parsed table
-- @return table|nil The parsed table or nil on failure
-- @usage local tbl = ax.util:SafeParseTable(jsonString)
function ax.util:SafeParseTable(tInput)
    if ( isstring(tInput) ) then
        return util.JSONToTable(tInput)
    end

    return tInput
end

--- Safely call a function and capture errors, returning success and results.
-- @param fn function Function to call
-- @param ... any Arguments to pass to fn
-- @return boolean ok True if function executed without error
-- @return any ... Results returned by fn when ok is true
-- @usage local ok, result = ax.util:SafeCall(function() return 1+1 end)
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

--- Convert a human-readable name to a sanitized unique id.
-- @param name string Human-readable name
-- @return string A sanitized lowercase unique id
-- @usage local id = ax.util:NameToUniqueID("My Module") -- "my_module"
function ax.util:NameToUniqueID(name)
    -- Replace spaces with underscores
    name = name:gsub("%s+", "_")

    -- Remove everything not in A-Z, a-z, or underscore
    name = name:gsub("[^A-Za-z_]", "")

    -- Convert to lowercase
    return name:lower()
end

--- Convert a unique id (underscored) back to a human-friendly name.
-- @param id string Unique id to convert
-- @return string Human-friendly name
-- @usage local name = ax.util:UniqueIDToName("my_module") -- "My Module"
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

--- Cap text to a maximum number of characters, adding ellipsis when trimmed.
-- @param text string Text to cap
-- @param maxLength number Maximum number of characters
-- @return string The truncated text (with ellipsis when trimmed)
-- @usage local short = ax.util:CapText(longText, 32)
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

--- Cap text at a word boundary to avoid breaking words when truncating.
-- @param text string Text to cap
-- @param maxLength number Maximum number of characters
-- @return string The truncated text at a word boundary
-- @usage local short = ax.util:CapTextWord(longText, 50)
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

--- Wraps text into multiple lines based on a maximum width (client-only).
-- @param text string Text to wrap
-- @param font string Font name used to measure text
-- @param maxWidth number Maximum width in pixels
-- @return table An array of line strings
-- @usage local lines = ax.util:GetWrappedText("Hello world", "Default", 200)
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

local stored = {}

--- Returns a material from the cache or creates a new one.
-- @param path string Material path
-- @param parameters string|nil Parameters string passed to Material()
-- @return IMaterial The created or cached material
-- @usage local mat = ax.util:GetMaterial("sprites/glow", "nocull")
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
    --- Returns the given text's width (client-only).
    -- @param font string Font name
    -- @param text string Text to measure
    -- @return number Width in pixels
    -- @usage local w = ax.util:GetTextWidth("Default", "Hello")
    function ax.util:GetTextWidth(font, text)
        surface.SetFont(font)
        return select(1, surface.GetTextSize(text))
    end

    --- Returns the given text's height (client-only).
    -- @param font string Font name
    -- @return number Height in pixels
    -- @usage local h = ax.util:GetTextHeight("Default")
    function ax.util:GetTextHeight(font)
        surface.SetFont(font)
        return select(2, surface.GetTextSize("W"))
    end

    --- Returns the given text's size (client-only).
    -- @param font string Font name
    -- @param text string Text to measure
    -- @return number w, number h Width and height in pixels
    -- @usage local w,h = ax.util:GetTextSize("Default", "Hello")
    function ax.util:GetTextSize(font, text)
        surface.SetFont(font)
        return surface.GetTextSize(text)
    end

    --- Draws a blur inside a rectangle (client-only).
    -- @param r number Roundness of rectangle corners
    -- @param x number X screen coordinate
    -- @param y number Y screen coordinate
    -- @param width number Width in pixels
    -- @param height number Height in pixels
    -- @param color Color Color of the blur overlay (alpha used)
    -- @usage ax.util:DrawBlur(16,10,10,200,100,Color(255,255,255,180))
    function ax.util:DrawBlur(r, x, y, width, height, color)
        ax.render.Draw(r, x, y, width, height, color, ax.render.BLUR)
    end
end

if ( CLIENT ) then
    --- Resolve a gradient material path by a short name.
    -- Accepts common names: "left", "right", "top", "bottom" or direct material paths.
    -- @param name string Short name or material path
    -- @return string Material path
    -- @usage local path = ax.util:GetGradientPath("left")
    function ax.util:GetGradientPath(name)
        if ( !isstring(name) or name == "" ) then return "vgui/gradient-l" end

        local lname = string.lower(name)
        if ( lname == "left" or lname == "l" or lname == 1 ) then return "vgui/gradient-l" end
        if ( lname == "right" or lname == "r" or lname == 2 ) then return "vgui/gradient-r" end
        if ( lname == "top" or lname == "up" or lname == "u" or lname == 3 ) then return "vgui/gradient-u" end
        if ( lname == "bottom" or lname == "down" or lname == "d" or lname == 4 ) then return "vgui/gradient-d" end

        -- If it looks like a material path, return it as-is
        return tostring(name)
    end

    --- Get a cached gradient material by name.
    -- @param name string Short name or material path
    -- @return IMaterial Material instance
    -- @usage local mat = ax.util:GetGradient("left")
    function ax.util:GetGradient(name)
        local path = self:GetGradientPath(name)
        return self:GetMaterial(path)
    end

    --- Draw a gradient material tinted with a color.
    -- @param name string Gradient short name or material path
    -- @param x number X coordinate
    -- @param y number Y coordinate
    -- @param w number Width
    -- @param h number Height
    -- @param color Color|nil Optional tint color (defaults to white)
    -- @usage ax.util:DrawGradient("left", 0, 0, 200, 400, Color(0,0,0,200))
    function ax.util:DrawGradient(name, x, y, w, h, color)
        local mat = self:GetGradient(name)
        if ( !mat ) then return end

        color = color or Color(255, 255, 255, 255)

        ax.render.DrawMaterial(0, x, y, w, h, color, mat)
    end
end

--- Convert a key to UpperCamelCase.
-- @param key string Input key e.g. "hello_world"
-- @return string Camel-cased string e.g. "HelloWorld"
-- @usage local s = ax.util:UpperCamel("my_key") -- "MyKey"
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

--- Safe function call wrapper (returns ok and result).
-- @param fn function Function to call
-- @return boolean ok True if function executed without error
-- @return any The return value of the function when ok
-- @usage local ok, res = ax.util:SafeCall(function() return 123 end)
function ax.util:SafeCall(fn, ...)
    if ( !isfunction(fn) ) then
        return false, "Not a function"
    end

    local ok, result = pcall(fn, ...)
    return ok, result
end

--- Clamp and round a number.
-- @param n number Input number
-- @param min number|nil Minimum allowed value
-- @param max number|nil Maximum allowed value
-- @param decimals number|nil Number of decimal places to keep
-- @return number The clamped and rounded value
-- @usage local v = ax.util:ClampRound(3.14159, 0, 10, 2) -- 3.14
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

--- Internal: read parallax-version.json from GAME or DATA and parse
-- @return table|nil Parsed table or nil
local function ReadVersionFile()
    -- Only allow file reads on the server. Clients must rely on the broadcasted global (ax.version).
    if ( CLIENT ) then return nil end

    -- The version file lives in the game install under gamemodes/parallax/
    local content = file.Read("gamemodes/parallax/parallax-version.json", "GAME")
    if ( !content ) then
        ax.util:PrintDebug("ReadVersionFile: parallax-version.json not found in GAME path")
        return nil
    end

    local ok, data = pcall(util.JSONToTable, content)
    if ( ok and istable(data) ) then return data end

    ax.util:PrintWarning("ReadVersionFile: failed to parse parallax-version.json")

    return nil
end

--- Get the Parallax version string (e.g. "0.3.42").
-- Prefers `ax.version` if available, else attempts to read `parallax-version.json`.
-- @return string|nil Version string or nil when unavailable
function ax.util:GetVersion()
    if ( istable(ax.version) and ax.version.version ) then
        return tostring(ax.version.version)
    end

    local data = ReadVersionFile()
    if ( istable(data) and data.version ) then
        return tostring(data.version)
    end

    return "0.0.0"
end

--- Get the Parallax commit count (number).
-- @return number|nil Commit count or nil when unavailable
function ax.util:GetCommitCount()
    if ( istable(ax.version) and ax.version.commitCount ) then
        return tonumber(ax.version.commitCount) or nil
    end

    local data = ReadVersionFile()
    if ( istable(data) and data.commitCount ) then
        return tonumber(data.commitCount) or nil
    end

    return 0
end

--- Get the Parallax commit hash (short).
-- @return string|nil Commit hash or nil when unavailable
function ax.util:GetCommitHash()
    if ( istable(ax.version) and ax.version.commitHash ) then
        return tostring(ax.version.commitHash)
    end

    local data = ReadVersionFile()
    if ( istable(data) and data.commitHash ) then
        return tostring(data.commitHash)
    end

    return ""
end

--- Get the Parallax branch name.
-- @return string|nil Branch name or nil when unavailable
function ax.util:GetBranch()
    if ( istable(ax.version) and ax.version.branch ) then
        return tostring(ax.version.branch)
    end

    local data = ReadVersionFile()
    if ( istable(data) and data.branch ) then
        return tostring(data.branch)
    end

    return "unknown"
end

--- Returns true if the entity is a valid player.
-- @param client Entity Candidate entity
-- @return boolean True if entity is a valid player
-- @usage if ax.util:IsValidPlayer(client) then -- do something end
function ax.util:IsValidPlayer(client)
    return IsValid(client) and client:IsPlayer()
end

--- Tokenize a string into arguments, respecting quoted strings.
-- @param str string Input command string
-- @return table Array of token strings
-- @usage local args = ax.util:TokenizeString('say "hello world"')
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

--- Sanitize a key to be safe for use in file names.
-- @param key string Input key
-- @return string A filesystem-safe string
-- @usage local safe = ax.util:SanitizeKey("Player:Test") -- "Player_Test"
function ax.util:SanitizeKey(key)
    if ( !key ) then return "" end

    -- Replace any path unfriendly characters with underscore
    return string.gsub(tostring(key), "[^%w%-_.]", "_")
end

--- Get the current project/gamemode name (falls back to "parallax").
-- @return string The active gamemode folder name or "parallax"
-- @usage local name = ax.util:GetProjectName()
function ax.util:GetProjectName()
    -- Try to detect active gamemode folder; fall back to 'parallax'
    if ( engine and engine.ActiveGamemode ) then
        return engine.ActiveGamemode() or "parallax"
    end

    return "parallax"
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

--- Get the server's network address.
-- Returns the raw address string as returned by game.GetIPAddress(),
-- plus the parsed ip and port when available.
-- @realm shared
-- @return string|nil full The full "ip:port" string or nil when unavailable
-- @return string|nil ip The IP portion (may be "0.0.0.0" or similar)
-- @return number|nil port The port number (0 when not present)
-- @usage local full, ip, port = ax.util:GetServerAddress()
function ax.util:GetServerAddress()
    local addr = nil

    if ( game and game.GetIPAddress ) then
        addr = game.GetIPAddress() or ""
    end

    -- Fallbacks if game.GetIPAddress isn't available or is empty
    if ( (addr == "" or addr == nil) and SERVER and GetConVar ) then
        -- sv_ip is rarely set, but try it as a best-effort fallback
        local svip = GetConVar("sv_ip")
        if ( svip ) then
            addr = svip:GetString() or ""
        end
    end

    if ( addr == "" or !isstring(addr) ) then
        self:PrintDebug("GetServerAddress: no address detected")
        return nil, nil, nil
    end

    -- Parse "ip:port" (port optional)
    local ip, port = string.match(addr, "^([^:]+):?(%d*)$")
    port = tonumber(port) or 0

    return addr, ip, port
end

function ax.util:GetSurfaceDataViaName(surfaceName)
    if ( !surfaceName ) then return nil end

    local idx = util.GetSurfaceIndex(surfaceName)
    if ( idx == 0 ) then return nil end

    return util.GetSurfaceData(idx)
end

function ax.util:GetSurfaceDataViaTrace(tr)
    if ( !tr or !tr.Hit ) then return nil end
    if ( !tr.SurfaceProps or tr.SurfaceProps == 0 ) then return nil end

    return util.GetSurfaceData(tr.SurfaceProps)
end

ax.util:Include("store_factory.lua")
