--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

function GM:PlayerButtonDown(client, button)
    if ( !IsFirstTimePredicted() ) then return end

    if ( button == KEY_F1 and !IsValid(ax.gui.info) ) then
        vgui.Create("ax.info")
    end
end

function GM:PlayerStartVoice(client)
    if ( IsValid(g_VoicePanelList) ) then
        g_VoicePanelList:Remove()
    end

    net.Start("ax.client.voice.start")
        net.WritePlayer(client)
    net.SendToServer()
end

function GM:PlayerEndVoice(client)
    if ( IsValid(g_VoicePanelList) ) then
        g_VoicePanelList:Remove()
    end

    net.Start("ax.client.voice.end")
        net.WritePlayer(client)
    net.SendToServer()
end

function GM:ShouldRenderMainMenu()
    local client = ax.client
    if ( !IsValid(client) ) then return false end

    return IsValid(ax.gui.splash) or IsValid(ax.gui.mainmenu)
end

function GM:GetMainMenuMusic()
    return ax.config:Get("mainmenu.music", "music/hl2_song20_submix0.mp3")
end

local currentStation = nil
local panels = {
    "mainmenu",
    "splash"
}
function GM:ShouldPlayMainMenuMusic()
    if ( !ax.config:Get("mainmenu.music", true) ) then return false end

    local client = ax.client
    if ( !IsValid(client) ) then return false end

    local exists = false
    for i = 1, #panels do
        if ( IsValid(ax.gui[panels[i]]) ) then
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
                station:SetVolume(ax.option:Get("mainmenu.music.volume", 75) / 100)
                station:EnableLooping(ax.option:Get("mainmenu.music.loop", true))

                currentStation = station
            else
                ax.util:PrintError("Failed to play main menu music: " .. errorName)
            end
        end)
    elseif ( IsValid(currentStation) and shouldPlay ) then
        local volume = ax.option:Get("mainmenu.music.volume", 75) / 100
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
            local from, to = currentStation:GetVolume(), shouldPlay and (ax.option:Get("mainmenu.music.volume", 75) / 100) or 0
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

    if ( !IsValid(ax.gui.tab) ) then
        vgui.Create("ax.tab")
    else
        ax.gui.tab:Remove()
    end

    return false
end

function GM:ScoreboardHide()
    return false
end

function GM:Initialize()
    ax.item:LoadFolder("parallax/gamemode/items")
    ax.module:LoadFolder("parallax/modules")
    ax.schema:Initialize()

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

    ax.item:LoadFolder("parallax/gamemode/items")
    ax.module:LoadFolder("parallax/modules")
    ax.schema:Initialize()
    ax.option:Load()

    ax.util:Print("Core reloaded in " .. math.Round(SysTime() - GM.RefreshTimeStart, 2) .. " seconds.")
    hook.Run("LoadFonts")
end

function GM:InitPostEntity()
    ax.client = LocalPlayer()
    ax.option:Load()

    if ( !IsValid(ax.gui.chatbox) ) then
        vgui.Create("ax.chatbox")
    end
end

function GM:OnCloseCaptionEmit()
    return true
end

local eyeTraceHullMin = Vector(-2, -2, -2)
local eyeTraceHullMax = Vector(2, 2, 2)
function GM:CalcView(client, pos, angles, fov)
    if ( hook.Run("ShouldRenderMainMenu") ) then
        local mainmenuPos = ax.config:Get("mainmenu.pos", vector_origin)
        local mainmenuAng = ax.config:Get("mainmenu.ang", angle_zero)
        local mainmenuFov = ax.config:Get("mainmenu.fov", 90)

        return {
            origin = mainmenuPos,
            angles = mainmenuAng,
            fov = mainmenuFov,
            drawviewer = true
        }
    end

    local ragdoll = !ax.client:Alive() and ax.client:GetRagdollEntity() or ax.client:GetRelay("ragdoll", nil)
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
    local client = ax.client
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

