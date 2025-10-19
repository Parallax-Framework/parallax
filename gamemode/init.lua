--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DeriveGamemode("sandbox")

ax = ax or {util = {}, config = {}, options = {}, character = {}, inventory = {}, item = {}}
ax._reload = ax._reload or { pingAt = 0, armed = false, frame = -1 }

AddCSLuaFile("cl_init.lua")

AddCSLuaFile("framework/util/boot.lua")
include("framework/util/boot.lua")

AddCSLuaFile("framework/boot.lua")
include("framework/boot.lua")

hook.Remove("OnEntityCreated", "CreateWidgets")
hook.Remove("PlayerTick", "TickWidgets")
