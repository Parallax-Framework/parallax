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

local steps = {".stepleft", ".stepright"}
function GM:EntityEmitSound(data)
    if ( !IsValid(data.Entity) and !data.Entity:IsPlayer() ) then return end

    local name = data.OriginalSoundName
    if ( name:find(steps[1]) or name:find(steps[2]) ) then
        return false
    end
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

ax.viewstack:RegisterModifier("ragdoll", function(client, view)
    if ( !IsValid(client) or client:InVehicle() ) then return end

    local ragdollIndex = client:GetNWInt("ax.ragdoll.index", -1)
    if ( ragdollIndex != -1 and !client:Alive() ) then
        local ragdoll = ents.GetByIndex(ragdollIndex)
        if ( !IsValid(ragdoll) ) then
            client:SetNWInt("ax.ragdoll.index", -1)
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