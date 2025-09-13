ax.localization = ax.localization or {}
ax.localization.langs = ax.localization.langs or {}

function ax.localization:Register(name, translation)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintWarning("Invalid localization name provided")
        return
    end

    if ( !istable(translation) ) then
        ax.util:PrintWarning("Invalid localization translation provided for \"" .. name .. "\"")
        return
    end

    if ( istable(ax.localization.langs[name]) ) then
        ax.localization.langs[name] = table.Merge(ax.localization.langs[name], translation)
    end

    self.langs[name] = translation
    ax.util:PrintDebug("Localization \"" .. name .. "\" registered successfully.")
end

function ax.localization:GetPhrase(phrase, ...)
    if ( !isstring(phrase) or phrase == "" ) then
        ax.util:PrintWarning("Invalid phrase provided to ax.localization:GetPhrase()")
        return ""
    end

    local langCode = CLIENT and GetConVar("gmod_language"):GetString() or "en"
    local lang = ax.localization.langs[langCode]
    if ( !istable(lang) or !lang[phrase] ) then
        ax.util:PrintWarning("Phrase \"" .. phrase .. "\" not found in language \"" .. langCode .. "\"")
        return phrase
    end

    local translation = lang[phrase]
    if ( !isstring(translation) or translation == "" ) then
        ax.util:PrintWarning("Translation for phrase \"" .. phrase .. "\" is not a valid string")
        return phrase
    end

    if ( ... ) then
        translation = string.format(translation, ...)
    end

    return translation
end