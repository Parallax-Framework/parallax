--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

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

    util.PrecacheSound("npc/vort/claw_swing1.wav")
    util.PrecacheSound("npc/vort/claw_swing2.wav")
    util.PrecacheSound("physics/plastic/plastic_box_impact_hard1.wav")
    util.PrecacheSound("physics/plastic/plastic_box_impact_hard2.wav")
    util.PrecacheSound("physics/plastic/plastic_box_impact_hard3.wav")
    util.PrecacheSound("physics/plastic/plastic_box_impact_hard4.wav")
    util.PrecacheSound("physics/wood/wood_crate_impact_hard2.wav")
    util.PrecacheSound("physics/wood/wood_crate_impact_hard3.wav")
end

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()
    if ( !IsValid(self:GetOwner()) ) then return end

    self:Reset()

    return true
end

function SWEP:Holster()
    if ( !IsValid(self:GetOwner()) ) then return end

    self:Reset()

    return true
end

function SWEP:OnRemove()
    self:Reset()
end

function SWEP:Reload()
    return false
end

local function SetSubPhysMotionEnabled(entity, enable)
    if ( !IsValid(entity) ) then return end

    for i = 0, entity:GetPhysicsObjectCount() - 1 do
        local subphys = entity:GetPhysicsObjectNum(i)

        if ( IsValid(subphys) ) then
            subphys:EnableMotion(enable)

            if ( enable ) then
                subphys:Wake()
            end
        end
    end
end

local function VelocityRemove(entity, normalize)
    if ( normalize ) then
        local physicsObject = entity:GetPhysicsObject()
        if ( IsValid(physicsObject) ) then
            physicsObject:SetVelocity(vector_origin)
        end

        entity:SetVelocity(vector_origin)

        SetSubPhysMotionEnabled(entity, false)
        timer.Simple(0, function() SetSubPhysMotionEnabled(entity, true) end)
    else
        local physicsObject = entity:GetPhysicsObject()
        local vel = IsValid(physicsObject) and physicsObject:GetVelocity() or entity:GetVelocity()
        local len = math.min(ax.config:Get("hands.max.throw", 150), vel:Length2D())

        vel:Normalize()
        vel = vel * len

        SetSubPhysMotionEnabled(entity, false)
        timer.Simple(0, function()
            SetSubPhysMotionEnabled(entity, true)

            if ( IsValid(physicsObject) ) then
                physicsObject:SetVelocity(vel)
            end

            entity:SetVelocity(vel)
            entity:SetLocalAngularVelocity(angle_zero)
        end)
    end
end

local function VelocityThrow(entity, owner, power)
    local physicsObject = entity:GetPhysicsObject()
    local vel = owner:GetAimVector()
    vel = vel * power

    SetSubPhysMotionEnabled(entity, false)
    timer.Simple(0, function()
        if ( IsValid(entity) ) then
            SetSubPhysMotionEnabled(entity, true)

            if ( IsValid(physicsObject) ) then
                physicsObject:SetVelocity(vel)
            end

            entity:SetVelocity(vel)
            entity:SetLocalAngularVelocity(angle_zero)
        end
    end)
end

function SWEP:Reset(throw)
    if ( IsValid(self.axCarry) ) then
        self.axCarry:Remove()
    end

    if ( IsValid(self.axConstraint) ) then
        self.axConstraint:Remove()
    end

    if ( IsValid(self.axHoldingEntity) ) then
        local desiredCollisionGroup = self.axHoldingEntity.oldCollisionGroup or COLLISION_GROUP_NONE
        self.axHoldingEntity:SetCollisionGroup(desiredCollisionGroup)
        self.axHoldingEntity.oldCollisionGroup = nil

        local children = self.axHoldingEntity:GetChildren()
        for i = 1, #children do
            children[i]:SetCollisionGroup(desiredCollisionGroup)
        end

        local physicsObject = self.axHoldingEntity:GetPhysicsObject()
        if ( self.holdingBone ) then
            physicsObject = self.axHoldingEntity:GetPhysicsObjectNum(self.holdingBone)
            self.holdingBone = nil
        end

        if ( IsValid(physicsObject) ) then
            physicsObject:ClearGameFlag(FVPHYSICS_PLAYER_HELD)
            physicsObject:AddGameFlag(FVPHYSICS_WAS_THROWN)
            physicsObject:EnableCollisions(true)
            physicsObject:EnableGravity(true)
            physicsObject:EnableDrag(true)
            physicsObject:EnableMotion(true)
        end

        if ( !throw ) then
            VelocityRemove(self.axHoldingEntity)
        else
            VelocityThrow(self.axHoldingEntity, self:GetOwner(), 300)
        end
    end

    self.axHoldingEntity = nil
    self.axCarry = nil
    self.axConstraint = nil
