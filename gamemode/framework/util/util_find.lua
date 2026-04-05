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

--- User and character finder utilities.
-- @section find_utilities

--- Normalises a value into a lowercase, trimmed string for search comparisons.
-- Converts `value` to a string via `tostring`, trims leading/trailing
-- whitespace, and lowercases the result using `utf8.lower` when available
-- (falling back to `string.lower`). Returns `""` when the result is empty or
-- when `value` is nil. Used as a pre-processing step by `SearchMatches` to
-- ensure consistent case-insensitive matching.
-- @realm shared
-- @param value any The value to normalise (coerced to string).
-- @return string The trimmed, lowercased string, or `""` if empty/nil.
-- @usage ax.util:NormalizeSearchString("  Hello  ")  -- "hello"
-- ax.util:NormalizeSearchString(nil)                 -- ""
function ax.util:NormalizeSearchString(value)
    value = string.Trim(tostring(value or ""))
    if ( value == "" ) then
        return ""
    end

    if ( utf8 and utf8.lower ) then
        return utf8.lower(value)
    end

    return string.lower(value)
end

--- Tests whether a search query is contained in any of the provided candidates.
-- Both the query and each candidate are normalised with `NormalizeSearchString`
-- before comparison. An empty query always returns true — this matches the
-- convention of "show everything when the search box is blank". The check is
-- substring-based (not exact match), so `"cit"` will match `"citizen"`.
-- @realm shared
-- @param query string The search text to look for.
-- @param ... any Candidate values to test against (each coerced to string).
-- @return boolean True if the query is empty, or if any candidate contains
--   the query as a substring (case-insensitive).
-- @usage ax.util:SearchMatches("pol", "Citizen", "Police Officer") -- true
-- ax.util:SearchMatches("", "anything")                            -- true
-- ax.util:SearchMatches("xyz", "Citizen", "Police")               -- false
function ax.util:SearchMatches(query, ...)
    query = self:NormalizeSearchString(query)
    if ( query == "" ) then
        return true
    end

    for i = 1, select("#", ...) do
        local value = self:NormalizeSearchString(select(i, ...))
        if ( value != "" and string.find(value, query, 1, true) ) then
            return true
        end
    end

    return false
end

--- Tests whether `find` appears as a substring inside `str`.
-- By default the search is case-insensitive (both strings are lowercased via
-- `utf8.lower` or `string.lower` before comparison) and pattern characters in
-- `find` are treated as plain text. All optional parameters allow overriding
-- these defaults when needed.
-- Prints an error and returns false when either `str` or `find` is nil.
-- @realm shared
-- @param str string The string to search in.
-- @param find string The substring (or pattern) to search for.
-- @param caseSensitive boolean|nil When true, the strings are compared without
--   lowercasing. Default: false (case-insensitive).
-- @param startPos number|nil The character position to start searching from.
--   Default: 0 (from the beginning).
-- @param usePatterns boolean|nil When true, `find` is treated as a Lua
--   pattern. Default: false (plain-text search via `string.find` plain flag).
-- @return boolean True if `find` appears in `str`, false otherwise.
-- @usage ax.util:FindString("Hello World", "world")            -- true
-- ax.util:FindString("Hello World", "World", true)            -- true (exact case)
-- ax.util:FindString("Hello World", "World", false)           -- true (case-insensitive)
-- ax.util:FindString("Hello World", "xyz")                    -- false
function ax.util:FindString(str, find, caseSensitive, startPos, usePatterns)
    if ( str == nil or find == nil ) then
        ax.util:PrintError("Attempted to find a string with no value to find for! (" .. tostring(str) .. ", " .. tostring(find) .. ")")
        return false
    end

    if ( !caseSensitive ) then
        if ( utf8 and utf8.lower ) then
            str = utf8.lower(str)
            find = utf8.lower(find)
        else
            str = string.lower(str)
            find = string.lower(find)
        end
    end

    return string.find(str, find, startPos or 0, usePatterns == nil and true or usePatterns) != nil
end

--- Tests whether any word in a text block contains a substring.
-- Splits `txt` by both spaces and newlines and passes each word individually
-- to `FindString`. Returns true as soon as any word matches. Returns false
-- immediately when either argument is nil. This is more permissive than a
-- whole-string search — it matches even when the query appears in only one
-- word of a multi-word text.
-- @realm shared
-- @param txt string The text block to split and search.
-- @param find string The substring to look for in each word.
-- @return boolean True if any word in `txt` contains `find` (case-insensitive).
-- @usage ax.util:FindText("the quick brown fox", "quick")   -- true
-- ax.util:FindText("hello\nworld", "world")                 -- true
-- ax.util:FindText("hello world", "xyz")                    -- false
function ax.util:FindText(txt, find)
    if ( txt == nil or find == nil ) then return false end

    local words = string.Explode(" ", txt)
    for i = 1, #words do
        if ( self:FindString(words[i], find) ) then
            return true
        end
    end

    words = string.Explode("\n", txt)
    for i = 1, #words do
        if ( self:FindString(words[i], find) ) then
            return true
        end
    end

    return false
