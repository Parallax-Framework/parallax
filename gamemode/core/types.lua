--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--[[
    The MIT License (MIT)

    Copyright (c) 2015 Brian Hang, Kyu Yeon Lee
    Copyright (c) 2018-2021 Alexander Grist-Hucker, Igor Radovanovic

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
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

-- Credit @ Helix :: https://github.com/NebulousCloud/helix/blob/master/gamemode/core/sh_util.lua

ax.types = ax.types or {
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
}