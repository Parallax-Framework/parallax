--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Localization library
-- @module ax.localization

ax.localization = {}
ax.localization.stored = {}

--- Register a new language.
-- @realm client
-- @param language The language code.
-- @param data The language data.
function ax.localization:Register(languageName, data)
    if ( !isstring(languageName) ) then
        ax.util:PrintError("Attempted to register a language without a language code!")
        return false
    end

    if ( !istable(data) ) then
        ax.util:PrintError("Attempted to register a language without data!")
        return false
    end

    local stored = self.stored[languageName]
    if ( !istable(stored) ) then
        self.stored[languageName] = {}
    end

    for phrase, translation in pairs(data) do
        self.stored[languageName][phrase] = translation
    end

    hook.Run("OnLanguageRegistered", languageName, data)
end

--- Get a language.
-- @realm client
-- @param language The language code.
-- @return The language data.
function ax.localization:Get(languageName)
    local stored = self.stored[languageName]
    if ( !istable(stored) ) then
        ax.util:PrintError("Attempted to get localisation data that doesn't exist! Language: " .. languageName)
        return false
    end

    return self.stored[languageName]
end

--- Get a localized string.
-- @realm client
-- @param key The key of the string.
-- @param language The language code.
-- @return The localized string.

local gmod_language = GetConVar("gmod_language")
function ax.localization:GetPhrase(key, ...)
    local languageName = ( gmod_language and gmod_language:GetString() ) or "en"

    local data = self:Get(languageName)
    if ( !istable(data) ) then
        return key
    end

    local value = data[key]
    if ( !isstring(value) ) then
        return key
    end

    -- If we got additional arguments, format the string, and also try to translate them.
    -- Otherwise if there is none and the language has a %s, we remove it from the string.
    if ( select("#", ...) > 0 ) then
        local args = { ... }
        for i = 1, #args do
            local arg = args[i]
            if ( isstring(arg) ) then
                args[i] = self:GetPhrase(arg, languageName)
            end
        end

        value = string.format(value, unpack(args))
    elseif ( string.find(value, "%%s") ) then
        -- If the string contains a %s but no additional arguments, we remove it.
        value = string.gsub(value, "%%s", "")
    end

    -- Remove any leading or trailing whitespace.
    value = string.Trim(value)
    return value
end

concommand.Add("ax_localization_check", function(client, command, arguments)
    local enLocalisation = ax.localization.stored.en
    local enCount = table.Count(enLocalisation)
    ax.util:Print("English Localisation has " .. enCount .. " phrases.")

    for languageName, data in pairs(ax.localization.stored) do
        if ( languageName == "en" ) then continue end

        local missingPhrases = {}
        for phrase, translation in SortedPairs(enLocalisation) do
            if ( !data[phrase] ) then
                table.insert(missingPhrases, phrase)
            end
        end

        local dataCount = table.Count(data)
        if ( dataCount != enCount ) then
            ax.util:Print("Language '" .. languageName .. "' has " .. ( dataCount > enCount and "more" or "less" ) .. " phrases (" .. dataCount .. ") than English! (" .. enCount .. ")")
        end

        if ( missingPhrases[1] != nil ) then
            ax.util:PrintWarning("Language \"" .. languageName .. "\" is missing the following phrases: (" .. #missingPhrases .. ")")
            for i = 1, #missingPhrases do
                ax.util:PrintWarning("\t" .. missingPhrases[i])
            end
        end
    end
end)

ax.localisation = ax.localization -- tea