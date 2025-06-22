--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DeriveGamemode("sandbox")
GM.RefreshTimeStart = SysTime()

ax = ax or {util = {}, meta = {}, config = {}, globals = {}}

AddCSLuaFile("cl_init.lua")

AddCSLuaFile("core/types.lua")
include("core/types.lua")

AddCSLuaFile("core/util.lua")
include("core/util.lua")

include("core/sqlite.lua")
include("core/sqloo.lua")
include("core/database.lua")

AddCSLuaFile("core/boot.lua")
include("core/boot.lua")


local addons = engine.GetAddons()
for i = 1, #addons do
    local addon = addons[i]
    if ( tobool(addon.mounted) and tobool(addon.downloaded) and isnumber(addon.wsid) ) then
        resource.AddWorkshop(addon.wsid)
    end
end

resource.AddWorkshop("3479969076")

resource.AddFile("resource/fonts/gordin-black.ttf")
resource.AddFile("resource/fonts/gordin-bold.ttf")
resource.AddFile("resource/fonts/gordin-light.ttf")
resource.AddFile("resource/fonts/gordin-regular.ttf")
resource.AddFile("resource/fonts/gordin-semibold.ttf")