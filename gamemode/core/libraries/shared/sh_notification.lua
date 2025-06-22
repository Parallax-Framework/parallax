--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.notification = ax.notification or {}

NOTIFY_GENERIC = 0
NOTIFY_ERROR = 1
NOTIFY_HINT = 2
NOTIFY_UNDO = 3
NOTIFY_CLEANUP = 4

function ax.notification:Send(client, text, iType, duration)
    if ( !text or text == "" ) then return end

    if ( !iType and string.EndsWith(text, "!") ) then
        iType = NOTIFY_ERROR
    elseif ( !iType and string.EndsWith(text, "?") ) then
        iType = NOTIFY_HINT
    else
        iType = iType or NOTIFY_GENERIC
    end

    duration = duration or 3

    if ( SERVER ) then
        ax.net:Start(client, "notification.send", text, iType, duration)
    else
        notification.AddLegacy(text, iType, duration)
    end
end