--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Chat system for registering chat types with commands, permissions, and custom formatting.
-- Supports message preprocessing with shortcuts, capitalization, and punctuation normalization.
-- @module ax.chat

ax.chat = ax.chat or {}
ax.chat.registry = ax.chat.registry or {}

function ax.chat:Add(name, def)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("ax.chat:Add - Invalid chat name provided")
        return
    end

    if ( !istable(def) ) then
        ax.util:PrintError("ax.chat:Add - Invalid chat definition provided for \"" .. name .. "\"")
        return
    end

    if ( !def.noCommand ) then
        ax.command:Add(name, {
            displayName = def.displayName or ax.util:UniqueIDToName(name),
            description = def.description or "No description available.",
            chatCommand = true,
            arguments = {
                { name = "message", type = ax.type.text }
            },
            OnRun = function(cmd, client, message)
                if ( !isstring(message) or message == "" ) then
                    return
                end

                if ( def.OnRun ) then
                    message = hook.Run("PlayerMessageSend", client, name, message) or message
                    ax.chat:Send(client, name, message)
                end
            end
        })
    end

    self.registry[name] = def
    ax.util:PrintDebug("ax.chat:Add - Chat Type \"" .. name .. "\" registered successfully")
end

if ( SERVER ) then
    function ax.chat:Send(client, chatType, ...)
        if ( !IsValid(client) or !client:IsPlayer() ) then return end
        if ( !isstring(chatType) or chatType == "" ) then return end

        local def = self.registry[chatType]
        if ( !def ) then
            ax.util:PrintError("ax.chat:Send - Invalid chat type \"" .. chatType .. "\"")
            return
        end

        local packaged = {}
        if ( isfunction(def.OnRun) ) then
            local result = { def:OnRun(client, ...) }
            if ( #result == 0 ) then return end

            packaged = result
        else
            packaged = { ... }
        end

        local clients = {}
        for _, v in player.Iterator() do
            if ( v == client ) then
                clients[#clients + 1] = v
            elseif ( isfunction(def.CanHear) ) then
                if ( def:CanHear(client, v) ) then
                    clients[#clients + 1] = v
                end
            else
                clients[#clients + 1] = v
            end
        end

        for i = 1, #clients do
            local v = clients[i]
            v:ChatPrint(unpack(packaged))
        end
    end
end

local LAST_SYMBOLS = {
    ["!"] = true,
    ["?"] = true,
    ["."] = true,
}

local SHORTCUTS = {
    -- Greetings & casual
    ["hi"] = "hello",
    ["hey"] = "hello",
    ["yo"] = "hello",
    ["sup"] = "hello",

    -- Abbreviations & internet shorthand
    ["u"] = "you",
    ["ur"] = "your",
    ["r"] = "are",
    ["pls"] = "please",
    ["plz"] = "please",
    ["thx"] = "thanks",
    ["ty"] = "thanks",
    ["brb"] = "be right back",
    ["btw"] = "by the way",
    ["idk"] = "I don't know",
    ["np"] = "no problem",
    ["ik"] = "I know",

    -- Contractions/missing apostrophes
    ["dont"] = "don't",
    ["cant"] = "can't",
    ["wont"] = "won't",
    ["didnt"] = "didn't",
    ["doesnt"] = "doesn't",
    ["wasnt"] = "wasn't",
    ["werent"] = "weren't",
    ["shouldnt"] = "shouldn't",
    ["couldnt"] = "couldn't",
    ["wouldnt"] = "wouldn't",

    -- Pronouns & phrases
    ["im"] = "I'm",
    ["ive"] = "I've",
    ["id"] = "I'd",
    ["alot"] = "a lot",
    ["whats"] = "what's",
    ["wanna"] = "want to",
    ["gonna"] = "going to",
    ["gotta"] = "got to",
    ["ya"] = "you",
    ["aint"] = "ain't",
    ["lemme"] = "let me",
    ["gimme"] = "give me",
    ["howre"] = "how are",
    ["heres"] = "here is",
    ["theres"] = "there is",
    ["whereve"] = "where have",
    ["whatre"] = "what are",
    ["whatcha"] = "what are you"
}

local function apply_shortcuts(text)
    for k, v in pairs(SHORTCUTS) do
        text = string.gsub(text, "%f[%a]" .. k .. "%f[^%a]", v)
    end

    return text
end

local function normalize_spacing(text)
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "%s+([,%.%!%?%:%;])", "%1")
    text = string.gsub(text, "([,%:%;])%s*", "%1 ")
    text = string.gsub(text, "%?%?%?+", "?")
    text = string.gsub(text, "!!!+", "!")
    text = string.gsub(text, "%.%.+", ".")

    return string.Trim(text)
end

local function capitalize_sentences(text)
    text = string.gsub(text, "^%s*([%l])", utf8.upper)
    text = string.gsub(text, "([%.%!%?]%s+)([%l])", function(punct, ch)
        return punct .. utf8.upper(ch)
    end)

    return text
end

local function fix_pronoun_i(text)
    text = string.gsub(text, "%f[%a]i%f[^%a]", "I")
    text = string.gsub(text, "%f[%a]i('?)m%f[^%a]", "I'm")
    text = string.gsub(text, "%f[%a]i('?)ve%f[^%a]", "I've")
    text = string.gsub(text, "%f[%a]i('?)d%f[^%a]", "I'd")
    text = string.gsub(text, "%f[%a]i('?)ll%f[^%a]", "I'll")

    return text
end

local function detect_capitalization(text)
    if ( utf8.upper(text) == text ) then return "upper" end
    if ( utf8.lower(text) == text ) then return "lower" end

    return "mixed"
end

function ax.chat:Format(message)
    if ( !isstring(message) ) then return "" end

    message = string.Trim(message)
    if ( message == "" ) then return "" end

    local capStyle = detect_capitalization(message)

    message = apply_shortcuts(message)
    message = fix_pronoun_i(message)
    message = normalize_spacing(message)
    message = capitalize_sentences(message)

    if ( !LAST_SYMBOLS[string.sub(message, -1)] ) then
        message = message .. "."
    end

    if ( capStyle == "upper" ) then
        message = utf8.upper(message)
    end

    return message
end
