--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

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

function GM:OnEntityCreated(entity)
    if ( entity == LocalPlayer() and !IsValid(ax.client) ) then
        ax.client = LocalPlayer()

        hook.Run("OnClientCached", ax.client)
    end
end

function GM:PlayerStartVoice()
    if ( IsValid(g_VoicePanelList) ) then
        g_VoicePanelList:Remove()
    end
end

function GM:PostRenderCurvy(width, height, client, isCurved)
    ax.notification:Render()
end

local hide = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudSuit"] = true,
    ["CHudChat"] = true,
    ["CHudAmmo"] = true,
    ["CHudSecondaryAmmo"] = true,
    ["CHudCrosshair"] = true
}

function GM:HUDShouldDraw(name)
    if ( hide[name] ) then return false end

    local client = ax.client
    if ( !IsValid(client) ) then return false end
    if ( client:GetViewEntity() != client ) then return false end
    if ( gui.IsGameUIVisible() ) then return false end

    local weapon = client:GetActiveWeapon()
    if ( IsValid(weapon) and weapon:GetClass() == "gmod_camera" ) then return false end

    return true
end

local healthIcon = ax.util:GetMaterial("parallax/icons/hud/health.png", "smooth mips")
local healthColor = Color(255, 150, 150, 200)
local armorIcon = ax.util:GetMaterial("parallax/icons/hud/armor.png", "smooth mips")
local armorColor = Color(100, 150, 255, 200)
local talkingIcon = ax.util:GetMaterial("parallax/icons/hud/talking.png", "smooth mips")
local speakingIcon = ax.util:GetMaterial("parallax/icons/hud/speaking.png", "smooth mips")
function GM:HUDPaintCurvy(width, height, client, isCurved)
    if ( !IsValid(client) ) then return end

    local shouldDraw = hook.Run("ShouldDrawHealthHUD")
    if ( shouldDraw != false ) then
        local barWidth, barHeight = ScreenScale(64), ScreenScaleH(8)
        local barX, barY = ScreenScale(8), ScreenScaleH(8) + barHeight / 2

        -- Draw health icon
        ax.render.DrawMaterial(0, barX, barY - barHeight / 2, barHeight * 2, barHeight * 2, healthColor, healthIcon)
        barX = barX + barHeight * 2 + ScreenScale(4)

        -- Draw health bar background
        ax.render.Draw(barHeight, barX, barY, barWidth, barHeight, Color(0, 0, 0, 150))

        -- Interpolated health value for smooth transitions
        local targetHealth = math.Clamp(client:Health(), 0, 100)
        client._axCurvyHealth = client._axCurvyHealth or targetHealth
        client._axCurvyHealth = Lerp(math.Clamp(FrameTime() * 10, 0, 1), client._axCurvyHealth, targetHealth)

        local healthFraction = client._axCurvyHealth / 100
        local fillWidth = math.max(0, barWidth * healthFraction - ScreenScale(2))

        -- Draw health bar fill using interpolated value
        ax.render.Draw(barHeight, barX + ScreenScale(1), barY + ScreenScaleH(1), fillWidth, barHeight - ScreenScaleH(2), healthColor)

        -- Draw armor icon and bar if player has armor
        if ( client:Armor() > 0 ) then
            barX = barX + barWidth + ScreenScale(8)

            ax.render.DrawMaterial(0, barX, barY - barHeight / 2, barHeight * 2, barHeight * 2, armorColor, armorIcon)
            barX = barX + barHeight * 2 + ScreenScale(4)

            ax.render.Draw(barHeight, barX, barY, barWidth, barHeight, Color(0, 0, 0, 150))

            local targetArmor = math.Clamp(client:Armor(), 0, 100)
            client._axCurvyArmor = client._axCurvyArmor or targetArmor
            client._axCurvyArmor = Lerp(math.Clamp(FrameTime() * 10, 0, 1), client._axCurvyArmor, targetArmor)

            local armorFraction = client._axCurvyArmor / 100
            local armorFillWidth = math.max(0, barWidth * armorFraction - ScreenScale(2))

            ax.render.Draw(barHeight, barX + ScreenScale(1), barY + ScreenScaleH(1), armorFillWidth, barHeight - ScreenScaleH(2), armorColor)
        end

        -- Draw voice chat icon if player is talking
        if ( client:IsSpeaking() ) then
            local iconSize = barHeight * 2
            local iconX = width - ScreenScale(8) - iconSize
            local iconY = height / 2 - iconSize / 2

            local iconColor = Color(255, 255, 255, 200)
            local iconMaterial = talkingIcon
            if ( client:IsSpeaking() ) then
                iconMaterial = speakingIcon
            end

            ax.render.DrawMaterial(0, iconX, iconY, iconSize, iconSize, iconColor, iconMaterial)
        end

        -- Draw talking icon if player is typing
        if ( IsValid(ax.gui.chatbox) and ax.gui.chatbox:GetAlpha() >= 255 ) then
            local iconSize = barHeight * 2
            local iconX = width - ScreenScale(8) - iconSize
            local iconY = height / 2 - iconSize / 2 + (client:IsSpeaking() and iconSize + ScreenScale(4) or 0)

            ax.render.DrawMaterial(0, iconX, iconY, iconSize, iconSize, Color(255, 255, 255, 200), talkingIcon)
        end
    end
