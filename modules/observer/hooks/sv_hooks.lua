local MODULE = MODULE

function MODULE:EntityTakeDamage(target, dmgInfo)
    if ( !IsValid(target) or !target:IsPlayer() ) then return end

    if ( target:InObserver() ) then
        return true
    end
end

function MODULE:PlayerEnteredVehicle(client, vehicle, role)
    if ( client:InObserver() ) then
        client:SetNoDraw(false)
        client:DrawShadow(true)
        client:SetNotSolid(false)
        client:SetNoTarget(false)
    end
end