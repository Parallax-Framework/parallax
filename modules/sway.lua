local MODULE = MODULE

MODULE.Name = "Sway"
MODULE.Description = "Implements a swaying effect ported over from ARC9."
MODULE.Author = "Riggs"

ax.localization:Register("en", {
    ["category.sway"] = "Sway",
    ["option.sway"] = "Sway",
    ["option.sway.help"] = "Enable or disable sway.",
    ["option.sway.multiplier"] = "Sway Multiplier",
    ["option.sway.multiplier.help"] = "Set the sway multiplier.",
    ["option.sway.multiplier.sprint"] = "Sway Multiplier Sprint",
    ["option.sway.multiplier.sprint.help"] = "Set the sway multiplier while sprinting.",
})

ax.option:Register("sway", {
    Name = "option.sway",
    Type = ax.types.bool,
    Default = true,
    Description = "option.sway.help",
    NoNetworking = true,
    Category = "category.sway"
})

ax.option:Register("sway.multiplier", {
    Name = "option.sway.multiplier",
    Type = ax.types.number,
    Default = 1,
    Min = 0,
    Max = 10,
    Decimals = 1,
    Description = "option.sway.multiplier.help",
    NoNetworking = true,
    Category = "category.sway"
})

ax.option:Register("sway.multiplier.sprint", {
    Name = "option.sway.multiplier.sprint",
    Type = ax.types.number,
    Default = 1,
    Min = 0,
    Max = 10,
    Decimals = 1,
    Description = "option.sway.multiplier.sprint.help",
    NoNetworking = true,
    Category = "category.sway"
})

ax.option:Register("camera.max.roll", {
    Name = "Camera Max Roll",
    Type = ax.types.number,
    Default = 10,
    Min = 0,
    Max = 45,
    Decimals = 1,
    Description = "Maximum roll angle for the camera.",
    NoNetworking = true,
    Category = "category.sway"
})

ax.option:Register("camera.max.tilt", {
    Name = "Camera Max Tilt",
    Type = ax.types.number,
    Default = 10,
    Min = 0,
    Max = 45,
    Decimals = 1,
    Description = "Maximum tilt angle for the camera.",
    NoNetworking = true,
    Category = "category.sway"
})

ax.option:Register("camera.roll.speed", {
    Name = "Camera Roll Speed",
    Type = ax.types.number,
    Default = 5,
    Min = 0,
    Max = 20,
    Decimals = 1,
    Description = "Speed at which the camera roll adjusts to mouse movement.",
    NoNetworking = true,
    Category = "category.sway"
})

ax.option:Register("camera.pitch.speed", {
    Name = "Camera Pitch Speed",
    Type = ax.types.number,
    Default = 5,
    Min = 0,
    Max = 20,
    Decimals = 1,
    Description = "Speed at which the camera pitch adjusts to mouse movement.",
    NoNetworking = true,
    Category = "category.sway"
})

ax.option:Register("camera.intensity", {
    Name = "Camera Intensity",
    Type = ax.types.number,
    Default = 1,
    Min = 0,
    Max = 5,
    Decimals = 1,
    Description = "Intensity of the camera offset effect.",
    NoNetworking = true,
    Category = "category.sway"
})

