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

--- Printing and logging helpers.
-- @section print_utilities

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

            if ( ax.util:IsValidPlayer(arg) ) then
                package[#package + 1] = "[" .. arg:SteamID64() .. "]"
            end
        else
            package[#package + 1] = arg
        end
    end

    package[#package + 1] =  "\n"

    return package
end

--- Define colors for different print types (legacy globals for compatibility)
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
    local printColor = color_print

    MsgC(printColor, "[PARALLAX] ", unpack(args))

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
    local warningColor = color_warning

    MsgC(warningColor, "[PARALLAX] [WARNING] ", unpack(args))

    return args
end

--- Print a success message.
-- @param ... any Values to print as success output
-- @return table The prepared arguments that were printed
-- @usage ax.util:PrintSuccess("Configuration saved")
function ax.util:PrintSuccess(...)
    local args = self:PreparePackage(...)
    local successColor = color_success

    MsgC(successColor, "[PARALLAX] [SUCCESS] ", unpack(args))

    return args
end

local developer = GetConVar("developer")
local debugRealm = CreateConVar("ax_debug_realm", "0", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Set to 1 to enable debug messages on the client, 2 for server, 3 for both.")
local debugFilter = CreateConVar("ax_debug_filter", "", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Optional comma-separated filter for debug messages. Only messages containing any of the specified keywords will be printed.")
local debugRateLimit = CreateConVar("ax_debug_rate_limit", "0", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Set to a positive number to enable rate limiting for debug messages (in seconds).")

local rateLimitTracker = {}

--- Print a debug message, requires "developer" convar to be enabled
-- @param ... any Values to print for debugging
-- @return table|nil The prepared arguments when printed, nil otherwise
-- @usage ax.util:PrintDebug("Loaded module", moduleName)
function ax.util:PrintDebug(...)
    if ( developer:GetInt() < 1 ) then return end

    if ( ( CLIENT and debugRealm:GetInt() != 1 and debugRealm:GetInt() != 3 ) or ( SERVER and debugRealm:GetInt() != 2 and debugRealm:GetInt() != 3 ) ) then
        return
    end

    local args = self:PreparePackage(...)

    local filterText = debugFilter:GetString()
    if ( filterText != "" ) then
        local filters = string.Split(filterText, ",")
        local messageString = string.lower(tostring(unpack(args)))
        local matchesFilter = false

        for _, filter in ipairs(filters) do
            filter = string.Trim(filter)
            if ( filter != "" and string.find(messageString, string.lower(filter), 1, true) ) then
                matchesFilter = true
                break
            end
        end

        if ( !matchesFilter ) then
            return
        end
    end

    local rateLimit = debugRateLimit:GetFloat()
    if ( rateLimit > 0 ) then
        local key = table.concat(args, " ")
        local lastPrinted = rateLimitTracker[key]
        if ( lastPrinted and ( CurTime() - lastPrinted ) < rateLimit ) then
            return
        end

        rateLimitTracker[key] = CurTime()
    end

    MsgC(color_debug, "[PARALLAX] [DEBUG] ", unpack(args))

    return args
end
