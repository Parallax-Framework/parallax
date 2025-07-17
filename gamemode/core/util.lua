--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Utility functions
-- @module ax.util

-- TESTTT

--- Checks if MySQLOO binary is available
-- @realm server
-- @treturn boolean True if MySQLOO is available
function ax.util:HasMysqlooBinary()
    return util.IsBinaryModuleInstalled("mysqloo")
end

--- Converts and sanitizes input data into the specified type.
-- This supports simple type coercion and fallback defaults.
-- @param typeID number A type constant from ax.types
-- @param value any The raw value to sanitize
-- @return any A validated and converted result
-- @usage ax.util:CoerceType(ax.types.number, "123") -- returns 123

-- Credit @ Helix :: https://github.com/NebulousCloud/helix/blob/master/gamemode/core/sh_util.lua
function ax.util:CoerceType(typeID, value)
    if ( typeID == nil or value == nil ) then
        if ( ax.config:Get("debug.developer") ) then
            ax.util:PrintError("Attempted to coerce a type with no type ID or value! (" .. tostring(typeID) .. ", " .. tostring(value) .. ")")
        end

        return nil
    end

    if ( typeID == ax.types.string or typeID == ax.types.text ) then
        return tostring(value)
    elseif ( typeID == ax.types.number ) then
        return tonumber(value) or 0
    elseif ( typeID == ax.types.bool ) then
        return tobool(value)
    elseif ( typeID == ax.types.vector ) then
        return isvector(value) and value
    elseif ( typeID == ax.types.angle ) then
        return isangle(value) and value
    elseif ( typeID == ax.types.color ) then
        return ( IsColor(value) or ( istable(value) and isnumber(value.r) and isnumber(value.g) and isnumber(value.b) and isnumber(value.a) ) ) and value
    elseif ( typeID == ax.types.player ) then
        return ax.util:FindPlayer(value)
    elseif ( typeID == ax.types.character ) then
        if ( istable(value) and ax.util:IsCharacter(value) ) then
            return value
        end
    elseif ( typeID == ax.types.steamid ) then
        if ( isstring(value) and #value == 19 and string.match(value, "STEAM_%d:%d:%d+") ) then
            return value
        end
    elseif ( typeID == ax.types.steamid64 ) then
        if ( isstring(value) and #value == 17 and ( string.match(value, "7656119%d+") != nil or string.match(value, "9007199%d+") != nil ) ) then
            return value
        end
    end

    return nil
end

local basicTypeMap = {
    string  = ax.types.string,
    number  = ax.types.number,
    boolean = ax.types.bool,
    Vector  = ax.types.vector,
    Angle   = ax.types.angle
}

local checkTypeMap = {
    [ax.types.color] = function(val)
        return IsColor(val) or ( istable(val) and isnumber(val.r) and isnumber(val.g) and isnumber(val.b) and isnumber(val.a) )
    end,
    [ax.types.character] = function(val) return getmetatable(val) == ax.character.meta end,
    [ax.types.steamid] = function(val) return isstring(val) and #val == 19 and string.match(val, "STEAM_%d:%d:%d+") != nil end,
    [ax.types.steamid64] = function(val) return isstring(val) and #val == 17 and ( string.match(val, "7656119%d+") != nil or string.match(val, "9007199%d+") != nil ) end
}

--- Attempts to identify the framework type of a given value.
-- @param value any The value to analyze
-- @return number|nil A type constant from ax.types or nil if unknown
-- @usage local t = ax.util:DetectType(Color(255,0,0)) -- returns ax.types.color
-- Credit @ Helix :: https://github.com/NebulousCloud/helix/blob/master/gamemode/core/sh_util.lua
function ax.util:DetectType(value)
    local luaType = type(value)
    local mapped = basicTypeMap[luaType]

    if ( mapped ) then return mapped end

    for typeID, validator in pairs(checkTypeMap) do
        if ( validator(value) ) then
            return typeID
        end
    end

    if ( IsValid(value) and value:IsPlayer() ) then
        return ax.types.player
    end
end

local typeNames = {
    [ax.types.string] = "String",
    [ax.types.number] = "Number",
    [ax.types.bool] = "Boolean",
    [ax.types.vector] = "Vector",
    [ax.types.angle] = "Angle",
    [ax.types.color] = "Color",
    [ax.types.player] = "Player",
    [ax.types.character] = "Character",
    [ax.types.steamid] = "SteamID",
    [ax.types.steamid64] = "SteamID64",
    [ax.types.array] = "Array"
}

--- Formats a type ID into a human-readable string.
-- @param typeID number The type ID to format.
-- @return string The formatted type name.
-- @usage local typeName = ax.util:FormatType(ax.types.color) -- returns "Color"
function ax.util:FormatType(typeID)
    if ( typeID == nil ) then
        ax.util:PrintError("Attempted to format a type with no type ID!", typeID)
        return "Unknown"
    end

    return typeNames[typeID] or "Unknown"
end

--- Sends a chat message to the player.
-- @realm shared
-- @param client Player The player to send the message to.
-- @param ... any The message to send.
function ax.util:SendChatText(client, ...)
    if ( client == nil ) then
        client = select(2, player.Iterator())
    end

    if ( SERVER ) then
        net.Start("ax.chat.text")
            net.WriteTable({...})
        net.Send(client)
    else
        chat.AddText(...)
    end
end

--- Prepares a package of arguments for printing.
-- @realm shared
-- @param ... any The package to prepare.
-- @return any The prepared package.
function ax.util:PreparePackage(...)
    local arguments = {...}
    local package = {}

    for i = 1, #arguments do
        local arg = arguments[i]
        if ( isentity(arg) ) then
            package[#package + 1] = tostring(arg)

            if ( type(arg) == "Player" ) then
                package[#package + 1] = "[" .. arg:SteamID64() .. "]"
            end
        else
            package[#package + 1] = arg
        end
    end

    package[#package + 1] =  "\n"

    return package
end

local frameworkColor = Color(142, 68, 255)
local serverMessageColor = Color(156, 241, 255, 200)
local clientMessageColor = Color(255, 241, 122, 200)
local errorColor = Color(255, 120, 120)
local warningColor = Color(255, 200, 120)
local successColor = Color(120, 255, 120)

--- Prints a message to the console.
-- @realm shared
-- @param ... any The message to print.
function ax.util:Print(...)
    local arguments = self:PreparePackage(...)

    local bConfigInit = istable(ax.config) and isfunction(ax.config.Get)

    local tagColor = bConfigInit and ax.config:Get("color.framework", frameworkColor) or frameworkColor
    local serverColor = bConfigInit and ax.config:Get("color.server.message", serverMessageColor) or serverMessageColor
    local clientColor = bConfigInit and ax.config:Get("color.client.message", clientMessageColor) or clientMessageColor

    local realmColor = SERVER and serverColor or clientColor
    MsgC(tagColor, "[PARALLAX] ", realmColor, unpack(arguments))

    if ( CLIENT and bConfigInit and ax.config:Get("debug.developer") ) then
        chat.AddText(tagColor, "[Parallax] ", realmColor, unpack(arguments))
    end

    return arguments
end

--- Prints an error message to the console.
-- @realm shared
-- @param ... any The message to print.
local _printingError = false
function ax.util:PrintError(...)
    if ( _printingError ) then return end
    _printingError = true

    local arguments = self:PreparePackage(...)
    local info = {}

    for i = 1, 10 do
        local traceInfo = debug.getinfo(i, "Sl")
        if ( !traceInfo ) then break end
        info[#info + 1] = traceInfo
    end

    local line = ""
    local quickInfo = info[3]
    if ( quickInfo and quickInfo.short_src and quickInfo.currentline > 0 ) then
        line = quickInfo.short_src .. ":" .. quickInfo.currentline
    end

    local argCount = select("#", ...)

    if ( line != "" ) then
        if ( argCount > 0 and type(arguments[argCount]) == "string" ) then
            arguments[argCount] = string.Trim(arguments[argCount])
        end

        line = string.gsub(line, "gamemodes/", "")
        arguments[#arguments + 1] = " (" .. line .. ")"
        arguments[#arguments + 1] = "\n"
    end

    local bConfigInit = istable(ax.config) and isfunction(ax.config.Get)

    local tagColor = bConfigInit and ax.config:Get("color.framework", violetColor) or violetColor
    local batchColor = bConfigInit and ax.config:Get("color.error", errorColor) or errorColor

    MsgC(tagColor, "[PARALLAX] ", batchColor, "[ERROR] ", unpack(arguments))

    if ( CLIENT and bConfigInit and ax.config:Get("debug.developer") ) then
        chat.AddText(tagColor, "[Parallax] ", batchColor, "[Error] ", unpack(arguments))
    end

    if ( bConfigInit and ax.config:Get("debug.developer") ) then
        local log = {}
        for i = 1, 10 do
            local traceInfo = info[i]
            if ( !traceInfo ) then break end

            local file = traceInfo.short_src or "unknown"
            local lineNum = traceInfo.currentline or 0
            log[#log + 1] = string.format("%s:%d", file, lineNum) .. "\n"
        end
        log = table.concat(log, " -> ")
        MsgC(tagColor, "[PARALLAX] ", batchColor, "[ERROR] [TRACEBACK] ", log, "\n")
    end

    _printingError = false
    return arguments
end

--- Prints a warning message to the console.
-- @realm shared
-- @param ... any The message to print.
function ax.util:PrintWarning(...)
    local arguments = self:PreparePackage(...)

    local bConfigInit = istable(ax.config) and isfunction(ax.config.Get)

    local tagColor = bConfigInit and ax.config:Get("color.framework", violetColor) or violetColor
    local batchColor = bConfigInit and ax.config:Get("color.warning", warningColor) or warningColor

    MsgC(tagColor, "[PARALLAX] ", batchColor, "[WARNING] ", unpack(arguments))

    if ( CLIENT and bConfigInit and ax.config:Get("debug.developer") ) then
        chat.AddText(tagColor, "[Parallax] ", batchColor, "[Warning] ", unpack(arguments))
    end

    return arguments
end

--- Prints a success message to the console.
-- @realm shared
-- @param ... any The message to print.
function ax.util:PrintSuccess(...)
    local arguments = self:PreparePackage(...)

    local bConfigInit = istable(ax.config) and isfunction(ax.config.Get)

    local tagColor = bConfigInit and ax.config:Get("color.framework", violetColor) or violetColor
    local batchColor = bConfigInit and ax.config:Get("color.success", successColor) or successColor

    MsgC(tagColor, "[PARALLAX] ", batchColor, "[SUCCESS] ", unpack(arguments))

    if ( CLIENT and bConfigInit and ax.config:Get("debug.developer") ) then
        chat.AddText(tagColor, "[Parallax] ", batchColor, "[Success] ", unpack(arguments))
    end

    return arguments
end

--- Loads a file based on the realm.
-- @realm shared
-- @param path string The path to the file.
-- @param realm string The realm to load the file in.
function ax.util:LoadFile(path, realm)
    if ( !isstring(path) ) then
        self:PrintError("Failed to load file " .. path .. "!")
        return
    end

    if ( ( realm == "server" or ax.util:FindString(path, "sv_") ) and SERVER ) then
        include(path)
    elseif ( realm == "shared" or ax.util:FindString(path, "shared.lua") or ax.util:FindString(path, "sh_") ) then
        if ( SERVER ) then
            AddCSLuaFile(path)
        end

        include(path)
    elseif ( realm == "client" or ax.util:FindString(path, "cl_") ) then
        if ( SERVER ) then
            AddCSLuaFile(path)
        else
            include(path)
        end
    end
end

--- Loads all files in a folder based on the realm.
-- @realm shared
-- @param directory string The directory to load the files from.
-- @param bFromLua boolean Whether or not the files are being loaded from Lua.
function ax.util:LoadFolder(directory, bFromLua)
    local baseDir = debug.getinfo(2).source
    baseDir = string.sub(baseDir, 2, string.find(baseDir, "/[^/]*$"))
    baseDir = string.gsub(baseDir, "gamemodes/", "")

    if ( bFromLua ) then
        baseDir = ""
    end

    local files = file.Find(baseDir .. directory .. "/*.lua", "LUA")
    for i = 1, #files do
        local v = files[i]
        if ( !file.Exists(baseDir .. directory .. "/" .. v, "LUA") ) then
            self:PrintError("Failed to load file " .. baseDir .. directory .. "/" .. v .. "!")
            continue
        end

        self:LoadFile(baseDir .. directory .. "/" .. v)
    end

    return true
end

--- Returns the type of a value.
-- @realm shared
-- @string str The value to get the type of.
-- @string find The type to search for.
-- @return boolean Whether or not the value matches the type.
function ax.util:FindString(str, find)
    if ( str == nil or find == nil ) then
        ax.util:PrintError("Attempted to find a string with no value to find for! (" .. tostring(str) .. ", " .. tostring(find) .. ")")
        return false
    end

    str = string.lower(str)
    find = string.lower(find)

    return string.find(str, find) != nil
end

--- Searches a given text for the specified value.
-- @realm shared
-- @string txt The text to search in.
-- @string find The value to search for.
-- @return boolean Whether or not the value was found.
function ax.util:FindText(txt, find)
    if ( txt == nil or find == nil ) then
        ax.util:PrintError("Attempted to find a string with no value to find for! (" .. txt .. ", " .. find .. ")")
        return false
    end

    local words = string.Explode(" ", txt)
    for i = 1, #words do
        if ( self:FindString(words[i], find) ) then
            return true
        end
    end

    return false
end

--- Searches for a string in a table.
-- @realm shared
-- @param tbl table The table to search in.
-- @param find string The string to search for.
function ax.util:FindInTable(tbl, find)
    if ( !istable(tbl) or !isstring(find) ) then
        ax.util:PrintError("Attempted to find a string in a table with no value to find for! (" .. tostring(tbl) .. ", " .. tostring(find) .. ")")
        return false
    end

    for k, v in pairs(tbl) do
        if ( self:FindString(v, find) ) then
            return true
        end
    end

    return false
end

--- Searches for a player based on the given identifier.
-- @realm shared
-- @param identifier any The identifier to search for.
-- @return Player The player that was found.
function ax.util:FindPlayer(identifier)
    if ( identifier == nil ) then return NULL end

    if ( type(identifier) == "Player" ) then
        return identifier
    end

    if ( isnumber(identifier) ) then
        return Player(identifier)
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

--- Breaks a string into lines that fit within a maximum width in pixels.
-- Words are wrapped cleanly, and long words are split by character if needed.
-- @realm client
-- @param text string The text to wrap.
-- @param font string Font name to use.
-- @param maxWidth number Maximum allowed width in pixels.
-- @return table Table of wrapped lines.
-- @usage local lines = ax.util:GetWrappedText("Long example string", "DermaDefault", 250)
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

--- Gets the bounds of a box, providing the center, minimum, and maximum points.
-- @realm shared
-- @param startpos Vector The starting position of the box.
-- @param endpos Vector The ending position of the box.
-- @return Vector center The center point of the box.
-- @return Vector min The minimum corner of the box.
-- @return Vector max The maximum corner of the box.
function ax.util:GetBounds(startpos, endpos)
    if ( !isvector(startpos) or !isvector(endpos) ) then
        ax.util:PrintError("Attempted to get bounds with invalid positions", startpos, endpos)
        return vector_origin, vector_origin, vector_origin
    end

    local min = Vector(math.min(startpos.x, endpos.x), math.min(startpos.y, endpos.y), math.min(startpos.z, endpos.z))
    local max = Vector(math.max(startpos.x, endpos.x), math.max(startpos.y, endpos.y), math.max(startpos.z, endpos.z))
    local center = (min + max) / 2

    return center, min, max
end

do
    local i
    local value
    local character

    local function iterator(clientTable)
        repeat
            i = i + 1
            value = clientTable[i]
            character = value and value:GetCharacter()
        until character or value == nil

        return value, character
    end

    function ax.util:GetCharacters()
        i = 0
        return iterator, select(2, player.Iterator())
    end
end

function ax.util:IsPlayerReceiver(obj)
    return IsValid(obj) and obj:IsPlayer()
end

function ax.util:SafeParseTable(input)
    if ( istable(input) ) then
        return input
    elseif ( isstring(input) and input != "" and input != "[]" ) then
        return util.JSONToTable(input) or {}
    end

    return {}
end

local directions = {
    { min = -180.0, max = -157.5, name = "S"  },
    { min = -157.5, max = -112.5, name = "SE" },
    { min = -112.5, max = -67.5,  name = "E"  },
    { min = -67.5,  max = -22.5,  name = "NE" },
    { min = -22.5,  max = 22.5,   name = "N"  },
    { min = 22.5,   max = 67.5,   name = "NW" },
    { min = 67.5,   max = 112.5,  name = "W"  },
    { min = 112.5,  max = 157.5,  name = "SW" },
    { min = 157.5,  max = 180.0,  name = "S"  }
}

--- Returns the compass direction from a yaw angle using a lookup table.
-- @param ang Angle The angle to interpret.
-- @return string Compass heading (e.g., "N", "SW")
-- @usage local heading = ax.util:GetHeadingFromAngle(client:EyeAngles())
function ax.util:GetHeadingFromAngle(ang)
    local yaw = ang.yaw or ang[2]

    for i = 1, #directions do
        local dir = directions[i]
        if ( yaw > dir.min and yaw <= dir.max ) then
            return dir.name
        end
    end

    return "N" -- Default to North if no match is found
end

ax.util.activeSoundQueues = ax.util.activeSoundQueues or {}

--- Queues and plays a sound sequence with controlled pacing.
-- Uses a polling step interval instead of chained timers.
-- @param ent Entity Entity to emit from.
-- @param queue table Table of sounds or {path, preDelay, postDelay}
-- @param volume number Volume to play at.
-- @param pitch number Pitch to play at.
function ax.util:QueueSounds(ent, queue, volume, pitch)
    if ( !IsValid(ent) or !istable(queue) or queue[1] == nil ) then return end

    local data = {
        entity = ent,
        sounds = queue,
        volume = volume or 75,
        pitch = pitch or 100,
        current = 1,
        nextTime = CurTime()
    }

    local id = tostring(ent) .. "_" .. CurTime()
    ax.util.activeSoundQueues[id] = data

    timer.Create("ax.Sound.queue." .. id, 0.1, 0, function()
        if ( !IsValid(data.entity) or !data.sounds[data.current] ) then
            timer.Remove("ax.Sound.queue." .. id)
            ax.util.activeSoundQueues[id] = nil
            return
        end

        if ( CurTime() < data.nextTime ) then return end

        local soundEntry = data.sounds[data.current]
        local path, pre, post

        if ( isstring(soundEntry) ) then
            path, pre, post = soundEntry, 0, 0
        else
            path = soundEntry[1]
            pre  = soundEntry[2] or 0
            post = soundEntry[3] or 0
        end

        -- apply pre-delay only before playback
        data.nextTime = CurTime() + pre

        -- emit sound after pre-delay expires
        timer.Simple(pre, function()
            if ( IsValid(data.entity) ) then
                data.entity:EmitSound(path, data.volume, data.pitch)
            end
        end)

        local dur = SoundDuration(path) or 1.0
        data.nextTime = data.nextTime + dur + post
        data.current = data.current + 1
    end)
end

--- Includes Lua files for a defined entity folder path.
-- @param path string Path to the entity directory.
-- @param clientOnly boolean Whether inclusion should be client-only.
-- @return boolean True if any file was included successfully.
function ax.util:LoadEntityFile(path, clientOnly)
    if ( SERVER and file.Exists(path .. "init.lua", "LUA") ) or ( CLIENT and file.Exists(path .. "cl_init.lua", "LUA") ) then
        ax.util:LoadFile(path .. "init.lua", clientOnly and "client" or "server")

        if ( file.Exists(path .. "cl_init.lua", "LUA") ) then
            ax.util:LoadFile(path .. "cl_init.lua", "client")
        end

        return true
    elseif ( file.Exists(path .. "shared.lua", "LUA") ) then
        ax.util:LoadFile(path .. "shared.lua", "shared")
        return true
    end

    return false
end

--- Scans a folder and registers all contained entity files.
-- @param basePath string Base directory path.
-- @param folder string Subfolder to search (e.g., "entities").
-- @param globalKey string Global variable name to assign during load (e.g., "ENT").
-- @param registerFn function Function to register the entity.
-- @param default table? Default values for the global table.
-- @param clientOnly boolean? Whether registration should only happen on client.
function ax.util:LoadEntityFolder(basePath, folder, globalKey, registerFn, default, clientOnly)
    local fullPath = basePath .. "/" .. folder .. "/"
    local files, folders = file.Find(fullPath .. "*", "LUA")
    default = default or {}

    for i = 1, #folders do
        local dir = folders[i]
        local subPath = fullPath .. dir .. "/"

        _G[globalKey] = table.Copy(default)
        _G[globalKey].ClassName = dir

        if ( self:LoadEntityFile(subPath, clientOnly) and ( !clientOnly or CLIENT ) ) then
            registerFn(_G[globalKey], dir)
        end

        _G[globalKey] = nil
    end

    for i = 1, #files do
        local fileName = files[i]
        local class = string.StripExtension(fileName)

        _G[globalKey] = table.Copy(default)
        _G[globalKey].ClassName = class

        self:LoadFile(fullPath .. fileName, clientOnly and "client" or "shared")

        if ( !clientOnly or CLIENT ) then
            registerFn(_G[globalKey], class)
        end

        _G[globalKey] = nil
    end
end

--- Loads and registers toolgun tools from a custom path.
-- Mimics GMod's native behavior for loading from stools/ folder.
-- @param path string Path to the folder containing tool files.
-- @realm shared
function ax.util:LoadTools(path)
    local files = file.Find(path .. "/*.lua", "LUA")
    for i = 1, #files do
        local val = string.lower(files[i])

        local _, _, toolmode = string.find(val, "([%w_]*).lua")
        toolmode = toolmode:lower()

        TOOL = ax.tool:Create()
        TOOL.Mode = toolmode

        ax.util:LoadFile(path .. "/" .. val, "shared")

        TOOL:CreateConVars()

        if ( hook.Run("PreRegisterTOOL", TOOL, toolmode) != false ) then
            weapons.GetStored("gmod_tool").Tool[toolmode] = TOOL
        end

        TOOL = nil
    end
end

--- Loads all entities, weapons, and effects from a module or schema directory.
-- @param path string Path to module or schema folder.
-- @realm shared
function ax.util:LoadEntities(path)
    self:LoadEntityFolder(path, "entities", "ENT", scripted_ents.Register, {
        Type = "anim",
        Base = "base_gmodentity",
        Spawnable = true
    })

    self:LoadEntityFolder(path, "weapons", "SWEP", weapons.Register, {
        Primary = {},
        Secondary = {},
        Base = "weapon_base"
    })

    self:LoadEntityFolder(path, "effects", "EFFECT", effects and effects.Register, nil, true)

    self:LoadTools(path .. "/tools")
end

--- Returns the current difference between local time and UTC in seconds.
-- @realm shared
-- @return number Time difference to UTC in seconds
-- @usage local utcOffset = ax.util:GetUTCTime()
function ax.util:GetUTCTime()
    local utcTable = os.date("!*t")
    local localTable = os.date("*t")

    localTable.isdst = false

    return os.difftime(os.time(utcTable), os.time(localTable))
end

local time = {
    s = 1,                  -- Seconds
    m = 60,                 -- Minutes
    h = 3600,               -- Hours
    d = 86400,              -- Days
    w = 604800,             -- Weeks
    mo = 2592000,           -- Months (approximate)
    y = 31536000            -- Years (approximate)
}

--- Converts a formatted time string into total seconds.
-- @realm shared
-- @string input Text to interpret (e.g., "5y2d7w")
-- @return number Time in seconds
-- @return boolean True if format was valid, false otherwise
-- @usage local seconds = ax.util:GetStringTime("2h30m")
function ax.util:GetStringTime(input)
    local rawMinutes = tonumber(input)
    if ( rawMinutes ) then
        return math.abs(rawMinutes * 60), true
    end

    local totalSeconds = 0
    local hasValidUnit = false

    for numberStr, suffix in input:lower():gmatch("(%d+)(%a+)") do
        local count = tonumber(numberStr)
        local multiplier = time[suffix]

        if ( count and multiplier ) then
            totalSeconds = totalSeconds + math.abs(count * multiplier)
            hasValidUnit = true
        end
    end

    return totalSeconds, hasValidUnit
end

local stored = {}

--- Returns a material with the given path and parameters.
-- @realm shared
-- @param path string The path to the material.
-- @param parameters string The parameters to apply to the material.
-- @return Material The material that was created.
-- @usage local vignette = ax.util:GetMaterial("parallax/overlay_vignette.png")
-- surface.SetMaterial(vignette)
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

--- Pads a number with leading zeros to a specified digit count.
-- @realm shared
-- @param number number The number to pad.
-- @param digits number The total number of digits to pad to.
-- @return string The padded number as a string.
-- @usage local padded = ax.util:ZeroNumber(5, 3) -- returns "005"
function ax.util:ZeroNumber(number, digits)
    local str = tostring(number)
    return string.rep("0", digits - #str) .. str
end

--- Caps a given text to a maximum length, adding ellipsis if needed.
-- @realm shared
-- @param text string The text to cap.
-- @param maxLength number The maximum length of the text.
-- @return string The capped text.
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

--- Caps a given text to a maximum length, adding ellipsis if needed, but only caps at word boundaries.
-- @realm shared
-- @param text string The text to cap.
-- @param maxLength number The maximum length of the text.
-- @return string The capped text.
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

if ( CLIENT ) then
    local families = {
        "regular",
        "bold",
        "italic",
        "italic.bold"
    }

    --- Creates a font family with the given name, font, and size.
    -- @realm client
    -- @param name string The name of the font family.
    -- @param font string The font to use for the family.
    -- @param size number The size of the font.
    -- @param familiesOverride table Optional table of families to override the default ones.
    -- @usage ax.util:CreateFontFamily("MyFont", "Arial", 16)
    function ax.util:CreateFontFamily(name, font, size, familiesOverride)
        if ( !font or font == "" ) then
            ax.util:PrintError("Failed to create font family '" .. name .. "': Font is not defined.")
            return
        end

        if ( !size or size <= 0 ) then
            ax.util:PrintError("Failed to create font family '" .. name .. "': Size is not defined or invalid.")
            return
        end

        -- Create the base font
        surface.CreateFont("ax." .. name, {
            font = font,
            size = size,
            weight = 700,
            antialias = true
        })

        -- Create the font families
        if ( familiesOverride and istable(familiesOverride) ) then
            -- If familiesOverride is provided, use it instead of the default families
            -- Though familiesOverride may use the key as the family name and the value as the font name incase of custom fonts
            for family, fontName in pairs(familiesOverride) do
                if ( isstring(family) and isstring(fontName) ) then
                    surface.CreateFont("ax." .. name .. "." .. family, {
                        font = fontName,
                        size = size,
                        weight = ax.util:FindString(family, "bold") and 900 or 700,
                        italic = ax.util:FindString(family, "italic"),
                        antialias = true
                    })
                else
                    surface.CreateFont("ax." .. name .. "." .. family, {
                        font = font,
                        size = size,
                        weight = ax.util:FindString(family, "bold") and 900 or 700,
                        italic = ax.util:FindString(family, "italic"),
                        antialias = true
                    })
                end
            end
        else
            for _, family in ipairs(families) do
                surface.CreateFont("ax." .. name .. "." .. family, {
                    font = font,
                    size = size,
                    weight = ax.util:FindString(family, "bold") and 900 or 700,
                    italic = ax.util:FindString(family, "italic"),
                    antialias = true
                })
            end
        end

        ax.util:Print("Font family '" .. name .. "' created successfully.")
    end

    --- Returns the given text's width.
    -- @realm client
    -- @param font string The font to use.
    -- @param text string The text to measure.
    -- @return number The width of the text.
    function ax.util:GetTextWidth(font, text)
        surface.SetFont(font)
        return select(1, surface.GetTextSize(text))
    end

    --- Returns the given text's height.
    -- @realm client
    -- @param font string The font to use.
    -- @return number The height of the text.
    function ax.util:GetTextHeight(font)
        surface.SetFont(font)
        return select(2, surface.GetTextSize("W"))
    end

    --- Returns the given text's size.
    -- @realm client
    -- @param font string The font to use.
    -- @param text string The text to measure.
    -- @return number The width of the text.
    -- @return number The height of the text.
    function ax.util:GetTextSize(font, text)
        surface.SetFont(font)
        return surface.GetTextSize(text)
    end

    local blurMaterial = ax.util:GetMaterial("pp/blurscreen")
    local scrW, scrH = ScrW(), ScrH()

    --- Draws a blur within a panel's bounds. Falls back to a dim overlay if blur is disabled.
    -- @param panel Panel Panel to apply blur to.
    -- @param intensity number Blur strength (0–10 suggested).
    -- @param steps number Blur quality/steps. Defaults to 0.2.
    -- @param alpha number Overlay alpha (default 255).
    -- @usage ax.util:DrawBlur(panel, 6, 0.2, 200)
    function ax.util:DrawBlur(panel, intensity, steps, alpha)
        if ( !IsValid(panel) or alpha == 0 ) then return end

        if ( ax.option:Get("performance.blur") != true ) then
            surface.SetDrawColor(30, 30, 30, alpha or (intensity or 5) * 20)
            surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
            return
        end

        local x, y = panel:LocalToScreen(0, 0)
        local blurAmount = intensity or 5
        local passStep = steps or 0.2
        local overlayAlpha = alpha or 255

        surface.SetMaterial(blurMaterial)
        surface.SetDrawColor(255, 255, 255, overlayAlpha)

        for i = -passStep, 1, passStep do
            blurMaterial:SetFloat("$blur", i * blurAmount)
            blurMaterial:Recompute()

            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
        end
    end

    --- Draws a blur within an arbitrary screen rectangle. Not intended for panels.
    -- @param x number X position.
    -- @param y number Y position.
    -- @param width number Width.
    -- @param height number Height.
    -- @param intensity number Blur strength (0–10 suggested).
    -- @param steps number Blur quality/steps. Defaults to 0.2.
    -- @param alpha number Overlay alpha (default 255).
    -- @usage ax.util:DrawBlurRect(0, 0, 512, 256, 8, 0.2, 180)
    function ax.util:DrawBlurRect(x, y, width, height, intensity, steps, alpha)
        if ( alpha == 0 ) then return end

        if ( ax.option:Get("performance.blur") != true ) then
            surface.SetDrawColor(30, 30, 30, alpha or (intensity or 5) * 20)
            surface.DrawRect(x, y, width, height)
            return
        end

        local blurAmount = intensity or 5
        local passStep = steps or 0.2
        local overlayAlpha = alpha or 255

        local u0, v0 = x / scrW, y / scrH
        local u1, v1 = (x + width) / scrW, (y + height) / scrH

        surface.SetMaterial(blurMaterial)
        surface.SetDrawColor(255, 255, 255, overlayAlpha)

        for i = -passStep, 1, passStep do
            blurMaterial:SetFloat("$blur", i * blurAmount)
            blurMaterial:Recompute()

            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRectUV(x, y, width, height, u0, v0, u1, v1)
        end
    end

    local circleCache = {}
    local unitCircleCache = {}
    local drawVertsCache = {}

    --- Prepare unit-circle vertices (radius = 1) for given segments.
    -- @param segments number Number of segments to approximate circle.
    -- @return table List of unit vertices.
    function ax.util:GetUnitCircle(segments)
        if ( !unitCircleCache[segments] ) then
            local verts = { { x = 0, y = 0 } }
            for i = 0, segments do
                local a = math.rad((i / segments) * -360)
                verts[#verts + 1] = { x = math.cos(a), y = math.sin(a) }
            end

            unitCircleCache[segments] = verts
        end

        return unitCircleCache[segments]
    end

    --- Draws a filled circle caching by radius_segments key.
    -- @param x number Center X.
    -- @param y number Center Y.
    -- @param radius number Circle radius.
    -- @param segments number Number of segments.
    -- @param color Color Fill color.
    function ax.util:DrawCircle(x, y, radius, segments, color)
        local key = radius .. "_" .. segments
        local shape = circleCache[key]

        if ( !shape ) then
            shape = { { x = 0, y = 0 } }

            for i = 0, segments do
                local a = math.rad((i / segments) * -360)
                shape[#shape + 1] = {
                    x = math.cos(a) * radius,
                    y = math.sin(a) * radius
                }
            end

            circleCache[key] = shape
        end

        local verts = {}
        for i = 1, #shape do
            local v = shape[i]
            verts[i] = { x = v.x + x, y = v.y + y }
        end

        surface.SetDrawColor(color.r, color.g, color.b, color.a)
        surface.DrawPoly(verts)
    end

    --- Draws a filled circle by scaling unit-circle vertices (cache per segments).
    -- @param x number Center X.
    -- @param y number Center Y.
    -- @param radius number Circle radius.
    -- @param segments number Number of segments.
    -- @param color Color Fill color.
    function ax.util:DrawCircleScaled(x, y, radius, segments, color)
        local unitVerts = self:GetUnitCircle(segments)
        local verts = drawVertsCache[segments]

        if ( !verts ) then
            verts = {}
            for i = 1, #unitVerts do
                verts[#verts + 1] = { x = 0, y = 0 }
            end

            drawVertsCache[segments] = verts
        end

        for i = 1, #unitVerts do
            local uv = unitVerts[i]
            verts[i].x = x + uv.x * radius
            verts[i].y = y + uv.y * radius
        end

        surface.SetDrawColor(color.r, color.g, color.b, color.a)
        surface.DrawPoly(verts)
    end

    hook.Add("OnScreenSizeChanged", "ax.util.ClearCircleCache", function()
        circleCache = {}
        unitCircleCache = {}
        drawVertsCache = {}
    end)
end

function ax.util:VerifyVersion()
    local version = file.Read("parallax/parallax-version.json", "LUA")
    if ( !version or version == "" ) then
        self:PrintError("Failed to read Parallax version file!")
        return
    end

    version = util.JSONToTable(version)
    if ( !istable(version) or !version.commitCount ) then
        self:PrintError("Invalid Parallax version file format!")
        return
    end

    -- Call in the next tick because ISteamHTTP may not be available at the moment
    timer.Simple(0, function()
        http.Fetch("https://raw.githubusercontent.com/Parallax-Framework/parallax/main/parallax-version.json", function(body)
            local data = util.JSONToTable(body)
            if ( istable(data) ) then
                local commitCount = data.commitCount or 0

                -- Compare with local (assume your local commit count and hash are loaded from a file)
                local localCommit = version.commitCount or 0
                local localVersion = version.version or "unknown"
                local remoteVersion = data.version or "unknown"

                if ( commitCount > localCommit ) then
                    self:PrintWarning("Parallax is out of date! Local version: " .. localVersion .. ", Remote version: " .. remoteVersion)
                elseif ( commitCount < localCommit ) then
                    self:PrintSuccess("Parallax is ahead of the remote repository! Local version: " .. localVersion .. ", Remote version: " .. remoteVersion)
                else
                    self:PrintSuccess("Parallax is up to date! Version: " .. localVersion)
                end

                GAMEMODE.Version = localVersion

                ax.relay:SetRelay("version", {
                    localVersion = localVersion,
                    remoteVersion = remoteVersion,
                    commitCount = localCommit,
                    remoteCommitCount = commitCount
                })
            end
        end)
    end)
end

--- Returns whether the given object is a valid faction object.
-- @realm shared
-- @param object any The object to check.
-- @return boolean True if the object is a faction, false otherwise.
function ax.util:IsFaction(object)
    return getmetatable(object) == ax.faction.meta
end

--- Returns whether the given object is a valid character object.
-- @realm shared
-- @param object any The object to check.
-- @return boolean True if the object is a character, false otherwise.
function ax.util:IsCharacter(object)
    return getmetatable(object) == ax.character.meta
end

--- Returns whether the given object is a valid class object.
-- @realm shared
-- @param object any The object to check.
-- @return boolean True if the object is a class, false otherwise.
function ax.util:IsClass(object)
    return getmetatable(object) == ax.class.meta
end

--- Returns whether the given object is a valid item object.
-- @realm shared
-- @param object any The object to check.
-- @return boolean True if the object is an item, false otherwise.
function ax.util:IsItem(object)
    return getmetatable(object) == ax.item.meta
end

--- Returns whether or not there's empty space in the provided vector.
-- @realm shared
-- @param entity Entity The entity to check around.
-- @param filter Entity|table The entity or table of entities to filter out.
-- @param spacing number The spacing between checks (default 32).
-- @param size number The size of the grid to check (default 3).
-- @param height number The height to check (default 36).
-- @param tolerance number The tolerance for the trace (default 5).
function ax.util:FindEmptySpace(entity, filter, spacing, size, height, tolerance)
    spacing = spacing or 32
    size = size or 3
    height = height or 36
    tolerance = tolerance or 5

    local position = entity:GetPos()
    local mins, maxs = Vector(-spacing * 0.5, -spacing * 0.5, 0), Vector(spacing * 0.5, spacing * 0.5, height)
    local output = {}

    for x = -size, size do
        for y = -size, size do
            local origin = position + Vector(x * spacing, y * spacing, 0)

            local data = {}
                data.start = origin + mins + Vector(0, 0, tolerance)
                data.endpos = origin + maxs
                data.filter = filter or entity
            local trace = util.TraceLine(data)

            data.start = origin + Vector(-maxs.x, -maxs.y, tolerance)
            data.endpos = origin + Vector(mins.x, mins.y, height)

            local trace2 = util.TraceLine(data)

            if (trace.StartSolid or trace.Hit or trace2.StartSolid or trace2.Hit or ( SERVER and !util.IsInWorld(origin) )) then
                continue
            end

            output[#output + 1] = origin
        end
    end

    table.sort(output, function(a, b)
        return a:DistToSqr(position) < b:DistToSqr(position)
    end)

    return output
end