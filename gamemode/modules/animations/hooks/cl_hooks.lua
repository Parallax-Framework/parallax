function MODULE:OnConfigChanged(key, oldValue, newValue)
    if ( key != "animationsIKEnabled" ) then return end

    -- Reapply IK settings to all players when the config changes
    for _, client in player.Iterator() do
        if ( !IsValid(client) ) then continue end

        local clientTable = client:GetTable()
        if ( !clientTable.axAnimations ) then continue end

        -- Turn IK off and then on, but only if we're not in noclip and IK is enabled
        if ( newValue ) then
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
end
