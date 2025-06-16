----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 --- Made by a transgender queen
 -- Slay queen Riggs
 -- Stay Powerfull against the Patiarchy by a man (Alex Grist) stealing code
 -- #OverwatchFramework #CodeStealingMatters

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

function MODULE:HandlePlayerJumping(client, velocity, clientTable)
    if ( !istable(clientTable) ) then
        clientTable = client:GetTable()
    end

    if ( client:GetMoveType() == MOVETYPE_NOCLIP ) then
        clientTable.m_bJumping = false
        return
    end

    if ( !clientTable.m_bJumping and !client:OnGround() and client:WaterLevel() <= 0) then
        if ( !clientTable.m_fGroundTime ) then
            clientTable.m_fGroundTime = CurTime()
        elseif ( ( CurTime() - clientTable.m_fGroundTime ) > 0 and velocity:Length2DSqr() < 0.25 ) then
            clientTable.m_bJumping = true
            clientTable.m_bFirstJumpFrame = false
            clientTable.m_flJumpStartTime = 0
        end
    end

    if ( clientTable.m_bJumping ) then
        if ( clientTable.m_bFirstJumpFrame ) then
            clientTable.m_bFirstJumpFrame = false
            client:AnimRestartMainSequence()
        end

        if ( ( client:WaterLevel() >= 2 ) or ( ( CurTime() - clientTable.m_flJumpStartTime ) > 0.2 and client:OnGround() ) ) then
            clientTable.m_bJumping = false
            clientTable.m_fGroundTime = nil
            client:AnimRestartMainSequence()
        end

        if ( clientTable.m_bJumping ) then
            clientTable.CalcIdeal = ACT_MP_JUMP
            return true
        end
    end

    return false
end

function MODULE:HandlePlayerDucking(client, velocity, clientTable)
    if ( !clientTable ) then
        clientTable = client:GetTable()
    end

    if ( !client:IsFlagSet(FL_ANIMDUCKING) ) then return false end

    if ( velocity:Length2DSqr() > 0.25 ) then
        clientTable.CalcIdeal = ACT_MP_CROUCHWALK
    else
        clientTable.CalcIdeal = ACT_MP_CROUCH_IDLE
    end

    return true
end

function MODULE:HandlePlayerNoClipping(client, velocity, clientTable)
    if ( !istable(clientTable) ) then
        clientTable = client:GetTable()
    end

    if ( client:GetMoveType() != MOVETYPE_NOCLIP or client:InVehicle() ) then
        if ( clientTable.m_bWasNoclipping ) then
            clientTable.m_bWasNoclipping = nil
            client:AnimResetGestureSlot(GESTURE_SLOT_CUSTOM)
        end

        return
    end

    if ( !clientTable.m_bWasNoclipping ) then
        client:AnimRestartGesture(GESTURE_SLOT_CUSTOM, ACT_GMOD_NOCLIP_LAYER, false)
    end

    return true
end

function MODULE:HandlePlayerVaulting(client, velocity, clientTable)
    if ( !istable(clientTable) ) then
        clientTable = client:GetTable()
    end

    if ( velocity:LengthSqr() < 1000000 ) then return end
    if ( client:IsOnGround() ) then return end

    clientTable.CalcIdeal = ACT_MP_SWIM

    return true
end

function MODULE:HandlePlayerSwimming(client, velocity, clientTable)
    if ( !istable(clientTable) ) then
        clientTable = client:GetTable()
    end

    if ( client:WaterLevel() < 2 or client:IsOnGround() ) then
        clientTable.m_bInSwim = false
        return false
    end

    clientTable.CalcIdeal = ACT_MP_SWIM
    clientTable.m_bInSwim = true

    return true
end

function MODULE:HandlePlayerLanding(client, velocity, WasOnGround)
    if ( client:GetMoveType() == MOVETYPE_NOCLIP ) then return end
    if ( client:IsOnGround() and !WasOnGround ) then
        client:AnimRestartGesture(GESTURE_SLOT_JUMP, ACT_LAND, true)
    end
end

