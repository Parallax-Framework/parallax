local MODULE = MODULE

function MODULE:CanPlayerObserve(client, state)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Observer") ) then return false end

    return true
end

function MODULE:PlayerNoClip(client, desiredState)
    if ( !hook.Run("CanPlayerObserve", client, desiredState) ) then
        return false
    end

    if ( desiredState ) then
        client:SetNoDraw(true)
        client:DrawShadow(false)
        client:SetNotSolid(true)

        if ( SERVER ) then
            client:SetNoTarget(true)
        end
    else
        client:SetNoDraw(false)
        client:DrawShadow(true)
        client:SetNotSolid(false)

        if ( SERVER ) then
            client:SetNoTarget(false)
        end
    end

    hook.Run("OnPlayerObserver", client, desiredState)

    return true
end

function MODULE:OnPlayerObserver(client, state)
    if ( CLIENT ) then return end
    if ( !IsValid(client) or !client:IsPlayer() ) then return end

    local logging = ax.module:Get("logging")
    if ( logging ) then
        logging:Send(client:Nick() .. " is now " .. (state and "observing" or "no longer observing") .. ".")
    end
end

function MODULE:ShouldDrawObserverHUD(client)
    return true
end