--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

include("shared.lua")

function SWEP:CheckYaw()
    local client = self:GetOwner()
    local playerPitch = client:EyeAngles().p
    if ( playerPitch < -20 ) then
        if ( !client:RateLimit("hands", 0.5) ) then return end

        ax.net:Start("ax.hands.reset")
    end
end

function SWEP:Think()
    if ( self:GetOwner() ) then
        self:CheckYaw()
    end
end
