--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

DEFINE_BASECLASS("weapon_base")

SWEP.Base = "weapon_base"
SWEP.Spawnable = false
SWEP.AdminOnly = true
SWEP.UseHands = true

SWEP.PrintName = "Parallax Weapon Base"
SWEP.Author = "Riggs"
SWEP.Category = "Parallax"

SWEP.Primary = {
    ClipSize = 10,
    DefaultClip = 0,
    Automatic = false,
    Ammo = "Pistol",
    Delay = 0.2,
    Damage = 15,
    Cone = 0.02,
    Recoil = 1,
    Sound = Sound("Weapon_Pistol.Single"),
    SoundEmpty = Sound("Weapon_Pistol.Empty"),
    NumShots = 1,
    TracerName = "Tracer"
}

SWEP.Primary.Sequence = SWEP.Primary.Sequence or ACT_VM_PRIMARYATTACK
SWEP.Primary.PlaybackRate = SWEP.Primary.PlaybackRate or 1
SWEP.Primary.IronSequence = SWEP.Primary.IronSequence or nil
SWEP.Primary.IronPlaybackRate = SWEP.Primary.IronPlaybackRate or 1

-- Recoil system configuration
SWEP.RecoilPitch = 1.0 -- Vertical recoil per shot
SWEP.RecoilYaw = 0.5 -- Horizontal recoil per shot (random direction)
SWEP.RecoilPitchMin = nil -- Optional min pitch for random range
SWEP.RecoilPitchMax = nil -- Optional max pitch for random range
SWEP.RecoilYawMin = nil -- Optional min yaw for random range
SWEP.RecoilYawMax = nil -- Optional max yaw for random range
SWEP.RecoilInterpSpeed = 15.0 -- How fast recoil interpolates to target (higher = snappier)
SWEP.RecoilRecoverySpeed = 10.0 -- How fast recoil recovers (degrees per second)
SWEP.RecoilRecoveryDelay = 0.1 -- Delay before recovery starts after shooting
SWEP.RecoilIronSightMultiplier = 0.5 -- Recoil multiplier when aiming down sights
SWEP.RecoilMaxPitch = 15.0 -- Maximum accumulated vertical recoil
SWEP.RecoilMaxYaw = 10.0 -- Maximum accumulated horizontal recoil
SWEP.RecoilPattern = nil -- Optional table of {pitch, yaw} vectors for pattern-based recoil

SWEP.Secondary = {
    ClipSize = -1,
    DefaultClip = -1,
    Automatic = false,
    Ammo = "none"
}

SWEP.ViewModel = "models/weapons/c_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.HoldType = "pistol"
SWEP.FireMode = "semi" -- semi, auto, burst, pump, projectile, grenade

SWEP.ViewModelFOV = 55
SWEP.Sensitivity = 1

SWEP.IronSightsEnabled = true
SWEP.IronSightsPos = vector_origin
SWEP.IronSightsAng = angle_zero
SWEP.IronSightsFOV = 0.8
SWEP.IronSightsSensitivity = 0.5
SWEP.IronSightsToggle = false
SWEP.IronSightsDelay = 0.25

-- Muzzle flash light configuration
SWEP.MuzzleLightColor = Color(255, 200, 150)
SWEP.MuzzleLightBrightness = 2
SWEP.MuzzleLightSize = 256
SWEP.MuzzleLightDecay = 1000
SWEP.MuzzleLightDuration = 0.1

-- View offset configuration (idle / lowered positioning)
-- Can be overridden per-weapon (e.g. SWEP.ViewOffsetPos = Vector(x,y,z))
SWEP.ViewOffsetPos = Vector(0, 0, 0)
SWEP.ViewOffsetAng = Angle(0, 0, 0)

-- Optional lowered offsets when sprinting or reloading (future expansion)
SWEP.LoweredOffsetPos = Vector(0, 0, 0)
SWEP.LoweredOffsetAng = Angle(0, 0, 0)

