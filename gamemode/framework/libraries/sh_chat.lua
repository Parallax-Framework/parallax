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

        if ( istable(def.aliases) and def.aliases[1] != nil ) then
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

    if ( !isfunction(def.CanHear) ) then
        def.CanHear = function(this, speaker, listener, data)
            if ( isnumber(this.hearDistance) ) then
                local dist = speaker:EyePos():DistToSqr(listener:EyePos())
                if ( dist > (this.hearDistance * this.hearDistance) ) then
                    return false
                end
            end

            return true
        end
    end

    if ( !isfunction(def.CanSay) ) then
        def.CanSay = function(this, speaker, text, data)
            if ( !this.deadCanChat and speaker:Alive() == false ) then
                return false
            end

            return true
        end
    end

    self.registry[key] = def
end

function ax.chat:Parse(text)
    local chatType = "ic"

    local args = string.Explode(" ", string.sub(text, 2))
    local commandName = string.lower(args[1] or "")

    for k, v in pairs(self.registry) do
        if ( v.key == commandName ) then
            chatType = v.key
            table.remove(args, 1)
            text = table.concat(args, " ")

            break
        end

        if ( istable(v.aliases) ) then
            for i = 1, #v.aliases do
                local alias = v.aliases[i]
                if ( isstring(alias) and string.lower(alias) == commandName ) then
                    chatType = v.key
                    table.remove(args, 1)
                    text = table.concat(args, " ")

                    break
                end
            end
        end
    end

    return chatType, text
end

if ( SERVER ) then
    function ax.chat:Send(speaker, chatType, text, data, receivers)
        local chatClass = self.registry[chatType]
        if ( !istable(chatClass) ) then
            ax.util:PrintError("ax.chat:Send - Invalid chat type \"" .. tostring(chatType) .. "\"")
            return
        end

        if ( !chatClass:CanSay(speaker, text, data) ) then return end

        if ( !istable(receivers) ) then
            receivers = {}

            for _, v in player.Iterator() do
                if ( chatClass:CanHear(speaker, v, data) ) then
                    receivers[#receivers + 1] = v
                end
            end

            if ( receivers[1] == nil ) then
                return
            end
        end

        text = string.Trim(text)

        if ( hook.Run("ShouldFormatMessage", speaker, chatType, text, receivers, data) != false ) then
            text = self:Format(text)
        end

        text = hook.Run("PlayerMessageSend", speaker, chatType, text, receivers, data) or text

        net.Start("ax.chat.message")
            net.WritePlayer(speaker)
            net.WriteString(chatType)
            net.WriteString(text)
            net.WriteTable(data or {})
        if ( isvector(receivers) ) then
            if ( data.receiversPAS ) then net.SendPAS(data.receiversPAS)
            elseif ( data.receiversPVS ) then net.SendPVS(data.receiversPVS)
            end
        else
            net.Send(receivers)
        end

        return text
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

    -- TODO: Add option for ::ApplyShortcuts

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
