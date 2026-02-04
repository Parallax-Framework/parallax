--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:UpdateClientAnimations(client)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    local clientTable = client:GetTable()
    if ( !clientTable ) then return end

    local holdType = client:GetHoldType()
    local model = client:GetModel()
    local modelClass = ax.animations:GetModelClass(model)
    local animTable = ax.animations.stored[modelClass]

    if ( animTable and animTable[holdType] ) then
        clientTable.axAnimations = animTable[holdType]
    else
        clientTable.axAnimations = {}
    end

    ax.net:Start(nil, "animations.update", client, clientTable.axAnimations, holdType)
end

function MODULE:PostEntitySetModel(ent, model)
    if ( !IsValid(ent) or !ent:IsPlayer() ) then return end

    self:UpdateClientAnimations(ent)
end

function MODULE:PostPlayerLoadout(client)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    self:UpdateClientAnimations(client)
end

function MODULE:PlayerSwitchWeapon(client, oldWeapon, newWeapon)
    if ( !ax.util:IsValidPlayer(client) or !IsValid(newWeapon) ) then return end

    timer.Simple(0, function()
        if ( ax.util:IsValidPlayer(client) ) then
            self:UpdateClientAnimations(client)
        end
    end)
end

function MODULE:PlayerNoClip(client, toggle)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    timer.Simple(0, function()
        if ( ax.util:IsValidPlayer(client) ) then
            self:UpdateClientAnimations(client)
        end
    end)
end

function MODULE:PlayerWeaponRaised(client, bRaised)
    if ( !ax.util:IsValidPlayer(client) ) then return end

    self:UpdateClientAnimations(client)
end

function MODULE:PlayerReady(client)
    for k, v in player.Iterator() do
        self:UpdateClientAnimations(v)
    end
end
