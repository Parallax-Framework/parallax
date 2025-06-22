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
    ax.option:Set("thirdperson", !ax.option:Get("thirdperson", false))
end, nil, ax.localization:GetPhrase("options.thirdperson.toggle"))

concommand.Add("ax_thirdperson_reset", function()
    ax.option:Set("thirdperson.position.x", ax.option:GetDefault("thirdperson.position.x"))
    ax.option:Set("thirdperson.position.y", ax.option:GetDefault("thirdperson.position.y"))
    ax.option:Set("thirdperson.position.z", ax.option:GetDefault("thirdperson.position.z"))
end, nil, ax.localization:GetPhrase("options.thirdperson.reset"))

local fakePos
local fakeAngles
local fakeFov

function MODULE:PreRenderThirdpersonView(client, pos, angles, fov)
    if ( IsValid(ax.gui.mainmenu) ) then
        return false
    end

    if ( IsValid(client:GetVehicle()) ) then
        return false
    end

    return true
end

function MODULE:CalcView(client, pos, angles, fov)
    if ( !ax.option:Get("thirdperson", false) or hook.Run("PreRenderThirdpersonView", client, pos, angles, fov) == false ) then
        fakePos = nil
        fakeAngles = nil
        fakeFov = nil

        return
    end

    local view = {}

    if ( ax.option:Get("thirdperson.follax.Head", false) ) then
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

    pos = pos + client:GetVelocity() / 8

    local trace = util.TraceHull({
        start = pos,
        endpos = pos - (angles:Forward() * ax.option:Get("thirdperson.position.x", 0)) + (angles:Right() * ax.option:Get("thirdperson.position.y", 0)) + (angles:Up() * ax.option:Get("thirdperson.position.z", 0)),
        filter = client,
        mask = MASK_SHOT,
        mins = Vector(-4, -4, -4),
        maxs = Vector(4, 4, 4)
    })

    local traceData = util.TraceHull({
        start = pos,
        endpos = pos + (angles:Forward() * 32768),
        filter = client,
        mask = MASK_SHOT,
        mins = Vector(-8, -8, -8),
        maxs = Vector(8, 8, 8)
    })

    local shootPos = traceData.HitPos
    local followHitAngles = ax.option:Get("thirdperson.follax.Hit.angles", true)
    local followHitFov = ax.option:Get("thirdperson.follax.Hit.fov", true)

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
    return ax.option:Get("thirdperson", false)
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

--[[
function MODULE:AddToolMenuCategories()
    spawnmenu.AddToolCategory("Parallax", "User", "User")
end

function MODULE:AddToolMenuTabs()
    spawnmenu.AddToolTab("Parallax", "Parallax", "icon16/computer.png")

    spawnmenu.AddToolMenuOption("Parallax", "User", "ax_thirdperson", "Third Person", "", "", function(panel)
        panel:ClearControls()

        panel:AddControl("Header", { Text = ax.localization:GetPhrase("options.thirdperson.title"), Description = ax.localization:GetPhrase("options.thirdperson.description") })
        panel:CheckBox(ax.localization:GetPhrase("options.thirdperson.enable"), "ax_thirdperson_enable")
        panel:NumSlider(ax.localization:GetPhrase("options.thirdperson.position.x"), "ax_thirdperson_position_x", -1000, 1000, 0)
        panel:NumSlider(ax.localization:GetPhrase("options.thirdperson.position.y"), "ax_thirdperson_position_y", -1000, 1000, 0)
        panel:NumSlider(ax.localization:GetPhrase("options.thirdperson.position.z"), "ax_thirdperson_position_z", -1000, 1000, 0)
    end)
end
]]