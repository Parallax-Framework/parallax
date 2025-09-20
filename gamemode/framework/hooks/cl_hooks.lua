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
    ["CHudChat"] = true
}

function GM:HUDShouldDraw(name)
    if ( hide[name] ) then return false end

    return true
end

local healthIcon = ax.util:GetMaterial("parallax/icons/hud/health.png", "smooth mips")
function GM:HUDPaintCurvy(width, height, client, isCurved)
    if ( !IsValid(client) ) then return end

    local shouldDraw = hook.Run("ShouldDrawHealthHUD")
    if ( shouldDraw != false ) then
        local barWidth, barHeight = ScreenScale(64), ScreenScaleH(8)
        local barX, barY = ScreenScale(8), ScrH() - ScreenScaleH(8) - barHeight * 1.5

        -- Draw health icon
        ax.render.DrawMaterial(0, barX, barY - barHeight / 2, barHeight * 2, barHeight * 2, Color(255, 255, 255, 200), healthIcon)
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
        ax.render.Draw(barHeight, barX + ScreenScale(1), barY + ScreenScaleH(1), fillWidth, barHeight - ScreenScaleH(2), Color(255, 255, 255, 200))
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
