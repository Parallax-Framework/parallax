--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

include("shared.lua")

SWEP.IronSightsProgress = 0

function SWEP:Think()
    local owner = self:GetOwner()
    if ( owner != ax.client ) then return end

    local aim = self:GetIronSights()
    self.IronSightsProgress = Lerp(FrameTime() * 10, self.IronSightsProgress, aim and 1 or 0)
end

function SWEP:TranslateFOV(fov)
    return Lerp(self.IronSightsProgress, fov, fov * (self.IronSightsFOV or 0.75))
end

function SWEP:GetViewModelPosition(pos, ang)
    if ( !self.IronSightsEnabled ) then return pos, ang end

    local offset = self.IronSightsPos or Vector(0, 0, 0)
    local offsetAng = self.IronSightsAng or Angle(0, 0, 0)

    local progress = self.IronSightsProgress

    local modPos = pos + ang:Right() * offset.x * progress
    modPos = modPos + ang:Forward() * offset.y * progress
    modPos = modPos + ang:Up() * offset.z * progress

    ang:RotateAroundAxis(ang:Right(), offsetAng.p * progress)
    ang:RotateAroundAxis(ang:Up(), offsetAng.y * progress)
    ang:RotateAroundAxis(ang:Forward(), offsetAng.r * progress)

    return modPos, ang
end