-- How fast (0-1 lerp fraction per frame) the view blends toward its desired offset
SWEP.ViewOffsetLerpSpeed = 8

SWEP.Reloading = {
    Sequence = ACT_VM_RELOAD,
    SequenceEmpty = ACT_VM_RELOAD_EMPTY,
    PlaybackRate = 1,
    Sound = Sound("Weapon_Pistol.Reload"),
    SoundEmpty = Sound("Weapon_Pistol.ReloadEmpty")
}

-- Shotgun reload configuration
SWEP.ShotgunReload = false
SWEP.ShotgunInsertAnim = ACT_VM_RELOAD
SWEP.ShotgunPumpAnim = ACT_SHOTGUN_RELOAD_FINISH
SWEP.ShotgunInsertSound = Sound("Weapon_Shotgun.Reload")
SWEP.ShotgunPumpSound = Sound("Weapon_Shotgun.Special1")

-- Pump after shoot configuration
SWEP.PumpAfterShoot = false
SWEP.PumpSound = Sound("Weapon_Shotgun.Special1")
SWEP.PumpAnim = ACT_SHOTGUN_PUMP

function SWEP:Precache()
    util.PrecacheSound(self.Primary.Sound)
    util.PrecacheModel(self.ViewModel)
    util.PrecacheModel(self.WorldModel)
end

local function IncludeFile(path)
    if ( ( realm == "server" or ax.util:FindString(path, "sv_") ) and SERVER ) then
        include(path)
    elseif ( realm == "shared" or ax.util:FindString(path, "shared.lua") or ax.util:FindString(path, "sh_") ) then
        if ( SERVER ) then
            AddCSLuaFile(path)
        end

        include(path)
    elseif ( realm == "client" or ax.util:FindString(path, "cl_") ) then
        if ( SERVER ) then
            AddCSLuaFile(path)
        else
            include(path)
        end
    end
end

IncludeFile("core/sh_anims.lua")

function SWEP:Initialize()
    BaseClass.Initialize(self)

    -- Initialize recoil state
    self.RecoilAccumPitch = 0
    self.RecoilAccumYaw = 0
    self.RecoilTargetPitch = 0
    self.RecoilTargetYaw = 0
    self.LastRecoilTime = 0
    self.ShotsFired = 0
    self.LastEyeAngles = Angle(0, 0, 0)
    self.RecoilControl = 0
end

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "Reloading")
end

function SWEP:GetIronSights()
    local owner = self:GetOwner()
    if ( !IsValid(owner) ) then return false end

    if ( self:GetReloading() ) then
        return false
    end

    if ( owner:KeyDown(IN_ATTACK2) ) then
        return true
    end

    return false
end

function SWEP:IsEmpty()
    return self:Clip1() <= 0
end

function SWEP:CanPrimaryAttack()
    local owner = self:GetOwner()
    if ( !IsValid(owner) ) then return false end

    if ( self:IsEmpty() ) then
        self:EmitSound(self.Primary.SoundEmpty or "Weapon_Pistol.Empty", nil, nil, nil, CHAN_STATIC)
        self:SetNextPrimaryFire(CurTime() + 1)
        return false
    end

    if ( self:GetReloading() ) then
        return false
    end

    return true
end

local viewPunchAngle = Angle()