end

--- Finds a connected player by a variety of identifier types.
-- Lookup is attempted in this priority order:
-- 1. If `identifier` is already a valid Player entity, it is returned as-is.
-- 2. If `identifier` is a number, `Entity(identifier)` is returned.
-- 3. If `identifier` is a string, the following are tried in order:
--    a. SteamID format (e.g. `"STEAM_0:1:12345"`) → `player.GetBySteamID`
--    b. SteamID64 format (e.g. `"76561198..."`) → `player.GetBySteamID64`
--    c. Partial name/SteamID/SteamID64 substring match against all players
--       (case-insensitive, first match wins).
-- 4. If `identifier` is a table (array), each element is tried recursively
--    and the first successful match is returned.
-- Returns `NULL` (not nil) on no match — callers should test with `IsValid`.
-- @realm shared
-- @param identifier number|string|Player|table An entity index, SteamID,
--   SteamID64, name substring, a Player entity, or a table of any of these.
-- @return Player|NULL The matched player entity, or `NULL` if not found.
-- @usage ax.util:FindPlayer("76561198000000000")
-- ax.util:FindPlayer("John")      -- partial name match
-- ax.util:FindPlayer(1)           -- entity index
function ax.util:FindPlayer(identifier)
    if ( identifier == nil ) then return NULL end

    if ( ax.util:IsValidPlayer(identifier) ) then
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
        else
            for _, v in player.Iterator() do
                if ( self:FindString(v:Nick(), identifier) or self:FindString(v:SteamName(), identifier) or self:FindString(v:SteamID(), identifier) or self:FindString(v:SteamID64(), identifier) ) then
                    return v
                end
            end
        end
    end

    if ( istable(identifier) ) then
        for i = 1, #identifier do
            local foundPlayer = self:FindPlayer(identifier[i])

            if ( self:IsValidPlayer(foundPlayer) ) then
                return foundPlayer
            end
        end
    end

    return NULL
end

-- Local helper to check if a character matches by name
local function matchesByName(char, identifier)
    local name = char:GetName()
    if ( name == identifier ) then
        return true -- exact match
    elseif ( utf8.lower(name) == utf8.lower(identifier) ) then
        return true -- case-insensitive exact match
    elseif ( ax.util:FindString(name, identifier) ) then
        return true -- partial match
    end

    return false
end

-- Local helper to search characters by name
local function searchByName(characters, identifier)
    for _, char in pairs(characters) do
        if ( matchesByName(char, identifier) ) then
            return char
        end
    end

    return nil
end

--- Finds a character by numeric ID or by name (partial, case-insensitive).
-- Searches in two passes:
-- 1. **Active characters** — iterates connected players and tests each one's
--    current character (`client:GetCharacter()`). Numeric identifiers are
--    matched by exact character ID; string identifiers are matched by name
--    using `FindString` (partial, case-insensitive, exact matches take
--    priority via the `matchesByName` helper).
-- 2. **All instances** — if no active character matched, falls back to
--    `ax.character.instances` (all loaded characters regardless of whether
--    a player is using them). Numeric lookup uses direct table indexing;
--    string lookup uses the same name-matching helper.
-- Returns nil when nothing is found.
-- @realm shared
-- @param identifier number|string A numeric character ID or a name string
--   (full or partial).
-- @return ax.character.meta|nil The matched character object, or nil.
-- @usage ax.util:FindCharacter(42)        -- by ID
-- ax.util:FindCharacter("John")           -- partial name match
-- ax.util:FindCharacter("john doe")       -- case-insensitive
function ax.util:FindCharacter(identifier)
    if ( identifier == nil ) then return nil end

    -- Always prioritize active characters (those currently being used by players)
    -- before falling back to all instanced characters.
    local identifierNumber = tonumber(identifier)

    -- First: search active characters bound to players
    for _, client in player.Iterator() do
        if ( !ax.util:IsValidPlayer(client) ) then continue end

        local char = client:GetCharacter()
        if ( !char ) then continue end

        -- Check by ID if searching numerically
        if ( identifierNumber and char:GetID() == identifierNumber ) then
            return char
        end

        -- Check by name if searching by string
        if ( isstring(identifier) and matchesByName(char, identifier) ) then
            return char
        end
    end

    -- No active match found; fall back to all instanced characters
    if ( identifierNumber and ax.character.instances[identifierNumber] ) then
        return ax.character.instances[identifierNumber]
    end

    if ( isstring(identifier) ) then
        return searchByName(ax.character.instances, identifier)
    end

    return nil
end
