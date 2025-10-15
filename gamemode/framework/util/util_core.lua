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
    --- Draws a blur inside a rectangle (client-only).
    -- @param r number Roundness of rectangle corners
    -- @param x number X screen coordinate
    -- @param y number Y screen coordinate
    -- @param width number Width in pixels
    -- @param height number Height in pixels
    -- @param color Color Color of the blur overlay (alpha used)
    -- @usage ax.util:DrawBlur(16,10,10,200,100,Color(255,255,255,180))
    function ax.util:DrawBlur(x, y, w, h, flags, tl, tr, bl, br, thickness)
        ax.render.DrawBlur(x, y, w, h, flags, tl, tr, bl, br, thickness)
    end

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

--- Scale a value using the user's UI scale preference.
-- @realm client
-- @param value number The base value to scale
-- @return number The scaled value
-- @usage local scaledSize = ax.util:UIScale(16) -- 16 * uiScale option
function ax.util:UIScale(value)
    if ( CLIENT and ax and ax.option ) then
        local uiScale = ax.option:Get("uiScale", 1.0)
        return value * uiScale
    end
    return value
end

--- Scale a ScreenScale value using the user's UI scale preference.
-- @realm client
-- @param value number The base value to pass to ScreenScale
-- @return number The ScreenScale'd and UI-scaled value
-- @usage local scaledPadding = ax.util:UIScreenScale(16)
function ax.util:UIScreenScale(value)
    return self:UIScale(ScreenScale(value))
end

--- Scale a ScreenScaleH value using the user's UI scale preference.
-- @realm client
-- @param value number The base value to pass to ScreenScaleH
-- @return number The ScreenScaleH'd and UI-scaled value
-- @usage local scaledHeight = ax.util:UIScreenScaleH(32)
function ax.util:UIScreenScaleH(value)
    return self:UIScale(ScreenScaleH(value))
end

--- Pads a number with leading zeroes until it reaches the desired digit length.
-- @param num number: The number to pad.
-- @param digits number: The total amount of digits the result should have.
-- @return string: The padded number as a string.
function ax.util:PadNumber(num, digits)
    return string.format("%0" .. tostring(digits) .. "d", num)
end
