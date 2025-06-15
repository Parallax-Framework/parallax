--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:EntityTakeDamage(target, dmgInfo)
    if ( !IsValid(target) or !target:IsPlayer() ) then return end

    if ( target:InObserver() ) then
        return true
    end
end

function MODULE:PlayerEnteredVehicle(client, vehicle, role)
    if ( client:InObserver() ) then
        client:SetNoDraw(false)
        client:DrawShadow(true)
        client:SetNotSolid(false)
        client:SetNoTarget(false)
    end
end