local MODULE = MODULE

MODULE.Name = "Viewmodel Motion"
MODULE.Author = "kek, Revlis, Riggs"
MODULE.Description = "Adds a small muzzle-driven camera sway effect to the player's viewmodel, along with viewmodel inertia."

CreateClientConVar("muzzlecam_scale", "1", true, false)

ax.option:Add("viewmodel.inertia_speed", ax.type.number, 7, { category = "view", description = "Inertia lerp speed" })
ax.option:Add("viewmodel.tilt_amount", ax.type.number, 2, { category = "view", description = "Base camera tilt amount" })
ax.option:Add("viewmodel.strafe_tilt", ax.type.number, 3.0, { category = "view", description = "Strafe roll amount" })
ax.option:Add("viewmodel.crouch_lower", ax.type.number, 2.0, { category = "view", description = "Crouch lower amount" })
ax.option:Add("viewmodel.crouch_roll", ax.type.number, 3.0, { category = "view", description = "Crouch roll amount" })
ax.option:Add("viewmodel.overshoot_strength", ax.type.number, 1.5, { category = "view", description = "Overshoot impulse strength" })
ax.option:Add("viewmodel.jump_bob", ax.type.number, 3.5, { category = "view", description = "Jump bob strength" })

local weapon_exclusion_list = {
    ["gmod_tool"] = true,
    ["weapon_physcannon"] = true,
    ["weapon_physgun"] = true,
}

local weapon_prefix_exclusion_list = {
    "arc9_",
    "mg_",
    "tacrp_",
}

local excluded_acts = {
    [ACT_VM_HOLSTER] = true,
}

local lastMuzzleAng = Angle(0, 0, 0)
local muzzleVel = Angle(0, 0, 0)
local viewOffset = Angle(0, 0, 0)

ax.viewstack:RegisterModifier("viewmodel", function(client, view)
    if ( !IsValid(client) or !client:Alive() or client:InVehicle() or client:ShouldDrawLocalPlayer() ) then return end

    local wep = client:GetActiveWeapon()
    if ( !IsValid(wep) ) then return end

    local wepClass = wep:GetClass()
    if ( weapon_exclusion_list[wepClass] ) then return end

    for _, prefix in ipairs(weapon_prefix_exclusion_list) do
        if ( string.StartWith(wepClass, prefix) ) then
            return
        end
    end

    local vm = client:GetViewModel()
    if ( !IsValid(vm) ) then return end

    local seq = vm:GetSequence()
    local act = vm:GetSequenceActivity(seq)
    if ( excluded_acts[act] ) then return end

    local attID = vm:LookupAttachment("muzzle")
    if ( attID <= 0 ) then return end

    local att = vm:GetAttachment(attID)
    if ( !att or !att.Ang ) then return end

    local scale = GetConVar("muzzlecam_scale"):GetFloat()
    if ( scale <= 0 ) then return end

    local muzzleAng = vm:WorldToLocalAngles(att.Ang)
    local ft = FrameTime()
    local delta = lastMuzzleAng - muzzleAng
    delta:Normalize()

    muzzleVel = muzzleVel + delta * 2 * scale

    muzzleVel.p = Lerp(math.Clamp(ft * 20, 0, 1), muzzleVel.p, -viewOffset.p * 2)
    muzzleVel.p = math.Clamp(muzzleVel.p, -scale * 5, scale * 5)

    muzzleVel.y = Lerp(math.Clamp(ft * 20, 0, 1), muzzleVel.y, -viewOffset.y * 2)
    muzzleVel.y = math.Clamp(muzzleVel.y, -scale * 5, scale * 5)

    muzzleVel.r = Lerp(math.Clamp(ft * 20, 0, 1), muzzleVel.r, -viewOffset.r * 2)
    muzzleVel.r = math.Clamp(muzzleVel.r, -scale * 5, scale * 5)

    viewOffset.p = math.Clamp(viewOffset.p + muzzleVel.p * ft, -90, 90)
    viewOffset.y = math.Clamp(viewOffset.y + muzzleVel.y * ft, -90, 90)
    viewOffset.r = math.Clamp(viewOffset.r + muzzleVel.r * ft, -90, 90)

    viewOffset.p = Lerp(math.Clamp(ft * math.abs(viewOffset.p) * 16, 0, 1), viewOffset.p, 0)
    viewOffset.y = Lerp(math.Clamp(ft * math.abs(viewOffset.y) * 16, 0, 1), viewOffset.y, 0)
    viewOffset.r = Lerp(math.Clamp(ft * math.abs(viewOffset.r) * 16, 0, 1), viewOffset.r, 0)

    lastMuzzleAng = muzzleAng

    return {
        origin = view.origin,
        angles = view.angles + viewOffset,
        fov = view.fov
    }
end, 1)

