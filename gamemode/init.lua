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

resource.AddFile("materials/parallax/banners/unknown.png")
resource.AddFile("materials/parallax/icons/armor.png")
resource.AddFile("materials/parallax/icons/health.png")
resource.AddFile("materials/parallax/icons/speaking.png")
resource.AddFile("materials/parallax/icons/talking.png")
resource.AddFile("materials/parallax/overlays/radial_gradient.png")
resource.AddFile("materials/parallax/overlays/vignette_cinematic.png")
resource.AddFile("materials/parallax/overlays/vignette.png")
resource.AddFile("resources/fonts/gordin-black.ttf")
resource.AddFile("resources/fonts/gordin-bold.ttf")
resource.AddFile("resources/fonts/gordin-light.ttf")
resource.AddFile("resources/fonts/gordin-regular.ttf")
resource.AddFile("resources/fonts/gordin-semibold.ttf")
resource.AddFile("resources/fonts/inter-italic.ttf")
resource.AddFile("resources/fonts/inter.ttf")
resource.AddFile("sound/parallax/ui/error.wav")
resource.AddFile("sound/parallax/ui/generic.wav")
resource.AddFile("sound/parallax/ui/hint.wav")
resource.AddFile("sound/parallax/ui/notification_in.wav")
resource.AddFile("sound/parallax/ui/notification_out.wav")