end

function GM:PostDrawTranslucentRenderables(depth, skybox)
    if ( skybox ) then return end

    -- Draw voice chat icons above players' heads
    for _, client in player.Iterator() do
        if ( !IsValid(client) or client == LocalPlayer() ) then continue end
        if ( !client:IsSpeaking() ) then continue end

        local headBone = client:LookupBone("ValveBiped.Bip01_Head1")
        if ( !headBone ) then continue end

        local boneMatrix = client:GetBoneMatrix(headBone)
        if ( !boneMatrix ) then continue end

        local pos = boneMatrix:GetTranslation()
        pos = pos + Vector(0, 0, 16)

        local eyeAngles = EyeAngles()
        local angle = Angle(0, eyeAngles.y - 90, 90)
        local size = 96 * (1 + client:VoiceVolume())

        client._axCurvyVoiceIconSize = client._axCurvyVoiceIconSize or size
        client._axCurvyVoiceIconSize = Lerp(math.Clamp(FrameTime() * 10, 0, 1), client._axCurvyVoiceIconSize, size)
        size = client._axCurvyVoiceIconSize

        pos.z = pos.z + math.sin(CurTime()) * size / 96

        cam.Start3D2D(pos, angle, 0.1)
            local iconMaterial = talkingIcon
            if ( client:IsSpeaking() ) then
                iconMaterial = speakingIcon
            end

            ax.render.DrawMaterial(0, -size / 2, -size / 2, size, size, Color(255, 255, 255, 200), iconMaterial)
        cam.End3D2D()
    end
end

ax.viewstack:RegisterModifier("ragdoll", function(client, view)
    if ( !IsValid(client) or client:InVehicle() ) then return end

    local ragdollIndex = client:GetRelay("ax.ragdoll.index", -1)
    if ( ragdollIndex != -1 and !client:Alive() ) then
        local ragdoll = ents.GetByIndex(ragdollIndex)
        if ( !IsValid(ragdoll) ) then
            client:SetRelay("ax.ragdoll.index", -1)
            return
        end

        local matrix = ragdoll:GetBoneMatrix(ragdoll:LookupBone("ValveBiped.Bip01_Head1"))
        local pos = matrix:GetTranslation()
        local ang = matrix:GetAngles()

        ang:RotateAroundAxis(ang:Up(), 270)
        ang:RotateAroundAxis(ang:Forward(), 270)

        return {
            origin = pos,
            angles = ang,
            fov = view.fov
        }
    end
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