end

function SWEP:Drop(throw)
    if ( !self:CheckValidity() ) then return end
    if ( !self:AllowEntityDrop() ) then return end

    if ( SERVER ) then
        SafeRemoveEntity(self.axConstraint)
        SafeRemoveEntity(self.axCarry)

        local entity = self.axHoldingEntity

        local physicsObject = entity:GetPhysicsObject()
        if ( IsValid(physicsObject) ) then
            physicsObject:EnableCollisions(true)
            physicsObject:EnableGravity(true)
            physicsObject:EnableDrag(true)
            physicsObject:EnableMotion(true)
            physicsObject:Wake()

            physicsObject:ClearGameFlag(FVPHYSICS_PLAYER_HELD)
            physicsObject:AddGameFlag(FVPHYSICS_WAS_THROWN)
        end

        if ( entity:GetClass() == "prop_ragdoll" ) then
            VelocityRemove(entity)
        end

        entity:SetPhysicsAttacker(self:GetOwner())
    end

    self:Reset(throw)
end

function SWEP:CheckValidity()
    if ( !IsValid(self.axHoldingEntity) or !IsValid(self.axCarry) or !IsValid(self.axConstraint) ) then
        if ( self.axHoldingEntity or self.axCarry or self.axConstraint ) then
            self:Reset()
        end

        return false
    else
        return true
    end
end

function SWEP:IsEntityStoodOn(entity)
    for k, v in player.Iterator() do
        if ( v:GetGroundEntity() == entity ) then
            return true
        end
    end

    return false
end

local primaryViewPunch = Angle(2, 5, 0.125)

function SWEP:PrimaryAttack()
    if ( !IsFirstTimePredicted() ) then return end

    local owner = self:GetOwner()
    if ( !IsValid(owner) ) then return end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if ( IsValid(self.axHoldingEntity) ) then
        if ( SERVER ) then
            owner:EmitSound("npc/vort/claw_swing" .. math.random(1, 2) .. ".wav", 60)
        end

        owner:SetAnimation(PLAYER_ATTACK1)
        owner:ViewPunch(primaryViewPunch)

        self:DoPickup(true)
    elseif ( owner:IsWeaponRaised() ) then
        self:DoPunch()
    end
end

local knockViewPunchAngle = Angle(-1.3, 1.8, 0)
local pushViewPunchAngle = Angle()

