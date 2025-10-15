--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- The type library provides utilities for type detection, sanitization, and formatting.
-- Adapted from the Helix framework with modifications for the Parallax framework.
-- @module ax.type

--- List of supported types with their corresponding IDs.
-- @table ax.type
ax.type = ax.type or {
    [1]         = "string",
    [2]         = "text",
    [4]         = "number",
    [8]         = "bool",
    [16]        = "vector",
    [32]        = "angle",
    [64]        = "color",
    [128]       = "player",
    [256]       = "character",
    [512]       = "steamid",
    [1024]      = "steamid64",
    [2048]      = "array",
    [4096]      = "table",

    string      = 1,
    text        = 2,
    number      = 4,
    bool        = 8,
    vector      = 16,
    angle       = 32,
    color       = 64,
    player      = 128,
    character   = 256,
    steamid     = 512,
    steamid64   = 1024,
    array       = 2048,
    table       = 4096,
}

--- Sanitizes a value to match the specified type ID.
-- Converts and validates values to ensure they conform to the expected type.
-- Returns nil if the value cannot be sanitized to the target type.
-- @realm shared
-- @param typeID number The type ID to sanitize the value to
-- @param value any The value to sanitize
-- @return any The sanitized value, or nil if sanitization failed
-- @usage local sanitizedValue = ax.type:Sanitise(ax.type.number, "123") -- returns 123
-- @usage local player = ax.type:Sanitise(ax.type.player, "John") -- returns player entity or nil
function ax.type:Sanitise(typeID, value)
    if ( typeID == nil or value == nil ) then return nil end

    if ( typeID == ax.type.string or typeID == ax.type.text ) then
        return tostring(value)
    elseif ( typeID == ax.type.number ) then
        return tonumber(value) or 0
    elseif ( typeID == ax.type.bool ) then
        return tobool(value)
    elseif ( typeID == ax.type.vector ) then
        return isvector(value) and value
    elseif ( typeID == ax.type.angle ) then
        return isangle(value) and value
    elseif ( typeID == ax.type.color ) then
        return ( IsColor(value) or ( istable(value) and isnumber(value.r) and isnumber(value.g) and isnumber(value.b) and isnumber(value.a) ) ) and value
    elseif ( typeID == ax.type.player ) then
        return ax.util:FindPlayer(value)
    elseif ( typeID == ax.type.character ) then
        if ( istable(value) and ax.util:IsCharacter(value) ) then
            return value
        end
    elseif ( typeID == ax.type.steamid ) then
        if ( isstring(value) and #value == 19 and string.match(value, "STEAM_%d:%d:%d+") ) then
            return value
        end
    elseif ( typeID == ax.type.steamid64 ) then
        if ( isstring(value) and #value == 17 and ( string.match(value, "7656119%d+") != nil or string.match(value, "9007199%d+") != nil ) ) then
            return value
        end
    elseif ( typeID == ax.type.array ) then
        -- Arrays are handled by the config/option system with populate() validation
        return value
    elseif ( typeID == ax.type.table ) then
        return istable(value) and value
    end

    return nil
end

local basicTypeMap = {
    string  = ax.type.string,
    number  = ax.type.number,
    boolean = ax.type.bool,
    Vector  = ax.type.vector,
    Angle   = ax.type.angle,
    table   = ax.type.table
}

local checkTypeMap = {
    [ax.type.color] = function(val)
        return IsColor(val) or ( istable(val) and isnumber(val.r) and isnumber(val.g) and isnumber(val.b) and isnumber(val.a) )
    end,
    [ax.type.character] = function(val) return getmetatable(val) == ax.character.meta end,
    [ax.type.steamid] = function(val) return isstring(val) and #val == 19 and string.match(val, "STEAM_%d:%d:%d+") != nil end,
    [ax.type.steamid64] = function(val) return isstring(val) and #val == 17 and ( string.match(val, "7656119%d+") != nil or string.match(val, "9007199%d+") != nil ) end
}

--- Detects the type ID of a given value.
-- Automatically determines the appropriate type constant for any Lua value.
-- Useful for dynamic type checking and validation.
-- @realm shared
-- @param value any The value to detect the type of
-- @return number|nil The detected type ID, or nil if the type could not be determined
-- @usage local typeID = ax.type:Detect("example") -- returns ax.type.string
-- @usage local typeID = ax.type:Detect(Vector(1,2,3)) -- returns ax.type.vector
function ax.type:Detect(value)
    local luaType = type(value)
    local mapped = basicTypeMap[luaType]

    if ( mapped ) then return mapped end

    for typeID, validator in pairs(checkTypeMap) do
        if ( validator(value) ) then
            return typeID
        end
    end

    if ( IsValid(value) and value:IsPlayer() ) then
        return ax.type.player
    end

    return nil
end

local typeNames = {
    [ax.type.string] = "String",
    [ax.type.number] = "Number",
    [ax.type.bool] = "Boolean",
    [ax.type.vector] = "Vector",
    [ax.type.angle] = "Angle",
    [ax.type.color] = "Color",
    [ax.type.player] = "Player",
    [ax.type.character] = "Character",
    [ax.type.steamid] = "SteamID",
    [ax.type.steamid64] = "SteamID64",
    [ax.type.array] = "Array",
    [ax.type.table] = "Table"
}

--- Formats a type ID into a human-readable string.
-- Converts type constants into user-friendly names for display purposes.
-- @realm shared
-- @param typeID number The type ID to format
-- @return string The formatted type name
-- @usage local typeName = ax.type:Format(ax.type.color) -- returns "Color"
-- @usage local typeName = ax.type:Format(ax.type.player) -- returns "Player"
function ax.type:Format(typeID)
    if ( typeID == nil ) then return "Unknown" end

    return typeNames[typeID] or "Unknown"
end
