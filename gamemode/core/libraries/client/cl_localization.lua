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
    if ( stored == nil ) then
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
        return nil
    end

    local value = data[key]
    if ( !isstring(value) ) then
        return nil
    end

    -- If we got additional arguments, format the string, and also try to translate them.
    -- Otherwise if there is none and the language has a %s, we remove it from the string.
    if ( select("#", ...) > 0 ) then
        local args = { ... }
        for i, arg in ipairs(args) do
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