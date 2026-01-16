--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

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

function GM:PlayerStartVoice(speaker, speakerIndex) -- speakerIndex only appears non-locally when the speaker speaks for the first time
    if ( IsValid(g_VoicePanelList) ) then
        g_VoicePanelList:Remove()
    end

    ax.net:Start("voice.start", speaker)
end

function GM:PlayerEndVoice(speaker)
    ax.net:Start("voice.end", speaker)
end

function GM:ShouldDrawVignette()
    return ax.config:Get("interface.vignette.enabled", true)
end

local vignette = ax.util:GetMaterial("parallax/overlays/vignette.png", "smooth noclamp")
local vignetteColor = Color(0, 0, 0, 255)
function GM:HUDPaintBackground()
    local client = ax.client
    if ( !IsValid(client) ) then return end

    if ( !client:Alive() ) then
        ax.render.Draw(0, 0, 0, ScrW(), ScrH(), Color(0, 0, 0, 255))
        return
    end

    if ( hook.Run("ShouldDrawVignette") != false ) then
        local scrW, scrH = ScrW(), ScrH()
        local trace = util.TraceLine({
            start = client:GetShootPos(),
            endpos = client:GetShootPos() + client:GetAimVector() * 96,
            filter = client,
            mask = MASK_SHOT
        })

        if ( trace.Hit and trace.HitPos:DistToSqr(client:GetShootPos()) < 96 * 96 ) then
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

function GM:PostRenderCurvy()
    local _, height = ScrW(), ScrH()
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
    if ( gui.IsGameUIVisible() ) then return false end

    local client = ax.client
    if ( !IsValid(client) ) then return false end

    local viewEntity = client:GetViewEntity()
    if ( viewEntity and viewEntity:GetClass():find("camera") and cameraShow[name] != true ) then return false end

    local weapon = client:GetActiveWeapon()
    if ( IsValid(weapon) and weapon:GetClass() == "gmod_camera" and cameraShow[name] != true ) then return false end

    return true
end

local healthIcon = ax.util:GetMaterial("parallax/icons/heart.png", "smooth mips")
local healthColor = Color(255, 150, 150, 200)
local armorIcon = ax.util:GetMaterial("parallax/icons/shield.png", "smooth mips")
local armorColor = Color(100, 150, 255, 200)
local speakingIcon = ax.util:GetMaterial("parallax/icons/volume-full.png", "smooth mips")
function GM:HUDPaintCurvy()
    local client = ax.client
    if ( !IsValid(client) or !client:Alive() ) then return end

    local width, height = ScrW(), ScrH()

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
end