function MODULE:HandlePlayerDriving(client, clientTable)
    if ( !istable(clientTable) ) then
        clientTable = client:GetTable()
    end

    if ( !client:InVehicle() or !IsValid(client:GetParent()) ) then
        return false
    end

    local pVehicle = client:GetVehicle()
    if ( !pVehicle.HandleAnimation and pVehicle.GetVehicleClass ) then
        local c = pVehicle:GetVehicleClass()
        local t = list.Get("Vehicles")[c]
        if ( t and t.Members and t.Members.HandleAnimation ) then
            pVehicle.HandleAnimation = t.Members.HandleAnimation
        else
            pVehicle.HandleAnimation = true
        end
    end

    if ( isfunction(pVehicle.HandleAnimation) ) then
        local seq = pVehicle:HandleAnimation(client)
        if ( seq != nil ) then
            clientTable.CalcSeqOverride = seq
        end
    end

    if ( clientTable.CalcSeqOverride == -1 ) then
        local class = pVehicle:GetClass()
        if ( class == "prop_vehicle_jeep" ) then
            clientTable.CalcSeqOverride = client:LookupSequence("drive_jeep")
        elseif ( class == "prop_vehicle_airboat" ) then
            clientTable.CalcSeqOverride = client:LookupSequence("drive_airboat")
        elseif ( class == "prop_vehicle_prisoner_pod" and pVehicle:GetModel() == "models/vehicles/prisoner_pod_inner.mdl" ) then
            clientTable.CalcSeqOverride = client:LookupSequence("drive_pd")
        else
            clientTable.CalcSeqOverride = client:LookupSequence("sit_rollercoaster")
        end
    end

    local use_anims = ( clientTable.CalcSeqOverride == client:LookupSequence("sit_rollercoaster") or clientTable.CalcSeqOverride == client:LookupSequence("sit") )
    if ( use_anims and client:GetAllowWeaponsInVehicle() and IsValid(client:GetActiveWeapon()) ) then
        local holdtype = client:GetActiveWeapon():GetHoldType()
        if ( holdtype == "smg" ) then
            holdtype = "smg1"
        end

        local seqid = client:LookupSequence("sit_" .. holdtype)
        if ( seqid != -1 ) then
            clientTable.CalcSeqOverride = seqid
        end
    end

    return true
end

function MODULE:UpdateAnimation(client, velocity, maxseqgroundspeed)
    local len = velocity:Length()
    local movement = 1.0
    if ( len > 0.2 ) then
        movement = (len / maxseqgroundspeed)
    end

    local rate = math.min(movement, 2)
    if ( client:WaterLevel() >= 2 ) then
        rate = math.max(rate, 0.5)
    elseif ( !client:IsOnGround() and len >= 1000 ) then
        rate = 0.1
    end

    client:SetPlaybackRate(rate)

    if ( CLIENT ) then
        if ( client:InVehicle() ) then
            local Vehicle = client:GetVehicle()
            local Velocity = Vehicle:GetVelocity()
            local fwd = Vehicle:GetUp()
            local dp = fwd:Dot(Vector(0, 0, 1))
            client:SetPoseParameter("vertical_velocity", (dp < 0 and dp or 0) + fwd:Dot(Velocity) * 0.005)

            local steer = Vehicle:GetPoseParameter("vehicle_steer")
            steer = steer * 2 - 1
            if ( Vehicle:GetClass() == "prop_vehicle_prisoner_pod" ) then
                steer = 0 client:SetPoseParameter("aim_yaw", math.NormalizeAngle(client:GetAimVector():Angle().y - Vehicle:GetAngles().y - 90))
            end

            client:SetPoseParameter("vehicle_steer", steer)
        end

        self:GrabEarAnimation(client)
        self:MouthMoveAnimation(client)
    end
end

function MODULE:GrabEarAnimation(client, clientTable)
    if ( !istable(clientTable) ) then
        clientTable = client:GetTable()
    end

    clientTable.ChatGestureWeight = clientTable.ChatGestureWeight or 0

    if ( client:IsPlayingTaunt() ) then
        return
    end

    if ( client:IsTyping() ) then
        clientTable.ChatGestureWeight = math.Approach(clientTable.ChatGestureWeight, 1, FrameTime() * 5)
    else
        clientTable.ChatGestureWeight = math.Approach(clientTable.ChatGestureWeight, 0, FrameTime() * 5)
    end

    if ( clientTable.ChatGestureWeight > 0 ) then
        client:AnimRestartGesture(GESTURE_SLOT_VCD, ACT_GMOD_IN_CHAT, true)
        client:AnimSetGestureWeight(GESTURE_SLOT_VCD, clientTable.ChatGestureWeight)
    end
end

function MODULE:MouthMoveAnimation(client)
    local flexes = {
        client:GetFlexIDByName("jaw_drop"),
        client:GetFlexIDByName("left_part"),
        client:GetFlexIDByName("right_part"),
        client:GetFlexIDByName("left_mouth_drop"),
        client:GetFlexIDByName("right_mouth_drop")
    }

    local weight = client:IsSpeaking() and math.Clamp(client:VoiceVolume() * 2, 0, 2) or 0
    for k, v in ipairs(flexes) do
        client:SetFlexWeight(v, weight)
    end
end

