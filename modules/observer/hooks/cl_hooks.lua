--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:DrawPhysgunBeam(client, physgun, enabled, target, physBone, hitPos)
    if ( CAMI.PlayerHasAccess(client, "Parallax - Observer") and client:GetNoDraw() and client:GetMoveType() == MOVETYPE_NOCLIP ) then
        return false
    end
end

function MODULE:HUDPaint()
    local client = ax.client
    if ( !IsValid(client) or !client:InObserver() or !client:Alive() or !client:GetNoDraw() ) then return end

    if ( hook.Run("ShouldDrawObserverHUD", client) == false ) then return end

    local playerCount = 0
    local admins = 0
    for k, v in player.Iterator() do
        playerCount = playerCount + 1

        if ( v:IsAdmin() ) then
            admins = admins + 1
        end

        if ( v == client or !v:Alive() ) then continue end

        local headBone = v:LookupBone("ValveBiped.Bip01_Head1")
        if ( !headBone ) then continue end

        local headPos = v:GetBonePosition(headBone)
        if ( !headPos ) then continue end

        local screenPos = headPos:ToScreen()
        if ( !screenPos.visible ) then continue end

        local y = screenPos.y
        local _, h = draw.SimpleText(v:Name(), "DermaDefault", screenPos.x, y, ax.color:Get("text"))
        y = y + h + 2

        local health = v:Health()
        local maxHealth = v:GetMaxHealth()
        local healthText = health .. "/" .. maxHealth
        if ( health <= 0 ) then
            healthText = "DEAD"
        end

        _, h = draw.SimpleText(healthText, "DermaDefault", screenPos.x, y, ax.color:Get("text"))
        y = y + h + 2

        local faction = v:GetFactionData()
        if ( faction ) then
            _, h = draw.SimpleText(faction.Name, "DermaDefault", screenPos.x, y, faction.Color)
            y = y + h + 2
        end
    end

    local y = 10

    local _, h = draw.SimpleText("Players: " .. playerCount, "DermaDefault", 10, y, ax.color:Get("text"))
    y = y + h + 2

    _, h = draw.SimpleText("Admins: " .. admins, "DermaDefault", 10, y, ax.color:Get("text"))
    y = y + h + 2

    hook.Run("PostDrawObserverHUD", client)
end