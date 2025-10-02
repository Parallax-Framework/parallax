--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

include("shared.lua")

SWEP.BobScale = 0 -- Disable default gmod bobbing
SWEP.SwayScale = 0 -- Disable default gmod swaying

SWEP.IronSightsProgress = 0
SWEP._vmCachedPos = Vector(0, 0, 0)
SWEP._vmCachedAng = Angle(0, 0, 0)

-- Think doesn't run when reloading, so we have to do this in ViewModelDrawn
function SWEP:ViewModelDrawn()
    local owner = self:GetOwner()
    if ( owner != ax.client ) then return end

    local aim = self:GetIronSights()
    self.IronSightsProgress = math.Clamp(
        ax.ease:Lerp("InOutQuad", FrameTime() * 14, self.IronSightsProgress, aim and 1 or 0),
        0, 1
    )
end

function SWEP:TranslateFOV(fov)
    return ax.ease:Lerp("InOutQuad", self.IronSightsProgress, fov, fov * (self.IronSightsFOV or 0.75))
end

-- Combines base view offsets + ironsight offsets with smoothing
function SWEP:GetViewModelPosition(pos, ang)
    local targetPos = self.ViewOffsetPos or vector_origin
    local targetAng = self.ViewOffsetAng or angle_zero

    local progress = math.Clamp(self.IronSightsProgress, 0, 1)
    if ( self.IronSightsEnabled and progress > 0 ) then
        targetPos = targetPos + (self.IronSightsPos or vector_origin) * progress
        if ( self.IronSightsAng ) then
            targetAng = Angle(
                targetAng.p + self.IronSightsAng.p * progress,
                targetAng.y + self.IronSightsAng.y * progress,
                targetAng.r + self.IronSightsAng.r * progress
            )
        end
    end

    self._vmCachedPos = ax.ease:Lerp("InOutQuad", progress, self._vmCachedPos or vector_origin, targetPos)
    local curAng = self._vmCachedAng or angle_zero
    curAng.p = ax.ease:Lerp("InOutQuad", progress, curAng.p, targetAng.p)
    curAng.y = ax.ease:Lerp("InOutQuad", progress, curAng.y, targetAng.y)
    curAng.r = ax.ease:Lerp("InOutQuad", progress, curAng.r, targetAng.r)
    self._vmCachedAng = curAng

    -- Base rotation from offsets
    ang:RotateAroundAxis(ang:Right(),  curAng.p)
    ang:RotateAroundAxis(ang:Up(),     curAng.y)
    ang:RotateAroundAxis(ang:Forward(),curAng.r)

    -- Apply base positional offsets
    pos = pos + ang:Right()   * self._vmCachedPos.x
    pos = pos + ang:Forward() * self._vmCachedPos.y
    pos = pos + ang:Up()      * self._vmCachedPos.z

    return pos, ang
end