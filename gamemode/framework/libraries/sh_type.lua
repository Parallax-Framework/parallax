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

-- Credit @ Helix :: https://github.com/NebulousCloud/helix/blob/master/gamemode/core/sh_util.lua
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
    end

    return nil
end

local basicTypeMap = {
    string  = ax.type.string,
    number  = ax.type.number,
    boolean = ax.type.bool,
    Vector  = ax.type.vector,
    Angle   = ax.type.angle
}

local checkTypeMap = {
    [ax.type.color] = function(val)
        return IsColor(val) or ( istable(val) and isnumber(val.r) and isnumber(val.g) and isnumber(val.b) and isnumber(val.a) )
    end,
    [ax.type.character] = function(val) return getmetatable(val) == ax.character.meta end,
    [ax.type.steamid] = function(val) return isstring(val) and #val == 19 and string.match(val, "STEAM_%d:%d:%d+") != nil end,
    [ax.type.steamid64] = function(val) return isstring(val) and #val == 17 and ( string.match(val, "7656119%d+") != nil or string.match(val, "9007199%d+") != nil ) end
}

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
    [ax.type.array] = "Array"
}

--- Formats a type ID into a human-readable string.
-- @param typeID number The type ID to format.
-- @return string The formatted type name.
-- @usage local typeName = ax.util:FormatType(ax.type.color) -- returns "Color"
function ax.type:Format(typeID)
    if ( typeID == nil ) then return "Unknown" end

    return typeNames[typeID] or "Unknown"
end