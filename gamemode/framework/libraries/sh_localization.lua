--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

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
