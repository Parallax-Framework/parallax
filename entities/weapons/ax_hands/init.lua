--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ax.net:Hook("ax.hands.reset", function(client)
    if ( !IsValid(client) ) then return end
    if ( !client:RateLimit("hands", 0.5) ) then return end

    local weapon = client:GetActiveWeapon()
    if ( !IsValid(weapon) ) then return end

    if ( weapon:GetClass() == "ax_hands" ) then
        weapon:Reset()
    end
end)

function SWEP:SetWeaponRaised(bRaised)
    if ( bRaised ) then
        self:SetHoldType("fist")

        local vm = self:GetOwner():GetViewModel()
        vm:SendViewModelMatchingSequence(vm:LookupSequence("fists_draw"))
    else
        self:SetHoldType("normal")

        local vm = self:GetOwner():GetViewModel()
        local fistsHolster = vm:LookupSequence("fists_holster")
        vm:SendViewModelMatchingSequence(fistsHolster)

        timer.Simple(vm:SequenceDuration(fistsHolster), function()
            if ( IsValid(self) and IsValid(self:GetOwner()) and !self:GetOwner():IsWeaponRaised() ) then
                vm:SendViewModelMatchingSequence(vm:LookupSequence("idle"))
            end
        end)
    end
end

function SWEP:CalcLerpSpeed(eHoldingEntity)
    if ( eHoldingEntity:IsRagdoll() ) then
        return 4
    end

    return 8
end

local entDiff = Vector(0, 0, 0)
local entDiffTime = CurTime()
local standTime = 0
function SWEP:Think()
    if ( !self:CheckValidity() ) then
        return
    end

    local curTime = CurTime()
    if ( curTime > entDiffTime ) then
        entDiff = self:GetPos() - self.axHoldingEntity:GetPos()
        if ( entDiff:Dot(entDiff) > 40000 ) then
            self:Reset()
            return
        end

        entDiffTime = curTime + 1
    end

    if ( curTime > standTime ) then
        if ( self:IsEntityStoodOn(self.axHoldingEntity) ) then
            self:Reset()
            return
        end

        standTime = curTime + 0.1
    end

    local pos = self:GetOwner():EyePos() + self:GetOwner():GetAimVector() * self.axCarry.distance
    local lerpSpeed = self:CalcLerpSpeed(self.axHoldingEntity)

    local ft = FrameTime()
    self.axCarry.lerpPos = LerpVector(ft * lerpSpeed, self.axCarry.lerpPos or pos, pos)

    self.axCarry:SetPos(self.axCarry.lerpPos)

    local targetAng = self:GetOwner():GetAngles()
    if ( self.axCarry.preferedAngle ) then
        targetAng.p = 0
    end

    self.axCarry.lerpAng = LerpAngle(ft * lerpSpeed, self.axCarry.lerpAng or targetAng, targetAng)

    self.axCarry:SetAngles(self.axCarry.lerpAng)
    self.axHoldingEntity:PhysWake()
end