local vectorAngle = FindMetaTable("Vector").Angle
local normalizeAngle = math.NormalizeAngle
function MODULE:CalcMainActivity(client, velocity)
    local clientTable = client:GetTable()
    local forcedSequence = clientTable["ax.sequence.forced"]

    if ( forcedSequence ) then
        if ( client:GetSequence() != forcedSequence ) then
            client:SetCycle(0)
        end

        return -1, forcedSequence
    end

    clientTable.CalcIdeal = ACT_MP_STAND_IDLE

    local eyeAngles = client:EyeAngles()
    local aimVector = client:GetAimVector()
    local aimVectorAng = aimVector:Angle()
    local renderAng = client:GetRenderAngles()

    client:SetPoseParameter("move_yaw", normalizeAngle(vectorAngle(velocity).y - eyeAngles.y))

    local aimYaw = normalizeAngle(renderAng.y - eyeAngles.y)
    local aimPitch = normalizeAngle(renderAng.p - eyeAngles.p)

    client:SetPoseParameter("aim_yaw", aimYaw)
    client:SetPoseParameter("aim_pitch", aimPitch)

    local headYaw = normalizeAngle(renderAng.y - aimVectorAng.y)
    local headPitch = normalizeAngle(renderAng.p - aimVectorAng.p)

    client:SetPoseParameter("head_yaw", headYaw)
    client:SetPoseParameter("head_pitch", headPitch)

    self:HandlePlayerLanding(client, velocity, clientTable.m_bWasOnGround)

    if !( self:HandlePlayerNoClipping(client, velocity, clientTable) or
        self:HandlePlayerDriving(client, clientTable) or
        self:HandlePlayerVaulting(client, velocity, clientTable) or
        self:HandlePlayerJumping(client, velocity, clientTable) or
        self:HandlePlayerSwimming(client, velocity, clientTable) or
        self:HandlePlayerDucking(client, velocity, clientTable) ) then

        local len2d = velocity:Length2DSqr()
        if ( velocity[3] != 0 and len2d <= 16 ^ 2 ) then
            clientTable.CalcIdeal = ACT_GLIDE
        elseif ( len2d > 22500 ) then
            clientTable.CalcIdeal = ACT_MP_RUN
        elseif ( len2d > 0.25 ) then
            clientTable.CalcIdeal = ACT_MP_WALK
        else
            clientTable.CalcIdeal = ACT_MP_STAND_IDLE
        end
    end

    hook.Run("TranslateActivity", client, clientTable.CalcIdeal)

    local seqOverride = clientTable.CalcSeqOverride
    clientTable.CalcSeqOverride = -1

    clientTable.m_bWasOnGround = client:IsOnGround()
    clientTable.m_bWasNoclipping = (client:GetMoveType() == MOVETYPE_NOCLIP and !client:InVehicle())

    return clientTable.CalcIdeal, seqOverride or clientTable.CalcSeqOverride
end

local IdleActivity = ACT_HL2MP_IDLE
local IdleActivityTranslate = {}
IdleActivityTranslate[ACT_MP_STAND_IDLE] = IdleActivity
IdleActivityTranslate[ACT_MP_WALK] = IdleActivity + 1
IdleActivityTranslate[ACT_MP_RUN] = IdleActivity + 2
IdleActivityTranslate[ACT_MP_CROUCH_IDLE] = IdleActivity + 3
IdleActivityTranslate[ACT_MP_CROUCHWALK] = IdleActivity + 4
IdleActivityTranslate[ACT_MP_ATTACK_STAND_PRIMARYFIRE] = IdleActivity + 5
IdleActivityTranslate[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE] = IdleActivity + 5
IdleActivityTranslate[ACT_MP_RELOAD_STAND] = IdleActivity + 6
IdleActivityTranslate[ACT_MP_RELOAD_CROUCH] = IdleActivity + 6
IdleActivityTranslate[ACT_MP_JUMP] = ACT_HL2MP_JUMP_SLAM
IdleActivityTranslate[ACT_MP_SWIM] = IdleActivity + 9
IdleActivityTranslate[ACT_LAND] = ACT_LAND