if ( CLIENT ) then
    local SideMove = 0
    local JumpMove = 0

    local ViewModelBobVelocity = 0
    local ViewModelNotOnGround = 0

    local BobCT = 0
    local Multiplier = 0

    local SprintInertia = 0
    local WalkInertia = 0
    local CrouchMultiplier = 0
    local SprintMultiplier = 0
    local WalkMultiplier = 0
    local function GetViewModelBob(pos, ang)
        local step = 10
        local mag = 1
        local ts = 0

        local swayEnabled = ax.option:Get("sway")
        if ( !swayEnabled ) then return pos, ang end

        local swayMult = ax.option:Get("sway.multiplier")
        local swayMultSprint = ax.option:Get("sway.multiplier.sprint")

        local client = ax.client
        local ft = FrameTime()

        Multiplier = Lerp(ft * 64, Multiplier, client:IsSprinting() and swayMultSprint or swayMult)

        local velocityangle = client:GetVelocity()
        local v = velocityangle:Length()
        v = math.Clamp(v, 0, 500)
        ViewModelBobVelocity = math.Approach(ViewModelBobVelocity, v, ft * 1000)
        local d = math.Clamp(ViewModelBobVelocity / 500, 0, 1)

        if ( client:OnGround() and client:GetMoveType() != MOVETYPE_NOCLIP ) then
            ViewModelNotOnGround = math.Approach(ViewModelNotOnGround, 0, ft / 0.1)
        else
            ViewModelNotOnGround = math.Approach(ViewModelNotOnGround, 1, ft / 0.1)
        end

        local amount = 0.1

        d = d * Lerp(amount, 1, 0.03) * Lerp(ts, 1, 1.5)
        mag = d * 2
        mag = mag * Lerp(ts, 1, 2)
        step = Lerp(ft * 4, step, 12)

        local sidemove = (client:GetVelocity():Dot(client:EyeAngles():Right()) / client:GetMaxSpeed()) * 4 * (1.5-amount)
        SideMove = Lerp(math.Clamp(ft * 8, 0, 1), SideMove, sidemove)

        CrouchMultiplier = Lerp(ft * 4, CrouchMultiplier, 1)
        if ( client:Crouching() ) then
            CrouchMultiplier = Lerp(ft * 4, CrouchMultiplier, 3.5 + amount * 10)
            step = Lerp(ft * 4, step, 8)
        end

        local jumpmove = math.Clamp(math.ease.InExpo(math.Clamp(velocityangle.z, -150, 0) / -150) / 2 + math.ease.InExpo(math.Clamp(velocityangle.z, 0, 500) / 500) * -50, -4, 2.5) / 2
        JumpMove = Lerp(math.Clamp(ft * 8, 0, 1), JumpMove, jumpmove)
        local smoothjumpmove2 = math.Clamp(JumpMove, -0.3, 0.01) * (1.5 - amount)

        if ( client:IsSprinting() ) then
            SprintInertia = Lerp(ft * 2, SprintInertia, 1)
            WalkInertia = Lerp(ft * 2, WalkInertia, 0)
        else
            SprintInertia = Lerp(ft * 2, SprintInertia, 0)
            WalkInertia = Lerp(ft * 2, WalkInertia, 1)
        end

        if ( SprintInertia > 0 ) then
            SprintMultiplier = Multiplier * SprintInertia
            pos = pos - (ang:Up() * math.sin(BobCT * step) * 0.45 * ((math.sin(BobCT * 3.515) / 6) + 1) * mag * SprintMultiplier)
            pos = pos + (ang:Forward() * math.sin(BobCT * step / 3) * 0.11 * ((math.sin(BobCT * 2) * ts * 1.25) + 1) * ((math.sin(BobCT * 0.615) / 6) + 2) * mag * SprintMultiplier)
            pos = pos + (ang:Right() * (math.sin(BobCT * step / 2) + (math.cos(BobCT * step / 2))) * 0.55 * mag * SprintMultiplier)
            ang:RotateAroundAxis(ang:Forward(), math.sin(BobCT * step / 2) * ((math.sin(BobCT * 6.151) / 6) + 1) * 9 * d * SprintMultiplier + SideMove * 1.5)
            ang:RotateAroundAxis(ang:Right(), math.sin(BobCT * step * 0.12) * ((math.sin(BobCT * 1.521) / 6) + 1) * 1 * d * SprintMultiplier)
            ang:RotateAroundAxis(ang:Up(), math.sin(BobCT * step / 2) * ((math.sin(BobCT * 1.521) / 6) + 1) * 6 * d * SprintMultiplier)
            ang:RotateAroundAxis(ang:Right(), smoothjumpmove2 * 5)
        end

        if ( WalkInertia > 0 ) then
            WalkMultiplier = Multiplier * WalkInertia
            pos = pos - (ang:Up() * math.sin(BobCT * step) * 0.1 * ((math.sin(BobCT * 3.515) / 6) + 2) * mag * CrouchMultiplier * WalkMultiplier) - (ang:Up() * SideMove * -0.05) - (ang:Up() * smoothjumpmove2 / 6)
            pos = pos + (ang:Forward() * math.sin(BobCT * step / 3) * 0.11 * ((math.sin(BobCT * 2) * ts * 1.25) + 1) * ((math.sin(BobCT * 0.615) / 6) + 1) * mag * WalkMultiplier)
            pos = pos + (ang:Right() * (math.sin(BobCT * step / 2) + (math.cos(BobCT * step / 2))) * 0.55 * mag * WalkMultiplier)
            ang:RotateAroundAxis(ang:Forward(), math.sin(BobCT * step / 2) * ((math.sin(BobCT * 6.151) / 6) + 1) * 5 * d * WalkMultiplier + SideMove)
            ang:RotateAroundAxis(ang:Right(), math.sin(BobCT * step * 0.12) * ((math.sin(BobCT * 1.521) / 6) + 1) * 0.1 * d * WalkMultiplier)
            ang:RotateAroundAxis(ang:Right(), smoothjumpmove2 * 5)
        end

        local steprate = Lerp(d, 1, 2.75)
        steprate = Lerp(ViewModelNotOnGround, steprate, 0.75)

        BobCT = ( BobCT + ( ft / 2 * steprate ) ) % ( math.pi * 2 )

        return pos, ang
    end

    local horizontalRoll = 0
    local targetHorizontalRoll = 0
    local sensitivityX = 0.1

    local verticalTilt = 0
    local targetVerticalTilt = 0
    local sensitivityY = 0.1
    function MODULE:CreateMove(cmd)
        local maxRoll = ax.option:Get("camera.max.roll", 10)
        local maxTilt = ax.option:Get("camera.max.tilt", 10)
        local mouseX = cmd:GetMouseX()
        local mouseY = cmd:GetMouseY()

        targetHorizontalRoll = math.Clamp(mouseX * sensitivityX, -maxRoll, maxRoll)
        targetVerticalTilt = math.Clamp(mouseY * sensitivityY, -maxTilt, maxTilt)
    end

    local lerpMultiplier = 0
    local lerpRoll = 0
    local lerpYaw = 0
    local lerpPitch = 0
    local lerpFOV = 75
    function MODULE:CalcView(client, origin, angles, fov, znear, zfar)
        if ( !IsValid(client) or client:InObserver() ) then return end

        local view = {
            origin = origin,
            angles = angles,
            fov = fov,
            znear = znear or 1,
            zfar = zfar or 10000
        }

        local newOrigin = origin
        local newAngles = angles

        local velocity = client:GetVelocity()
        local speed = velocity:Length()
        local multiplier = 0.5 + ( speed / 100 )

        local ft = FrameTime()
        local time = ft * 2

        lerpMultiplier = Lerp(time, lerpMultiplier, multiplier)
        lerpRoll = Lerp(time, lerpRoll, velocity:Dot(newAngles:Right()) * 0.05 * math.max(0, lerpMultiplier - 0.5))
        lerpYaw = Lerp(time, lerpYaw, velocity:Dot(newAngles:Right()) * 0.01 * math.max(0, lerpMultiplier - 0.5))
        lerpPitch = Lerp(time, lerpPitch, ( velocity:Dot(newAngles:Up()) * 0.05 + ( speed / 64 ) ) / 2)
        lerpFOV = Lerp(time, lerpFOV, fov + ( speed / 64 ))

        -- Side roll when moving left or right
        newAngles.roll = newAngles.roll + ( ( math.cos( CurTime() * 1.35 ) / 2 * lerpMultiplier ) + lerpRoll )

        -- Side to side pitch when moving left or right
        newAngles.yaw = newAngles.yaw + ( ( math.sin( CurTime() ) / 6 * lerpMultiplier ) + lerpYaw )

        -- Up and down pitch when moving forward or backward
        newAngles.pitch = newAngles.pitch + ( ( math.sin( CurTime() ) / 6 * lerpMultiplier ) + lerpPitch )

        local rollSpeed = ax.option:Get("camera.roll.speed", 5)
        local pitchSpeed = ax.option:Get("camera.pitch.speed", 5)

        -- Smoothly interpolate the current values toward the target values.
        horizontalRoll = Lerp(FrameTime() * rollSpeed, horizontalRoll, targetHorizontalRoll)
        verticalTilt = Lerp(FrameTime() * pitchSpeed, verticalTilt, targetVerticalTilt)

        -- Apclient the horizontal roll effect.
        newAngles.r = newAngles.r + horizontalRoll
        -- Apclient the vertical tilt offset to the pitch (in addition to the player’s actual pitch).
        newAngles.p = newAngles.p + verticalTilt

        --- Implementation of Camera bone if it exists
        local viewModel = client:GetViewModel()
        if ( IsValid(viewModel) ) then
            local cameraAttachmentIndex = viewModel:LookupAttachment("camera")
            if ( cameraAttachmentIndex > 0 ) then
                local cameraAttachment = viewModel:GetAttachment(cameraAttachmentIndex)
                if ( cameraAttachment ) then
                    local rootAttachmentIndex = viewModel:LookupAttachment("camera_root")
                    if ( rootAttachmentIndex == 0 ) then
                        rootAttachmentIndex = viewModel:LookupAttachment("camera")
                    end

                    local rootAttachment = rootAttachmentIndex > 0 and viewModel:GetAttachment(rootAttachmentIndex) or {
                        Pos = cameraAttachment.Pos,
                        Ang = Angle(0, 0, 0)
                    }

                    local offsetAngles = cameraAttachment.Ang - rootAttachment.Ang
                    local intensity = ax.option:Get("camera.intensity", 1)

                    newAngles = newAngles + offsetAngles * intensity
                end
            end
        end

        view.origin = newOrigin
        view.angles = newAngles + client:GetViewPunchAngles() -- Double the view punch angles to make it more pronounced
        view.fov = lerpFOV

        return view
    end

    function MODULE:CalcViewModelView(weapon, viewModel, oldEyePos, oldEyeAng, eyePos, eyeAng)
        if ( !IsValid(weapon) or !IsValid(viewModel) ) then return end
        if ( ax.client:InObserver() ) then return end

        local newOrigin, newAngles = GAMEMODE.BaseClass:CalcViewModelView(weapon, viewModel, oldEyePos, oldEyeAng, eyePos, eyeAng)
        newOrigin, newAngles = GetViewModelBob(newOrigin, newAngles)

        -- Animate the weapon more, so it looks like a breathing effect
        local bIron = weapon.GetIronSights and weapon:GetIronSights()
        local breathScale = bIron and 0.125 or 1
        newOrigin.z = newOrigin.z + math.sin(CurTime() * 2) * 0.25 * breathScale
        newOrigin.x = newOrigin.x + math.cos(CurTime() * 2) * 0.25 * breathScale

        return newOrigin, newAngles
    end
end

local function HandlePlayerStep(client, side)
    if ( !IsValid(client) or client:InObserver() ) then return end

    local punch = Angle(0, 0, 0)
    if ( side == 1 ) then
        punch.r = -1
    else
        punch.r = 1
    end

    punch.p = 1

    punch = punch * 0.25

    client:ViewPunch(punch)
end

function MODULE:HandlePlayerStep(client, side)
    if ( !IsValid(client) or client:InObserver() ) then return end

    HandlePlayerStep(client, side)
end

function MODULE:PlayerFootstep(client, pos, foot, sound, volume, filter)
    if ( !IsValid(client) or client:InObserver() ) then return end

    HandlePlayerStep(client, foot)
end