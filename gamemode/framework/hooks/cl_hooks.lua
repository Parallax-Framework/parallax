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

local vignette = ax.util:GetMaterial("parallax/overlays/vignette.png", "noclamp smooth")
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

function GM:PostRenderCurvy(width, height, client, isCurved)
    ax.notification:Render()
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

-- Not sure if I like this
local targetIDTarget = nil
local targetIDAlpha = 0
local targetIDTargetAlpha = 0
local function DrawTargetID()
    local client = ax.client
    if ( !IsValid(client) ) then return end
    
    -- Perform a trace to see what we're looking at
    local trace = util.TraceLine({
        start = client:EyePos(),
        endpos = client:EyePos() + client:EyeAngles():Forward() * 400,
        filter = client
    })
    
    local target = trace.Entity
    local shouldShow = false
    
    -- Check if we're looking at a valid player
    if ( IsValid(target) and target:IsPlayer() and target != client ) then
        -- Check distance and angle for smooth interaction
        local distance = client:GetPos():Distance(target:GetPos())
        if ( distance <= 128 ) then
            shouldShow = true
            targetIDTarget = target
        end
    end
    
    -- Update target alpha with smooth transitions
    targetIDTargetAlpha = shouldShow and 255 or 0
    targetIDAlpha = Lerp(math.Clamp(FrameTime() * 8, 0, 1), targetIDAlpha, targetIDTargetAlpha)
    
    -- Only draw if we have some alpha
    if ( targetIDAlpha > 5 and IsValid(targetIDTarget) ) then
        local scrW, scrH = ScrW(), ScrH()
        local centerX, centerY = scrW * 0.5, scrH * 0.5
        
        -- Get character information
        local character = targetIDTarget:GetCharacter()
        local displayName = character and character.vars.name or targetIDTarget:Name()
        local description = character and character.vars.description or ""
        
        -- Wrap and cap description text
        local maxWidth = ScreenScale(128) -- Maximum width for description
        local descriptionLines = {}
        
        if ( description and description != "" ) then
            -- First cap the description to a reasonable length
            description = ax.util:CapTextWord(description, ScreenScale(32))
            -- Then wrap it to fit within our max width
            descriptionLines = ax.util:GetWrappedText(description, "ax.small.italic", maxWidth)
        end
        
        -- Calculate text dimensions with fallback fonts
        local nameFont = "ax.large.bold"
        local descFont = "ax.small.italic"
        
        surface.SetFont(nameFont)
        local nameW, nameH = surface.GetTextSize(displayName or "")
        nameW = nameW or 100
        nameH = nameH or 16
        
        -- Calculate description dimensions
        local descW, descH = 0, 0
        local totalDescH = 0
        if ( #descriptionLines > 0 ) then
            surface.SetFont(descFont)
            for i = 1, #descriptionLines do
                local lineW, lineH = surface.GetTextSize(descriptionLines[i] or "")
                descW = math.max(descW, lineW or 0)
                totalDescH = totalDescH + (lineH or 14)
            end
            descH = totalDescH + ScreenScale(1) * (#descriptionLines - 1) -- Add spacing between lines
        end
        
        -- Calculate panel dimensions with padding
        local padding = ScreenScale(4)
        local panelW = math.max(nameW or 100, descW or 0) + padding * 2
        local panelH = (nameH or 16) + (#descriptionLines > 0 and descH + ScreenScale(2) or 0) + padding * 2
        
        -- Position above the target player in 2D space
        local targetPos = targetIDTarget:GetPos() + targetIDTarget:OBBCenter() * 1.5
        local screenPos = targetPos:ToScreen()
        
        -- Ensure the panel stays on screen
        local panelX = math.Clamp(screenPos.x - panelW / 2, padding, ScrW() - panelW - padding)
        local panelY = math.Clamp(screenPos.y - panelH / 2, padding, ScrH() - panelH - padding)
        
        -- Apply alpha for smooth fade
        local alpha = math.Round(targetIDAlpha)
        local bgColor = Color(0, 0, 0, math.min(alpha * 0.8, 200))
        local nameColor = ColorAlpha(team.GetColor(targetIDTarget:Team()), alpha)
        local descColor = Color(200, 200, 200, alpha * 0.9)
        
        -- Draw background with rounded corners
        -- ax.util:DrawBlur(24, panelX, panelY, panelW, panelH, bgColor) -- Man do I wish RNDX's blur worked here
        ax.render.Draw(24, panelX, panelY, panelW, panelH, bgColor)
        
        -- Draw subtle border
        local borderColor = Color(255, 255, 255, alpha * 0.1)
        ax.render.DrawOutlined(24, panelX, panelY, panelW, panelH, borderColor, 1)
        
        -- Draw character name
        local textY = panelY + padding
        surface.SetFont(nameFont)
        surface.SetTextColor(nameColor)
        surface.SetTextPos(panelX + panelW * 0.5 - nameW * 0.5, textY)
        surface.DrawText(displayName or "")
        
        -- Draw description lines if available
        if ( #descriptionLines > 0 ) then
            textY = textY + (nameH or 16) + ScreenScale(2)
            surface.SetFont(descFont)
            surface.SetTextColor(descColor)
            
            for i = 1, #descriptionLines do
                local line = descriptionLines[i] or ""
                local lineW, lineH = surface.GetTextSize(line)
                lineW = lineW or 0
                lineH = lineH or 14
                
                surface.SetTextPos(panelX + panelW * 0.5 - lineW * 0.5, textY)
                surface.DrawText(line)
                textY = textY + lineH + ScreenScale(1)
            end
        end
    end
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
    
    -- Draw target ID system
    DrawTargetID()

    -- Draw version watermark
    if ( ax.version and ax.version.version ) then
        local versionText = string.format("Parallax v%s", ax.version.version)
        if ( ax.version.commitHash ) then
            versionText = versionText .. " (" .. ax.version.commitHash .. ")"
        end
        
        draw.SimpleText(versionText, "ax.tiny.bold", ScreenScale(4), height - ScreenScaleH(4), Color(255, 255, 255, 50), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
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

function GM:DrawDeathNotice(_x, _y)
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
            origin = pos + ang:Forward() * 10,
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

-- Due to viewstack, it breaks the SWEP:GetViewModelPosition hook, so we have to do it ourselves
ax.viewstack:RegisterViewModelModifier("swep", function(weapon, patch)
    if ( !IsValid(weapon) or !weapon.GetViewModelPosition ) then return end

    local pos, ang = weapon:GetViewModelPosition(patch.pos, patch.ang)

    return {
        pos = pos,
        ang = ang
    }
end, 99) -- Run last
