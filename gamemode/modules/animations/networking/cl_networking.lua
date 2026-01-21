--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local function ApplyIK(client)
    if ( !ax.config:Get("animations.ik") or !ax.util:IsValidPlayer(client) ) then
        client:SetIK(false)
        return
    end

    client:SetIK(false)
    timer.Simple(0.1, function()
        if ( ax.util:IsValidPlayer(client) ) then
            client:SetIK(client:GetMoveType() != MOVETYPE_NOCLIP)
        end
    end)
end

ax.net:Hook("animations.update", function(client, animations, holdType)

    if ( !ax.util:IsValidPlayer(client) ) then return end

    local clientTable = client:GetTable()

    clientTable.axAnimations = animations
    clientTable.axHoldType = holdType
    clientTable.axLastAct = -1

    ApplyIK(client)
end)

ax.net:Hook("sequence.reset", function(client)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    hook.Run("PostPlayerLeaveSequence", client)
end)

ax.net:Hook("sequence.set", function(client)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    hook.Run("PostPlayerForceSequence", client)
end)
