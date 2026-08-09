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

-- print("i'm such a cool debug print!")

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

local buildingTools = {
    ["gmod_tool"] = true,
    ["weapon_physgun"] = true,
    ["weapon_physcannon"] = true,
}

local buildingBinds = {
    ["+menu"] = true,
    ["+menu_context"] = true,
}

function GM:PlayerBindPress(client, bind, pressed, code)
    local override = hook.Run("OverrideBuildMenuBind", client, bind, pressed, code)
    if ( override != nil ) then
        return override
    end

    if ( pressed and buildingBinds[bind] ) then
        if ( ax.config:Get("interface.buildmenu.requires_tools", true) == false ) then
            return false
        end

        local weapon = client:GetActiveWeapon()
        if ( type(weapon) == "Weapon" ) then
            local class = weapon:GetClass()
            if ( buildingTools[class] ) then
                return false
            end
        end

        local notifyAttempts = math.max(math.floor(tonumber(ax.config:Get("interface.buildmenu.notify_attempts", 3)) or 3), 1)
        local resetDelay = math.max(tonumber(ax.config:Get("interface.buildmenu.notify_reset_delay", 2)) or 2, 0)

        client.axMenuPressCount = (client.axMenuPressCount or 0) + 1
        client.axMenuPressTime = CurTime()

        if ( client.axMenuPressCount >= notifyAttempts ) then
            local menuName = ax.localization:GetPhrase(bind == "+menu" and "buildmenu.name.spawn" or "buildmenu.name.context")
            client:Notify(ax.localization:GetPhrase("buildmenu.requires_tools", menuName))
            client.axMenuPressCount = 0
        elseif ( resetDelay > 0 ) then
            local pressTime = client.axMenuPressTime
            timer.Simple(resetDelay, function()
                if ( ax.util:IsValidPlayer(client) and client.axMenuPressTime == pressTime ) then
                    client.axMenuPressCount = 0
                end
            end)
        else
            client.axMenuPressCount = 0
        end

        return true
    end
end

function GM:OnEntityCreated(entity)
    if ( entity == LocalPlayer() and !IsValid(ax.client) ) then
        ax.client = LocalPlayer()

        LocalPlayer = function() return ax.client end

        hook.Run("OnClientCached")
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
    if ( !ax.util:IsValidPlayer(client) ) then return end

    if ( !client:Alive() and client:GetCharacter() ) then
        ax.render.Draw(0, 0, 0, ScrW(), ScrH(), Color(0, 0, 0, 255))
        return
    end

    if ( hook.Run("ShouldDrawVignette") != false ) then
        local scrW, scrH = ScrW(), ScrH()
        local bTraceEnabled = ax.option:Get("performance.vignette.trace", true)
        local targetAlpha = 255

        if ( bTraceEnabled ) then
            local shootPos = client:GetShootPos()
            local trace = util.TraceLine({
                start = shootPos,
                endpos = shootPos + client:GetAimVector() * 96,
                filter = client,
                mask = MASK_SHOT
            })

            if ( trace.Hit and trace.HitPos:DistToSqr(shootPos) < 96 * 96 ) then
                targetAlpha = 200
            end
        end

        vignetteColor.a = ax.ease:Lerp("Linear", FrameTime(), vignetteColor.a, targetAlpha)

        if ( hook.Run("ShouldDrawDefaultVignette") != false ) then
            ax.render.DrawMaterial(0, 0, 0, scrW, scrH, vignetteColor, vignette)
        end

        hook.Run("DrawVignette", 1 - (vignetteColor.a / 255))
    end
end

function GM:DrawVignette(fraction)
end

function GM:ShouldDrawVersionWatermark()
    return ax.ENV != nil and ax.ENV:IsDev()
end