function SWEP:PrimaryAttack()
    if ( CurTime() < self:GetNextPrimaryFire() ) then return end

    local owner = self:GetOwner()
    if ( !IsValid(owner) ) then return end

    if ( !self:CanPrimaryAttack() ) then return end

    -- Interrupt shotgun reload if shooting
    if ( self:GetReloading() and self.ShotgunReload ) then
        self:FinishShotgunReload()
    end

    local delay = self.Primary.Delay
    if ( self.Primary.RPM ) then
        delay = 60 / self.Primary.RPM
    end

    self:SetNextPrimaryFire(CurTime() + delay)

    -- Client-side: visuals and effects
    if ( CLIENT and IsFirstTimePredicted() ) then
        self:EmitSound(self.Primary.Sound, nil, nil, nil, CHAN_STATIC)
        owner:MuzzleFlash()

        -- Add muzzle flash light
        local dlight = DynamicLight(self:EntIndex())
        if ( dlight ) then
            dlight.pos = owner:GetShootPos() + owner:GetAimVector() * 32
            dlight.r = self.MuzzleLightColor.r
            dlight.g = self.MuzzleLightColor.g
            dlight.b = self.MuzzleLightColor.b
            dlight.brightness = self.MuzzleLightBrightness
            dlight.Decay = self.MuzzleLightDecay
            dlight.Size = self.MuzzleLightSize
            dlight.DieTime = CurTime() + self.MuzzleLightDuration
        end
    end

    -- Shared or server-side: shooting logic
    if ( self.FireMode == "projectile" and self.ProjectileClass ) then
        self:LaunchProjectile(self.ProjectileClass)
    elseif ( self.FireMode == "grenade" ) then
        self:ThrowGrenade()
    else
        self:ShootBullet(self.Primary.Damage, self.Primary.NumShots, self.Primary.Cone)
    end

    self:TakePrimaryAmmo(1)
    owner:SetAnimation(PLAYER_ATTACK1)

    local anim = self.Primary.Sequence
    local rate = self.Primary.PlaybackRate or 1

    if ( self:GetIronSights() and self.Primary.IronSequence ) then
        anim = self.Primary.IronSequence
        rate = self.Primary.IronPlaybackRate or rate
    end

    self:PlayAnimation(anim, rate)

    -- Pump after shoot for shotguns
    if ( self.PumpAfterShoot ) then
        timer.Simple(0.1, function()
            if ( IsValid(self) ) then
                self:EmitSound(self.PumpSound, nil, nil, nil, CHAN_STATIC)
                self:PlayAnimation(self.PumpAnim, 1)
            end
        end)
    end
end

function SWEP:SecondaryAttack()
    -- Secondary attack logic can be implemented here
end

local spreadVector = Vector()

function SWEP:ShootBullet(damage, num, cone)
    local owner = self:GetOwner()
    owner:LagCompensation(true)

    spreadVector.x = cone
    spreadVector.y = cone

    local bullet = {
        Num = num,
        Src = owner:GetShootPos(),
        Dir = owner:GetAimVector(),
        Spread = spreadVector,
        Tracer = 1,
        TracerName = "none",
        Damage = damage,
        AmmoType = self.Primary.Ammo
    }

    local trace = util.TraceLine({
        start = bullet.Src,
        endpos = bullet.Src + bullet.Dir * 32768,
        filter = owner,
        mask = MASK_SHOT
    })

    if ( self.OnShootBullet ) then
        self:OnShootBullet(bullet, trace)
    end

    if ( self.Primary.TracerName ) then
        bullet.TracerName = self.Primary.TracerName
    end

    owner:FireBullets(bullet)
    owner:LagCompensation(false)

    if ( IsFirstTimePredicted() and ( CLIENT or game.SinglePlayer() ) ) then
        self:ApplyRecoil()
    end
end

