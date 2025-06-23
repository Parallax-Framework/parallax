--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

function GM:PlayerStartVoice(client)
    if ( IsValid(g_VoicePanelList) ) then
        g_VoicePanelList:Remove()
    end

    Parallax.Net:Start("client.voice.start", client)
end

function GM:PlayerEndVoice(client)
    if ( IsValid(g_VoicePanelList) ) then
        g_VoicePanelList:Remove()
    end

    Parallax.Net:Start("client.voice.end", client)
end

function GM:ShouldRenderMainMenu()
    local client = Parallax.Client
    if ( !IsValid(client) ) then return false end

    return IsValid(Parallax.GUI.Splash) or IsValid(Parallax.GUI.Mainmenu)
end

function GM:GetMainMenuMusic()
    return Parallax.Config:Get("mainmenu.music", "music/hl2_song20_submix0.mp3")
end

local currentStation = nil
local panels = {
    "mainmenu",
    "splash"
}
function GM:ShouldPlayMainMenuMusic()
    if ( !Parallax.Config:Get("mainmenu.music", true) ) then return false end

    local client = Parallax.Client
    if ( !IsValid(client) ) then return false end

    local exists = false
    for i = 1, #panels do
        if ( IsValid(Parallax.GUI[panels[i]]) ) then
            exists = true
            break
        end
    end

    if ( !exists ) then
        return false
    end

    return true
end

local function PlayTrack()
    local music = hook.Run("GetMainMenuMusic")
    if ( !music or music == "" ) then
        return
    end

    local shouldPlay = hook.Run("ShouldPlayMainMenuMusic")
    if ( !IsValid(currentStation) and shouldPlay ) then
        sound.PlayFile("sound/" .. music, "noblock", function(station, errorID, errorName)
            if ( IsValid(station) ) then
                station:SetVolume(Parallax.Option:Get("mainmenu.music.volume", 75) / 100)
                station:EnableLooping(Parallax.Option:Get("mainmenu.music.loop", true))

                currentStation = station
            else
                Parallax.Util:PrintError("Failed to play main menu music: " .. errorName)
            end
        end)
    elseif ( IsValid(currentStation) and shouldPlay ) then
        local volume = Parallax.Option:Get("mainmenu.music.volume", 75) / 100
        if ( currentStation:GetVolume() != volume ) then
            currentStation:SetVolume(volume)
        end
    end
end

local nextThink = 0
function GM:Think()
    if ( nextThink > CurTime() ) then return end
    nextThink = CurTime() + 0.1

    if ( IsValid(currentStation) ) then
        if ( currentStation:GetVolume() <= 0 ) then
            currentStation:Stop()
            currentStation = nil
        else
            local shouldPlay = hook.Run("ShouldPlayMainMenuMusic")
            local from, to = currentStation:GetVolume(), shouldPlay and (Parallax.Option:Get("mainmenu.music.volume", 75) / 100) or 0
            local output = math.Approach(from, to, FrameTime() * 8)
            currentStation:SetVolume(output)
        end
    end

    PlayTrack()
end

function GM:ScoreboardShow()
    if ( hook.Run("ShouldRenderMainMenu") ) then
        return false
    end

    if ( !IsValid(Parallax.GUI.Tab) ) then
        vgui.Create("Parallax.Tab")
    else
        Parallax.GUI.Tab:Remove()
    end

    return false
end

function GM:ScoreboardHide()
    return false
end

function GM:Initialize()
    Parallax.Item:LoadFolder("parallax/gamemode/items")
    Parallax.Module:LoadFolder("parallax/modules")
    Parallax.Schema:Initialize()

    hook.Run("LoadFonts")
end

local _reloaded = false
function GM:OnReloaded()
    if ( _reloaded ) then return end
    _reloaded = true

    if ( IsValid(currentStation) ) then
        currentStation:Stop()
        currentStation = nil
    end

    Parallax.Item:LoadFolder("parallax/gamemode/items")
    Parallax.Module:LoadFolder("parallax/modules")
    Parallax.Schema:Initialize()
    Parallax.Option:Load()

    Parallax.Util:Print("Core reloaded in " .. math.Round(SysTime() - GM.RefreshTimeStart, 2) .. " seconds.")
    hook.Run("LoadFonts")
end

function GM:InitPostEntity()
    Parallax.Client = LocalPlayer()
    Parallax.Option:Load()

    if ( !IsValid(Parallax.GUI.Chatbox) ) then
        vgui.Create("Parallax.Chatbox")
    end
end

function GM:OnCloseCaptionEmit()
    return true
end

