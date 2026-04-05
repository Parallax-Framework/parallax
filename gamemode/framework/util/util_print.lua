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

--- Converts a list of values into a flat array suitable for `MsgC` output.
-- Iterates the arguments and converts each one as follows:
-- - Valid entities are converted to their `tostring` representation.
-- - Valid player entities additionally get `[SteamID64]` appended as a
--   separate element so the output clearly identifies who was involved.
-- - All other values are included as-is.
-- A newline string is always appended as the last element so that each call
-- to a Print* function ends on its own line. The returned table can be
-- unpacked directly into `MsgC` or used with `table.concat`.
-- @realm shared
-- @param ... any Any number of values to prepare.
-- @return table Flat array of values ready to unpack into `MsgC` or similar.
-- @usage local pkg = ax.util:PreparePackage("Player joined:", somePlayer)
-- MsgC(Color(255, 255, 255), unpack(pkg))
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

--- Prints an informational message prefixed with `[PARALLAX]`.
-- Uses `MsgC` with `color_print` (blue-ish `Color(100, 150, 255)`). Visible
-- on both server and client consoles. All arguments are processed through
-- `PreparePackage` — entities are converted to strings and players get their
-- SteamID64 appended. A trailing newline is included automatically.
-- @realm shared
-- @param ... any Values to print.
-- @return table The prepared argument array that was printed.
-- @usage ax.util:Print("Module loaded:", moduleName)
-- ax.util:Print("Player connected:", client)
function ax.util:Print(...)
    local args = self:PreparePackage(...)
    local printColor = color_print

    MsgC(printColor, "[PARALLAX] ", unpack(args))

    return args
end

--- Prints an error message prefixed with `[PARALLAX] [ERROR]`, with a stack trace.
-- Uses `ErrorNoHaltWithStack`, so the full call stack is included in the
-- console output. Execution continues after the call — this does NOT throw.
-- Use this for non-fatal errors where you want clear diagnostics without
-- stopping the current execution path. Arguments are joined with spaces via
-- `table.concat` after `PreparePackage` processing.
-- @realm shared
-- @param ... any Values to include in the error message.
-- @return table The prepared argument array that was printed.
-- @usage ax.util:PrintError("Failed to load config:", err)
function ax.util:PrintError(...)
    local args = self:PreparePackage(...)

    ErrorNoHaltWithStack("[PARALLAX] [ERROR] " .. string.Trim(table.concat(args, " ")))

    return args
end

--- Prints a warning message prefixed with `[PARALLAX] [WARNING]`.
-- Uses `MsgC` with `color_warning` (orange `Color(255, 200, 100)`). No stack
-- trace is included — use `PrintError` when a stack trace is needed. Suitable
-- for recoverable conditions that should be visible in the console without
-- alarming users or halting execution.
-- @realm shared
-- @param ... any Values to include in the warning.
-- @return table The prepared argument array that was printed.
-- @usage ax.util:PrintWarning("Deprecated function called, use NewFunc instead")
function ax.util:PrintWarning(...)
    local args = self:PreparePackage(...)
    local warningColor = color_warning

    MsgC(warningColor, "[PARALLAX] [WARNING] ", unpack(args))

    return args
end

--- Prints a success message prefixed with `[PARALLAX] [SUCCESS]`.
-- Uses `MsgC` with `color_success` (green `Color(100, 255, 100)`). Use to
-- confirm that an operation completed as expected — module loads, database
-- connections established, configuration saved successfully, etc.
-- @realm shared
-- @param ... any Values to include in the success message.
-- @return table The prepared argument array that was printed.
-- @usage ax.util:PrintSuccess("Database connected:", dbName)
-- ax.util:PrintSuccess("Configuration saved to", path)
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

--- Prints a debug message, gated behind developer mode and realm convars.
-- Output is only produced when ALL of the following conditions are true:
-- 1. The `developer` convar is ≥ 1 (set with `developer 1` in console).
-- 2. `ax_debug_realm` matches the current realm:
--    - `1` → client only
--    - `2` → server only
--    - `3` → both sides
-- 3. If `ax_debug_filter` is non-empty, the message must contain at least one of its comma-separated keywords (case-insensitive substring match).
-- 4. If `ax_debug_rate_limit` is positive, the same message (by content key) can only be printed once within that many seconds — prevents log spam from code running every frame.
-- Uses `MsgC` with `color_debug` (grey `Color(150, 150, 150)`). Returns nil silently when any gate condition prevents output.
-- @realm shared
-- @param ... any Values to include in the debug message.
-- @return table|nil The prepared argument array when printed, nil when gated.
-- @usage ax.util:PrintDebug("Character loaded:", char:GetName())
-- ax.util:PrintDebug("Store set:", key, "=", value)
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
