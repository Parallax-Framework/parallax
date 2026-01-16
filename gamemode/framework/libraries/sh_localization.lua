--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Localization system for multi-language support.
-- Manages translation strings and provides phrase lookup based on client language settings.
-- @module ax.localization

ax.localization = ax.localization or {}
ax.localization.langs = ax.localization.langs or {}

--- Register a localization language with translation table.
-- Adds or merges translation strings for a specific language code.
-- @realm shared
-- @param name string The language code (e.g., "en", "es", "fr")
-- @param translation table Table of phrase keys to translated strings
-- @usage ax.localization:Register("en", { hello = "Hello", goodbye = "Goodbye" })
function ax.localization:Register(name, translation)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintWarning("Invalid localization name provided")
        return
    end

    if ( !istable(translation) ) then
        ax.util:PrintWarning("Invalid localization translation provided for \"" .. name .. "\"")
        return
    end

    self.langs[name] = table.Merge(self.langs[name] or {}, translation)

    ax.util:PrintDebug("Localization \"" .. name .. "\" registered successfully.")
end

--- Adds or updates a single phrase translation for a language.
-- @realm shared
-- @param lang string The language code (e.g., "en", "es", "fr")
-- @param phrase string The phrase key to add/update
-- @param translation string The translated string
-- @usage ax.localization:AddPhrase("en", "welcome", "Welcome")
function ax.localization:AddPhrase(lang, phrase, translation)
    if ( !isstring(lang) or lang == "" ) then
        ax.util:PrintWarning("Invalid localization language provided")
        return
    end

    if ( !isstring(phrase) or phrase == "" ) then
        ax.util:PrintWarning("Invalid phrase key provided for localization \"" .. lang .. "\"")
        return
    end

    if ( !isstring(translation) or translation == "" ) then
        ax.util:PrintWarning("Invalid translation string provided for phrase \"" .. phrase .. "\" in localization \"" .. lang .. "\"")
        return
    end

    self.langs[lang] = self.langs[lang] or {}
    self.langs[lang][phrase] = translation

    ax.util:PrintDebug("Phrase \"" .. phrase .. "\" added/updated for localization \"" .. lang .. "\".")
end

--- Get a localized phrase in the client's language.
-- Looks up a phrase key and returns the translation for the current language.
-- Falls back to the phrase key if no translation is found.
-- @realm shared
-- @param phrase string The phrase key to look up
-- @param ... any Optional format arguments for string.format
-- @return string The translated phrase or the original phrase key if not found
-- @usage local greeting = ax.localization:GetPhrase("hello")
-- @usage local msg = ax.localization:GetPhrase("welcome_player", playerName)
function ax.localization:GetPhrase(phrase, ...)
    if ( !isstring(phrase) or phrase == "" ) then
        ax.util:PrintWarning("Invalid phrase provided to ax.localization:GetPhrase()")
        return ""
    end

    local langCode = CLIENT and GetConVar("gmod_language"):GetString() or "en"
    local lang = ax.localization.langs[langCode]
    if ( !istable(lang) or !lang[phrase] ) then
        return phrase
    end

    local translation = lang[phrase]
    if ( !isstring(translation) or translation == "" ) then
        ax.util:PrintWarning("Translation for phrase \"" .. phrase .. "\" is not a valid string")
        return phrase
    end

    local argCount = select("#", ...)
    if ( argCount > 0 ) then
        translation = string.format(translation, ...)
    end

    return translation
end

cvars.RemoveChangeCallback("gmod_language", "ax_localization_change")
cvars.AddChangeCallback("gmod_language", function(convar, oldValue, newValue)
    ax.util:PrintDebug("Language changed from \"" .. oldValue .. "\" to \"" .. newValue .. "\"")

    for _, panel in pairs(ax.gui) do
        if ( IsValid( panel ) ) then
            if ( isfunction(panel.OnLanguageChanged) ) then
                panel:OnLanguageChanged(oldValue, newValue)
            end

            panel:Remove()
        end

        ax.gui[_] = nil
    end
end, "ax_localization_change")

ax.localisation = ax.localization
