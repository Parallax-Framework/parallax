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

--- User and character finder utilities.
-- @section find_utilities

--- Find a specific piece of text within a larger body of text (case-insensitive).
-- @param str string The string to search in
-- @param find string The substring to search for
-- @return boolean True if substring exists in string
-- @usage if ax.util:FindString("Hello World", "world") then print("found") end
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

--- Search each word in a text for a substring (case-insensitive).
-- @param txt string The text to search
-- @param find string The substring to search for across words
-- @return boolean True when any word in txt contains find
-- @usage ax.util:FindText("the quick brown fox", "quick")
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

--- Find a player by SteamID, SteamID64, name, entity or numeric index.
-- @param identifier number|string|Entity|table Player identifier or list of identifiers
-- @return Player|NULL The found player entity or NULL
-- @usage local client = ax.util:FindPlayer("7656119...")
function ax.util:FindPlayer(identifier)
    if ( identifier == nil ) then return NULL end

    if ( isentity(identifier) and IsValid(identifier) and identifier:IsPlayer() ) then
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
        end

        for _, v in player.Iterator() do
            if ( self:FindString(v:Nick(), identifier) or self:FindString(v:SteamName(), identifier) or self:FindString(v:SteamID(), identifier) or self:FindString(v:SteamID64(), identifier) ) then
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

--- Find a character by ID or name (case-insensitive, partial match).
-- @param identifier number|string Character ID or name to search for
-- @return ax.character.meta|nil The found character or nil
-- @usage local char = ax.util:FindCharacter("John")
function ax.util:FindCharacter(identifier)
    if ( identifier == nil ) then return nil end

    -- Always prioritize active characters (those currently being used by players)
    -- before falling back to all instanced characters.
    local identifierNumber = tonumber(identifier)

    -- First: search active characters bound to players
    for _, client in player.Iterator() do
        if ( !IsValid(client) ) then continue end

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