local PlayerPassiveTranslator = {
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE,
        [ACT_MP_WALK] = ACT_HL2MP_WALK,
        [ACT_MP_RUN] = ACT_HL2MP_RUN,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH,
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE,
        [ACT_MP_WALK] = ACT_HL2MP_WALK,
        [ACT_MP_RUN] = ACT_HL2MP_RUN,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH,
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_PASSIVE,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_PASSIVE,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_PASSIVE,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_PASSIVE,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_PASSIVE,
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_PASSIVE,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_PASSIVE,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_PASSIVE,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_PASSIVE,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_PASSIVE,
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = ACT_HL2MP_IDLE_PASSIVE,
        [ACT_MP_WALK] = ACT_HL2MP_WALK_PASSIVE,
        [ACT_MP_RUN] = ACT_HL2MP_RUN_PASSIVE,
        [ACT_MP_CROUCH_IDLE] = ACT_HL2MP_IDLE_CROUCH_PASSIVE,
        [ACT_MP_CROUCHWALK] = ACT_HL2MP_WALK_CROUCH_PASSIVE,
    }
}

function MODULE:TranslateActivity(client, act)
    local clientTable = client:GetTable()
    local oldAct = clientTable.axLastAct or -1

    local newAct = client:TranslateWeaponActivity(act)
    if ( act == newAct ) then
        return IdleActivityTranslate[act]
    end

    local class = ax.animations:GetModelClass(client:GetModel())
    if ( !class or class == "player" ) then
        if ( client:InVehicle() ) then
            return
        end

        local holdType = clientTable.axHoldType
        if ( holdType and !client:IsWeaponRaised() ) then
            local animTable = PlayerPassiveTranslator[holdType]
            if ( animTable and animTable[act] ) then
                newAct = animTable[act]
            end
        end

        return newAct
    end

    local animTable = clientTable.axAnimations
    if ( animTable ) then
        if ( !animTable[ACT_MP_JUMP] ) then
            animTable[ACT_MP_JUMP] = ACT_JUMP
        end

        animTable = animTable[act]

        if ( animTable ) then
            if ( istable(animTable) ) then
                local preferred = animTable[client:IsWeaponRaised() and 2 or 1]
                newAct = preferred
            else
                newAct = animTable
            end
        elseif ( client.m_bJumping ) then
            newAct = ACT_GLIDE
        end
    end

    if ( isstring(newAct) ) then
        local seq = client:LookupSequence(newAct)
        if ( seq != -1 ) then
            clientTable.CalcSeqOverride = client:LookupSequence(newAct)
        end
    elseif ( istable(newAct) ) then
        if ( !clientTable.CalcSeqOverrideTable ) then
            clientTable.CalcSeqOverrideTable = client:LookupSequence(newAct[math.random(#newAct)])
        end

        if ( oldAct != newAct ) then
            clientTable.CalcSeqOverrideTable = client:LookupSequence(newAct[math.random(#newAct)])
        end

        clientTable.CalcSeqOverride = clientTable.CalcSeqOverrideTable
    end

    if ( oldAct != newAct ) then
        clientTable.axLastAct = newAct
    end

    return newAct
end

function MODULE:DoAnimationEvent(client, event, data)
    local clientTable = client:GetTable()
    if ( event == PLAYERANIMEVENT_ATTACK_PRIMARY ) then
        local animTable = clientTable.axAnimations
        local desired = animTable.shoot or ACT_MP_ATTACK_STAND_PRIMARYFIRE
        if ( client:IsFlagSet(FL_ANIMDUCKING) ) then
            desired = animTable.shoot_crouch or animTable.shoot or ACT_MP_ATTACK_CROUCH_PRIMARYFIRE
        end

        if ( isstring(desired) ) then
            desired = client:LookupSequence(desired)
        elseif ( istable(desired) ) then
            desired = client:LookupSequence(desired[math.random(#desired)])
        end

        client:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, desired, true)

        return ACT_VM_PRIMARYATTACK
    elseif ( event == PLAYERANIMEVENT_ATTACK_SECONDARY ) then
        return ACT_VM_SECONDARYATTACK
    elseif ( event == PLAYERANIMEVENT_RELOAD ) then
        local animTable = clientTable.axAnimations
        local desired = animTable.reload or ACT_MP_RELOAD_STAND
        if ( client:IsFlagSet(FL_ANIMDUCKING) ) then
            desired = animTable.reload_crouch or animTable.reload or ACT_MP_RELOAD_CROUCH
        end

        if ( isstring(desired) ) then
            desired = client:LookupSequence(desired)
        elseif ( istable(desired) ) then
            desired = client:LookupSequence(desired[math.random(#desired)])
        end

        client:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, desired, true)

        return ACT_INVALID
    elseif ( event == PLAYERANIMEVENT_JUMP ) then
        clientTable.m_bJumping = true
        clientTable.m_bFirstJumpFrame = true
        clientTable.m_flJumpStartTime = CurTime()

        client:AnimRestartMainSequence()

        return ACT_INVALID
    elseif ( event == PLAYERANIMEVENT_CANCEL_RELOAD ) then
        client:AnimResetGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD)

        return ACT_INVALID
    end
end