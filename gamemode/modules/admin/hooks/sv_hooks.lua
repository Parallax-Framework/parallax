local MODULE = MODULE or {}

function MODULE:EntityTakeDamage(target, dmgInfo)
    if ( target:IsPlayer() and target:GetMoveType() == MOVETYPE_NOCLIP ) then
        return true
    end
end
