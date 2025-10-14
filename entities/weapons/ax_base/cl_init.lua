--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

include("shared.lua")

function SWEP:Initialize()
    self:SetHoldType(self.HoldType or "pistol")
end

SWEP.BobScale = 0 -- Disable default gmod bobbing
SWEP.SwayScale = 0 -- Disable default gmod swaying

SWEP.IronSightsProgress = 0

--- Returns the ironsight transition duration in seconds.
-- Override per-SWEP: set SWEP.IronSightsDuration = 0.18, etc.
-- @treturn number duration seconds
function SWEP:GetIronSightsDuration()
    return self.IronSightsDuration or math.sin(math.pi / 4)
end

--- Starts a timed lerp for ironsight progress from current to target.
-- Internal helper; called when ironsight state flips.
-- @tparam boolean aiming target ironsight state
function SWEP:_StartIronsightLerp(aiming)
    self._ironStartTime = CurTime()
    self._ironFrom = self.IronSightsProgress or (aiming and 0 or 1)
    self._ironTo = aiming and 1 or 0
end

-- Think doesn't run when reloading, so we have to do this in ViewModelDrawn
function SWEP:ViewModelDrawn()
    local owner = self:GetOwner()
    if ( owner != ax.client ) then return end

    -- Handle ironsight progress at a fixed duration
    local aiming = self:GetIronSights() == true
    if ( self._ironLastState == nil ) then
        -- First tick: snap to current state so we don't tween from nil
        self.IronSightsProgress = aiming and 1 or 0
        self._ironLastState = aiming
        self._ironStartTime = nil
    elseif ( aiming != self._ironLastState ) then
        -- State changed: begin a new timed tween
        self:_StartIronsightLerp(aiming)
        self._ironLastState = aiming
    end

    local dur = self:GetIronSightsDuration()
    if ( dur <= 0 ) then
        -- Instant if duration is zero or negative
        self.IronSightsProgress = aiming and 1 or 0
        self._ironStartTime = nil
    elseif ( self._ironStartTime ) then
        -- Evaluate tween
        local t1 = self._ironStartTime
        local t2 = t1 + dur
        local frac = math.TimeFraction(t1, t2, CurTime())
        frac = math.Clamp(frac, 0, 1)

        self.IronSightsProgress = ax.ease:Lerp("OutCubic", frac, self._ironFrom or 0, self._ironTo or (aiming and 1 or 0))

        if ( frac >= 1 ) then
            -- Finished: snap, clear tween state
            self.IronSightsProgress = aiming and 1 or 0
            self._ironStartTime = nil
            self._ironFrom = nil
            self._ironTo = nil
        end
    end
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
        targetPos = targetPos + ((self.IronSightsPos or vector_origin) * progress)
        if ( self.IronSightsAng ) then
            targetAng = Angle(
                targetAng.p + self.IronSightsAng.p * progress,
                targetAng.y + self.IronSightsAng.y * progress,
                targetAng.r + self.IronSightsAng.r * progress
            )
        end
    end

    pos = pos + (ang:Right() * targetPos.x) + (ang:Forward() * targetPos.y) + (ang:Up() * targetPos.z)
    ang:RotateAroundAxis(ang:Right(), targetAng.p)
    ang:RotateAroundAxis(ang:Up(), targetAng.y)
    ang:RotateAroundAxis(ang:Forward(), targetAng.r)

    return pos, ang
end
