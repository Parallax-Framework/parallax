--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Utility helpers used across the Parallax framework (printing, file handling, text utilities, etc.).
-- @module ax.util

--- Register a sound script by name.
-- Wrapper around `sound.Add` with a stable signature used across the framework.
--
-- Notes:
-- - `path` may be a string or a table of strings.
-- - `pitch` may be a number (fixed) or a {min,max} table.
--
-- @realm shared
-- @param name string Sound script name (e.g. "ax.ui.hint")
-- @param path string|table Sound file path(s)
-- @param volume number|nil Volume scalar (0-1)
-- @param pitch number|table|nil Pitch percent or range table
-- @param channel number|nil Sound channel (CHAN_*)
-- @param level number|nil Sound level (dB)
function ax.util:AddSound(name, path, volume, pitch, channel, level)
    if ( !isstring(name) or name == "" ) then
        self:PrintError("AddSound: invalid name")
        return false
    end

    if ( !(isstring(path) or istable(path)) ) then
        self:PrintError("AddSound: invalid path for sound '" .. name .. "'")
        return false
    end

    volume = tonumber(volume) or 1.0
    channel = channel or CHAN_AUTO
    level = tonumber(level) or 75
    pitch = pitch or 100

    sound.Add({
        name = name,
        channel = channel,
        volume = volume,
        level = level,
        pitch = pitch,
        sound = path
    })

    util.PrecacheSound(name)

    return true
end