-- Local inertia state
local lastEyeAng = Angle(0, 0, 0)
local lastAngDiff = Angle(0, 0, 0)
local currentOffset = Angle(0, 0, 0)
local moveOffset = Angle(0, 0, 0)
local crouchLerp = 0
local jumpBob = 0
local jumpTarget = 0
local lastOnGround = true
local overshootDecay = 0

function MODULE:CalcViewModelView(weapon, vm, oldPos, oldAng, origin, angles)
    local client = ax.client
    if ( !IsValid(client) or !client:Alive() ) then return origin, angles end

    local ft = FrameTime()

    local inertiaSpeed = ax.option:Get("viewmodel.inertia_speed", 7) or 7
    local baseTilt = ax.option:Get("viewmodel.tilt_amount", 2) or 2
    local strafeTilt = ax.option:Get("viewmodel.strafe_tilt", 3.0) or 3.0
    local crouchLower = ax.option:Get("viewmodel.crouch_lower", 2.0) or 2.0
    local crouchRoll = ax.option:Get("viewmodel.crouch_roll", 3.0) or 3.0
    local overshootStr = ax.option:Get("viewmodel.overshoot_strength", 1.5) or 1.5
    local jumpBobAmt = ax.option:Get("viewmodel.jump_bob", 3.5) or 3.5

    -- Camera inertia + overshoot
    local curEye = client:EyeAngles()
    if ( lastEyeAng.p == 0 and lastEyeAng.y == 0 and lastEyeAng.r == 0 ) then
        lastEyeAng = curEye
        lastAngDiff = Angle(0, 0, 0)
    end

    local angDiff = curEye - lastEyeAng
    angDiff:Normalize()

    local targetCamOffset = Angle(-angDiff.p * baseTilt, 0, angDiff.y * baseTilt)

    local lastSpeed = math.max(math.abs(lastAngDiff.p), math.abs(lastAngDiff.y))
    local curSpeed  = math.max(math.abs(angDiff.p), math.abs(angDiff.y))
    local decel = lastSpeed - curSpeed

    if ( decel > 0.08 ) then
        local overshootP = -lastAngDiff.p * (overshootStr * 0.12)
        local overshootR =  lastAngDiff.y * (overshootStr * 0.12)
        overshootDecay = math.min(1, overshootDecay + decel * 4)
        targetCamOffset = targetCamOffset + Angle(overshootP * overshootDecay, 0, overshootR * overshootDecay)
    end

    if ( overshootDecay > 0 ) then
        overshootDecay = Lerp(ft * 4, overshootDecay, 0)
    end

    local safeSpeed = math.Clamp(ft * inertiaSpeed, 0, 1)
    currentOffset = LerpAngle(safeSpeed, currentOffset, targetCamOffset)

    lastEyeAng = curEye
    lastAngDiff = angDiff

    -- Strafe roll
    local mvRight = client:KeyDown(IN_MOVERIGHT)
    local mvLeft  = client:KeyDown(IN_MOVELEFT)

    local targetMoveRoll = 0
    if ( mvRight ) then
        targetMoveRoll = strafeTilt
    elseif ( mvLeft ) then
        targetMoveRoll = -strafeTilt
    else
        targetMoveRoll = 0
    end

    local vel = client:GetVelocity()
    local speed2d = vel:Length2D()
    if ( speed2d > 5 and (mvRight or mvLeft) ) then
        local rightDir = client:EyeAngles():Right()
        local rightDot = vel:Dot(rightDir) / speed2d
        targetMoveRoll = Lerp(0.5, targetMoveRoll, rightDot * strafeTilt)
    end

    moveOffset.r = Lerp(ft * 8, moveOffset.r, targetMoveRoll)

    -- Crouch lower/roll
    local duckingNow = client:KeyDown(IN_DUCK) or client:Crouching()
    local crouchTarget = duckingNow and 1 or 0
    crouchLerp = Lerp(ft * 5, crouchLerp, crouchTarget)
    if ( crouchLerp > 0.0001 ) then
        local lowerAmt = crouchLower * crouchLerp
        origin = origin + angles:Up() * -lowerAmt
        angles:RotateAroundAxis(angles:Forward(), -crouchRoll * crouchLerp)
    end

    -- Jump bob
    local onGround = client:OnGround()
    if ( onGround != lastOnGround ) then
        if ( !lastOnGround and onGround ) then
            jumpTarget = jumpBobAmt * 0.7
        elseif ( lastOnGround and !onGround ) then
            jumpTarget = -jumpBobAmt * 1.0
        end
        lastOnGround = onGround
    end

    jumpBob = Lerp(ft * 10, jumpBob, jumpTarget)
    jumpTarget = Lerp(ft * 4, jumpTarget, 0)
    if ( math.abs(jumpBob) > 0.001 ) then
        origin = origin + angles:Up() * (jumpBob * 0.6)
    end

    -- Apply camera offsets (pitch and roll)
    angles:RotateAroundAxis(angles:Right(),  currentOffset.p)
    angles:RotateAroundAxis(angles:Forward(), currentOffset.r + moveOffset.r)
end