function SWEP:SecondaryAttack()
    if ( !IsFirstTimePredicted() ) then return end

    local owner = self:GetOwner()
    if ( !IsValid(owner) ) then return end

    local data = {}
    data.start = owner:GetShootPos()
    data.endpos = data.start + owner:GetAimVector() * ax.config:Get("hands.range", 96)
    data.mask = MASK_SHOT
    data.filter = {self, owner}
    local traceData = util.TraceLine(data)

    local entity = traceData.Entity
    if ( SERVER and IsValid(entity) ) then
        if ( entity:GetClass():find("door") ) then
            if ( entity:GetPos():DistToSqr(owner:GetPos()) > 6000 ) then
                return
            end

            if ( hook.Run("PlayerCanKnock", owner, entity) == false ) then
                return
            end

            owner:ViewPunch(knockViewPunchAngle)
            owner:EmitSound("physics/wood/wood_crate_impact_hard" .. math.random(2, 3) .. ".wav", 60)
            owner:SetAnimation(PLAYER_ATTACK1)

            self:SetNextSecondaryFire(CurTime() + 0.4)
            self:SetNextPrimaryFire(CurTime() + 1)

            hook.Run("PlayerKnock", owner, entity)
        elseif ( !entity:IsPlayer() and !entity:IsNPC() ) then
            self:DoPickup()
        elseif entity:IsPlayer() and entity:Alive() then
            if ( self:RateLimit("push", 0.5) ) then return end
            if ( entity:GetPos():DistToSqr(owner:GetPos()) > 2000 ) then return end
            if ( hook.Run("PlayerCanPush", owner, entity) == false ) then
                return
            end

            timer.Simple (0.25, function()
                local vDirection = owner:GetAimVector() * ( 350 + ( 3 * 3 ) )
                vDirection.z = 0
                entity:SetVelocity(vDirection)

                pushViewPunchAngle.x = math.random(1, 2)
                pushViewPunchAngle.y = math.random(2, 6)
                pushViewPunchAngle.z = math.random(0, -3)

                entity:ViewPunch(pushViewPunchAngle)
                entity:EmitSound("physics/flesh/flesh_impact_hard" .. math.random(2, 5) .. ".wav", 60)
            end)

            self:RateLimit("push", 0.5)
            owner:ViewPunch(pushViewPunchAngle)
            owner:EmitSound("physics/flesh/flesh_impact_hard" .. math.random(2, 5) .. ".wav", 60)
            owner:SetAnimation(PLAYER_ATTACK1)

            hook.Run("PlayerPush", owner, entity)
        elseif ( IsValid(self.axHeldEntity) and !self.axHeldEntity:IsPlayerHolding() ) then
            self.axHeldEntity = nil
        end
    else
        if ( IsValid(self.axHoldingEntity))  then
            self:DoPickup()
        end
    end
end

function SWEP:GetRange(target)
    local customRange = hook.Run("GetPickupRange", self, target)
    if ( customRange ) then
        return customRange
    end

    if ( IsValid(target) and target:GetClass() == "prop_ragdoll" ) then
        return 96
    else
        return 128
    end
end

function SWEP:AllowPickup(target)
    local physicsObject = target:GetPhysicsObject()
    local owner = self:GetOwner()

    return ( IsValid(physicsObject)
    and IsValid(owner)
    and !physicsObject:HasGameFlag(FVPHYSICS_NO_PLAYER_PICKUP)
    and physicsObject:GetMass() < ax.config:Get("hands.max.Carry", 160)
    and !self:IsEntityStoodOn(target)
    and target.CanPickup != false )
    and hook.Run("CanPlayerPickup", owner, target) != false
end

function SWEP:DoPickup(throw)
    self:SetNextPrimaryFire(CurTime() + 0.2)
    self:SetNextSecondaryFire(CurTime() + 0.2)

    if ( IsValid(self.axHoldingEntity) ) then
        self:Drop(throw)
        self:SetNextSecondaryFire(CurTime() + 0.2)
        return
    end

    local owner = self:GetOwner()
    local traceData = owner:GetEyeTrace(MASK_SHOT)
    if ( IsValid(traceData.Entity) ) then
        local entity = traceData.Entity
        local physicsObject = traceData.Entity:GetPhysicsObject()

        if ( !IsValid(physicsObject) or !physicsObject:IsMoveable() or physicsObject:HasGameFlag(FVPHYSICS_PLAYER_HELD) ) then
            return
        end

        if ( SERVER and (owner:EyePos() - traceData.HitPos):Length() < self:GetRange(entity) and self:AllowPickup(entity) ) then
            self:Pickup()
            self:SendWeaponAnim(ACT_VM_HITCENTER)

            local delay = entity:GetClass() == "prop_ragdoll" and 1 or 0.2

            self:SetNextSecondaryFire(CurTime() + delay)

            return
        end
    end
end

local punchViewPunchAngle = Angle(-1.3, -1.8, 0)
local entityViewPunchAngle = Angle(8, 0, 0)

