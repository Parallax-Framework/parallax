--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:SetupMove(client, mv, cmd)
    if ( !ax.config:Get("stamina", true) ) then return end

    local st = client:GetRelay("stamina")
    if ( istable(st) and st.current <= 0 ) then
        -- Prevent sprinting input
        if ( mv:KeyDown(IN_SPEED) ) then
            mv:SetButtons(mv:GetButtons() - IN_SPEED)
        end

        -- Prevent jumping input
        if ( mv:KeyDown(IN_JUMP) ) then
            mv:SetButtons(mv:GetButtons() - IN_JUMP)
        end

        -- Reduce max speed (e.g., 25% slower)
        mv:SetMaxSpeed(mv:GetMaxSpeed() * 0.75)
        mv:SetMaxClientSpeed(mv:GetMaxClientSpeed() * 0.75)
    end
end