--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local function ApplyIK(client, enableIK)
    if ( !IsValid(client) ) then return end

    if ( enableIK ) then
        client:SetIK(false)
        timer.Simple(0.1, function()
            if ( IsValid(client) ) then
                client:SetIK(client:GetMoveType() != MOVETYPE_NOCLIP)
            end
        end)
    else
        client:SetIK(false)
    end
end

function MODULE:OnConfigChanged(key, oldValue, newValue)
    if ( key != "animations.ik" ) then return end

    -- Reapply IK settings to all players when the config changes
    for _, client in player.Iterator() do
        if ( !IsValid(client) ) then continue end

        local clientTable = client:GetTable()
        if ( !clientTable.axAnimations ) then continue end

        ApplyIK(client, newValue)
    end
end

-- Support for blocking TPIK in ARC9 when weapon is not raised
function MODULE:ARC9_Hook_BlockTPIK(weapon)
    local owner = weapon:GetOwner()
    if ( !owner:IsWeaponRaised() ) then
        return true
    end
end
