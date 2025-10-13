--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local basePath = ""

if ( SERVER ) then
    AddCSLuaFile(basePath .. "util_bots.lua")
    AddCSLuaFile(basePath .. "util_core.lua")
    AddCSLuaFile(basePath .. "util_file.lua")
    AddCSLuaFile(basePath .. "util_find.lua")
    AddCSLuaFile(basePath .. "util_print.lua")
    AddCSLuaFile(basePath .. "util_store.lua")
    AddCSLuaFile(basePath .. "util_text.lua")
end

include(basePath .. "util_bots.lua")
include(basePath .. "util_core.lua")
include(basePath .. "util_file.lua")
include(basePath .. "util_find.lua")
include(basePath .. "util_print.lua")
include(basePath .. "util_store.lua")
include(basePath .. "util_text.lua")

if ( !ax.util.Include ) then
    ax.util:PrintError("Failed to load utility functions!")
    return
end
