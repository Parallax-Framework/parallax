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
    NumShots = 1
}

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
    return tobool(self:Clip1() <= 0)
end

function SWEP:CanPrimaryAttack()
    local owner = self:GetOwner()
    if ( !IsValid(owner) ) then return false end

    if ( self:IsEmpty() ) then
        self:EmitSound(self.Primary.SoundEmpty or "Weapon_Pistol.Empty")
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

    local delay = self.Primary.Delay
    if ( self.Primary.RPM ) then
        delay = 60 / self.Primary.RPM
    end

    self:SetNextPrimaryFire(CurTime() + delay)

    -- Client-side: visuals and effects
    if ( CLIENT and IsFirstTimePredicted() ) then
        self:EmitSound(self.Primary.Sound)
        owner:MuzzleFlash()
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

    self:PlayAnimation(self.Primary.Sequence, self.Primary.PlaybackRate)
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
        Damage = damage,
        AmmoType = self.Primary.Ammo
    }

    viewPunchAngle.x = self.Primary.Recoil / 4
    viewPunchAngle.y = math.Rand(-self.Primary.Recoil, self.Primary.Recoil) / 2
    viewPunchAngle.z = math.Rand(-self.Primary.Recoil, self.Primary.Recoil) / 4

    owner:FireBullets(bullet)
    owner:ViewPunch(viewPunchAngle)
    owner:LagCompensation(false)

    -- Kick up the client's view on the shooting client
    if ( CLIENT and IsFirstTimePredicted() ) then
        local eyeAng = owner:EyeAngles()
        eyeAng.p = eyeAng.p - viewPunchAngle.x / 3
        eyeAng.y = eyeAng.y - viewPunchAngle.y / 3
        owner:SetEyeAngles(eyeAng)
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

    self:EmitSound(path)

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

function SWEP:CanReload()
    return self:Clip1() < self:GetMaxClip1() and self:Ammo1() > 0
end