--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.chatbox = ax.chatbox or {}
ax.chatbox.messages = ax.chatbox.messages or {}
ax.chatbox.util = ax.chatbox.util or {}

ax.chatbox.util.constants = ax.chatbox.util.constants or {
    CHAT_TYPE_DEFAULT = "ic",
    CHAT_TYPE_HISTORY_LIMIT = 16,

    RECOMMEND_TYPE_COMMANDS = "commands",
    RECOMMEND_TYPE_VOICES = "voices",

    RECOMMEND_ALPHA_VISIBLE = 255,
    RECOMMEND_ALPHA_HIDDEN = 0,
    RECOMMEND_CYCLE_IDLE = 0,
    RECOMMEND_CYCLE_ACTIVE = 1,

    RECOMMEND_ANIM_DEFAULT = 0.2,
    RECOMMEND_DEBOUNCE_DEFAULT = 0.15,
    RECOMMEND_COMMAND_LIMIT_DEFAULT = 20,
    RECOMMEND_VOICE_LIMIT_DEFAULT = 20,

    MESSAGE_LENGTH_LIMIT_DEFAULT = 512,
    ENTRY_HISTORY_LIMIT_DEFAULT = 128,
    LOOC_PREFIX_DEFAULT = ".//",

    DRAG_ZONE_HEIGHT = 24,
    RESIZE_HANDLE_SIZE = 20,
    OPTION_FLUSH_INTERVAL = 0.12,

    SCREEN_PADDING_SCALE = 2,
    INNER_PADDING_SCALE = 1
}

function ax.chatbox.util:Lower(text)
    return isstring(text) and utf8.lower(text) or ""
end

function ax.chatbox.util:GetPhrase(key, fallback, ...)
    if ( ax.localization and ax.localization.GetPhrase ) then
        local value = ax.localization:GetPhrase(key, ...)
        if ( isstring(value) and value != "" and value != key ) then
            return value
        end
    end

    if ( select("#", ...) > 0 and isstring(fallback) and fallback != "" ) then
        local ok, formatted = pcall(string.format, fallback, ...)
        if ( ok ) then
            return formatted
        end
    end

    return fallback or key
end

function ax.chatbox.util:TrimRight(text)
    return isstring(text) and string.gsub(text, "%s+$", "") or ""
end

function ax.chatbox.util:HasTrailingSpace(text)
    return isstring(text) and string.match(text, "%s$") != nil
end

function ax.chatbox.util:FindLastSpace(text)
    if ( !isstring(text) ) then
        return nil
    end

    for i = #text, 1, -1 do
        if ( string.sub(text, i, i) == " " ) then
            return i
        end
    end
end

function ax.chatbox.util:ParseCommandText(text)
    if ( !isstring(text) or string.sub(text, 1, 1) != "/" ) then
        return "", "", false
    end

    local body = string.sub(text, 2)
    local firstSpace = string.find(body, " ", 1, true)

    if ( !firstSpace ) then
        return string.Trim(body), "", self:HasTrailingSpace(text)
    end

    local command = string.Trim(string.sub(body, 1, firstSpace - 1))
    local args = string.sub(body, firstSpace + 1)

    return command, args, self:HasTrailingSpace(text)
end

function ax.chatbox.util:ReplaceLastToken(text, replacement)
    replacement = replacement or ""

    if ( !isstring(text) or text == "" ) then
        return replacement
    end

    if ( self:HasTrailingSpace(text) ) then
        return text .. replacement
    end

    local index = self:FindLastSpace(text)
    if ( !index ) then
        return replacement
    end

    return string.sub(text, 1, index) .. replacement
end

function ax.chatbox.util:InsertVoiceInCommandText(currentText, voiceName)
    local command, args, trailing = self:ParseCommandText(currentText)
    if ( command == "" ) then
        return voiceName
    end

    local trimmedArgs = string.Trim(args)
    if ( trimmedArgs == "" ) then
        return "/" .. command .. " " .. voiceName
    end

    if ( trailing ) then
        return currentText .. voiceName
    end

    return "/" .. command .. " " .. self:ReplaceLastToken(trimmedArgs, voiceName)
end

function ax.chatbox.util:InsertVoiceInRegularText(currentText, voiceName)
    local trimmed = string.Trim(currentText or "")
    if ( trimmed == "" ) then
        return voiceName
    end

    if ( self:HasTrailingSpace(currentText) ) then
        return currentText .. voiceName
    end

    return self:ReplaceLastToken(currentText, voiceName)
end

function ax.chatbox.util:ExtractVoiceSearchText(text, trailing)
    if ( !isstring(text) ) then
        return ""
    end

    if ( trailing ) then
        return ""
    end

    local trimmed = self:TrimRight(text)
    if ( trimmed == "" ) then
        return ""
    end

    local index = self:FindLastSpace(trimmed)
    if ( !index ) then
        return trimmed
    end

    return string.sub(trimmed, index + 1)
end

function ax.chatbox.util:CopyRecommendations(items)
    local output = {}

    for i = 1, #items do
        local item = items[i]
        output[i] = {
            name = item.name,
            displayName = item.displayName,
            description = item.description,
            isVoice = item.isVoice == true
        }
    end

    return output
end
