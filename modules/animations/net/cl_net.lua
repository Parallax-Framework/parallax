--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

net.Receive("ax.sequence.reset", function()
    local client = net.ReadPlayer()
    if ( !IsValid(client) ) then return end

    hook.Run("PostPlayerLeaveSequence", client)
end)

net.Receive("ax.sequence.set", function()
    local client = net.ReadPlayer()
    if ( !IsValid(client) ) then return end

    hook.Run("PostPlayerForceSequence", client)
end)