function SWEP:DoPunch()
    local owner = self:GetOwner()
    if ( !IsValid(owner) ) then return end

    if ( ax.stamina ) then
        local stamina = ax.stamina:Get(owner)
        if ( stamina < 5 ) then
            if ( CLIENT ) then
                owner:ChatText("You are too tired to punch.")
            end

            return
        end
    end

    owner:LagCompensation(true)

    local data = {}
    data.start = owner:GetShootPos()
    data.endpos = data.start + owner:GetAimVector() * 96
    data.filter = owner

    local trace = util.TraceLine(data)
    local canPunch = hook.Run("PrePlayerPunch", owner, trace)
    if ( canPunch == false ) then
        owner:LagCompensation(false)
        return
    end

    owner:SetAnimation(PLAYER_ATTACK1)
    self:EmitSound(Sound("WeaponFrag.Throw"))

    local random = math.random(1, 2)
    owner:ViewPunch(random == 1 and punchViewPunchAngle or knockViewPunchAngle)

    local vm = owner:GetViewModel()
    vm:SendViewModelMatchingSequence(vm:LookupSequence(random == 1 and "fists_left" or "fists_right"))

    if ( SERVER and trace.Hit ) then
        local entity = trace.Entity
        if ( IsValid(entity) ) then
            local dmgInfo = DamageInfo()
            dmgInfo:SetAttacker(owner)
            dmgInfo:SetInflictor(self)
            dmgInfo:SetDamage(5)
            dmgInfo:SetDamageType(DMG_CLUB)
            dmgInfo:SetDamagePosition(trace.HitPos)
            dmgInfo:SetDamageForce(owner:GetAimVector() * 1000)

            owner:EmitSound(Sound("Flesh.ImpactHard"))

            if ( entity:IsPlayer() ) then
                if ( owner.bFistDamage and !entity.bFistDamage or !owner.bFistDamage ) then
                    owner:LagCompensation(false)
                    return
                end

                if ( entity:GetRelay("state") == STATE_KNOCKOUT ) then
                    owner:LagCompensation(false)
                    return
                end

                if ( entity:Health() <= 50 ) then
                    if ( math.random(1, 10) == 1 ) then
                        entity:SetRelay("state", STATE_KNOCKOUT)
                    else
                        entity:DispatchTraceAttack(dmgInfo, trace, trace.HitNormal)
                    end
                else
                    entity:DispatchTraceAttack(dmgInfo, trace, trace.HitNormal)
                end
            else
                entity:DispatchTraceAttack(dmgInfo, trace, trace.HitNormal)

                if ( math.random(1, 2) == 1 ) then
                    entity:EmitSound("physics/plastic/plastic_box_impact_hard" .. math.random(1, 4) .. ".wav", 80)
                else
                    entity:EmitSound("physics/wood/wood_crate_impact_hard" .. math.random(2, 3) .. ".wav", 80)
                end

                local physicsObject = entity:GetPhysicsObject()
                if ( IsValid(physicsObject) and physicsObject:IsMoveable() and !physicsObject:HasGameFlag(FVPHYSICS_PLAYER_HELD) ) then
                    physicsObject:ApplyForceOffset(owner:GetAimVector() * math.random(64, 256) * physicsObject:GetMass(), trace.HitPos)

                    local mass = physicsObject:GetMass()
                    random = math.random(0, mass / 10)
                    if ( random > mass / 11 ) then
                        owner:TakeDamage(5, owner, self)
                        owner:ViewPunch(entityViewPunchAngle)
                    end
                end
            end

            if ( ax.stamina ) then
                ax.stamina:Consume(owner, 5)
            end
        elseif ( trace.HitWorld ) then
            owner:EmitSound(Sound("Flesh.ImpactHard"))
        end
    end

    hook.Run("PostPlayerPunch", owner, trace)

    owner:LagCompensation(false)
end

local down = Vector(0, 0, -1)
function SWEP:AllowEntityDrop()
    local owner = self:GetOwner()
    local ent = self.axCarry
    if ( !IsValid(owner) or !IsValid(ent) ) then return false end

    local ground = owner:GetGroundEntity()
    if ( ground and ( ground:IsWorld() or IsValid(ground) ) ) then return true end

    local diff = (ent:GetPos() - owner:GetShootPos()):GetNormalized()

    return down:Dot(diff) <= 0.75
end