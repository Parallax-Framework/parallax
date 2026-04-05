--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Utility helpers used across the Parallax framework (printing, file handling, text utilities, etc.).
-- @module ax.util

--- Registers a named sound script and precaches it for use in gameplay.
-- Wraps `sound.Add` with validated inputs and sane defaults. After registration the sound is immediately precached via `util.PrecacheSound`, so callers do not need to call that separately. Sound scripts registered here can be emitted with `Entity:EmitSound(name)`.
-- Defaults when parameters are omitted:
-- - `volume`: 1.0 (full volume)
-- - `pitch`: 100 (normal pitch)
-- - `channel`: `CHAN_AUTO` (GMod selects the channel automatically)
-- - `level`: 75 dB (typical indoor sound radius)
-- `path` may be a string for a single file, or a table of file paths for random variation (GMod picks one at random per emission). `pitch` may be a fixed number (e.g. 100) or a `{ min, max }` table for random pitch per emission (e.g. `{ 95, 105 }`).
-- Returns false with a printed error when `name` or `path` is invalid.
-- @realm shared
-- @param name string The sound script identifier (e.g. `"ax.ui.click"`). Use namespaced names to avoid collisions with other addons.
-- @param path string|table The sound file path(s) relative to `sound/` (e.g. `"buttons/button14.wav"`).
-- @param volume number|nil Volume scalar 0–1. Default: 1.0.
-- @param pitch number|table|nil Fixed pitch percent, or `{ min, max }` table for random pitch. Default: 100.
-- @param channel number|nil Sound channel constant (`CHAN_*`). Default: `CHAN_AUTO`.
-- @param level number|nil Sound propagation level in dB. Default: 75.
-- @return boolean True on successful registration, false on invalid input.
-- @usage ax.util:AddSound("ax.ui.click", "buttons/button14.wav")
-- ax.util:AddSound("ax.ui.notify", { "ambient/alarms/alarm1.wav", "ambient/alarms/alarm2.wav" }, 0.8, { 95, 105 })
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
