--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

function GM:Think()
    if ( !vgui.CursorVisible() ) then
        if ( !IsValid(ax.gui.main) and input.IsKeyDown(KEY_F1) ) then
            vgui.Create("ax.main")
        end

        hook.Run("OnMenuInputCheck")
    end
end

function GM:ScoreboardShow()
    if ( hook.Run("ShouldShowTab") == false ) then return end

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

function GM:OnEntityCreated(entity)
    if ( entity == LocalPlayer() and !IsValid(ax.client) ) then
        ax.client = LocalPlayer()

        LocalPlayer = function() return ax.client end

        hook.Run("OnClientCached", ax.client)
    end
end

function GM:PlayerStartVoice()
    if ( IsValid(g_VoicePanelList) ) then
        g_VoicePanelList:Remove()
    end
end

function GM:ShouldDrawVignette()
    return ax.config:Get( "interface.vignette.enabled", true )
end

local vignette = ax.util:GetMaterial("parallax/overlays/vignette.png", "smooth noclamp")
local vignetteColor = Color(0, 0, 0, 255)
function GM:HUDPaintBackground()
    if ( hook.Run("ShouldDrawVignette") != false ) then
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
            vignetteColor.a = Lerp(FrameTime(), vignetteColor.a, 200)
        else
            vignetteColor.a = Lerp(FrameTime(), vignetteColor.a, 255)
        end

        if ( hook.Run("ShouldDrawDefaultVignette") != false ) then
            ax.render.DrawMaterial(0, 0, 0, scrW, scrH, vignetteColor, vignette)
        end

        hook.Run("DrawVignette", 1 - (vignetteColor.a / 255))
    end
end

function GM:DrawVignette(fraction)
end

function GM:PostRenderCenter(width, height, client)
    ax.notification:Render()

    local shouldDraw = hook.Run("ShouldDrawVersionWatermark")
    if ( shouldDraw != false and ax.version and ax.version.version ) then
        local versionText = string.format("Parallax v%s", ax.version.version)
        if ( ax.version.commitHash ) then
            versionText = versionText .. " (" .. ax.version.commitHash .. ")"
        end

        draw.SimpleText(versionText, "ax.tiny.bold", ax.util:ScreenScale(4), height - ax.util:ScreenScaleH(4), Color(255, 255, 255, 50), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    end
end

function GM:HUDDrawTargetID()
    return false
end

local hide = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudSuit"] = true,
    ["CHudChat"] = true,
    ["CHudAmmo"] = true,
    ["CHudSecondaryAmmo"] = true,
    ["CHudCrosshair"] = true,
}

local cameraShow = {
    ["CHudWeapon"] = true,
    ["CHudWeaponSelection"] = true,
}

function GM:HUDShouldDraw(name)
    if ( hide[name] ) then return false end

    local client = ax.client
    if ( !IsValid(client) ) then return false end
    if ( client:GetViewEntity() != client and cameraShow[name] != true ) then return false end
    if ( gui.IsGameUIVisible() ) then return false end

    local weapon = client:GetActiveWeapon()
    if ( IsValid(weapon) and weapon:GetClass() == "gmod_camera" and cameraShow[name] != true ) then return false end

    return true
end

