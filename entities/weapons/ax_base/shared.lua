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

-- Sprint inaccuracy multiplier (applied to cone/spread when player is sprinting)
SWEP.SprintConeMultiplier = 4

SWEP.Primary.Sequence = SWEP.Primary.Sequence or ACT_VM_PRIMARYATTACK
SWEP.Primary.PlaybackRate = SWEP.Primary.PlaybackRate or 1
SWEP.Primary.IronSequence = SWEP.Primary.IronSequence or nil
SWEP.Primary.IronPlaybackRate = SWEP.Primary.IronPlaybackRate or 1

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

-- Movement animations configuration
SWEP.WalkAnim = nil -- Set to ACT_VM_IDLE_LOWERED or custom sequence for walking
SWEP.SprintAnim = nil -- Set to ACT_VM_IDLE_DEPLOYED or custom sequence for sprinting
SWEP.IdleAnim = ACT_VM_IDLE -- Default idle animation
SWEP.WalkAnimPlaybackRate = 1
SWEP.SprintAnimPlaybackRate = 1
SWEP.IdleAnimPlaybackRate = 1

SWEP.Reloading = {
    Sequence = ACT_VM_RELOAD,
    SequenceEmpty = ACT_VM_RELOAD_EMPTY,
    PlaybackRate = 1,
    Sound = Sound("Weapon_Pistol.Reload"),
    SoundEmpty = Sound("Weapon_Pistol.ReloadEmpty")
}

-- Shotgun reload configuration
SWEP.ShotgunReload = false
SWEP.ShotgunInsertAnim = ACT_SHOTGUN_RELOAD
SWEP.ShotgunPumpAnim = ACT_SHOTGUN_RELOAD_FINISH -- legacy compatibility; prefer ShotgunFinishAnim
SWEP.ShotgunInsertSound = Sound("Weapon_Shotgun.Reload")
SWEP.ShotgunPumpSound = Sound("Weapon_Shotgun.Special1")
-- Optional dedicated start/finish animations and sounds
SWEP.ShotgunStartAnim = ACT_SHOTGUN_RELOAD_START
SWEP.ShotgunStartSound = Sound("Weapon_Shotgun.Reload")
SWEP.ShotgunFinishAnim = ACT_SHOTGUN_RELOAD_FINISH
SWEP.ShotgunFinishSound = Sound("Weapon_Shotgun.Special1")

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
end

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", 0, "Reloading")

    -- Movement animation state
    self.MovementState = "idle" -- idle, walk, sprint
    self.LastMovementState = "idle"
    self.MovementStateChangeTime = 0
end

function SWEP:GetIronSights()
    local owner = self:GetOwner()
    if ( !IsValid(owner) ) then return false end

    if ( self:GetReloading() ) then return false end

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

    if ( self:GetReloading() ) then return false end

    return true
end

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

    -- Apply recoil kick (client-side)
    if ( CLIENT and IsFirstTimePredicted() ) then
        local pitchMult, yawMult = hook.Run("GetWeaponRecoilMultipliers", self)
        pitchMult = pitchMult or 1.0
        yawMult = yawMult or 1.0
        print( "Recoil Multipliers - Pitch: ", pitchMult, " Yaw: ", yawMult )
        self:ApplyRecoilKick(pitchMult, yawMult)
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

    -- Increase inaccuracy when sprinting
    if ( owner:IsSprinting() ) then
        cone = cone * self.SprintConeMultiplier
    end

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
end

--[[
    Recoil configuration defaults. Override these in derived weapon classes.
    @realm shared
]]
SWEP.RecoilPitch = 1.0 -- Vertical recoil amount per shot
SWEP.RecoilYaw = 0.5 -- Horizontal recoil amount per shot
SWEP.RecoilInterpolationSpeed = 10.0 -- Speed of recoil kick interpolation (degrees per second)
SWEP.RecoilIronSightMultiplier = 0.5 -- Multiplier when aiming down sights
SWEP.RecoilMaxPitch = 20.0 -- Maximum accumulated vertical recoil
SWEP.RecoilMaxYaw = 12.0 -- Maximum accumulated horizontal recoil
SWEP.RecoilPattern = nil -- Optional table of {pitch, yaw} vectors for pattern-based recoil
SWEP.RecoilPatternResetDelay = 0.3 -- Time in seconds before pattern resets when not shooting