local eyeTraceHullMin = Vector(-2, -2, -2)
local eyeTraceHullMax = Vector(2, 2, 2)
function GM:CalcView(client, pos, angles, fov)
    if ( hook.Run("ShouldRenderMainMenu") ) then
        local mainmenuPos = Parallax.Config:Get("mainmenu.pos", vector_origin)
        local mainmenuAng = Parallax.Config:Get("mainmenu.ang", angle_zero)
        local mainmenuFov = Parallax.Config:Get("mainmenu.fov", 90)

        return {
            origin = mainmenuPos,
            angles = mainmenuAng,
            fov = mainmenuFov,
            drawviewer = true
        }
    end

    local ragdoll = !Parallax.Client:Alive() and Parallax.Client:GetRagdollEntity() or Parallax.Client:GetRelay("ragdoll", nil)
    if ( IsValid(ragdoll) ) then
        local eyePos
        local eyeAng

        if ( ragdoll:LookupAttachment("eyes") ) then
            local attachment = ragdoll:GetAttachment(ragdoll:LookupAttachment("eyes"))
            if ( attachment ) then
                eyePos = attachment.Pos
                eyeAng = attachment.Ang
            end
        else
            local bone = ragdoll:LookupBone("ValveBiped.Bip01_Head1")
            if ( !bone ) then return end

            eyePos, eyeAng = ragdoll:GetBonePosition(bone)
        end

        if ( !eyePos or !eyeAng ) then return end

        local traceHull = util.TraceHull({
            start = eyePos,
            endpos = eyePos + eyeAng:Forward() * 2,
            filter = ragdoll,
            mask = MASK_PLAYERSOLID,
            mins = eyeTraceHullMin,
            maxs = eyeTraceHullMax
        })

        return {
            origin = traceHull.HitPos,
            angles = eyeAng,
            fov = fov,
            drawviewer = true
        }
    end
end

local LOWERED_POS = Vector(0, 0, 0)
local LOWERED_ANGLES = Angle(10, 10, 0)
local LOWERED_LERP = {pos = Vector(0, 0, 0), angles = Angle(0, 0, 0)}
function GM:CalcViewModelView(weapon, viewModel, oldPos, oldAng, pos, ang)
    local client = Parallax.Client
    if ( !IsValid(client) ) then return end

    local targetPos = LOWERED_POS
    local targetAngles = LOWERED_ANGLES
    if ( IsValid(weapon) and weapon:IsWeapon() ) then
        if ( weapon.LoweredPos ) then
            targetPos = weapon.LoweredPos
        end

        if ( weapon.LoweredAngles ) then
            targetAngles = weapon.LoweredAngles
        end
    end

    if ( IsValid(weapon) and !client:IsWeaponRaised() ) then
        LOWERED_LERP.pos = Lerp(FrameTime() * 4, LOWERED_LERP.pos, targetPos)
        LOWERED_LERP.angles = LerpAngle(FrameTime() * 4, LOWERED_LERP.angles, targetAngles)
    else
        LOWERED_LERP.pos = Lerp(FrameTime() * 4, LOWERED_LERP.pos, vector_origin)
        LOWERED_LERP.angles = LerpAngle(FrameTime() * 4, LOWERED_LERP.angles, angle_zero)
    end

    pos = pos + LOWERED_LERP.pos
    ang = ang + LOWERED_LERP.angles

    return self.BaseClass:CalcViewModelView(weapon, viewModel, oldPos, oldAng, pos, ang)
end

local vignette = Parallax.Util:GetMaterial("parallax/overlay_vignette.png", "noclamp smooth")
local vignetteColor = Color(0, 0, 0, 255)
function GM:HUDPaintBackground()
    if ( tobool(hook.Run("ShouldDrawVignette")) ) then
        local client = Parallax.Client
        if ( !IsValid(client) ) then return end

        local scrW, scrH = ScrW(), ScrH()
        local trace = util.TraceLine({
            start = client:GetShootPos(),
            endpos = client:GetShootPos() + client:GetAimVector() * 96,
            filter = client,
            mask = MASK_SHOT
        })

        if ( trace.Hit and trace.HitPos:DistToSqr(client:GetShootPos()) < 96 ^ 2 ) then
            vignetteColor.a = Lerp(FrameTime(), vignetteColor.a, 255)
        else
            vignetteColor.a = Lerp(FrameTime(), vignetteColor.a, 100)
        end

        if ( hook.Run("ShouldDrawDefaultVignette") != false ) then
            surface.SetDrawColor(vignetteColor)
            surface.SetMaterial(vignette)
            surface.DrawTexturedRect(0, 0, scrW, scrH)
        end

        hook.Run("DrawVignette", 1 - (vignetteColor.a / 255))
    end
end

function GM:DrawVignette(fraction)
end

