local MODULE = MODULE or {}

function MODULE:PlayerNoClip( client, desiredState )
    if ( !CAMI.PlayerHasAccess( client, "Parallax - Observer", nil ) ) then
        return false
    end

    if ( desiredState ) then
        client:SetNoDraw( true )
        client:SetNotSolid( true )
        client:DrawViewModel( false )
        client:SetNoTarget( true )
    else
        client:SetNoDraw( false )
        client:SetNotSolid( false )
        client:DrawViewModel( true )
        client:SetNoTarget( false )
    end
end
