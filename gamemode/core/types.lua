--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- A list of framework value types used for validation, conversion, and type safety.
-- Types are represented by constant flags for efficient comparison and expansion.
-- You should **only use the named keys**, never rely on the numeric values directly.
--
-- The table also includes reverse mappings from the internal numeric value back to the type name.
-- Use this system to ensure compatibility if values are ever changed internally.
--
-- @realm shared
-- @table ax.types
-- @field string Basic string type
-- @field text Multi-line string
-- @field number Numeric values
-- @field bool Boolean true/false
-- @field vector 3D Vector
-- @field angle Angle structure
-- @field color RGBA Color
-- @field player A player entity or reference
-- @field character A player's character object
-- @field steamid A Steam ID string
-- @field steamid64 A Steam ID 64-bit integer
-- @field array Flag that represents an array of values
-- @usage if ( ax.types[number] ) then ... end

ax.types = ax.types or {
    [1]     = "string",
    [2]     = "text",
    [4]     = "number",
    [8]     = "bool",
    [16]    = "vector",
    [32]    = "angle",
    [64]    = "color",
    [128]   = "player",
    [256]   = "character",
    [512]   = "steamid",
    [1024]  = "steamid64",
    [2048]  = "array",

    string     = 1,
    text       = 2,
    number     = 4,
    bool       = 8,
    vector     = 16,
    angle      = 32,
    color      = 64,
    player     = 128,
    character  = 256,
    steamid    = 512,
    steamid64  = 1024,
    array   = 2048,
}