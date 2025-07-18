--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:PreRenderThirdpersonView(client, pos, angles, fov)
    if ( !ax.option:Get("thirdperson", false) ) then
        return false
    end

    if ( IsValid(ax.gui.mainmenu) or IsValid(ax.gui.splash) ) then
        return false
    end

    if ( IsValid(client:GetVehicle()) ) then
        return false
    end

    if ( !client:Alive() ) then
        return false
    end

    return true
end

local traceVector = Vector(4, 4, 4)
local dataTraceVector = Vector(8, 8, 8)
local fakeVelocityOffset = Vector(0, 0, 0)
local fakePos
local fakeAngles
local fakeFov

function MODULE:CalcView(client, pos, angles, fov)
    if ( hook.Run("PreRenderThirdpersonView", client, pos, angles, fov) == true ) then
        local view = {}

        if ( ax.option:Get("thirdperson.follow.head", false) ) then
            local head

            for i = 0, client:GetBoneCount() do
                local bone = client:GetBoneName(i)
                if ( ax.util:FindString(bone, "head") ) then
                    head = i
                    break
                end
            end

            if ( head ) then
                local head_pos = select(1, client:GetBonePosition(head))
                pos = head_pos
            end
        end

        local frameTime = FrameTime()

        if ( !fakeVelocityOffset or fakeVelocityOffset == Vector(0, 0, 0) ) then
            fakeVelocityOffset = client:GetVelocity() / 8
        end

        fakeVelocityOffset = LerpVector(frameTime * 8, fakeVelocityOffset, client:GetVelocity() / 8)

        local thirdpersonX = ax.option:Get("thirdperson.position.x", 0)
        local thirdpersonY = ax.option:Get("thirdperson.position.y", 0)
        local thirdpersonZ = ax.option:Get("thirdperson.position.z", 0)

        local forward = angles:Forward()
        local right = angles:Right()
        local up = angles:Up()

        local offset = (forward * -thirdpersonX) + (right * thirdpersonY) + (up * thirdpersonZ) + fakeVelocityOffset

        local trace = util.TraceHull({
            start = pos,
            endpos = pos + offset,
            filter = client,
            mask = MASK_SHOT,
            mins = -traceVector,
            maxs = traceVector
        })

        local traceData = util.TraceHull({
            start = pos,
            endpos = pos + (angles:Forward() * 32768),
            filter = client,
            mask = MASK_SHOT,
            mins = -dataTraceVector,
            maxs = dataTraceVector
        })

        local shootPos = traceData.HitPos
        local followHitAngles = ax.option:Get("thirdperson.follow.hit.angles", true)
        local followHitFov = ax.option:Get("thirdperson.follow.hit.fov", true)

        local viewBob = angle_zero
        local curTime = CurTime()

        viewBob.p = math.sin(curTime / 4) / 2
        viewBob.y = math.cos(curTime) / 2

        fakeAngles = LerpAngle(frameTime * 8, fakeAngles or angles, (followHitAngles and (shootPos - trace.HitPos):Angle() or angles) + viewBob)
        fakePos = LerpVector(frameTime * 8, fakePos or trace.HitPos, trace.HitPos)

        local distance = pos:Distance(traceData.HitPos) / 64
        distance = math.Clamp(distance, 0, 50)
        fakeFov = Lerp(frameTime, fakeFov or fov, followHitFov and (fov - distance) or fov)

        view.origin = fakePos or trace.HitPos
        view.angles = fakeAngles or angles
        view.fov = fakeFov or fov

        hook.Run("PostRenderThirdpersonView", client, view)

        return view
    else
        fakePos = nil
        fakeAngles = nil
        fakeFov = nil
    end
end

function MODULE:ShouldDrawLocalPlayer(client)
    if ( hook.Run("PreRenderThirdpersonView", client) == true ) then
        return true
    end
end

function MODULE:PrePlayerDraw(client, flags)
    if ( ax.config:Get("thirdperson.tracecheck") and ax.client != client ) then
        local traceLine = util.TraceLine({
            start = ax.client:GetShootPos(),
            endpos = client:GetShootPos(),
            filter = ax.client
        })

        if ( !traceLine.Hit ) then
            return true
        end
    end
end