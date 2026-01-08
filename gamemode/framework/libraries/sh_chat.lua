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

function ax.chat:Add(key, def)
    if ( !isstring(key) or key == "" ) then
        ax.util:PrintError("ax.chat:Add - Invalid chat key provided")
        return
    end

    if ( !istable(def) ) then
        ax.util:PrintError("ax.chat:Add - Invalid chat definition provided for \"" .. key .. "\"")
        return
    end

    def.key = key

    if ( CLIENT ) then
        ax.command:Add(def.key, {
            displayName = def.name or def.key,
            description = def.description or "Sends a " .. (def.name or def.key) .. " message.",
            arguments = def.arguments or {
                {
                    type = ax.type.text,
                    name = "message",
                    optional = false,
                }
            },
            OnRun = nil -- handle with networking
        })

        if ( isstring(def.alias) and def.alias != "" ) then
            if ( def.alias[1] == "/" ) then def.alias = string.sub(def.alias, 2) end

            ax.command:Add(def.alias, {
                displayName = def.name or def.alias,
                description = def.description or "Sends a " .. (def.name or def.alias) .. " message.",
                arguments = def.arguments or {
                    {
                        type = ax.type.text,
                        name = "message",
                        optional = false,
                    }
                },
                OnRun = nil -- handle with networking
            })
        elseif ( istable(def.aliases) and def.aliases[1] != nil ) then
            for i = 1, #def.aliases do
                local alias = def.aliases[i]
                if ( isstring(alias) and alias != "" ) then
                    if ( alias[1] == "/" ) then alias = string.sub(alias, 2) end

                    ax.command:Add(alias, {
                        displayName = def.name or alias,
                        description = def.description or "Sends a " .. (def.name or alias) .. " message.",
                        arguments = def.arguments or {
                            {
                                type = ax.type.text,
                                name = "message",
                                optional = false,
                            }
                        },
                        OnRun = nil -- handle with networking
                    })
                end
            end
        end
    end

    self.registry[key] = def
end

if ( SERVER ) then
    function ax.chat:Send(speaker, text, chatType, data, receivers, ...)
        local chatType = self.registry[chatType]
        if ( !istable(chatType) ) then
            ax.util:PrintError("ax.chat:Send - Invalid chat type \"" .. tostring(chatType) .. "\"")
            return
        end
    end
end

local LAST_SYMBOLS = {
    ["."] = true,
    ["!"] = true,
    ["?"] = true,
}

function ax.chat:Format(text)
    text = string.Trim(text)

    local lastChar = string.sub(text, -1)
    if ( lastChar != "" and !LAST_SYMBOLS[lastChar] ) then
        text = text .. "."
    end

    text = string.upper(string.sub(text, 1, 1)) .. string.sub(text, 2)
    return text
end

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

--- Apply chat shortcuts to text
-- @realm shared
-- @param text string The text to process
-- @return string The text with shortcuts replaced
function ax.chat:ApplyShortcuts(text)
    for k, v in pairs(SHORTCUTS) do
        text = string.gsub(text, "%f[%a]" .. k .. "%f[^%a]", v)
    end
    return text
end
