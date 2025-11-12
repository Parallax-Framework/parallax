-- Localize math functions for performance
local normalizeAngle = math.NormalizeAngle
local atan2 = math.atan2
local deg = math.deg
local asin = math.asin

function MODULE:HandlePlayerJumping(client, velocity, clientTable)
    if ( !istable(clientTable) ) then
        clientTable = client:GetTable()
    end

    if ( client:GetMoveType() == MOVETYPE_NOCLIP ) then
        clientTable.m_bJumping = false
        return
    end

    if ( !clientTable.m_bJumping and !client:OnGround() and client:WaterLevel() <= 0) then
        local curTime = CurTime()
        if ( !clientTable.m_fGroundTime ) then
            clientTable.m_fGroundTime = curTime
        elseif ( ( curTime - clientTable.m_fGroundTime ) > 0 and velocity:Length2DSqr() < 0.25 ) then
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

        local curTime = CurTime()
        if ( ( client:WaterLevel() >= 2 ) or ( ( curTime - clientTable.m_flJumpStartTime ) > 0.2 and client:OnGround() ) ) then
            clientTable.m_bJumping = false
            clientTable.m_fGroundTime = nil
            client:AnimRestartMainSequence()
            return false
        end

        clientTable.CalcIdeal = ACT_MP_JUMP
        return true
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