local WATERMARK_COL = Color(255, 255, 255, 50)
local LATEST_VERSION_REMOTE = LATEST_VERSION_REMOTE or nil
local VERSION_REMOTE_INTERVAL_CHECK = 30
local REMOTE_VERSION_URL = "https://raw.githubusercontent.com/Parallax-Framework/parallax/refs/heads/main/version.json"
function GM:PostRenderCurvy()
    local _, height = ScrW(), ScrH()
    ax.notification:Render()

    local shouldDraw = hook.Run("ShouldDrawVersionWatermark")
    if ( shouldDraw != false and ax.version and ax.version.data and ax.version.data.version ) then
        if ( ( self.lastRemoteVersionCheck or 0 ) < CurTime() ) then
            self.lastRemoteVersionCheck = CurTime() + VERSION_REMOTE_INTERVAL_CHECK

            http.Fetch(REMOTE_VERSION_URL, function(body)
                local success, data = pcall(util.JSONToTable, body)
                if ( success and data and data.version ) then
                    LATEST_VERSION_REMOTE = data.version
                end
            end)
        end

        local versionText = string.format("Parallax v%s", ax.version.data.version)
        if ( ax.version.data.commitHash ) then
            versionText = versionText .. " (" .. ax.version.data.commitHash .. ")"
        end

        if ( LATEST_VERSION_REMOTE and ax.version.data.version != LATEST_VERSION_REMOTE ) then
            versionText = versionText .. " - Outdated!"
        end


        draw.SimpleText(versionText, "ax.small.bold", ax.util:ScreenScale(4), height - ax.util:ScreenScaleH(4), WATERMARK_COL, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
    end
end

-- Runs after every `hook.Add` handler for this event, which puts it after the curvy module's blit and above all VGUI, so it is the correct place for anything that must cover the entire screen. Nil-guarded because framework/hooks is included before framework/interface.
function GM:PostRenderVGUI()
    if ( ax.fade ) then
        ax.fade:Render()
    end

    -- After the black, so the boot wordmark sits on top of it rather than under it.
    if ( ax.boot ) then
        ax.boot:Render()
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

    local viewEntity = ax.client:GetViewEntity()
    if ( viewEntity and viewEntity:GetClass():find("camera") and cameraShow[name] != true ) then return false end

    local weapon = ax.client:GetActiveWeapon()
    if ( type(weapon) == "Weapon" and weapon:GetClass() == "gmod_camera" and cameraShow[name] != true ) then return false end

    return true
end

local healthIcon = ax.util:GetMaterial("parallax/icons/heart.png", "smooth mips")
local healthColor = Color(255, 150, 150, 200)
local armorIcon = ax.util:GetMaterial("parallax/icons/shield.png", "smooth mips")
local armorColor = Color(100, 150, 255, 200)
local speakingIcon = ax.util:GetMaterial("parallax/icons/volume-full.png", "smooth mips")
function GM:HUDPaintCurvy()
    local client = ax.client
    if ( !ax.util:IsValidPlayer(client) or !client:Alive() ) then return end
    if ( IsValid(ax.gui.main) or IsValid(ax.gui.tab) ) then return false end

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
            client.axHealth = ax.ease:Lerp("Linear", math.Clamp(FrameTime() * 10, 0, 1), client.axHealth, targetHealth)

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
            client.axArmor = ax.ease:Lerp("Linear", math.Clamp(FrameTime() * 10, 0, 1), client.axArmor, targetArmor)

            local armorFraction = client.axArmor / 100
            local armorFillWidth = math.max(0, barWidth * armorFraction - ax.util:ScreenScale(2))

            ax.render.Draw(barHeight, barX + ax.util:ScreenScale(1), barY + ax.util:ScreenScaleH(1), armorFillWidth, barHeight - ax.util:ScreenScaleH(2), armorColor)
        else
            client.axArmor = 0
        end
    end

    shouldDraw = hook.Run("ShouldDrawVoiceChatIcon")
    local bVoiceIndicators = ax.option:Get("performance.voice.indicators", true)
    if ( shouldDraw != false and bVoiceIndicators and client:IsSpeaking() ) then
        local iconSize = 64 * (1 + client:VoiceVolume())
        local iconX = width - ax.util:ScreenScale(8) - iconSize
        local iconY = height / 2 - iconSize / 2

        local iconColor = Color(255, 255, 255, 200)

        ax.render.DrawMaterial(0, iconX, iconY, iconSize, iconSize, iconColor, speakingIcon)
    end
end

-- `ax.elements` is part of the interface rewrite and does not exist yet; both call sites run every frame, so they are guarded rather than removed.
function GM:HUDPaint()
    if ( !ax.elements ) then return end

    ax.elements:PaintHUD()
end

function GM:GetEntityDisplayText(entity)
    if ( !ax.elements ) then return end

    return ax.elements:GetEntityDisplayText(entity)
end

function GM:PostDrawTranslucentRenderables(depth, skybox)
    if ( skybox ) then return end
    if ( !ax.option:Get("performance.voice.indicators", true) ) then return end

    local ft = FrameTime()
    local curTime = CurTime()
    for _, client in player.Iterator() do
        if ( !ax.util:IsValidPlayer(client) or !client:Alive() or client == ax.client or !client:IsSpeaking() ) then continue end

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
        client.axVoiceIconSize = ax.ease:Lerp("Linear", math.Clamp(ft * 10, 0, 1), client.axVoiceIconSize, size)
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
    if ( ax.gui.bPauseLegacy ) then
        ax.gui.bPauseLegacy = false
        return
    end

    if ( !ax.client:GetCharacter() ) then return end

    if ( IsValid(ax.gui.pause) ) then
        ax.gui.pause:Close()
    else
        if ( vgui.CursorVisible() ) then
            return
        end

        vgui.Create("ax.pause")
    end

    return false
end

ax.viewstack:RegisterModifier("ragdoll", function(client, patch)
    if ( !ax.util:IsValidPlayer(client) or client:InVehicle() ) then return end

    local ragdollIndex = client:GetRelay("ragdoll.index", -1)
    local ragdoll = Entity(ragdollIndex)
    if ( !IsValid(ragdoll) ) then return end

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

    ang = client:Alive() and patch.angles or ang

    return { origin = pos + ang:Forward() * 10, angles = ang, fov = patch.fov }
end, 1)

ax.viewstack:RegisterModifier("sequence.viewer", function(client, patch)
    if ( !ax.util:IsValidPlayer(client) or !client:Alive() ) then return end
    if ( client:GetRelay("sequence.identifier") == nil ) then return end

    local ragdoll = Entity(client:GetRelay("ragdoll.index", -1))
    local bHasRagdoll = IsValid(ragdoll)
    local headEntity = bHasRagdoll and ragdoll or client

    local headPos, headAng = ax.util:GetHeadTransform(headEntity)

    headAng = ax.ease:Lerp("Linear", 0.5, patch.angles, headAng)
    headAng = headAng:Normalize()

    return {
        origin = headPos or patch.origin,
        angles = headAng,
        drawviewer = true
    }
end, 2)

local function ShouldHideSequenceViewerHead(client)
    if ( !ax.util:IsValidPlayer(client) ) then return false end
    if ( client != ax.client ) then return false end
    if ( client:GetRelay("sequence.identifier") == nil ) then return false end

    return hook.Run("ShouldDrawLocalPlayer", client) != true
end

hook.Add("PostPlayerDraw", "ax.sequence.viewer.hide_head", function(client)
    local headBone = client:LookupBone("ValveBiped.Bip01_Head1")
    if ( !isnumber(headBone) or headBone < 0 ) then return end

    if ( ShouldHideSequenceViewerHead(client) ) then
        client:ManipulateBoneScale(headBone, Vector(0.001, 0.001, 0.001))
        return
    end

    client:ManipulateBoneScale(headBone, Vector(1, 1, 1))
end)

local cameraFOV = CreateConVar("ax_camera_fov", "90", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Set the camera FOV when using a view entity.")
ax.viewstack:RegisterModifier("camera", function(client, patch)
    if ( !ax.util:IsValidPlayer(client) or client:InVehicle() ) then return end

    local viewEntity = client:GetViewEntity()
    if ( IsValid(viewEntity) and viewEntity != client and viewEntity:GetClass() != "gmod_camera" ) then
        local pos = viewEntity:GetPos()
        local ang = viewEntity:GetAngles()

        return { origin = pos, angles = ang, fov = cameraFOV:GetFloat() }
    end
end, 99)

ax.viewstack:RegisterModifier("swep", function(client, patch)
    local weapon = client:GetActiveWeapon()
    if ( type(weapon) != "Weapon" or !weapon.TranslateFOV ) then return end

    local fov = weapon:TranslateFOV(patch.fov)

    return { origin = patch.origin, angles = patch.angles, fov = fov }
end, 1)

ax.viewstack:RegisterViewModelModifier("swep", function(weapon, patch)
    if ( type(weapon) != "Weapon" or !weapon.GetViewModelPosition ) then return end

    local pos, ang = weapon:GetViewModelPosition(patch.pos, patch.ang)

    return { pos = pos, ang = ang }
end, 1)

widgets.PlayerTick = nil
widgets.RenderMe = nil

hook.Remove("OnEntityCreated", "CreateWidgets")
hook.Remove("PlayerTick", "TickWidgets")
hook.Remove("PostDrawEffects", "RenderWidgets")
hook.Remove("EntityRemoved", "RemoveWidgets")
