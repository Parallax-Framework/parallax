local MODULE = MODULE or {}

function MODULE:PlayerNoClip( client, desiredState )
    if ( !CAMI.PlayerHasAccess( client, "Parallax - Observer", nil ) ) then
        return false
    end

    if ( desiredState ) then
        client:SetNoDraw( true )
        client:SetNotSolid( true )
        client:SetNoTarget( true )
        client:DrawWorldModel( false )
        client:DrawShadow( false )
        client:GodEnable()
    else
        client:SetNoDraw( false )
        client:SetNotSolid( false )
        client:SetNoTarget( false )
        client:DrawWorldModel( true )
        client:DrawShadow( true )
        client:GodDisable()
    end
end

function MODULE:EntityTakeDamage( target, dmgInfo )
    if ( target:IsPlayer() and target:GetMoveType() == MOVETYPE_NOCLIP ) then
        return true
    end
end
