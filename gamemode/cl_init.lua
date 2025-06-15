--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DeriveGamemode("sandbox")

ax = ax or {util = {}, gui = {}, meta = {}, config = {}}

include("core/types.lua")
include("core/util.lua")
include("core/boot.lua")

LocalPlayerInternal = LocalPlayer
function LocalPlayer()
    if ( IsValid(ax.client) ) then
        return ax.client
    end

    return LocalPlayerInternal()
end

timer.Remove("HintSystem_OpeningMenu")
timer.Remove("HintSystem_Annoy1")
timer.Remove("HintSystem_Annoy2")