function SWEP:Pickup()
    if ( IsValid(self.axHoldingEntity) ) then return end

    local client = self:GetOwner()
    local traceData = client:GetEyeTrace(MASK_SHOT)
    local ent = traceData.Entity
    if ( !IsValid(ent) ) then return end

    local holdingPhysicsObject = ent:GetPhysicsObject()
    if ( !IsValid(holdingPhysicsObject) ) then return end

    if ( ent:GetRelay("disallowPickup", false) ) then return end
    if ( ent:GetMoveType() == MOVETYPE_NONE ) then return end

    self.axHoldingEntity = ent
    self.axCarry = ents.Create("prop_physics")

    if ( IsValid(self.axCarry) ) then
        local pos, obb = self.axHoldingEntity:GetPos(), self.axHoldingEntity:OBBCenter()
        pos = pos + self.axHoldingEntity:GetForward() * obb.x
        pos = pos + self.axHoldingEntity:GetRight() * obb.y
        pos = pos + self.axHoldingEntity:GetUp() * obb.z
        pos = traceData.HitPos

        self.axCarry:SetPos(pos)
        self.axCarry.distance = math.min(64, client:GetShootPos():Distance(pos))

        self.axCarry:SetModel("models/weapons/w_bugbait.mdl")

        self.axCarry:SetNoDraw(true)
        self.axCarry:DrawShadow(false)

        self.axCarry:SetHealth(999)
        self.axCarry:SetOwner(self.axHoldingEntity:GetOwner())
        self.axCarry:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        self.axCarry:SetSolid(SOLID_NONE)

        local preferredAngles = hook.Run("GetPreferredCarryAngles", self.axHoldingEntity)
        if ( self:GetOwner():KeyDown(IN_RELOAD) and !preferredAngles ) then
            preferredAngles = angle_zero
        end

        if ( preferredAngles ) then
            local entAngle = self.axHoldingEntity:GetAngles()
            self.axCarry.preferedAngle = self.axHoldingEntity:GetAngles()
            local grabAngle = self.axHoldingEntity:GetAngles()

            grabAngle:RotateAroundAxis(entAngle:Right(), preferredAngles[1])
            grabAngle:RotateAroundAxis(entAngle:Up(), preferredAngles[2])
            grabAngle:RotateAroundAxis(entAngle:Forward(), preferredAngles[3])

            self.axCarry:SetAngles(grabAngle)
        else
            local ang = self:GetOwner():GetAngles()
            self.axCarry.storedAng = LerpAngle(FrameTime() * 2, self.axCarry.storedAng or ang, ang)
            self.axCarry:SetAngles(self.axCarry.storedAng)
        end

        self.axCarry:Spawn()

        local physicsObject = self.axCarry:GetPhysicsObject()
        if ( IsValid(physicsObject) ) then
            physicsObject:SetMass(200)
            physicsObject:SetDamping(0, 1000)
            physicsObject:EnableGravity(false)
            physicsObject:EnableCollisions(false)
            physicsObject:EnableMotion(false)
            physicsObject:AddGameFlag(FVPHYSICS_PLAYER_HELD)
        end

        local bone = math.Clamp(traceData.PhysicsBone, 0, 1)
        if ( ent:GetClass() == "prop_ragdoll" ) then
            bone = traceData.PhysicsBone
            self.holdingBone = bone
            holdingPhysicsObject = self.axHoldingEntity:GetPhysicsObjectNum(bone)
        end

        holdingPhysicsObject:AddGameFlag(FVPHYSICS_PLAYER_HELD)

        local maxForce = ax.config:Get("handsMaxForce", 16500)
        local vSize = self.axHoldingEntity:OBBMaxs() - self.axHoldingEntity:OBBMins()
        if ( self.axHoldingEntity:IsRagdoll() or math.max(vSize.x, vSize.y, vSize.z) > 60 ) then
            self.axConstraint = constraint.Ballsocket(self.axCarry, self.axHoldingEntity, 0, bone, holdingPhysicsObject:WorldToLocal(pos), maxForce / 3, 0, 1)
        else
            self.axConstraint = constraint.Weld(self.axCarry, self.axHoldingEntity, 0, bone, maxForce, true)

            self.axHoldingEntity.HandsConstraint = self.axConstraint
        end

        self.axHoldingEntity.oldCollisionGroup = self.axHoldingEntity.oldCollisionGroup or self.axHoldingEntity:GetCollisionGroup()
        self.axHoldingEntity:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)

        local children = self.axHoldingEntity:GetChildren()
        for i = 1, #children do
            children[i]:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
        end

        self:GetOwner():EmitSound("physics/body/body_medium_impact_soft" .. math.random(1, 3) .. ".wav", 60)

        hook.Run("PlayerPickup", self:GetOwner(), self.axHoldingEntity)
    end
end
