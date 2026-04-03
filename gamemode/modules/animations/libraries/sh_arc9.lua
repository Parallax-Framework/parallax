if ( !tobool(ARC9) ) then return end

-- attempt to get the correct holdtype for arc9 weapons with holster stances
function MODULE:GetPlayerHoldType(client, weapon, holdType)
    if ( type(weapon) == "Weapon" and weapon.ARC9 == true ) then
        if ( client:IsWeaponRaised() == false or weapon:GetSafe() == true ) then
            weapon:SetHoldType(weapon.HoldTypeHolstered)
            return weapon.HoldTypeHolstered
        else
            weapon:SetHoldType(weapon.HoldType)
            return weapon.HoldType
        end
    end
end

-- attempt to run a hook when a player toggles their safetymode on arc9 weapons
function MODULE:PlayerPostThink(client)
    if ( SERVER ) then
        self:HandleHoldTypeChanged(client)
    end

    local weapon = client:GetActiveWeapon()
    if ( type(weapon) != "Weapon" or weapon.ARC9 != true ) then return end

    client.axLastSafetyMode = client.axLastSafetyMode or false

    local safe = weapon:GetSafe()
    if ( client.axLastSafetyMode != safe ) then
        hook.Run("OnPlayerToggleSafetyMode", client, weapon, safe)
        client.axLastSafetyMode = safe
    end
end

-- hook for when a player toggles safetymode on arc9 weapons
function MODULE:OnPlayerToggleSafetyMode(client, weapon, isSafe)
    if ( SERVER ) then
        self:UpdateClientAnimations(client)
    end
end