local targetIDTarget = nil
local targetIDAlpha = 0
local targetIDTargetAlpha = 0
local function DrawTargetID(client)
    local trace = util.TraceLine({
        start = client:EyePos(),
        endpos = client:EyePos() + client:EyeAngles():Forward() * 384,
        filter = client
    })

    local target = trace.Entity
    local shouldShow = false

    if ( IsValid(target) and target:IsPlayer() and target != client ) then
        local distance = client:GetPos():Distance(target:GetPos())
        if ( distance <= 128 ) then
            shouldShow = true
            targetIDTarget = target
        end
    end

    targetIDTargetAlpha = shouldShow and 255 or 0
    targetIDAlpha = Lerp(math.Clamp(FrameTime() * 8, 0, 1), targetIDAlpha, targetIDTargetAlpha)

    if ( targetIDAlpha > 5 and IsValid(targetIDTarget) ) then
        local character = targetIDTarget:GetCharacter()
        local displayName = character and character.vars.name or targetIDTarget:Name()
        local description = character and character.vars.description or ""

        local maxWidth = ax.util:ScreenScale(128)
        local descriptionLines = {}

        if ( description and description != "" ) then
            description = ax.util:CapTextWord(description, ax.util:ScreenScale(32))
            descriptionLines = ax.util:GetWrappedText(description, "ax.small.italic", maxWidth)
        end

        local nameFont = "ax.large.bold"
        local descFont = "ax.small.italic"

        surface.SetFont(nameFont)
        local nameW, nameH = surface.GetTextSize(displayName or "")
        nameW = nameW or 100
        nameH = nameH or 16

        local descW, descH = 0, 0
        local totalDescH = 0
        if ( #descriptionLines > 0 ) then
            surface.SetFont(descFont)
            for i = 1, #descriptionLines do
                local lineW, lineH = surface.GetTextSize(descriptionLines[i] or "")
                descW = math.max(descW, lineW or 0)
                totalDescH = totalDescH + (lineH or 14)
            end
            descH = totalDescH + ax.util:ScreenScale(1) * (#descriptionLines - 1)
        end

        local padding = ax.util:ScreenScale(4)
        local panelW = math.max(nameW or 100, descW or 0) + padding * 2
        local panelH = (nameH or 16) + (#descriptionLines > 0 and descH + ax.util:ScreenScale(2) or 0) + padding * 2

        local targetPos = targetIDTarget:GetPos() + targetIDTarget:OBBCenter() * 1.5
        local screenPos = targetPos:ToScreen()

        local panelX = math.Clamp(screenPos.x - panelW / 2, padding, ScrW() - panelW - padding)
        local panelY = math.Clamp(screenPos.y - panelH / 2, padding, ScrH() - panelH - padding)

        local alpha = math.Round(targetIDAlpha)
        local nameColor = ColorAlpha(team.GetColor(targetIDTarget:Team()), alpha)
        local descColor = Color(200, 200, 200, alpha * 0.9)

        local borderColor = Color(255, 255, 255, alpha * 0.1)
        ax.render.DrawOutlined(24, panelX, panelY, panelW, panelH, borderColor, 1)

        local textY = panelY + padding
        surface.SetFont(nameFont)
        surface.SetTextColor(nameColor)
        surface.SetTextPos(panelX + panelW / 2 - nameW / 2, textY)
        surface.DrawText(displayName or "")

        if ( #descriptionLines > 0 ) then
            textY = textY + (nameH or 16)
            surface.SetFont(descFont)
            surface.SetTextColor(descColor)

            for i = 1, #descriptionLines do
                local line = descriptionLines[i] or ""
                local lineW, lineH = surface.GetTextSize(line)
                lineW = lineW or 0
                lineH = lineH or 14

                surface.SetTextPos(panelX + panelW / 2 - lineW / 2, textY)
                surface.DrawText(line)
                textY = textY + lineH - ax.util:ScreenScaleH(2)
            end
        end
    end
end

local healthIcon = ax.util:GetMaterial("parallax/icons/heart.png", "smooth mips")
local healthColor = Color(255, 150, 150, 200)
local armorIcon = ax.util:GetMaterial("parallax/icons/shield.png", "smooth mips")
local armorColor = Color(100, 150, 255, 200)
local speakingIcon = ax.util:GetMaterial("parallax/icons/volume-full.png", "smooth mips")
function GM:HUDPaintCenter(width, height, client)
    if ( !IsValid(client) or !client:Alive() ) then return end

    local barWidth, barHeight = ax.util:ScreenScale(64), ax.util:ScreenScaleH(8)
    local barX, barY = ax.util:ScreenScale(8), ax.util:ScreenScaleH(8) + barHeight / 2

    local shouldDraw = hook.Run("ShouldDrawHealthHUD")
    if ( shouldDraw != false ) then
        if ( client:Health() > 0 and ax.option:Get("hud.bar.health.show", true) ) then
            ax.render.DrawMaterial(0, barX, barY - barHeight / 2, barHeight * 2, barHeight * 2, healthColor, healthIcon)
            barX = barX + barHeight * 2 + ax.util:ScreenScale(4)

            ax.render.Draw(barHeight, barX, barY, barWidth, barHeight, Color(0, 0, 0, 150))

            local targetHealth = math.Clamp(client:Health(), 0, 100)
            client.axHealth = client.axHealth or targetHealth
            client.axHealth = Lerp(math.Clamp(FrameTime() * 10, 0, 1), client.axHealth, targetHealth)

            local healthFraction = client.axHealth / 100
            local fillWidth = math.max(0, barWidth * healthFraction - ax.util:ScreenScale(2))

            ax.render.Draw(barHeight, barX + ax.util:ScreenScale(1), barY + ax.util:ScreenScaleH(1), fillWidth, barHeight - ax.util:ScreenScaleH(2), healthColor)

            barX = barX + barWidth + ax.util:ScreenScale(8)
        else
            client.axHealth = 0
        end
    end

    shouldDraw = hook.Run("ShouldDrawArmorHUD")
    if ( shouldDraw != false ) then
        if ( client:Armor() > 0 and ax.option:Get("hud.bar.armor.show", true) ) then
            ax.render.DrawMaterial(0, barX, barY - barHeight / 2, barHeight * 2, barHeight * 2, armorColor, armorIcon)
            barX = barX + barHeight * 2 + ax.util:ScreenScale(4)

            ax.render.Draw(barHeight, barX, barY, barWidth, barHeight, Color(0, 0, 0, 150))

            local targetArmor = math.Clamp(client:Armor(), 0, 100)
            client.axArmor = client.axArmor or targetArmor
            client.axArmor = Lerp(math.Clamp(FrameTime() * 10, 0, 1), client.axArmor, targetArmor)

            local armorFraction = client.axArmor / 100
            local armorFillWidth = math.max(0, barWidth * armorFraction - ax.util:ScreenScale(2))

            ax.render.Draw(barHeight, barX + ax.util:ScreenScale(1), barY + ax.util:ScreenScaleH(1), armorFillWidth, barHeight - ax.util:ScreenScaleH(2), armorColor)
        else
            client.axArmor = 0
        end
    end

    shouldDraw = hook.Run("ShouldDrawVoiceChatIcon")
    if ( shouldDraw != false and client:IsSpeaking() ) then
        local iconSize = 64 * (1 + client:VoiceVolume())
        local iconX = width - ax.util:ScreenScale(8) - iconSize
        local iconY = height / 2 - iconSize / 2

        local iconColor = Color(255, 255, 255, 200)

        ax.render.DrawMaterial(0, iconX, iconY, iconSize, iconSize, iconColor, speakingIcon)
    end

    shouldDraw = hook.Run("ShouldDrawTargetID")
    if ( shouldDraw != false ) then
        DrawTargetID(client)
    end
end

function GM:PostDrawTranslucentRenderables(depth, skybox)
    if ( skybox ) then return end

    local ft = FrameTime()
    local curTime = CurTime()
    for _, client in player.Iterator() do
        if ( !IsValid(client) or !client:Alive() or client == ax.client or !client:IsSpeaking() ) then continue end

        local headBone = client:LookupBone("ValveBiped.Bip01_Head1")
        if ( !headBone ) then continue end

        local boneMatrix = client:GetBoneMatrix(headBone)
        if ( !boneMatrix ) then continue end

        local pos = boneMatrix:GetTranslation()
        pos = pos + Vector(0, 0, 16)

        local eyeAngles = EyeAngles()
        local angle = Angle(0, eyeAngles.y - 90, 90)
        local size = 64 * (1 + client:VoiceVolume() * 2)

        client.axVoiceIconSize = client.axVoiceIconSize or size
        client.axVoiceIconSize = Lerp(math.Clamp(ft * 10, 0, 1), client.axVoiceIconSize, size)
        size = client.axVoiceIconSize

        pos.z = pos.z + math.sin(curTime) * size / 96

        cam.Start3D2D(pos, angle, 0.1)
            ax.render.DrawMaterial(0, -size / 2, -size / 2, size, size, Color(255, 255, 255, 200), speakingIcon)
        cam.End3D2D()
    end
end

function GM:DrawDeathNotice(_x, _y)
end

ax.viewstack:RegisterModifier("ragdoll", function(client, view)
    if ( !IsValid(client) or client:InVehicle() ) then return end

    local ragdoll = client:GetRagdollEntity()
    if ( !IsValid(ragdoll) or client:Alive() ) then return end
    local boneId = ragdoll:LookupBone("ValveBiped.Bip01_Head1")
    if ( !isnumber( boneId ) ) then
        ax.util:PrintDebug("Player ragdoll has no \"ValveBiped.Bip01_Head1\" bone!")
        return
    end

    local matrix = ragdoll:GetBoneMatrix(boneId)
    local pos = matrix:GetTranslation()
    local ang = matrix:GetAngles()

    ang:RotateAroundAxis(ang:Up(), 270)
    ang:RotateAroundAxis(ang:Forward(), 270)

    return {
        origin = pos + ang:Forward() * 10,
        angles = ang,
        fov = fov
    }
end, 10)

local cameraFOV = CreateConVar("ax_camera_fov", "90", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Set the camera FOV when using a view entity.")
ax.viewstack:RegisterModifier("camera", function(client, view)
    if ( !IsValid(client) or client:InVehicle() ) then return end

    local viewEntity = client:GetViewEntity()
    if ( IsValid(viewEntity) and viewEntity != client and viewEntity:GetClass() != "gmod_camera" ) then
        local pos = viewEntity:GetPos()
        local ang = viewEntity:GetAngles()

        return {
            origin = pos,
            angles = ang,
            fov = cameraFOV:GetFloat()
        }
    end
end, 99)

ax.viewstack:RegisterViewModelModifier("swep", function(weapon, patch)
    if ( !IsValid(weapon) or !weapon.GetViewModelPosition ) then return end

    local pos, ang = weapon:GetViewModelPosition(patch.pos, patch.ang)

    return {
        pos = pos,
        ang = ang
    }
end, 99)
