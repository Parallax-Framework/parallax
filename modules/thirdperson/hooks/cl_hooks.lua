--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

concommand.Add("ax_thirdperson_toggle", function()
    Parallax.Option:Set("thirdperson", !Parallax.Option:Get("thirdperson", false))
end, nil, Parallax.Localization:GetPhrase("options.thirdperson.toggle"))

concommand.Add("ax_thirdperson_reset", function()
    Parallax.Option:Set("thirdperson.position.x", Parallax.Option:GetDefault("thirdperson.position.x"))
    Parallax.Option:Set("thirdperson.position.y", Parallax.Option:GetDefault("thirdperson.position.y"))
    Parallax.Option:Set("thirdperson.position.z", Parallax.Option:GetDefault("thirdperson.position.z"))
end, nil, Parallax.Localization:GetPhrase("options.thirdperson.reset"))

local fakePos
local fakeAngles
local fakeFov

function MODULE:PreRenderThirdpersonView(client, pos, angles, fov)
    if ( IsValid(Parallax.GUI.Mainmenu) ) then
        return false
    end

    if ( IsValid(client:GetVehicle()) ) then
        return false
    end

    return true
end

local traceVector = Vector(4, 4, 4)
local dataTraceVector = Vector(8, 8, 8)

function MODULE:CalcView(client, pos, angles, fov)
    if ( !Parallax.Option:Get("thirdperson", false) or hook.Run("PreRenderThirdpersonView", client, pos, angles, fov) == false ) then
        fakePos = nil
        fakeAngles = nil
        fakeFov = nil

        return
    end

    local view = {}

    if ( Parallax.Option:Get("thirdperson.follParallax.Head", false) ) then
        local head

        for i = 0, client:GetBoneCount() do
            local bone = client:GetBoneName(i)
            if ( Parallax.Util:FindString(bone, "head") ) then
                head = i
                break
            end
        end

        if ( head ) then
            local head_pos = select(1, client:GetBonePosition(head))
            pos = head_pos
        end
    end

    pos = pos + client:GetVelocity() / 8

    local trace = util.TraceHull({
        start = pos,
        endpos = pos - (angles:Forward() * Parallax.Option:Get("thirdperson.position.x", 0)) + (angles:Right() * Parallax.Option:Get("thirdperson.position.y", 0)) + (angles:Up() * Parallax.Option:Get("thirdperson.position.z", 0)),
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
    local followHitAngles = Parallax.Option:Get("thirdperson.follParallax.Hit.angles", true)
    local followHitFov = Parallax.Option:Get("thirdperson.follParallax.Hit.fov", true)

    local viewBob = angle_zero
    local curTime = CurTime()
    local frameTime = FrameTime()

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

    return view
end

function MODULE:ShouldDrawLocalPlayer(client)
    return Parallax.Option:Get("thirdperson", false)
end

function MODULE:PrePlayerDraw(client, flags)
    if ( Parallax.Config:Get("thirdperson.tracecheck") and Parallax.Client != client ) then
        local traceLine = util.TraceLine({
            start = Parallax.Client:GetShootPos(),
            endpos = client:GetShootPos(),
            filter = Parallax.Client
        })

        if ( !traceLine.Hit ) then
            return true
        end
    end
end

--[[
function MODULE:AddToolMenuCategories()
    spawnmenu.AddToolCategory("Parallax", "User", "User")
end

function MODULE:AddToolMenuTabs()
    spawnmenu.AddToolTab("Parallax", "Parallax", "icon16/computer.png")

    spawnmenu.AddToolMenuOption("Parallax", "User", "ax_thirdperson", "Third Person", "", "", function(panel)
        panel:ClearControls()

        panel:AddControl("Header", { Text = Parallax.Localization:GetPhrase("options.thirdperson.title"), Description = Parallax.Localization:GetPhrase("options.thirdperson.description") })
        panel:CheckBox(Parallax.Localization:GetPhrase("options.thirdperson.enable"), "ax_thirdperson_enable")
        panel:NumSlider(Parallax.Localization:GetPhrase("options.thirdperson.position.x"), "ax_thirdperson_position_x", -1000, 1000, 0)
        panel:NumSlider(Parallax.Localization:GetPhrase("options.thirdperson.position.y"), "ax_thirdperson_position_y", -1000, 1000, 0)
        panel:NumSlider(Parallax.Localization:GetPhrase("options.thirdperson.position.z"), "ax_thirdperson_position_z", -1000, 1000, 0)
    end)
end
]]