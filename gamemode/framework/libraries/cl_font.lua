--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.font = ax.font or {}
ax.font.stored = ax.font.stored or {}

surface.axCreateFont = surface.axCreateFont or surface.CreateFont

function surface.CreateFont(name, data)
    if ( !isstring(name) or !istable(data) ) then
        ax.util:PrintError("Invalid parameters for surface.CreateFont: " .. tostring(name) .. ", " .. tostring(data))
        return
    end

    if ( string.sub(name, 1, 3) == "ax." or string.StartsWith(name, "Parallax") ) then
        ax.font.stored[name] = data
    end

    surface.axCreateFont(name, data)
end