--[[
    Applies recoil to the weapon. This accumulates recoil and modifies the player's view angles.
    Respects ironsight multipliers and optional recoil patterns.
]]
function SWEP:ApplyRecoil()
    if ( SERVER ) then return end

    local owner = self:GetOwner()
    if ( !IsValid(owner) or !owner:IsPlayer() ) then return end

    -- Initialize recoil state if not present
    self.RecoilAccumPitch = self.RecoilAccumPitch or 0
    self.RecoilAccumYaw = self.RecoilAccumYaw or 0
    self.RecoilTargetPitch = self.RecoilTargetPitch or 0
    self.RecoilTargetYaw = self.RecoilTargetYaw or 0
    self.LastRecoilTime = self.LastRecoilTime or 0
    self.ShotsFired = self.ShotsFired or 0

    -- Calculate recoil multiplier based on ironsights
    local multiplier = 1.0
    if ( self:GetIronSights() ) then
        multiplier = self.RecoilIronSightMultiplier
    end

    -- Determine recoil amounts
    local pitch, yaw

    if ( self.RecoilPattern and #self.RecoilPattern > 0 ) then
        -- Use pattern-based recoil
        local patternIndex = ( self.ShotsFired % #self.RecoilPattern ) + 1
        local pattern = self.RecoilPattern[patternIndex]
        pitch = pattern.pitch or pattern[1] or self.RecoilPitch
        yaw = pattern.yaw or pattern[2] or 0
    else
        -- Use random recoil
        if ( self.RecoilPitchMin and self.RecoilPitchMax ) then
            pitch = math.Rand(self.RecoilPitchMin, self.RecoilPitchMax)
        else
            pitch = self.RecoilPitch
        end

        if ( self.RecoilYawMin and self.RecoilYawMax ) then
            yaw = math.Rand(self.RecoilYawMin, self.RecoilYawMax)
        else
            yaw = math.Rand(-self.RecoilYaw, self.RecoilYaw)
        end
    end

    -- Apply multiplier
    pitch = pitch * multiplier
    yaw = yaw * multiplier

    -- Set target recoil (will be interpolated in Think)
    self.RecoilTargetPitch = math.Clamp(self.RecoilTargetPitch + pitch, 0, self.RecoilMaxPitch)
    self.RecoilTargetYaw = math.Clamp(self.RecoilTargetYaw + yaw, -self.RecoilMaxYaw, self.RecoilMaxYaw)

    -- Track state
    self.LastRecoilTime = CurTime()
    self.ShotsFired = self.ShotsFired + 1
end

--[[
    Think hook for recoil interpolation and recovery.
]]
function SWEP:Think()
    BaseClass.Think(self)

    if ( CLIENT and IsFirstTimePredicted() ) then
        self:RecoilInterpolation()
        self:RecoilRecovery()
    end
end

--[[
    Interpolates current recoil toward target recoil for smooth camera movement.
]]
function SWEP:RecoilInterpolation()
    if ( !IsValid(self:GetOwner()) ) then return end

    local owner = self:GetOwner()
    if ( !owner:IsPlayer() ) then return end

    -- Initialize recoil state if not present
    self.RecoilAccumPitch = self.RecoilAccumPitch or 0
    self.RecoilAccumYaw = self.RecoilAccumYaw or 0
    self.RecoilTargetPitch = self.RecoilTargetPitch or 0
    self.RecoilTargetYaw = self.RecoilTargetYaw or 0

    -- Detect player input that attempts to control/counter recoil. We measure
    -- the change in eye angles between frames and consider movement that
    -- opposes the recoil direction as "control". We smooth this into a
    -- RecoilControl factor in [0,1]. Higher values reduce automatic recovery.
    local curEye = owner:EyeAngles()
    self.LastEyeAngles = self.LastEyeAngles or curEye

    local eyeDeltaP = curEye.p - self.LastEyeAngles.p
    local eyeDeltaY = curEye.y - self.LastEyeAngles.y

    local function sign(x)
        if ( x > 0 ) then return 1 end
        if ( x < 0 ) then return -1 end
        return 0
    end

    local opposePitch = math.max(0, eyeDeltaP) -- positive p movement opposes downward recoil
    local recoilYawDir = sign(self.RecoilTargetYaw - self.RecoilAccumYaw)
    local opposeYaw = 0
    if ( recoilYawDir > 0 ) then
        opposeYaw = math.max(0, -eyeDeltaY)
    elseif ( recoilYawDir < 0 ) then
        opposeYaw = math.max(0, eyeDeltaY)
    end

    local controlInstant = math.Clamp((opposePitch + math.abs(opposeYaw)) * 10, 0, 1)
    self.RecoilControl = Lerp(8 * FrameTime(), self.RecoilControl or 0, controlInstant)

    local delta = FrameTime()
    local interpSpeed = self.RecoilInterpSpeed

    -- Calculate differences
    local pitchDiff = self.RecoilTargetPitch - self.RecoilAccumPitch
    local yawDiff = self.RecoilTargetYaw - self.RecoilAccumYaw

    -- If differences are negligible, snap to target
    if ( math.abs(pitchDiff) < 0.001 and math.abs(yawDiff) < 0.001 ) then
        self.RecoilAccumPitch = self.RecoilTargetPitch
        self.RecoilAccumYaw = self.RecoilTargetYaw
        return
    end

    -- Interpolate toward target
    local pitchStep = pitchDiff * interpSpeed * delta
    local yawStep = yawDiff * interpSpeed * delta

    -- Apply to view angles
    if ( math.abs(pitchStep) > 0.001 or math.abs(yawStep) > 0.001 ) then
        local ang = owner:EyeAngles()
        ang.p = ang.p - pitchStep
        ang.y = ang.y + yawStep
        owner:SetEyeAngles(ang)

        -- Update accumulated recoil
        self.RecoilAccumPitch = self.RecoilAccumPitch + pitchStep
        self.RecoilAccumYaw = self.RecoilAccumYaw + yawStep
    end

    -- Update last eye angles for the next frame (capture player's input)
    self.LastEyeAngles = curEye
end

--[[
    Recovers accumulated recoil over time, smoothly returning view angles toward original position.
]]
function SWEP:RecoilRecovery()
    if ( !IsValid(self:GetOwner()) ) then return end

    local owner = self:GetOwner()
    if ( !owner:IsPlayer() ) then return end

    -- Initialize recoil state if not present
    self.RecoilAccumPitch = self.RecoilAccumPitch or 0
    self.RecoilAccumYaw = self.RecoilAccumYaw or 0
    self.RecoilTargetPitch = self.RecoilTargetPitch or 0
    self.RecoilTargetYaw = self.RecoilTargetYaw or 0
    self.LastRecoilTime = self.LastRecoilTime or 0
    self.ShotsFired = self.ShotsFired or 0

    -- Check if we should start recovering
    if ( CurTime() - self.LastRecoilTime < self.RecoilRecoveryDelay ) then
        return
    end

    -- If no recoil target accumulated, reset shots fired counter
    if ( self.RecoilTargetPitch <= 0.001 and math.abs(self.RecoilTargetYaw) <= 0.001 ) then
        self.RecoilTargetPitch = 0
        self.RecoilTargetYaw = 0
        self.RecoilAccumPitch = 0
        self.RecoilAccumYaw = 0
        self.ShotsFired = 0
        return
    end

    -- Calculate recovery amount for this frame
    local delta = FrameTime()
    -- If the player is actively countering recoil, lower automatic recovery
    local controlFactor = math.Clamp(self.RecoilControl or 0, 0, 0.95)
    local recoveryScale = math.Clamp(1 - controlFactor * 0.9, 0.05, 1)
    local recoveryAmount = self.RecoilRecoverySpeed * delta * recoveryScale

    -- Recover pitch target
    local pitchRecovery = math.min(recoveryAmount, self.RecoilTargetPitch)
    if ( pitchRecovery > 0 ) then
        self.RecoilTargetPitch = self.RecoilTargetPitch - pitchRecovery
    end

    -- Recover yaw target
    local yawRecovery = math.min(recoveryAmount, math.abs(self.RecoilTargetYaw))
    if ( yawRecovery > 0 ) then
        if ( self.RecoilTargetYaw > 0 ) then
            self.RecoilTargetYaw = self.RecoilTargetYaw - yawRecovery
        else
            self.RecoilTargetYaw = self.RecoilTargetYaw + yawRecovery
        end
    end
end


--[[
    Resets recoil accumulation/targets and delays recovery. Call when an action
    interrupts normal firing/recovery (reloads, weapon swap, etc.).
]]
function SWEP:ResetRecoilRecovery()
    self.RecoilTargetPitch = 0
    self.RecoilTargetYaw = 0
    self.RecoilAccumPitch = 0
    self.RecoilAccumYaw = 0
    self.LastRecoilTime = CurTime()
    self.ShotsFired = 0
    self.RecoilControl = 0
    local owner = self:GetOwner()
    if ( IsValid(owner) and owner:IsPlayer() ) then
        self.LastEyeAngles = owner:EyeAngles()
    end
end

function SWEP:LaunchProjectile(class)
    local owner = self:GetOwner()
    local ent = ents.Create(class)
    if ( !IsValid(ent) ) then return end

    ent:SetPos(owner:GetShootPos())
    ent:SetAngles(owner:EyeAngles())
    ent:SetOwner(owner)
    ent:Spawn()
    ent:SetVelocity(owner:GetAimVector() * 1200)

    return ent
end

function SWEP:ThrowGrenade()
    local owner = self:GetOwner()
    local ent = ents.Create("npc_grenade_frag")
    if ( !IsValid(ent) ) then return end

    ent:SetPos(owner:GetShootPos())
    ent:SetAngles(owner:EyeAngles())
    ent:SetOwner(owner)
    ent:Spawn()
    ent:SetVelocity(owner:GetAimVector() * 800)

    return ent
end

function SWEP:Reload()
    local owner = self:GetOwner()
    if ( !IsValid(owner) ) then return end
    if ( !self:CanReload() ) then return end

    if ( self.ShotgunReload ) then
        self:StartShotgunReload()
    else
        local anim = self.Reloading.Sequence
        if ( self:IsEmpty() ) then
            anim = self.Reloading.SequenceEmpty or anim
        end

        local rate = self.Reloading.PlaybackRate or 1
        self:PlayAnimation(anim, rate)

        local path = self.Reloading.Sound
        if ( self:IsEmpty() ) then
            path = self.Reloading.SoundEmpty or path
        end

        self:EmitSound(path, nil, nil, nil, CHAN_STATIC)

        local duration = self:GetActiveAnimationDuration()
        if ( duration > 0 ) then
            self:SetReloading(true)

            timer.Simple(duration, function()
                if ( IsValid(self) ) then
                    self:SetReloading(false)
                end
            end)
        end

        self:DefaultReload(ACT_VM_RELOAD)
    end
end

function SWEP:CanReload()
    return self:Clip1() < self:GetMaxClip1() and self:Ammo1() > 0
end

function SWEP:StartShotgunReload()
    if ( !self:CanReload() or self:GetReloading() ) then
        return
    end

    self:SetReloading(true)
    self:InsertShell()
    self:DefaultReload(ACT_VM_RELOAD)
end

function SWEP:InsertShell()
    if ( self:Clip1() >= self:GetMaxClip1() or self:Ammo1() <= 0 ) then
        self:FinishShotgunReload()
        return
    end

    local owner = self:GetOwner()
    if ( IsValid(owner) and owner:IsPlayer() ) then
        owner:RemoveAmmo(1, self.Primary.Ammo)
    end

    self:SetClip1(self:Clip1() + 1)

    self:PlayAnimation(self.ShotgunInsertAnim, 1)
    self:EmitSound(self.ShotgunInsertSound, nil, nil, nil, CHAN_STATIC)

    local duration = self:GetActiveAnimationDuration()
    timer.Simple(duration, function()
        if ( IsValid(self) ) then
            self:InsertShell()
        end
    end)
end

function SWEP:FinishShotgunReload()
    self:PlayAnimation(self.ShotgunPumpAnim, 1)
    self:EmitSound(self.ShotgunPumpSound, nil, nil, nil, CHAN_STATIC)

    local duration = self:GetActiveAnimationDuration()
    timer.Simple(duration, function()
        if ( IsValid(self) ) then
            self:SetReloading(false)
        end
    end)
end
