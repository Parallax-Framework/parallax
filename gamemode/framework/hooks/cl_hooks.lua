--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

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

function GM:CalcView(client, origin, angles, fov)
    if ( !IsValid(client) ) then return end

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
            fov = fov
        }
    end
end