local padding = 16
local backgroundColor = Color(10, 10, 10, 220)
local healthLerp = 0
local healthAlpha = 0
local healthTime = 0
local healthLast = 0
function GM:HUDPaint()
    local client = Parallax.Client
    if ( !IsValid(client) ) then return end

    local shouldDraw = hook.Run("PreHUDPaint")
    if ( shouldDraw == false ) then return end

    local x, y = 24, 24
    local scrW, scrH = ScrW(), ScrH()
    local ft = FrameTime()

    shouldDraw = hook.Run("ShouldDrawDebugHUD")
    if ( shouldDraw != false ) then
        local green = Parallax.Config:Get("color.framework")
        local width = math.max(Parallax.Util:GetTextWidth("Parallax.Developer", "Pos: " .. tostring(client:GetPos())), Parallax.Util:GetTextWidth("Parallax.Developer", "Ang: " .. tostring(client:EyeAngles())))
        local height = 16 * 6

        local character = client:GetCharacter()
        if ( character ) then
            height = height + 16 * 6
        end

        Parallax.Util:DrawBlurRect(x - padding, y - padding, width + padding * 2, height + padding * 2)

        surface.SetDrawColor(backgroundColor)
        surface.DrawRect(x - padding, y - padding, width + padding * 2, height + padding * 2)

        draw.SimpleText("[DEVELOPER HUD]", "Parallax.Developer", x, y, green, TEXT_ALIGN_LEFT)

        draw.SimpleText("Pos: " .. tostring(client:GetPos()), "Parallax.Developer", x, y + 16 * 1, green, TEXT_ALIGN_LEFT)
        draw.SimpleText("Ang: " .. tostring(client:EyeAngles()), "Parallax.Developer", x, y + 16 * 2, green, TEXT_ALIGN_LEFT)
        draw.SimpleText("Health: " .. client:Health(), "Parallax.Developer", x, y + 16 * 3, green, TEXT_ALIGN_LEFT)
        draw.SimpleText("Ping: " .. client:Ping(), "Parallax.Developer", x, y + 16 * 4, green, TEXT_ALIGN_LEFT)

        local fps = math.floor(1 / ft)
        draw.SimpleText("FPS: " .. fps, "Parallax.Developer", x, y + 16 * 5, green, TEXT_ALIGN_LEFT)

        if ( character ) then
            local name = character:GetName()
            local charModel = character:GetModel()
            local inventories = Parallax.Inventory:GetByCharacterID(character:GetID()) or {}
            for k, v in pairs(inventories) do
                inventories[k] = tostring(v)
            end
            local inventoryText = "Inventories: " .. table.concat(inventories, ", ")

            draw.SimpleText("[CHARACTER INFO]", "Parallax.Developer", x, y + 16 * 7, green, TEXT_ALIGN_LEFT)
            draw.SimpleText("Character: " .. tostring(character), "Parallax.Developer", x, y + 16 * 8, green, TEXT_ALIGN_LEFT)
            draw.SimpleText("Name: " .. name, "Parallax.Developer", x, y + 16 * 9, green, TEXT_ALIGN_LEFT)
            draw.SimpleText("Model: " .. charModel, "Parallax.Developer", x, y + 16 * 10, green, TEXT_ALIGN_LEFT)
            draw.SimpleText(inventoryText, "Parallax.Developer", x, y + 16 * 11, green, TEXT_ALIGN_LEFT)
        end
    end

    shouldDraw = hook.Run("ShouldDrawPreviewHUD")
    if ( shouldDraw != false ) then
        local orange = Parallax.Color:Get("orange")
        local red = Parallax.Color:Get("red")

        Parallax.Util:DrawBlurRect(x - padding, y - padding, 410 + padding * 2, 45 + padding * 2)

        surface.SetDrawColor(backgroundColor)
        surface.DrawRect(x - padding, y - padding, 410 + padding * 2, 45 + padding * 2)

        draw.SimpleText("[PREVIEW MODE]", "Parallax.Developer", x, y, orange, TEXT_ALIGN_LEFT)
        draw.SimpleText("Warning! Anything you witness is subject to change.", "Parallax.Developer", x, y + 16, red, TEXT_ALIGN_LEFT)
        draw.SimpleText("This is not the final product.", "Parallax.Developer", x, y + 16 * 2, red, TEXT_ALIGN_LEFT)
    end

    shouldDraw = hook.Run("ShouldDrawCrosshair")
    if ( shouldDraw != false and Parallax.Option:Get("hud.crosshair", true) ) then
        local crosshairColor = Parallax.Option:Get("hud.crosshair.color", color_white)
        local crosshairSize = Parallax.Option:Get("hud.crosshair.size", 1)
        local crosshairThickness = Parallax.Option:Get("hud.crosshair.thickness", 1)
        local crosshairType = Parallax.Option:Get("hud.crosshair.type", "cross")

        local centerX, centerY = ScrW() / 2, ScrH() / 2
        if ( hook.Run("ShouldDrawLocalPlayer", client) ) then
            local trace = util.TraceLine({
                start = client:GetShootPos(),
                endpos = client:GetShootPos() + client:GetAimVector() * 8192,
                filter = client,
                mask = MASK_SHOT
            })

            centerX, centerY = trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y
        end

        local size = ScreenScale(8) * crosshairSize

        if ( crosshairType == "cross" ) then
            surface.SetDrawColor(crosshairColor)
            surface.DrawRect(centerX - size / 2, centerY - crosshairThickness / 2, size, crosshairThickness)
            surface.DrawRect(centerX - crosshairThickness / 2, centerY - size / 2, crosshairThickness, size)
        elseif ( crosshairType == "rectangle" ) then
            surface.SetDrawColor(crosshairColor)
            surface.DrawRect(centerX - size / 2, centerY - size / 2, size, size)
        elseif ( crosshairType == "circle" ) then
            Parallax.Util:DrawCircleScaled(centerX, centerY, size / 2, 32, crosshairColor)
        else
            Parallax.Util:PrintError("Unknown crosshair type: " .. crosshairType)
            Parallax.Option:Reset("hud.crosshair.type")
            Parallax.Client:Notify("Unknown crosshair type: " .. crosshairType .. ". Resetting!")
        end
    end

    shouldDraw = hook.Run("ShouldDrawAmmoBox")
    if ( shouldDraw != nil and shouldDraw != false ) then
        local activeWeapon = client:GetActiveWeapon()
        if ( !IsValid(activeWeapon) ) then return end

        local ammo = client:GetAmmoCount(activeWeapon:GetPrimaryAmmoType())
        local clip = activeWeapon:Clip1()
        local ammoText = clip .. " / " .. ammo

        draw.SimpleTextOutlined(ammoText, "Parallax.Bold", scrW - 16, scrH - 16, Parallax.Color:Get("white"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM, 1, Parallax.Color:Get("black"))
    end

    shouldDraw = hook.Run("ShouldDrawHealthBar")
    if ( shouldDraw != nil and shouldDraw != false ) then
        local healthFraction = client:Health() / client:GetMaxHealth()
        healthLerp = Lerp(ft * 5, healthLerp, healthFraction)

        if ( Parallax.Option:Get("hud.health.bar.always", false) ) then
            healthAlpha = 255
        else
            if ( healthLast != healthFraction ) then
                healthTime = CurTime() + 10
                healthLast = healthFraction
            elseif ( healthTime < CurTime() ) then
                healthAlpha = Lerp(ft * 2, healthAlpha, 0)
            elseif ( healthAlpha < 255 ) then
                healthAlpha = Lerp(ft * 8, healthAlpha, 255)
            end
        end

        if ( math.Round(healthAlpha) > 0 and healthLerp > 0 ) then
            local barWidth, barHeight = scrW / 6, ScreenScale(4)
            local barX, barY = scrW / 2 - barWidth / 2, scrH / 1.025 - barHeight / 2

            if ( Parallax.Globals.drawingStamina ) then
                barY = barY - barHeight - padding
            end

            Parallax.Util:DrawBlurRect(barX, barY, barWidth, barHeight, 2, nil, healthAlpha)

            surface.SetDrawColor(ColorAlpha(Parallax.Color:Get("background.transparent"), healthAlpha / 2))
            surface.DrawRect(barX, barY, barWidth, barHeight)

            surface.SetDrawColor(ColorAlpha(Parallax.Color:Get("red.soft"), healthAlpha))
            surface.DrawRect(barX, barY, barWidth * healthLerp, barHeight)
        end
    end

    hook.Run("PostHUDPaint")
end

local textAngle = Angle(0, 0, 90)

function GM:PostDrawTranslucentRenderables(bDrawingDepth, bDrawingSkybox)
    if ( !Parallax.Config:Get("debug.developer") ) then return end
    if ( !Parallax.Client:IsDeveloper() ) then return end

    local client = Parallax.Client
    if ( !IsValid(client) ) then return end

    local trace = client:GetEyeTrace()
    if ( !trace.Hit or !IsValid(trace.Entity) ) then return end

    local entity = trace.Entity
    local pos = entity:GetPos()
    local ang = entity:GetAngles()
    local center = entity:LocalToWorld(entity:OBBCenter())
    local model = entity:GetModel() or "N/A"
    local class = entity:GetClass() or "N/A"

    local text = string.format("Entity: %s\nClass: %s\nModel: %s\nPosition: %s\nAngles: %s",
        tostring(entity), class, model, tostring(pos), tostring(ang))
    local markedUp = markup.Parse("<font=Parallax.Developer>" .. text .. "</font>")
    if ( !markedUp ) then return end

    local textWidth, textHeight = markedUp:Size()
    local x = -ScrW() * 0.5 + (ScrW() - textWidth) * 0.5
    local y = -ScrH() * 0.5 + (ScrH() - textHeight) * 0.5

    local distance = pos:DistToSqr(client:GetPos())
    if ( distance > 1024 ^ 2 ) then
        return
    end

    local scale = math.Clamp(0 + (distance / 1024), 0.1, 1)

    textAngle.y = client:EyeAngles().y - 90

    -- Draw a background for the text
    cam.IgnoreZ(true)
    cam.Start3D2D(center, textAngle, scale)
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(x - padding, y - padding, textWidth + padding, textHeight + padding)

        -- Draw the text
        markedUp:Draw(x - padding / 2, y - padding / 2)
    cam.End3D2D()
    cam.IgnoreZ(false)
end

local elements = {
    ["CHUDQuickInfo"] = true,
    ["CHudAmmo"] = true,
    ["CHudBattery"] = true,
    ["CHudChat"] = true,
    ["CHudCrosshair"] = true,
    ["CHudDamageIndicator"] = true,
    ["CHudGeiger"] = true,
    ["CHudHealth"] = true,
    ["CHudHistoryResource"] = true,
    ["CHudPoisonDamageIndicator"] = true,
    ["CHudSecondaryAmmo"] = true,
    ["CHudSquadStatus"] = true,
    ["CHudSuitPower"] = true,
    ["CHudTrain"] = true,
    ["CHudVehicle"] = true
}

function GM:HUDShouldDraw(name)
    return !elements[name]
end

function GM:LoadFonts()
    local scale6 = ScreenScaleH(6)
    local scale8 = ScreenScaleH(8)
    local scale10 = ScreenScaleH(10)
    local scale16 = ScreenScaleH(16)
    local scale24 = ScreenScaleH(24)
    local scale32 = ScreenScaleH(32)

    surface.CreateFont("Parallax.Tiny", {
        font = "GorDIN Regular",
        size = scale6,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("Parallax.Tiny.Bold", {
        font = "GorDIN Bold",
        size = scale6,
        weight = 900,
        antialias = true
    })

    surface.CreateFont("Parallax.Small", {
        font = "GorDIN Regular",
        size = scale8,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("Parallax.Small.Bold", {
        font = "GorDIN Bold",
        size = scale8,
        weight = 900,
        antialias = true
    })

    surface.CreateFont("Parallax.Small.Italic", {
        font = "GorDIN Regular",
        size = scale8,
        weight = 700,
        italic = true,
        antialias = true
    })

    surface.CreateFont("Parallax.Small.Italic.Bold", {
        font = "GorDIN Bold",
        size = scale8,
        weight = 900,
        italic = true,
        antialias = true
    })

    surface.CreateFont("parallax", {
        font = "GorDIN Regular",
        size = scale10,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("Parallax.Bold", {
        font = "GorDIN Bold",
        size = scale10,
        weight = 900,
        antialias = true
    })

    surface.CreateFont("Parallax.Italic", {
        font = "GorDIN Regular",
        size = scale10,
        weight = 700,
        italic = true,
        antialias = true
    })

    surface.CreateFont("Parallax.Italic.Bold", {
        font = "GorDIN Bold",
        size = scale10,
        weight = 900,
        italic = true,
        antialias = true
    })

    surface.CreateFont("Parallax.Large", {
        font = "GorDIN Regular",
        size = scale16,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("Parallax.Large.Bold", {
        font = "GorDIN Bold",
        size = scale16,
        weight = 900,
        antialias = true
    })

    surface.CreateFont("Parallax.Large.Italic", {
        font = "GorDIN Regular",
        size = scale16,
        weight = 700,
        italic = true,
        antialias = true
    })

    surface.CreateFont("Parallax.Large.Italic.Bold", {
        font = "GorDIN Bold",
        size = scale16,
        weight = 900,
        italic = true,
        antialias = true
    })

    surface.CreateFont("Parallax.Massive", {
        font = "GorDIN Regular",
        size = scale24,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("Parallax.Massive.Bold", {
        font = "GorDIN Bold",
        size = scale24,
        weight = 900,
        antialias = true
    })

    surface.CreateFont("Parallax.Massive.Italic", {
        font = "GorDIN Regular",
        size = scale24,
        weight = 700,
        italic = true,
        antialias = true
    })

    surface.CreateFont("Parallax.Massive.Italic.Bold", {
        font = "GorDIN Bold",
        size = scale24,
        weight = 900,
        italic = true,
        antialias = true
    })

    surface.CreateFont("Parallax.Huge", {
        font = "GorDIN Regular",
        size = scale32,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("Parallax.Huge.Bold", {
        font = "GorDIN Bold",
        size = scale32,
        weight = 900,
        antialias = true
    })

    surface.CreateFont("Parallax.Huge.Italic", {
        font = "GorDIN",
        size = scale32,
        weight = 700,
        italic = true,
        antialias = true
    })

    surface.CreateFont("Parallax.Huge.Italic.Bold", {
        font = "GorDIN Bold",
        size = scale32,
        weight = 900,
        italic = true,
        antialias = true
    })

    surface.CreateFont("Parallax.Developer", {
        font = "Courier New",
        size = 16,
        weight = 700,
        antialias = true
    })

    surface.CreateFont("Parallax.Chat", {
        font = "GorDIN Regular",
        size = ScreenScale(8) * Parallax.Option:Get("chat.size.font", 1),
        weight = 700,
        antialias = true
    })

    hook.Run("PostLoadFonts")
end

function GM:OnPauseMenuShow()
    if ( IsValid(Parallax.GUI.Tab) ) then
        Parallax.GUI.Tab:Close()
        return false
    end

    if ( IsValid(Parallax.GUI.Chatbox) and Parallax.GUI.Chatbox:GetAlpha() == 255 ) then
        Parallax.GUI.Chatbox:SetVisible(false)
        return false
    end

    if ( !IsValid(Parallax.GUI.Mainmenu) ) then
        vgui.Create("Parallax.Mainmenu")
    else
        if ( Parallax.Client:GetCharacter() ) then
            Parallax.GUI.Mainmenu:Remove()
            return
        end
    end

    return false
end

function GM:PreHUDPaint()
end

function GM:PostHUDPaint()
end

function GM:ShouldDrawCrosshair()
    if ( IsValid(Parallax.GUI.Mainmenu) ) then return false end
    if ( IsValid(Parallax.GUI.Tab) ) then return false end

    return true
end

function GM:ShouldDrawAmmoBox()
    if ( IsValid(Parallax.GUI.Mainmenu) ) then return false end
    if ( IsValid(Parallax.GUI.Tab) ) then return false end

    local client = Parallax.Client
    local activeWeapon = client:GetActiveWeapon()
    if ( !IsValid(activeWeapon) ) then return false end

    local clip = activeWeapon:Clip1()
    local ammo = client:GetAmmoCount(activeWeapon:GetPrimaryAmmoType())
    if ( clip <= 0 and ammo <= 0 ) then return false end

    local viewEntity = client:GetViewEntity()
    if ( IsValid(viewEntity) and viewEntity != client ) then
        return false
    end

    return true
end

function GM:ShouldDrawHealthBar()
    if ( IsValid(Parallax.GUI.Mainmenu) ) then return false end
    if ( IsValid(Parallax.GUI.Tab) ) then return false end

    local client = Parallax.Client
    if ( !IsValid(client) or !client:Alive() ) then return false end

    return Parallax.Option:Get("hud.health.bar", true)
end

function GM:ShouldDrawDebugHUD()
    if ( !Parallax.Config:Get("debug.developer") ) then return false end
    if ( IsValid(Parallax.GUI.Mainmenu) ) then return false end
    if ( IsValid(Parallax.GUI.Tab) ) then return false end

    return Parallax.Client:IsDeveloper()
end

function GM:ShouldDrawPreviewHUD()
    if ( !Parallax.Config:Get("debug.preview") ) then return false end
    if ( IsValid(Parallax.GUI.Mainmenu) ) then return false end
    if ( IsValid(Parallax.GUI.Tab) ) then return false end

    return !hook.Run("ShouldDrawDebugHUD")
end

function GM:ShouldDrawVignette()
    if ( IsValid(Parallax.GUI.Mainmenu) ) then return false end

    return Parallax.Option:Get("hud.vignette", true)
end

function GM:ShouldDrawDefaultVignette()
    return !vignette:IsError()
end

function GM:ShouldShowInventory()
    return true
end

function GM:GetCharacterName(client, target)
    -- TODO: Empty hook, implement this in the future
end

function GM:PopulateTabButtons(buttons)
    if ( CAMI.PlayerHasAccess(Parallax.Client, "Parallax - Manage Config", nil) ) then
        buttons["tab.config"] = {
            Populate = function(this, container)
                container:Add("Parallax.Tab.config")
            end
        }
    end

    buttons["tab.help"] = {
        Populate = function(this, container)
            container:Add("Parallax.Tab.Help")
        end
    }

    if ( hook.Run("ShouldShowInventory") != false ) then
        buttons["tab.inventory"] = {
            Populate = function(this, container)
                container:Add("Parallax.Tab.Inventory")
            end
        }
    end

    buttons["tab.inventory"] = {
        Populate = function(this, container)
            container:Add("Parallax.Tab.Inventory")
        end
    }

    buttons["tab.scoreboard"] = {
        Populate = function(this, container)
            container:Add("Parallax.Tab.Scoreboard")
        end
    }

    buttons["tab.options"] = {
        Populate = function(this, container)
            container:Add("Parallax.Tab.Options")
        end
    }
end

function GM:PopulateHelpCategories(categories)
    categories["test"] = function(container)
        local filler = container:Add("DPanel")
        filler:Dock(FILL)
    end

    categories["flags"] = function(container)
        local scroller = container:Add("Parallax.Scroller.Vertical")
        scroller:Dock(FILL)
        scroller:GetVBar():SetWide(0)
        scroller.Paint = nil

        for k, v in SortedPairs(Parallax.Flag.Stored) do
            local char = Parallax.Client:GetCharacter()
            if ( !char ) then return end

            local hasFlag = char:HasFlag(k)

            local button = scroller:Add("Parallax.Button.Flat")
            button:Dock(TOP)
            button:SetFont("Parallax.Large.Bold")
            button:SetText("")
            button:SetBackgroundAlphaHovered(1)
            button:SetBackgroundAlphaUnHovered(0.5)
            button:SetBackgroundColor(hasFlag and Parallax.Config:Get("color.success") or Parallax.Config:Get("color.error"))
            button.DoRightClick = function(this)
                if ( !CAMI.PlayerHasAccess(Parallax.Client, "Parallax - Manage Flags", nil) ) then return end

                local menu = DermaMenu()
                menu:AddOption("Give Flag", function()
                    Parallax.Command:Run("CharGiveFlags", Parallax.Client:SteamID64(), k)
                end)

                menu:AddOption("Remove Flag", function()
                    Parallax.Command:Run("CharTakeFlags", Parallax.Client:SteamID64(), k)
                end)

                for _, target in player.Iterator() do
                    if ( target == Parallax.Client ) then continue end

                    menu:AddSpacer()

                    menu:AddOption("Give Flag to " .. target:Nick(), function()
                        Parallax.Command:Run("CharGiveFlags", target:SteamID64(), k)
                    end)
                    menu:AddOption("Remove Flag from " .. target:Nick(), function()
                        Parallax.Command:Run("CharTakeFlags", target:SteamID64(), k)
                    end)
                end

                menu:Open()
            end

            local key = button:Add("Parallax.Text")
            key:Dock(LEFT)
            key:DockMargin(ScreenScale(8), 0, 0, 0)
            key:SetFont("Parallax.Large.Bold")
            key:SetText(k)

            local seperator = button:Add("Parallax.Text")
            seperator:Dock(LEFT)
            seperator:SetFont("Parallax.Large")
            seperator:SetText(" - ")

            local description = button:Add("Parallax.Text")
            description:Dock(LEFT)
            description:SetFont("Parallax.Large")
            description:SetText(v.description)

            local function Think(this)
                this:SetTextColor(button:GetTextColor())
            end

            key.Think = Think
            seperator.Think = Think
            description.Think = Think
        end
    end

    categories["commands"] = function(container)
        local scroller = container:Add("Parallax.Scroller.Vertical")
        scroller:Dock(FILL)
        scroller:GetVBar():SetWide(0)
        scroller.Paint = nil

        for commandName, commandInfo in SortedPairs(Parallax.Command:GetAll()) do
            if ( !istable(commandInfo) ) then
                Parallax.Util:PrintError("Command '" .. commandName .. "' is not a valid table.")
                continue
            end

            if ( commandInfo.ChatType and Parallax.Chat:Get(commandInfo.ChatType) ) then
                continue -- Skip commands that are chat types
            end

            local panel = scroller:Add("DPanel")
            panel:Dock(TOP)
            panel:DockMargin(0, 0, 0, 8)
            panel.Paint = function(this, width, height)
                surface.SetDrawColor(30, 30, 30, 200)
                surface.DrawRect(0, 0, width, height)
            end

            local nameLabel = panel:Add("Parallax.Text")
            nameLabel:SetFont("Parallax.Bold")
            nameLabel:SetText(commandName, true)
            nameLabel:Dock(TOP)
            nameLabel:DockMargin(8, 0, 8, 0)

            local description = commandInfo.Description
            if ( !description or description == "" ) then
                description = "No description provided."
            end

            local descriptionLabel = panel:Add("Parallax.Text")
            descriptionLabel:SetFont("Parallax.Small")
            descriptionLabel:SetText(description, true)
            descriptionLabel:Dock(TOP)
            descriptionLabel:DockMargin(8, -4, 8, 0)

            if ( istable(commandInfo.Arguments) ) then
                local argumentsLabel = panel:Add("Parallax.Text")
                argumentsLabel:SetFont("Parallax.Small")
                argumentsLabel:SetText("Useable Arguments:", true)
                argumentsLabel:Dock(TOP)
                argumentsLabel:DockMargin(8, -4, 8, 0)

                for i = 1, #commandInfo.Arguments do
                    local data = commandInfo.Arguments[i]
                    if ( !istable(data) ) then
                        Parallax.Util:PrintError("Command argument at index " .. i .. " from command '" .. commandName .. "' is not a table. Expected a table with 'Type' and 'ErrorMsg' fields.")
                        data = { Type = "Unknown", ErrorMsg = "No error message provided." }
                    end

                    local argLabel = panel:Add("Parallax.Text")
                    argLabel:SetFont("Parallax.Small")
                    argLabel:SetText(i .. ": " .. Parallax.Util:FormatType(data.Type) .. " - " .. (data.ErrorMsg or "No error message provided."), true)
                    if ( data.Optional ) then
                        argLabel:SetText(argLabel:GetText() .. " (Optional)", true)
                    end
                    argLabel:Dock(TOP)
                    argLabel:DockMargin(16, -4, 8, 0)
                end
            end

            local height = 0
            local children = panel:GetChildren()
            for i = 1, #children do
                local v = children[i]
                if ( ispanel(v) and v:IsVisible() ) then
                    height = height + v:GetTall() + select(2, v:GetDockMargin())
                end
            end

            panel:SetTall(height + 8) -- Add some padding
        end
    end
end

function GM:GetChatboxSize()
    local width = ScrW() * 0.4
    local height = ScrH() * 0.35

    return width, height
end

function GM:GetChatboxPos()
    local _, height = self:GetChatboxSize()
    local x = ScrW() * 0.0125
    local y = ScrH() * 0.025
    y = ScrH() - height - y

    return x, y
end

function GM:ChatboxOnTextChanged(text)
    Parallax.Net:Start("client.chatbox.text.changed", text)

    -- Notify the command system about the text change
    local command = Parallax.Command:Get(Parallax.GUI.Chatbox:GetChatType())
    if ( command and command.OnChatTextChanged ) then
        command:OnTextChanged(text)
    end

    -- Notify the chat system about the text change
    local chat = Parallax.Chat:Get(Parallax.GUI.Chatbox:GetChatType())
    if ( chat and chat.OnChatTextChanged ) then
        chat:OnTextChanged(text)
    end
end

function GM:ChatboxOnChatTypeChanged(newType, oldType)
    Parallax.Net:Start("client.chatbox.type.changed", newType, oldType)

    -- Notify the command system about the chat type change
    local command = Parallax.Command:Get(newType)
    if ( command and command.OnChatTypeChanged ) then
        command:OnChatTypeChanged(newType, oldType)
    end

    -- Notify the chat system about the chat type change
    local chat = Parallax.Chat:Get(newType)
    if ( chat and chat.OnChatTypeChanged ) then
        chat:OnChatTypeChanged(newType, oldType)
    end
end

function GM:PlayerBindPress(client, bind, pressed)
    bind = bind:lower()

    if ( string.find(bind, "messagemode") and pressed ) then
        Parallax.GUI.Chatbox:SetVisible(true)

        for i = 1, #Parallax.Chat.messages do
            local pnl = Parallax.Chat.messages[i]
            if ( IsValid(pnl) ) then
                pnl.alpha = 1
            end
        end

        return true
    end
end

function GM:StartChat()
end

function GM:FinishChat()
end

function GM:ForceDermaSkin()
    return "Parallax"
end

function GM:OnScreenSizeChanged(oldWidth, oldHeight, newWidth, newHeight)
    for i = 1, #Parallax.GUI do
        local v = Parallax.GUI[i]
        if ( ispanel(v) and IsValid(v) ) then
            local className = v:GetClassName()
            v:Remove()

            -- Attempt to recreate the GUI element
            if ( className == "Parallax.Mainmenu" ) then
                vgui.Create("Parallax.Mainmenu")
            elseif ( className == "Parallax.Tab" ) then
                vgui.Create("Parallax.Tab")
            end
        end
    end

    hook.Run("LoadFonts")
end

function GM:SpawnMenuOpen()
    local character = Parallax.Client:GetCharacter()
    if ( !character ) then return end

    if ( !character:HasFlag("s") ) then
        return false
    end

    return true
end

function GM:PostOptionsLoad(instancesTable)
    for optionName, value in pairs(instancesTable) do
        local optionData = Parallax.Option.Stored[optionName]
        if ( !istable(optionData) ) then continue end

        if ( optionData.Type == Parallax.Types.number and optionData.IsKeybind ) then
            Parallax.Binds[optionName] = value
        end
    end
end