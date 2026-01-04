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
            adminOnly = def.adminOnly or false,
            superAdminOnly = def.superAdminOnly or false,
            chatCommand = true,
            alias = def.alias,
            arguments = {
                { name = "message", type = ax.type.text }
            },
            OnRun = function(client, message)
                if ( !isstring(message) or message == "" ) then
                    return
                end

                if ( def.OnRun ) then
                    message = hook.Run("PlayerMessageSend", client, name, message) or message
                    ax.chat:Send(client, name, message)
                    hook.Run("PlayerMessageSent", client, name, message)
                end
            end
        })
    end

    self.registry[name] = def
    ax.util:PrintDebug("ax.chat:Add - Chat Type \"" .. name .. "\" registered successfully")
end

if ( SERVER ) then
    function ax.chat:Send(client, chatType, ...)
        if ( !isstring(chatType) or chatType == "" ) then
            ax.util:PrintError("ax.chat:Send - Invalid chat type provided")
            return
        end

        local def = self.registry[chatType]
        if ( !def ) then
            ax.util:PrintError("ax.chat:Send - Invalid chat type \"" .. chatType .. "\"")
            return
        end

        local isClientValid = IsValid( client )

        if ( isClientValid and isfunction( def.OnCanRun ) and !def:OnCanRun( client ) ) then
            ax.util:PrintWarning("ax.chat:Send - Client " .. client:SteamID() .. " is not allowed to run chat type \"" .. chatType .. "\"")
            return
        end

        local packaged = {}
        if ( isfunction(def.OnRun) ) then
            local result = { def:OnRun(client, ...) }
            if ( #result == 0 ) then
                ax.util:PrintWarning("ax.chat:Send - Chat type \"" .. chatType .. "\" OnRun did not return any values")
                return
            end

            packaged = result
        else
            packaged = {...}
            ax.util:PrintWarning("ax.chat:Send - Chat type \"" .. chatType .. "\" has no OnRun function defined")
        end

        local clients = {}
        if ( isClientValid ) then clients[#clients + 1] = client end
        for _, v in player.Iterator() do
            if ( isClientValid and v == client ) then continue end

            if ( isfunction(def.CanHear) ) then
                if ( def:CanHear(client, v) ) then
                    clients[#clients + 1] = v
                end
            else
                clients[#clients + 1] = v
            end
        end

        for i = 1, #clients do
            local v = clients[i]
            local messageData = packaged

            -- Allow per-listener message customization
            if ( isfunction(def.OnFormatForListener) ) then
                local customData = { def:OnFormatForListener(client, v, ...) }
                if ( #customData > 0 ) then
                    messageData = customData
                end
            end

            v:ChatPrint(unpack(messageData))
        end

        -- remove any html tags for server logging
        for i = 1, #packaged do
            if isstring(packaged[i]) then
                packaged[i] = string.gsub(packaged[i], "<[^>]->", "")
            end
        end

        -- Log to server console
        ax.util:Print("[CHAT] [" .. utf8.upper(chatType) .. "] ", unpack(packaged))
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

--- Normalize spacing in text
-- @realm shared
-- @param text string The text to normalize
-- @return string The normalized text
function ax.chat:NormalizeSpacing(text)
    text = string.gsub(text, "%s+", " ")
    text = string.gsub(text, "%s+([,%.%!%?%:%;])", "%1")
    text = string.gsub(text, "([,%:%;])%s*", "%1 ")
    text = string.gsub(text, "%?%?%?+", "?")
    text = string.gsub(text, "!!!+", "!")
    text = string.gsub(text, "%.%.+", ".")
    return string.Trim(text)
end

--- Capitalize the first letter of sentences
-- @realm shared
-- @param text string The text to capitalize
-- @return string The capitalized text
function ax.chat:CapitalizeSentences(text)
    -- Capitalize first letter (skip markdown markers)
    text = string.gsub(text, "^([%s%*_~]*)([%l])", function(prefix, ch)
        return prefix .. utf8.upper(ch)
    end)

    -- Capitalize after sentence endings
    text = string.gsub(text, "([%.%!%?]%s+)([%*_~]*)([%l])", function(punct, markers, ch)
        return punct .. markers .. utf8.upper(ch)
    end)

    return text
end

--- Fix pronoun "I" capitalization
-- @realm shared
-- @param text string The text to fix
-- @return string The fixed text
function ax.chat:FixPronounI(text)
    text = string.gsub(text, "%f[%a]i%f[^%a]", "I")
    text = string.gsub(text, "%f[%a]i('?)m%f[^%a]", "I'm")
    text = string.gsub(text, "%f[%a]i('?)ve%f[^%a]", "I've")
    text = string.gsub(text, "%f[%a]i('?)d%f[^%a]", "I'd")
    text = string.gsub(text, "%f[%a]i('?)ll%f[^%a]", "I'll")
    return text
end

--- Detect capitalization style of text
-- @realm shared
-- @param text string The text to analyze
-- @return string "upper", "lower", or "mixed"
function ax.chat:DetectCapitalization(text)
    if ( utf8.upper(text) == text ) then return "upper" end
    if ( utf8.lower(text) == text ) then return "lower" end
    return "mixed"
end

--- Build font name from active styles
-- @realm shared
-- @param baseFont string The base font name
-- @param styles table Table of active styles (bold, italic, underline, strikeout)
-- @return string The complete font name
function ax.chat:BuildFontName(baseFont, styles)
    if ( !next(styles) ) then return baseFont end

    local styleNames = {}
    if ( styles.bold ) then table.insert(styleNames, "bold") end
    if ( styles.italic ) then table.insert(styleNames, "italic") end
    if ( styles.strikeout ) then table.insert(styleNames, "strikeout") end
    if ( styles.underline ) then table.insert(styleNames, "underline") end
    table.sort(styleNames)

    return baseFont .. "." .. table.concat(styleNames, ".")
end

--- Parse Discord-style markdown into font tags
-- Supports: *italic*, **bold**, ***bold+italic***, __underline__, ~~strikeout~~
-- @realm shared
-- @param text string The text to parse
-- @param baseFont string The base font name (default: "ax.small")
-- @param styles table Active styles being applied
-- @return string The formatted text with font tags
function ax.chat:ParseMarkdown(text, baseFont, styles)
    if ( !isstring(text) or text == "" ) then return text end

    baseFont = baseFont or "ax.small"
    styles = styles or {}

    local result = ""
    local i = 1

    while i <= #text do
        local matched = false

        -- Check for ***text*** (bold + italic)
        if ( string.sub(text, i, i + 2) == "***" ) then
            local endPos = string.find(text, "***", i + 3, true)
            if ( endPos ) then
                local newStyles = table.Copy(styles)
                newStyles.bold, newStyles.italic = true, true
                local content = self:ParseMarkdown(string.sub(text, i + 3, endPos - 1), baseFont, newStyles)
                result = result .. content
                i = endPos + 3
                matched = true
            else
                -- Unmatched marker: treat the marker literally and advance to avoid infinite loop
                result = result .. "***"
                i = i + 3
                matched = true
            end
        end

        -- Check for **text** (bold)
        if ( !matched and string.sub(text, i, i + 1) == "**" ) then
            local endPos = string.find(text, "**", i + 2, true)
            if ( endPos ) then
                local newStyles = table.Copy(styles)
                newStyles.bold = true
                local content = self:ParseMarkdown(string.sub(text, i + 2, endPos - 1), baseFont, newStyles)
                result = result .. content
                i = endPos + 2
                matched = true
            else
                -- Unmatched marker: append literal and advance
                result = result .. "**"
                i = i + 2
                matched = true
            end
        end

        -- Check for __text__ (underline)
        if ( !matched and string.sub(text, i, i + 1) == "__" ) then
            local endPos = string.find(text, "__", i + 2, true)
            if ( endPos ) then
                local newStyles = table.Copy(styles)
                newStyles.underline = true
                local content = self:ParseMarkdown(string.sub(text, i + 2, endPos - 1), baseFont, newStyles)
                result = result .. content
                i = endPos + 2
                matched = true
            else
                -- Unmatched marker: append literal and advance
                result = result .. "__"
                i = i + 2
                matched = true
            end
        end

        -- Check for ~~text~~ (strikeout)
        if ( !matched and string.sub(text, i, i + 1) == "~~" ) then
            local endPos = string.find(text, "~~", i + 2, true)
            if ( endPos ) then
                local newStyles = table.Copy(styles)
                newStyles.strikeout = true
                local content = self:ParseMarkdown(string.sub(text, i + 2, endPos - 1), baseFont, newStyles)
                result = result .. content
                i = endPos + 2
                matched = true
            else
                -- Unmatched marker: append literal and advance
                result = result .. "~~"
                i = i + 2
                matched = true
            end
        end

        -- Check for *text* (italic)
        if ( !matched and string.sub(text, i, i) == "*" ) then
            local endPos = string.find(text, "*", i + 1, true)
            if ( endPos ) then
                local newStyles = table.Copy(styles)
                newStyles.italic = true
                local content = self:ParseMarkdown(string.sub(text, i + 1, endPos - 1), baseFont, newStyles)
                result = result .. content
                i = endPos + 1
                matched = true
            else
                -- Unmatched marker: append literal and advance
                result = result .. "*"
                i = i + 1
                matched = true
            end
        end

        if ( !matched ) then
            -- Collect plain text until next markdown marker
            local plainText = ""
            while i <= #text do
                local ch = string.sub(text, i, i)
                if ( ch == "*" or string.sub(text, i, i + 1) == "**" or
                     string.sub(text, i, i + 1) == "__" or string.sub(text, i, i + 1) == "~~" ) then
                    break
                end
                plainText = plainText .. ch
                i = i + 1
            end

            if ( plainText != "" ) then
                if ( next(styles) ) then
                    result = result .. "<font=" .. self:BuildFontName(baseFont, styles) .. ">" .. plainText .. "</font>"
                else
                    result = result .. plainText
                end
            end
        end
    end

    return result
end

--- Format a chat message with text processing and optional markdown
-- @realm shared
-- @param message string The message to format
-- @param options table Options table (baseFont, markdown)
-- @return string The formatted message
function ax.chat:Format(message, options)
    if ( !isstring(message) or message == "" ) then return "" end

    message = string.Trim(message)
    options = options or {}

    local baseFont = options.baseFont or "ax.small.shadow"
    local enableMarkdown = options.markdown != false
    local capStyle = self:DetectCapitalization(message)

    -- Apply text transformations
    message = self:ApplyShortcuts(message)
    message = self:FixPronounI(message)
    message = self:NormalizeSpacing(message)
    message = self:CapitalizeSentences(message)
    -- Ensure there's a trailing punctuation character on the visible text.
    -- If the message ends with markdown markers (e.g. '__', '**', '*', '~~'), insert the period
    -- before those markers so the punctuation becomes part of the styled segment.
    local function InsertPeriodBeforeTrailingMarkers(str)
        if ( str == nil or str == "" ) then return str end

        -- Find last index that is not a marker character
        local i = #str
        while i > 0 do
            local ch = string.sub(str, i, i)
            if ( ch != "*" and ch != "_" and ch != "~" ) then break end
            i = i - 1
        end

        if ( i == 0 ) then
            -- Message is only markers; append period at end
            return str .. "."
        end

        local lastChar = string.sub(str, i, i)
        if ( LAST_SYMBOLS[lastChar] ) then
            return str
        end

        -- Insert period after the last non-marker character (before trailing markers)
        return string.sub(str, 1, i) .. "." .. string.sub(str, i + 1)
    end

    message = InsertPeriodBeforeTrailingMarkers(message)

    -- Parse markdown to font tags if enabled
    if ( enableMarkdown ) then
        message = self:ParseMarkdown(message, baseFont)
    end

    if ( capStyle == "upper" ) then
        message = utf8.upper(message)
    end

    return message
end

--- Format message with markdown support
function ax.chat:FormatWithMarkdown(message, baseFont)
    return self:Format(message, { markdown = true, baseFont = baseFont })
end
