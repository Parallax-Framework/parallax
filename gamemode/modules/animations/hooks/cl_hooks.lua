-- Helper function to apply IK settings
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
    if ( key != "animationsIKEnabled" ) then return end

    -- Reapply IK settings to all players when the config changes
    for _, client in player.Iterator() do
        if ( !IsValid(client) ) then continue end

        local clientTable = client:GetTable()
        if ( !clientTable.axAnimations ) then continue end

        ApplyIK(client, newValue)
    end
end