local targetData = {}
function GM:HUDPaint()
    local client = ax.client
    if ( !IsValid(client) or !client:Alive() ) then return end

    local trace = util.TraceHull({
        start = client:GetShootPos(),
        endpos = client:GetShootPos() + client:GetAimVector() * 96,
        filter = client,
        mins = Vector(-4, -4, -4),
        maxs = Vector(4, 4, 4),
        mask = MASK_SHOT
    })

    local target = trace.Entity
    targetData[target:EntIndex()] = targetData[target:EntIndex()] or { lastSeen = 0, alpha = 0 }

    if ( IsValid(target) and target != client ) then
        targetData[target:EntIndex()].lastSeen = CurTime()
    end

    local ft = FrameTime()
    for entIndex, data in pairs(targetData) do
        local ent = Entity(entIndex)
        if ( !IsValid(ent) ) then
            targetData[entIndex] = nil
            continue
        end

        local timeSinceSeen = CurTime() - data.lastSeen
        if ( timeSinceSeen < 0.1 ) then
            data.alpha = ax.ease:Lerp("InOutQuad", ft * 10, data.alpha, 255)
        else
            data.alpha = ax.ease:Lerp("OutQuad", ft * 10, data.alpha, 0)
        end

        if ( data.alpha > 1 ) then
            local displayText, displayColor = hook.Run("GetEntityDisplayText", ent)
            if ( isstring(displayText) ) then
                local pos = ent:LocalToWorld(ent:OBBCenter())
                if ( ent:IsPlayer() ) then
                    pos = pos + Vector(0, 0, 16)
                end

                local screenPos = pos:ToScreen()
                local x, y = screenPos.x, screenPos.y

                data.x = ax.ease:Lerp("InOutQuad", ft * 20, data.x or x, x)
                data.y = ax.ease:Lerp("InOutQuad", ft * 20, data.y or y, y)

                if ( !IsColor(displayColor) ) then
                    displayColor = Color(255, 255, 255)
                end

                draw.SimpleText(displayText, "ax.small.bold", data.x + 2, data.y + 2, Color(0, 0, 0, data.alpha / 2), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(displayText, "ax.small.bold", data.x, data.y, ColorAlpha(displayColor, data.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                hook.Run("HUDPaintTargetIDExtra", ent, data.x, data.y, data.alpha)
            end
        else
            data.x = nil
            data.y = nil
        end
    end
end

function GM:GetEntityDisplayText(entity)
    if ( entity:IsPlayer() ) then
        return entity:Nick(), team.GetColor(entity:Team())
    elseif ( entity:GetClass() == "ax_item" ) then
        local itemTable = entity:GetItemTable()
        if ( itemTable ) then
            return itemTable:GetName()
        end
    end
end

function GM:HUDPaintTargetIDExtra(entity, x, y, alpha)
    -- Draw descriptions for items and characters
    local desc
    local itemTable = entity.GetItemTable and entity:GetItemTable() or nil
    if ( itemTable and itemTable:GetDescription() ) then
        desc = itemTable:GetDescription()
    elseif ( entity.GetCharacter and entity:GetCharacter() ) then
        desc = entity:GetCharacter():GetDescription()
    end

    if ( desc ) then
        local wrapped = ax.util:GetWrappedText(desc, "ax.tiny", ax.util:ScreenScale(128))
        for i, line in ipairs(wrapped) do
            draw.SimpleText(line, "ax.tiny", x + 1, y + ax.util:ScreenScaleH(6) * i + 1, Color(0, 0, 0, alpha / 4), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(line, "ax.tiny", x, y + ax.util:ScreenScaleH(6) * i, Color(255, 255, 255, alpha / 2), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
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

function GM:OnPauseMenuShow()
    if ( IsValid(ax.gui.main) and ax.client:GetCharacter() ) then
        ax.gui.main:Remove()
    end
end

ax.viewstack:RegisterModifier("ragdoll", function(client, patch)
    if ( !IsValid(client) or client:InVehicle() ) then return end

    local ragdollIndex = client:GetRelay("ragdoll.index", -1)
    local ragdoll = Entity(ragdollIndex)
    if ( !IsValid(ragdoll) or client:Alive() ) then return end

    local boneId = ragdoll:LookupBone("ValveBiped.Bip01_Head1")
    if ( !isnumber(boneId) ) then
        ax.util:PrintDebug("Player ragdoll has no \"ValveBiped.Bip01_Head1\" bone!")
        return
    end

    local matrix = ragdoll:GetBoneMatrix(boneId)
    if ( !matrix ) then
        ax.util:PrintDebug("Failed to get bone matrix for player ragdoll head bone!")
        return
    end

    local pos = matrix:GetTranslation()
    local ang = matrix:GetAngles()

    ang:RotateAroundAxis(ang:Up(), 270)
    ang:RotateAroundAxis(ang:Forward(), 270)

    return { origin = pos + ang:Forward() * 10, angles = ang, fov = patch.fov }
end, 1)

local cameraFOV = CreateConVar("ax_camera_fov", "90", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Set the camera FOV when using a view entity.")
ax.viewstack:RegisterModifier("camera", function(client, patch)
    if ( !IsValid(client) or client:InVehicle() ) then return end

    local viewEntity = client:GetViewEntity()
    if ( IsValid(viewEntity) and viewEntity != client and viewEntity:GetClass() != "gmod_camera" ) then
        local pos = viewEntity:GetPos()
        local ang = viewEntity:GetAngles()

        return { origin = pos, angles = ang, fov = cameraFOV:GetFloat() }
    end
end, 99)

ax.viewstack:RegisterModifier("swep", function(client, patch)
    local weapon = client:GetActiveWeapon()
    if ( !IsValid(weapon) or !weapon.TranslateFOV ) then return end

    local fov = weapon:TranslateFOV(patch.fov)

    return { origin = patch.origin, angles = patch.angles, fov = fov }
end, 1)

ax.viewstack:RegisterViewModelModifier("swep", function(weapon, patch)
    if ( !IsValid(weapon) or !weapon.GetViewModelPosition ) then return end

    local pos, ang = weapon:GetViewModelPosition(patch.pos, patch.ang)

    return { pos = pos, ang = ang }
end, 1)
