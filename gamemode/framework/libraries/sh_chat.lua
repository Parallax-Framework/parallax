--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.chat = ax.chat or {}
ax.chat.classes = ax.chat.classes or {}

function ax.chat:New(name, data)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("Invalid chat class name provided")
        return
    end

    if ( !istable(data) ) then
        ax.util:PrintError("Invalid chat class data provided for class \"" .. name .. "\"")
        return
    end

    self.classes[name] = data
    ax.util:PrintDebug("Chat class \"" .. name .. "\" added successfully.")
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
    text = string.gsub(text, "^%s*([%l])", string.upper)
    text = string.gsub(text, "([%.%!%?]%s+)([%l])", function(punct, ch)
        return punct .. string.upper(ch)
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
    if ( string.upper(text) == text ) then return "upper" end
    if ( string.lower(text) == text ) then return "lower" end
    return "mixed"
end

function ax.chat:Format(message)
    if ( !isstring(message) ) then return "" end

    message = string.Trim(message)
    if ( message == "" ) then return "" end

    local capStyle = detect_capitalization(message)

    message = apply_shortcuts(string.lower(message))
    message = fix_pronoun_i(message)
    message = normalize_spacing(message)
    message = capitalize_sentences(message)

    if ( !LAST_SYMBOLS[string.sub(message, -1)] ) then
        message = message .. "."
    end

    if ( capStyle == "upper" ) then
        message = string.upper(message)
    end

    return message
end