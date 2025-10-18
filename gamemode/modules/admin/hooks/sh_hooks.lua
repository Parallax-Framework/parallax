local MODULE = MODULE or {}

function MODULE:PlayerNoClip(client, desiredState)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Observer", nil) ) then
        return false
    end

    if ( desiredState ) then
        client:SetNoDraw(true)
        client:SetNotSolid(true)
        client:DrawWorldModel(false)
        client:DrawShadow(false)

        if ( SERVER ) then
            client:SetNoTarget(true)
        end
    else
        client:SetNoDraw(false)
        client:SetNotSolid(false)
        client:DrawWorldModel(true)
        client:DrawShadow(true)

        if ( SERVER ) then
            client:SetNoTarget(false)
        end
    end
end
