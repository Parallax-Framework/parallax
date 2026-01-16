--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.net:Hook("ax.version.init", function(data)
    if ( !istable(data) ) then
        ax.util:PrintWarning("Received invalid parallax version payload from server")
        ax.version = {}
        return
    end

    ax.version = data
    ax.util:PrintDebug("Received parallax version: " .. (ax.version.version or "<unknown>"))
end)