local vignette = ax.util:GetMaterial("parallax/overlay_vignette.png", "noclamp smooth")
local vignetteColor = Color(0, 0, 0, 255)
function GM:HUDPaintBackground()
    if ( tobool(hook.Run("ShouldDrawVignette")) ) then
        local client = ax.client
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
local x, y = padding, padding

local function DrawDebug()
    local shouldDraw = hook.Run("ShouldDrawDebugHUD")
    if ( shouldDraw == false ) then return end

    local client = ax.client

    local green = ax.config:Get("color.framework")
    local width = math.max(ax.util:GetTextWidth("ax.developer", "Pos: " .. tostring(client:GetPos())), ax.util:GetTextWidth("ax.developer", "Ang: " .. tostring(client:EyeAngles())))
    local height = 16 * 6

    local character = client:GetCharacter()
    if ( character ) then
        height = height + 16 * 6
    end

    ax.util:DrawBlurRect(x - padding, y - padding, width + padding * 2, height + padding * 2)

    surface.SetDrawColor(backgroundColor)
    surface.DrawRect(x - padding, y - padding, width + padding * 2, height + padding * 2)

    draw.SimpleText("[DEVELOPER HUD]", "ax.developer", x, y, green, TEXT_ALIGN_LEFT)

    draw.SimpleText("Pos: " .. tostring(client:GetPos()), "ax.developer", x, y + 16 * 1, green, TEXT_ALIGN_LEFT)
    draw.SimpleText("Ang: " .. tostring(client:EyeAngles()), "ax.developer", x, y + 16 * 2, green, TEXT_ALIGN_LEFT)
    draw.SimpleText("Health: " .. client:Health(), "ax.developer", x, y + 16 * 3, green, TEXT_ALIGN_LEFT)
    draw.SimpleText("Ping: " .. client:Ping(), "ax.developer", x, y + 16 * 4, green, TEXT_ALIGN_LEFT)

    local ft = FrameTime()
    local fps = math.floor(1 / ft)
    draw.SimpleText("FPS: " .. fps, "ax.developer", x, y + 16 * 5, green, TEXT_ALIGN_LEFT)

    if ( character ) then
        local name = character:GetName()
        local charModel = character:GetModel()
        local inventories = ax.inventory:GetByCharacterID(character:GetID()) or {}
        for k, v in pairs(inventories) do
            inventories[k] = tostring(v)
        end
        local inventoryText = "Inventories: " .. table.concat(inventories, ", ")

        draw.SimpleText("[CHARACTER INFO]", "ax.developer", x, y + 16 * 7, green, TEXT_ALIGN_LEFT)
        draw.SimpleText("Character: " .. tostring(character), "ax.developer", x, y + 16 * 8, green, TEXT_ALIGN_LEFT)
        draw.SimpleText("Name: " .. name, "ax.developer", x, y + 16 * 9, green, TEXT_ALIGN_LEFT)
        draw.SimpleText("Model: " .. charModel, "ax.developer", x, y + 16 * 10, green, TEXT_ALIGN_LEFT)
        draw.SimpleText(inventoryText, "ax.developer", x, y + 16 * 11, green, TEXT_ALIGN_LEFT)
    end
end

local function DrawPreview()
    local shouldDraw = hook.Run("ShouldDrawPreviewHUD")
    if ( shouldDraw == false ) then return end

    local client = ax.client
    if ( !IsValid(client) ) then return end

    local orange = ax.color:Get("orange")
    local red = ax.color:Get("red")

    ax.util:DrawBlurRect(x - padding, y - padding, 410 + padding * 2, 45 + padding * 2)

    surface.SetDrawColor(backgroundColor)
    surface.DrawRect(x - padding, y - padding, 410 + padding * 2, 45 + padding * 2)

    draw.SimpleText("[PREVIEW MODE]", "ax.developer", x, y, orange, TEXT_ALIGN_LEFT)
    draw.SimpleText("Warning! Anything you witness is subject to change.", "ax.developer", x, y + 16, red, TEXT_ALIGN_LEFT)
    draw.SimpleText("This is not the final product.", "ax.developer", x, y + 16 * 2, red, TEXT_ALIGN_LEFT)
