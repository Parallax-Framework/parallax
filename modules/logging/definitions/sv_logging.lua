--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

if ( SERVER ) then
    util.AddNetworkString("ax.logging.send")
end

function MODULE:Send(...)
    if ( !ax.config:Get("logging", true) ) then return end

    local receivers = {}
    for k, v in player.Iterator() do
        if ( !CAMI.PlayerHasAccess(v, "Parallax - Logging") ) then continue end

        receivers[#receivers + 1] = v
    end

    -- Send to the remote console if we are in a dedicated server
    if ( game.IsDedicated() ) then
        ax.util:Print("[Logging] ", ...)
    end

    net.Start("ax.logging.send")
        net.WriteTable({...})
    net.Send(receivers)
end
