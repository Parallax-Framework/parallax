--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.player:RegisterVar("steamID64", {
    field = "steamid64",
    fieldType = ax.type.steamid64,
    default = ""
})

ax.player:RegisterVar("name", {
    field = "name",
    fieldType = ax.type.string,
    default = "Unknown"
})

ax.player:RegisterVar("lastJoin", {
    field = "last_join",
    fieldType = ax.type.number,
    default = 0
})

ax.player:RegisterVar("lastLeave", {
    field = "last_leave",
    fieldType = ax.type.number,
    default = 0
})

ax.player:RegisterVar("playTime", {
    field = "play_time",
    fieldType = ax.type.number,
    default = 0
})

ax.player:RegisterVar("data", {
    field = "data",
    fieldType = ax.type.text,
    default = "[]",
    bNoGetter = true,
    bNoSetter = true
})