end

local function DrawCrosshair()
    local shouldDraw = hook.Run("ShouldDrawCrosshair")
    if ( shouldDraw == false ) then return end
    if ( !ax.option:Get("hud.crosshair", true) ) then return end

    local client = ax.client
    if ( !IsValid(client) ) then return end

    local crosshairColor = ax.option:Get("hud.crosshair.color", color_white)
    local crosshairSize = ax.option:Get("hud.crosshair.size", 1)
    local crosshairThickness = ax.option:Get("hud.crosshair.thickness", 1)
    local crosshairType = ax.option:Get("hud.crosshair.type", "cross")

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
        ax.util:DrawCircleScaled(centerX, centerY, size / 2, 32, crosshairColor)
    else
        ax.util:PrintError("Unknown crosshair type: " .. crosshairType)
        ax.option:Reset("hud.crosshair.type")
        ax.client:Notify("Unknown crosshair type: " .. crosshairType .. ". Resetting!")
    end
end

local function DrawAmmo()
    local shouldDraw = hook.Run("ShouldDrawAmmoBox")
    if ( shouldDraw == false ) then return end

    local client = ax.client
    if ( !IsValid(client) ) then return end

    local activeWeapon = client:GetActiveWeapon()
    if ( !IsValid(activeWeapon) or !activeWeapon:IsWeapon() ) then return end

    local ammoType = activeWeapon:GetPrimaryAmmoType()
    if ( ammoType == -1 ) then return end

    local ammoCount = client:GetAmmoCount(ammoType)
    local clipCount = activeWeapon:Clip1()

    local text = string.format("%d / %d", clipCount, ammoCount)
    draw.SimpleText(text, "ax.regular.bold", ScrW() - 16, ScrH() - 16, ax.color:Get("white"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
end

local function DrawHealth()
    local shouldDraw = hook.Run("ShouldDrawHealthBar")
    if ( shouldDraw == false ) then return end

    local client = ax.client
    if ( !IsValid(client) ) then return end

    local scrW, scrH = ScrW(), ScrH()
    local ft = FrameTime()
    local healthFraction = client:Health() / client:GetMaxHealth()
    healthLerp = Lerp(ft * 5, healthLerp, healthFraction)

    if ( ax.option:Get("hud.health.bar.always", false) ) then
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

        if ( ax.globals.drawingStamina ) then
            barY = barY - barHeight - padding
        end

        ax.util:DrawBlurRect(barX, barY, barWidth, barHeight, 2, nil, healthAlpha)

        surface.SetDrawColor(ColorAlpha(ax.color:Get("background.transparent"), healthAlpha / 2))
        surface.DrawRect(barX, barY, barWidth, barHeight)

        surface.SetDrawColor(ColorAlpha(ax.color:Get("red.soft"), healthAlpha))
        surface.DrawRect(barX, barY, barWidth * healthLerp, barHeight)
    end
end

function GM:DrawTargetInfo(target, alpha, is3D2D)
    local client = ax.client
    if ( is3D2D and target:IsPlayer() ) then
        local targetPos = target:EyePos() + Vector(0, 0, 10)
        local distToSqr = targetPos:DistToSqr(client:WorldSpaceCenter())
        local teamColor = team.GetColor(target:Team())
        local character = target:GetCharacter()
        local name = hook.Run("GetCharacterName", target, client) or (character and character:GetName() or target:Nick())
        cam.Start3D2D(targetPos, Angle(0, client:EyeAngles().y + 270, 90), 0.02 + (distToSqr / 1024 ^ 2))
            draw.SimpleTextOutlined(name, "ax.huge.bold", 0, 0, ColorAlpha(teamColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, Color(0, 0, 0, alpha))
        cam.End3D2D()
    end
end

local targetAlpha = {}
local nearbyEntities = {}
local lastEntityScan = 0
local scanInterval = 0.1
local infoDistance = 1024

local function UpdateNearbyEntities()
    local currentTime = CurTime()
    if ( currentTime - lastEntityScan < scanInterval ) then return end

    lastEntityScan = currentTime

    -- Clear old entities
    nearbyEntities = {}

    -- Use spatial partitioning to find nearby entities
    local clientPos = ax.client:WorldSpaceCenter()
    local nearbyEnts = ents.FindInSphere(clientPos, infoDistance)

    for i = 1, #nearbyEnts do
        local ent = nearbyEnts[i]
        if ( ent == ax.client ) then continue end

        -- Pre-filter entities that we might want to show target info for
        if ( hook.Run("ShouldDrawTargetInfo", ent, false) != false or
            hook.Run("ShouldDrawTargetInfo", ent, true) != false ) then
            nearbyEntities[#nearbyEntities + 1] = ent
        end
    end
end

local function DrawTargetInfos(is3D2D)
    UpdateNearbyEntities()

    local client = ax.client
    local clientShootPos = client:GetShootPos()
    local clientAimVector = client:GetAimVector()
    local clientWorldCenter = client:WorldSpaceCenter()

    -- Pre-calculate trace for aim detection
    local aimTrace = util.TraceLine({
        start = clientShootPos,
        endpos = clientShootPos + clientAimVector * 192,
        filter = client,
        mask = MASK_SHOT
    })

    local ft = FrameTime()

    for i = 1, #nearbyEntities do
        local v = nearbyEntities[i]
        if ( hook.Run("ShouldDrawTargetInfo", v, is3D2D) == false ) then continue end

        local index = v:EntIndex()
        if ( !targetAlpha[index] ) then
            targetAlpha[index] = 0
        end

        local alpha = targetAlpha[index]
        local targetPos = v:WorldSpaceCenter()
        local distToSqr = targetPos:DistToSqr(clientWorldCenter)

        -- Early distance check
        if ( distToSqr > infoDistance ^ 2 ) then
            alpha = Lerp(ft * 5, alpha, 0)
            targetAlpha[index] = alpha
            continue
        end

        -- Check if entity is being aimed at
        local isAimedAt = (distToSqr < 192 ^ 2 and aimTrace.Entity == v)
        if ( isAimedAt ) then
            alpha = Lerp(ft * 5, alpha, 255)
        else
            alpha = Lerp(ft * 5, alpha, 0)
        end

        alpha = math.Clamp(math.floor(alpha), 0, 255)
        targetAlpha[index] = alpha

        if ( alpha > 0 ) then
            hook.Run("DrawTargetInfo", v, alpha, is3D2D)
        end
    end

    -- Clean up alpha values for entities that no longer exist
    for index, alpha in pairs(targetAlpha) do
        local ent = Entity(index)
        if ( !IsValid(ent) ) then
            targetAlpha[index] = nil
        end
    end
end

function GM:HUDPaint()
    local client = ax.client
    if ( !IsValid(client) ) then return end

    local shouldDraw = hook.Run("PreHUDPaint")
    if ( shouldDraw == false ) then return end

    DrawDebug()
    DrawPreview()
    DrawCrosshair()
    DrawAmmo()
    DrawHealth()
    DrawTargetInfos(false)

    hook.Run("PostHUDPaint")
end

local textAngle = Angle(0, 0, 90)

function GM:PostDrawTranslucentRenderables(bDrawingDepth, bDrawingSkybox)
    local client = ax.client
    if ( !IsValid(client) ) then return end

    DrawTargetInfos(true)

    if ( !ax.config:Get("debug.developer") ) then return end
    if ( !ax.client:IsDeveloper() ) then return end

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
    local markedUp = markup.Parse("<font=ax.developer>" .. text .. "</font>")
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

local families = {
    ["regular"] = "GorDIN Regular",
    ["bold"] = "GorDIN Bold",
    ["italic"] = "GorDIN Regular",
    ["italic.bold"] = "GorDIN Bold"
}

function GM:LoadFonts()
    hook.Run("PreLoadFonts")

    ax.util:CreateFontFamily("tiny", "GorDIN Regular", ScreenScaleH(6), families)
    ax.util:CreateFontFamily("small", "GorDIN Regular", ScreenScaleH(8), families)
    ax.util:CreateFontFamily("regular", "GorDIN Regular", ScreenScaleH(10), families)
    ax.util:CreateFontFamily("large", "GorDIN Regular", ScreenScaleH(16), families)
    ax.util:CreateFontFamily("massive", "GorDIN Regular", ScreenScaleH(24), families)
    ax.util:CreateFontFamily("huge", "GorDIN Regular", ScreenScaleH(32), families)

    surface.CreateFont("ax.developer", {
        font = "Courier New",
        size = ScreenScaleH(6)
    })

    ax.util:CreateFontFamily("chat", "GorDIN Regular", ScreenScaleH(10) * ax.option:Get("chat.size.font", 1), families)

    hook.Run("PostLoadFonts")
end

function GM:GetChatFont(chatType)
    local chatData = ax.chat:Get(chatType)
    if ( chatData and chatData.Font ) then
        return chatData.Font
    end

    return "ax.chat"
end

function GM:OnPauseMenuShow()
    if ( IsValid(ax.gui.tab) ) then
        ax.gui.tab:Close()
        return false
    end

    if ( IsValid(ax.gui.chatbox) and ax.gui.chatbox:GetAlpha() == 255 ) then
        ax.gui.chatbox:SetVisible(false)
        return false
    end

    if ( !IsValid(ax.gui.mainmenu) ) then
        vgui.Create("ax.mainmenu")
    else
        if ( ax.client:GetCharacter() ) then
            ax.gui.mainmenu:Remove()
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
    if (
        IsValid(ax.gui.mainmenu) or
        IsValid(ax.gui.tab) or
        IsValid(ax.gui.splash)
    ) then
        return false
    end

    return true
end

function GM:ShouldDrawAmmoBox()
    if (
        IsValid(ax.gui.mainmenu) or
        IsValid(ax.gui.tab) or
        IsValid(ax.gui.splash)
    ) then
        return false
    end

    local client = ax.client
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
    if (
        IsValid(ax.gui.mainmenu) or
        IsValid(ax.gui.tab) or
        IsValid(ax.gui.splash)
    ) then
        return false
    end

    local client = ax.client
    if ( !IsValid(client) or !client:Alive() ) then return false end

    return ax.option:Get("hud.health.bar", true)
end

function GM:ShouldDrawTargetInfo(entity, is3D2D)
    if ( is3D2D and entity:IsPlayer() ) then return true end

    return false
end

function GM:ShouldDrawDebugHUD()
    if ( !ax.config:Get("debug.developer") ) then return false end
    if (
        IsValid(ax.gui.mainmenu) or
        IsValid(ax.gui.tab) or
        IsValid(ax.gui.splash)
    ) then
        return false
    end

    return ax.client:IsDeveloper()
end

function GM:ShouldDrawPreviewHUD()
    if ( !ax.config:Get("debug.preview") ) then return false end
    if (
        IsValid(ax.gui.mainmenu) or
        IsValid(ax.gui.tab) or
        IsValid(ax.gui.splash)
    ) then
        return false
    end

    return !hook.Run("ShouldDrawDebugHUD")
end

function GM:ShouldDrawVignette()
    if ( IsValid(ax.gui.mainmenu) ) then return false end

    return ax.option:Get("hud.vignette", true)
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
    if ( CAMI.PlayerHasAccess(ax.client, "Parallax - Manage Config", nil) ) then
        buttons["tab.config"] = {
            Populate = function(this, container)
                container:Add("ax.tab.config")
            end
        }
    end

    buttons["tab.help"] = {
        Populate = function(this, container)
            container:Add("ax.tab.help")
        end
    }

    if ( hook.Run("ShouldShowInventory") != false ) then
        buttons["tab.inventory"] = {
            Populate = function(this, container)
                container:Add("ax.tab.inventory")
            end
        }
    end

    buttons["tab.inventory"] = {
        Populate = function(this, container)
            container:Add("ax.tab.inventory")
        end
    }

    buttons["tab.scoreboard"] = {
        Populate = function(this, container)
            container:Add("ax.tab.scoreboard")
        end
    }

    buttons["tab.options"] = {
        Populate = function(this, container)
            container:Add("ax.tab.options")
        end
    }
end

function GM:PopulateHelpCategories(categories)
    categories["test"] = function(container)
        local filler = container:Add("DPanel")
        filler:Dock(FILL)
    end

    categories["flags"] = function(container)
        local scroller = container:Add("ax.scroller.vertical")
        scroller:Dock(FILL)
        scroller:GetVBar():SetWide(0)
        scroller.Paint = nil

        for k, v in SortedPairs(ax.flag.stored) do
            local char = ax.client:GetCharacter()
            if ( !char ) then return end

            local hasFlag = char:HasFlag(k)

            local button = scroller:Add("ax.button.flat")
            button:Dock(TOP)
            button:SetFont("ax.large.bold")
            button:SetText("")
            button:SetBackgroundAlphaHovered(1)
            button:SetBackgroundAlphaUnHovered(0.5)
            button:SetBackgroundColor(hasFlag and ax.config:Get("color.success") or ax.config:Get("color.error"))
            button.DoRightClick = function(this)
                if ( !CAMI.PlayerHasAccess(ax.client, "Parallax - Manage Flags", nil) ) then return end

                local menu = DermaMenu()
                menu:AddOption("Give Flag", function()
                    ax.command:Run("CharGiveFlags", ax.client:SteamID64(), k)
                end)

                menu:AddOption("Remove Flag", function()
                    ax.command:Run("CharTakeFlags", ax.client:SteamID64(), k)
                end)

                for _, target in player.Iterator() do
                    if ( target == ax.client ) then continue end

                    menu:AddSpacer()

                    menu:AddOption("Give Flag to " .. target:Nick(), function()
                        ax.command:Run("CharGiveFlags", target:SteamID64(), k)
                    end)
                    menu:AddOption("Remove Flag from " .. target:Nick(), function()
                        ax.command:Run("CharTakeFlags", target:SteamID64(), k)
                    end)
                end

                menu:Open()
            end

            local key = button:Add("ax.text")
            key:Dock(LEFT)
            key:DockMargin(ScreenScale(8), 0, 0, 0)
            key:SetFont("ax.large.bold")
            key:SetText(k)

            local seperator = button:Add("ax.text")
            seperator:Dock(LEFT)
            seperator:SetFont("ax.large")
            seperator:SetText(" - ")

            local description = button:Add("ax.text")
            description:Dock(LEFT)
            description:SetFont("ax.large")
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
        local scroller = container:Add("ax.scroller.vertical")
        scroller:Dock(FILL)
        scroller:GetVBar():SetWide(0)
        scroller.Paint = nil

        for commandName, commandInfo in SortedPairs(ax.command:GetAll()) do
            if ( !istable(commandInfo) ) then
                ax.util:PrintError("Command '" .. commandName .. "' is not a valid table.")
                continue
            end

            if ( commandInfo.ChatType and ax.chat:Get(commandInfo.ChatType) ) then
                continue -- Skip commands that are chat types
            end

            local panel = scroller:Add("DPanel")
            panel:Dock(TOP)
            panel:DockMargin(0, 0, 0, 8)
            panel.Paint = function(this, width, height)
                surface.SetDrawColor(30, 30, 30, 200)
                surface.DrawRect(0, 0, width, height)
            end

            local nameLabel = panel:Add("ax.text")
            nameLabel:SetFont("ax.regular.bold")
            nameLabel:SetText(commandName, true)
            nameLabel:Dock(TOP)
            nameLabel:DockMargin(8, 0, 8, 0)

            local description = commandInfo.Description
            if ( !description or description == "" ) then
                description = "No description provided."
            end

            local descriptionLabel = panel:Add("ax.text")
            descriptionLabel:SetFont("ax.small")
            descriptionLabel:SetText(description, true)
            descriptionLabel:Dock(TOP)
            descriptionLabel:DockMargin(8, -4, 8, 0)

            if ( istable(commandInfo.Arguments) ) then
                local argumentsLabel = panel:Add("ax.text")
                argumentsLabel:SetFont("ax.small")
                argumentsLabel:SetText("Useable Arguments:", true)
                argumentsLabel:Dock(TOP)
                argumentsLabel:DockMargin(8, -4, 8, 0)

                for i = 1, #commandInfo.Arguments do
                    local data = commandInfo.Arguments[i]
                    if ( !istable(data) ) then
                        ax.util:PrintError("Command argument at index " .. i .. " from command '" .. commandName .. "' is not a table. Expected a table with 'Type' and 'ErrorMsg' fields.")
                        data = { Type = "Unknown", ErrorMsg = "No error message provided." }
                    end

                    local argLabel = panel:Add("ax.text")
                    argLabel:SetFont("ax.small")
                    argLabel:SetText(i .. ": " .. ax.util:FormatType(data.Type) .. " - " .. (data.ErrorMsg or "No error message provided."), true)
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
    net.Start("ax.client.chatbox.text.changed")
        net.WriteString(text)
    net.SendToServer()

    -- Notify the command system about the text change
    local command = ax.command:Get(ax.gui.chatbox:GetChatType())
    if ( command and command.OnChatTextChanged ) then
        command:OnTextChanged(text)
    end

    -- Notify the chat system about the text change
    local chat = ax.chat:Get(ax.gui.chatbox:GetChatType())
    if ( chat and chat.OnChatTextChanged ) then
        chat:OnTextChanged(text)
    end
end

function GM:ChatboxOnChatTypeChanged(newType, oldType)
    net.Start("ax.client.chatbox.type.changed")
        net.WriteString(newType)
        net.WriteString(oldType)
    net.SendToServer()

    -- Notify the command system about the chat type change
    local command = ax.command:Get(newType)
    if ( command and command.OnChatTypeChanged ) then
        command:OnChatTypeChanged(newType, oldType)
    end

    -- Notify the chat system about the chat type change
    local chat = ax.chat:Get(newType)
    if ( chat and chat.OnChatTypeChanged ) then
        chat:OnChatTypeChanged(newType, oldType)
    end
end

function GM:PlayerBindPress(client, bind, pressed)
    bind = bind:lower()

    if ( ax.util:FindString(bind, "messagemode") and pressed ) then
        ax.gui.chatbox:SetVisible(true)

        for i = 1, #ax.chat.messages do
            local pnl = ax.chat.messages[i]
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
    for i = 1, #ax.gui do
        local v = ax.gui[i]
        if ( ispanel(v) and IsValid(v) ) then
            local className = v:GetClassName()
            v:Remove()

            -- Attempt to recreate the GUI element
            if ( className == "ax.mainmenu" ) then
                vgui.Create("ax.mainmenu")
            elseif ( className == "ax.tab" ) then
                vgui.Create("ax.tab")
            end
        end
    end

    hook.Run("LoadFonts")
end

function GM:SpawnMenuOpen()
    local character = ax.client:GetCharacter()
    if ( !character ) then return end

    if ( !character:HasFlag("s") ) then
        return false
    end

    return true
end

function GM:PostOptionsLoad(instancesTable)
    for uniqueID, data in pairs(ax.option.stored) do
        if ( data.Type == ax.types.number and data.IsKeybind ) then
            ax.binds[data.Default] = uniqueID
        end
    end

    for optionName, value in pairs(instancesTable) do
        local optionData = ax.option.stored[optionName]
        if ( !istable(optionData) ) then continue end

        if ( optionData.Type == ax.types.number and optionData.IsKeybind ) then
            ax.binds[value] = optionName
        end
    end
end

function GM:PrePopulateEntityTooltip(entity)
    local funcCall = entity.ShouldPopulateTooltip
    if ( isfunction(funcCall) ) then
        return funcCall(entity)
    elseif ( isbool(funcCall) ) then
        return funcCall
    end
end