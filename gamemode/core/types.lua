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
-- @field character A player’s character object
-- @field steamid A Steam64 ID string (17 digits)
-- @field optional Flag that makes a type optional
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

    optional   = 2048,
    array      = 4096,
}