SWEP.RecoilPitchAccum = 0
SWEP.RecoilYawAccum = 0
SWEP.RecoilPitchTarget = 0
SWEP.RecoilYawTarget = 0
SWEP.RecoilShotIndex = 0
SWEP.LastShotTime = 0

--[[
    Applies recoil impulse from a shot. Called when shooting.
    @realm client
    @param pitchMult optional pitch multiplier override
    @param yawMult optional yaw multiplier override
]]
function SWEP:ApplyRecoilKick(pitchMult, yawMult)
    if ( SERVER ) then return end

    local owner = self:GetOwner()
    if ( !IsValid(owner) or !owner:IsPlayer() ) then return end

    pitchMult = pitchMult or 1.0
    yawMult = yawMult or 1.0

    -- Apply iron sight multiplier
    local mult = 1.0
    if ( self:GetIronSights() ) then
        mult = self.RecoilIronSightMultiplier
    end

    -- Calculate recoil amounts
    local pitch, yaw

    -- Use pattern-based recoil if available
    if ( self.RecoilPattern and #self.RecoilPattern > 0 ) then
        -- Check if we're still within the pattern
        if ( self.RecoilShotIndex < #self.RecoilPattern ) then
            self.RecoilShotIndex = self.RecoilShotIndex + 1
            local pattern = self.RecoilPattern[self.RecoilShotIndex]
            pitch = (pattern.pitch or pattern[1] or self.RecoilPitch) * pitchMult * mult
            yaw = (pattern.yaw or pattern[2] or 0) * yawMult * mult
        else
            -- Pattern exhausted, use random recoil
            pitch = self.RecoilPitch * pitchMult * mult
            yaw = (math.Rand(0, 1) > 0.5 and 1 or -1) * self.RecoilYaw * yawMult * mult
        end
    else
        -- Random recoil (default behavior)
        pitch = self.RecoilPitch * pitchMult * mult
        yaw = (math.Rand(0, 1) > 0.5 and 1 or -1) * self.RecoilYaw * yawMult * mult
    end

    -- Set target recoil (will be interpolated in Think)
    self.RecoilPitchTarget = math.Clamp(self.RecoilPitchTarget + pitch, 0, self.RecoilMaxPitch)
    self.RecoilYawTarget = math.Clamp(self.RecoilYawTarget + yaw, -self.RecoilMaxYaw, self.RecoilMaxYaw)

    self.LastShotTime = CurTime()
end

function SWEP:Think()
    BaseClass.Think(self)

    if ( CLIENT and IsFirstTimePredicted() ) then
        self:UpdateRecoilInterpolation()
    end

    -- Reset recoil pattern if we haven't shot in a while
    if ( self.RecoilShotIndex > 0 and CurTime() - self.LastShotTime > self.RecoilPatternResetDelay ) then
        self:ResetRecoil()
    end

    self:UpdateMovementAnimation()
end

--[[
    Interpolates accumulated recoil toward target recoil.
    @realm client
]]
function SWEP:UpdateRecoilInterpolation()
    if ( !IsValid(self:GetOwner()) ) then return end

    local owner = self:GetOwner()
    if ( !owner:IsPlayer() ) then return end

    local delta = FrameTime()
    local interpSpeed = self.RecoilInterpolationSpeed

    -- Interpolate pitch
    local pitchDiff = self.RecoilPitchTarget - self.RecoilPitchAccum
    if ( math.abs(pitchDiff) > 0.001 ) then
        local pitchStep = math.Clamp(pitchDiff * interpSpeed * delta, -pitchDiff, pitchDiff)
        self.RecoilPitchAccum = self.RecoilPitchAccum + pitchStep
    else
        self.RecoilPitchAccum = self.RecoilPitchTarget
    end

    -- Interpolate yaw
    local yawDiff = self.RecoilYawTarget - self.RecoilYawAccum
    if ( math.abs(yawDiff) > 0.001 ) then
        local yawStep = math.Clamp(yawDiff * interpSpeed * delta, -math.abs(yawDiff), math.abs(yawDiff))
        self.RecoilYawAccum = self.RecoilYawAccum + yawStep
    else
        self.RecoilYawAccum = self.RecoilYawTarget
    end

    -- Apply interpolated recoil to view angles
    local ang = owner:EyeAngles()
    ang.p = ang.p - pitchDiff * interpSpeed * delta
    ang.y = ang.y + yawDiff * interpSpeed * delta
    owner:SetEyeAngles(ang)
end

--[[
    Resets recoil state.
    @realm shared
]]
function SWEP:ResetRecoil()
    self.RecoilPitchAccum = 0
    self.RecoilYawAccum = 0
    self.RecoilPitchTarget = 0
    self.RecoilYawTarget = 0
    self.RecoilShotIndex = 0
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

    self:ResetRecoil()
end

function SWEP:CanReload()
    return self:Clip1() < self:GetMaxClip1() and self:Ammo1() > 0
end

function SWEP:StartShotgunReload()
    if ( !self:CanReload() or self:GetReloading() ) then
        return
    end

    self:SetReloading(true)
    -- Play dedicated start animation if available, then begin per-shell loop
    local startAnim = self.ShotgunStartAnim or self.ShotgunInsertAnim
    local startSound = self.ShotgunStartSound or self.ShotgunInsertSound
    if ( startAnim ) then
        self:PlayAnimation(startAnim, 1)
    end
    if ( startSound ) then
        self:EmitSound(startSound, nil, nil, nil, CHAN_STATIC)
    end

    local duration = self:GetActiveAnimationDuration()
    if ( duration <= 0 ) then
        duration = 0.3
    end
    timer.Simple(duration, function()
        if ( IsValid(self) ) then
            self:InsertShell()
        end
    end)
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

    if ( SERVER ) then
        self:PlayAnimation(self.ShotgunInsertAnim, 1)
    end

    self:EmitSound(self.ShotgunInsertSound, nil, nil, nil, CHAN_STATIC)

    local duration = self:GetActiveAnimationDuration()
    if ( duration <= 0 ) then
        duration = 0.5
    end

    timer.Simple(duration, function()
        if ( IsValid(self) ) then
            self:InsertShell()
        end
    end)
end

function SWEP:FinishShotgunReload()
    -- Prefer explicit finish animation/sound; fall back to legacy pump fields
    local finishAnim = self.ShotgunFinishAnim or self.ShotgunPumpAnim
    local finishSound = self.ShotgunFinishSound or self.ShotgunPumpSound
    if ( finishAnim ) then
        self:PlayAnimation(finishAnim, 1)
    end

    if ( finishSound ) then
        self:EmitSound(finishSound, nil, nil, nil, CHAN_STATIC)
    end

    local duration = self:GetActiveAnimationDuration()
    timer.Simple(duration, function()
        if ( IsValid(self) ) then
            self:SetReloading(false)
        end
    end)
end

--- Determines the current movement state based on player velocity and input.
-- @realm shared
-- @treturn string "idle", "walk", or "sprint"
function SWEP:GetMovementState()
    local owner = self:GetOwner()
    if ( !IsValid(owner) or !owner:IsPlayer() ) then return "idle" end

    local vel = owner:GetVelocity()
    local speed = vel:Length2D()

    if ( speed < 5 ) then
        return "idle"
    end

    -- Check if sprinting (either via sprint key or high speed)
    local isSprinting = owner:IsSprinting() or ( owner:KeyDown(IN_SPEED) and speed > owner:GetWalkSpeed() )
    if ( isSprinting and speed > owner:GetWalkSpeed() * 0.9 ) then
        return "sprint"
    end

    return "walk"
end

--- Updates movement animation based on current player state.
-- Called from Think, handles transitions between idle/walk/sprint.
-- @realm shared
function SWEP:UpdateMovementAnimation()
    if ( self:GetReloading() ) then return end

    local state = self:GetMovementState()

    -- State changed, play appropriate animation
    if ( state != self.MovementState ) then
        self.LastMovementState = self.MovementState
        self.MovementState = state
        self.MovementStateChangeTime = CurTime()

        local anim = nil
        local rate = 1

        if ( state == "sprint" and self.SprintAnim ) then
            anim = self.SprintAnim
            rate = self.SprintAnimPlaybackRate or 1
        elseif ( state == "walk" and self.WalkAnim ) then
            anim = self.WalkAnim
            rate = self.WalkAnimPlaybackRate or 1
        elseif ( state == "idle" and self.IdleAnim ) then
            anim = self.IdleAnim
            rate = self.IdleAnimPlaybackRate or 1
        end

        if ( anim ) then
            self:PlayAnimation(anim, rate)
        end
    end
end
