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

function ax.chat:Format(message)
    message = string.Trim(message)
    message = string.upper(string.sub(message, 1, 1)) .. string.sub(message, 2)

    if ( !LAST_SYMBOLS[string.sub(message, -1)] ) then message = message .. "." end

    return message
end