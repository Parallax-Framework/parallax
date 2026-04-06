--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

SWEP.PrintName = "Hands"
SWEP.Author = "Parallax"
SWEP.Contact = ""
SWEP.Purpose = "Grab and throw things"
SWEP.Instructions = ""

SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModel = Model("models/weapons/c_arms.mdl")
SWEP.WorldModel = ""

SWEP.UseHands = true
SWEP.Spawnable = true

SWEP.ViewModelFOV = 45
SWEP.ViewModelFlip = false
SWEP.AnimPrefix = "rpg"

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""
SWEP.Primary.Damage = 5
SWEP.Primary.Delay = 0.5

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Secondary.Delay = 0.5

SWEP.HoldType = "normal"
SWEP.FireWhenLowered = true
SWEP.LoweredAngles = angle_zero

function SWEP:Precache()
    util.PrecacheModel(self.ViewModel)
    util.PrecacheModel(self.WorldModel)
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()
    local owner = self:GetOwner()
    if ( !ax.util:IsValidPlayer(owner) ) then return end

    -- TODO: Cancel action

    return true
end

function SWEP:Holster()
    local owner = self:GetOwner()
    if ( !ax.util:IsValidPlayer(owner) ) then return end

    -- TODO: Cancel action

    return true
end

function SWEP:OnRemove()
    -- TODO: Cancel action
end

function SWEP:Reload()
    return false
end

function SWEP:PrimaryAttack()
    if ( !IsFirstTimePredicted() ) then return end

    local owner = self:GetOwner()
    if ( !ax.util:IsValidPlayer(owner) ) then return end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
end

function SWEP:SecondaryAttack()
    if ( !IsFirstTimePredicted() ) then return end

    local owner = self:GetOwner()
    if ( !ax.util:IsValidPlayer(owner) ) then return end

    local data = {}
    data.start = owner:GetShootPos()
    data.endpos = data.start + owner:GetAimVector() * 96 -- TODO?: change 96 to config
    data.mask = MASK_SHOT
    data.filter = {self, owner}
    data.mins = Vector(-16, -16, -16)
    data.maxs = Vector(16, 16, 16)
    local traceData = util.TraceHull(data)

    local entity = traceData.Entity
    local selfTable = self:GetTable()
    if ( SERVER and IsValid(entity) and entity:IsDoor() ) then

    end
end
