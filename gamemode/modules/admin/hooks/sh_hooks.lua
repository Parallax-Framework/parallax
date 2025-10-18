local MODULE = MODULE or {}

function MODULE:PlayerNoClip(client, desiredState)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Observer", nil) ) then
        return false
    end

    if ( desiredState ) then
        client:SetNoDraw(true)
        client:SetNotSolid(true)
        client:DrawShadow(false)

        if ( SERVER ) then
            client:SetNoTarget(true)
            client:DrawWorldModel(false)
        end
    else
        client:SetNoDraw(false)
        client:SetNotSolid(false)
        client:DrawShadow(true)

        if ( SERVER ) then
            client:SetNoTarget(false)
            client:DrawWorldModel(true)
        end
    end
end