function MODULE:OnPlayerHitGround(client, inWater, onFloater, speed)
    if ( inWater or onFloater or SERVER ) then return end

    if ( CLIENT and !IsFirstTimePredicted() ) then return end

    local land = ACT_LAND
    local clientTable = client:GetTable()
    local animTable = clientTable.axAnimations
    if ( animTable and animTable.land ) then
        land = animTable.land
    end

    if ( isstring(land) ) then
        land = client:LookupSequence(land)
    elseif ( istable(land) ) then
        land = client:LookupSequence(land[math.random(#land)])
    end

    client:PlayGesture(GESTURE_SLOT_JUMP, land)
end

-- Cache sequence IDs for vehicle animations
local SEQ_SIT_ROLLERCOASTER = nil
local SEQ_SIT = nil

function MODULE:HandlePlayerDriving(client, clientTable)
    if ( !istable(clientTable) ) then
        clientTable = client:GetTable()
    end

    if ( !client:InVehicle() or !IsValid(client:GetParent()) ) then
        return false
    end

    local vehicle = client:GetVehicle()
    if ( !vehicle.HandleAnimation and vehicle.GetVehicleClass ) then
        local c = vehicle:GetVehicleClass()
        local t = list.Get("Vehicles")[c]
        if ( t and t.Members and t.Members.HandleAnimation ) then
            vehicle.HandleAnimation = t.Members.HandleAnimation
        else
            vehicle.HandleAnimation = true
        end
    end

    if ( isfunction(vehicle.HandleAnimation) ) then
        local seq = vehicle:HandleAnimation(client)
        if ( seq != nil ) then
            clientTable.CalcSeqOverride = seq
        end
    end

    if ( clientTable.CalcSeqOverride == -1 ) then
        local class = vehicle:GetClass()
        if ( class == "prop_vehicle_jeep" ) then
            clientTable.CalcSeqOverride = client:LookupSequence("drive_jeep")
        elseif ( class == "prop_vehicle_airboat" ) then
            clientTable.CalcSeqOverride = client:LookupSequence("drive_airboat")
        elseif ( class == "prop_vehicle_prisoner_pod" and vehicle:GetModel() == "models/vehicles/prisoner_pod_inner.mdl" ) then
            clientTable.CalcSeqOverride = client:LookupSequence("drive_pd")
        else
            clientTable.CalcSeqOverride = client:LookupSequence("sit_rollercoaster")
        end
    end

    -- Cache sequence lookups
    if ( !SEQ_SIT_ROLLERCOASTER ) then
        SEQ_SIT_ROLLERCOASTER = client:LookupSequence("sit_rollercoaster")
        SEQ_SIT = client:LookupSequence("sit")
    end

    local useAnims = ( clientTable.CalcSeqOverride == SEQ_SIT_ROLLERCOASTER or clientTable.CalcSeqOverride == SEQ_SIT )
    if ( useAnims and client:GetAllowWeaponsInVehicle() and IsValid(client:GetActiveWeapon()) ) then
        local holdType = client:GetActiveWeapon():GetHoldType()
        if ( holdType == "smg" ) then
            holdType = "smg1"
        end

        local seqid = client:LookupSequence("sit_" .. holdType)
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
            local vehicle = client:GetVehicle()
            local Velocity = vehicle:GetVelocity()
            local fwd = vehicle:GetUp()
            local dp = fwd:Dot(vector_up)
            client:SetPoseParameter("vertical_velocity", (dp < 0 and dp or 0) + fwd:Dot(Velocity) * 0.005)

            local steer = vehicle:GetPoseParameter("vehicle_steer")
            steer = steer * 2 - 1
            if ( vehicle:GetClass() == "prop_vehicle_prisoner_pod" ) then
                steer = 0
                -- Calculate aim yaw directly without creating Angle object
                local aimVec = client:GetAimVector()
                local aimYaw = deg(atan2(aimVec.y, aimVec.x))
                client:SetPoseParameter("aim_yaw", normalizeAngle(aimYaw - vehicle:GetAngles().y - 90))
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

    local frameTimeMult = FrameTime() * 5
    if ( client:IsTyping() ) then
        clientTable.ChatGestureWeight = math.Approach(clientTable.ChatGestureWeight, 1, frameTimeMult)
    else
        clientTable.ChatGestureWeight = math.Approach(clientTable.ChatGestureWeight, 0, frameTimeMult)
    end

    if ( clientTable.ChatGestureWeight > 0 ) then
        client:AnimRestartGesture(GESTURE_SLOT_VCD, ACT_GMOD_IN_CHAT, true)
        client:AnimSetGestureWeight(GESTURE_SLOT_VCD, clientTable.ChatGestureWeight)
    end
end

function MODULE:MouthMoveAnimation(client)
    local clientTable = client:GetTable()

    -- Cache flex IDs per client to avoid repeated lookups
    if ( !clientTable.axFlexCache ) then
        clientTable.axFlexCache = {
            client:GetFlexIDByName("jaw_drop"),
            client:GetFlexIDByName("left_part"),
            client:GetFlexIDByName("right_part"),
            client:GetFlexIDByName("left_mouth_drop"),
            client:GetFlexIDByName("right_mouth_drop")
        }
    end

    local weight = client:IsSpeaking() and math.Clamp(client:VoiceVolume() * 2, 0, 2) or 0
    local flexes = clientTable.axFlexCache
    for i = 1, #flexes do
        client:SetFlexWeight(flexes[i], weight)
    end
end

function MODULE:CalcMainActivity(client, velocity)
    local forcedSequence = client:GetRelay("sequence.forced")
    if ( forcedSequence ) then
        if ( client:GetSequence() != forcedSequence ) then
            client:SetCycle(0)
        end

        return -1, forcedSequence
    end

    local clientTable = client:GetTable()
    clientTable.CalcIdeal = ACT_MP_STAND_IDLE

    local eyeAngles = client:EyeAngles()
    local renderAng = client:GetRenderAngles()

    -- Cache velocity yaw calculation (avoid creating Angle object)
    local velocityYaw = deg(atan2(velocity.y, velocity.x))
    client:SetPoseParameter("move_yaw", normalizeAngle(velocityYaw - eyeAngles.y))

    -- Cache normalized angle differences
    local aimYaw = normalizeAngle(renderAng.y - eyeAngles.y)
    local aimPitch = normalizeAngle(renderAng.p - eyeAngles.p)

    client:SetPoseParameter("aim_yaw", aimYaw)
    client:SetPoseParameter("aim_pitch", aimPitch)

    -- Calculate aim vector angles directly (avoid creating Angle object)
    local aimVector = client:GetAimVector()
    local aimVectorYaw = deg(atan2(aimVector.y, aimVector.x))
    local aimVectorPitch = deg(asin(-aimVector.z))

    client:SetPoseParameter("head_yaw", normalizeAngle(renderAng.y - aimVectorYaw))
    client:SetPoseParameter("head_pitch", normalizeAngle(renderAng.p - aimVectorPitch))

    if !( self:HandlePlayerNoClipping(client, velocity, clientTable) or
        self:HandlePlayerDriving(client, clientTable) or
        self:HandlePlayerVaulting(client, velocity, clientTable) or
        self:HandlePlayerJumping(client, velocity, clientTable) or
        self:HandlePlayerSwimming(client, velocity, clientTable) or
        self:HandlePlayerDucking(client, velocity, clientTable) ) then

        local len2d = velocity:Length2DSqr()
        if ( velocity[3] != 0 and len2d <= 256 ) then
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

function MODULE:TranslateActivity(client, act)
    local clientTable = client:GetTable()
    local oldAct = clientTable.axLastAct or -1

    local newAct = client:TranslateWeaponActivity(act)

    -- When the weapon didn't translate the act we map it to HL2MP idle variants.
    if ( act == newAct ) then
        local mapped = IdleActivityTranslate[act]
        if ( mapped ) then
            newAct = mapped
        end
    end

    -- Cache weapon and holdType for reuse
    local activeWeapon = client:GetActiveWeapon()
    local holdType = ( IsValid(activeWeapon) and activeWeapon:GetHoldType() ) or client:GetHoldType()

    local class = ax.animations:GetModelClass(client:GetModel())
    if ( !class ) then
        -- Still allow external overrides even if we cannot resolve a model class.
        local override = hook.Run("OverrideActivity", client, act, newAct, {
            modelClass = class,
            holdType = holdType,
            animTable = clientTable.axAnimations
        })

        if ( override != nil ) then
            newAct = override
        end

        return newAct
    end

    if ( class:find("player") and client:InVehicle() ) then
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

    -- External override hook (post internal anim table resolution, pre sequence resolution)
    local override = hook.Run("OverrideActivity", client, act, newAct, {
        modelClass = class,
        holdType = holdType,
        animTable = clientTable.axAnimations
    })

    if ( override != nil ) then
        newAct = override
    end

    if ( isstring(newAct) ) then
        local seq = client:LookupSequence(newAct)
        if ( seq != -1 ) then
            clientTable.CalcSeqOverride = seq
        end
    elseif ( istable(newAct) ) then
        if ( !clientTable.CalcSeqOverrideTable or oldAct != newAct ) then
            clientTable.CalcSeqOverrideTable = client:LookupSequence(newAct[math.random(#newAct)])
        end

        clientTable.CalcSeqOverride = clientTable.CalcSeqOverrideTable
    end

    if ( oldAct != newAct ) then
        clientTable.axLastAct = newAct
    end

    -- Turning gesture handling
    -- https://github.com/TankNut/helix-plugins/blob/master/turning.lua
    if ( !client:InVehicle() ) then
        client.axNextTurn = client.axNextTurn or 0

        if ( client.axNextTurn <= CurTime() ) then
            local diff = normalizeAngle(client:GetRenderAngles().y - client:EyeAngles().y)
            local absDiff = diff < 0 and -diff or diff  -- math.abs without function call

            if ( absDiff >= 45 ) then
                local gesture = diff > 0 and "gesture_turn_right_90" or "gesture_turn_left_90"
                local gestureSeq = client:LookupSequence(gesture)

                client:PlayGesture(GESTURE_SLOT_FLINCH, gestureSeq)

                local duration = client:SequenceDuration(gestureSeq)
                if ( duration <= 0 ) then
                    duration = 0.5
                end

                client.axNextTurn = CurTime() + duration

                if ( SERVER ) then
                    net.Start("ax.animations.update")
                        net.WritePlayer(client)
                        net.WriteTable(clientTable.axAnimations)
                        net.WriteString(holdType)
                    net.Broadcast()
                end
            end
        end
    end

    return newAct
end

function MODULE:DoAnimationEvent(client, event, data)
    local clientTable = client:GetTable()
    local animTable = clientTable.axAnimations

    if ( event == PLAYERANIMEVENT_ATTACK_PRIMARY ) then
        if ( !animTable ) then return end

        local desired = animTable.shoot or ACT_MP_ATTACK_STAND_PRIMARYFIRE
        if ( client:IsFlagSet(FL_ANIMDUCKING) ) then
            desired = animTable.shoot_crouch or animTable.shoot or ACT_MP_ATTACK_CROUCH_PRIMARYFIRE
        end

        if ( isstring(desired) ) then
            desired = client:LookupSequence(desired)
        elseif ( istable(desired) ) then
            desired = client:LookupSequence(desired[math.random(#desired)])
        end

        local translated = hook.Run("TranslateEvent", client, event, data, desired)
        if ( translated ) then
            desired = translated
        end

        client:PlayGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, desired)

        return ACT_VM_PRIMARYATTACK
    elseif ( event == PLAYERANIMEVENT_ATTACK_SECONDARY ) then
        return ACT_VM_SECONDARYATTACK
    elseif ( event == PLAYERANIMEVENT_RELOAD ) then
        if ( !animTable ) then return end

        local desired = animTable.reload or ACT_MP_RELOAD_STAND
        if ( client:IsFlagSet(FL_ANIMDUCKING) ) then
            desired = animTable.reload_crouch or animTable.reload or ACT_MP_RELOAD_CROUCH
        end

        if ( isstring(desired) ) then
            desired = client:LookupSequence(desired)
        elseif ( istable(desired) ) then
            desired = client:LookupSequence(desired[math.random(#desired)])
        end

        local translated = hook.Run("TranslateEvent", client, event, data, desired)
        if ( translated ) then
            desired = translated
        end

        client:PlayGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, desired)

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

function MODULE:TranslateEvent(client, event, data, desired)
    if ( !wOS or !wOS.DynaBase ) then return end

    desired = isnumber(desired) and client:GetSequenceName(desired) or desired

    if ( string.StartsWith(desired, "reload_") ) then
        return "gesture_reload_" .. string.sub(desired, 8)
    elseif ( string.StartsWith(desired, "shoot_") ) then
        return "gesture_shoot_" .. string.sub(desired, 7)
    end
end

-- Official ARC9 integration for hold type modification
function MODULE:GetPlayerHoldType(client, weapon, holdType)
    if ( !tobool(ARC9) ) then return end

    if ( IsValid(weapon) and weapon.HoldTypeHolstered and weapon.Class == ARC9:GetPhrase("eft_class_weapon_pist") ) then
        if ( !client:IsWeaponRaised() ) then
            return weapon.HoldTypeHolstered
        else
            return weapon.HoldType
        end
    end
end
