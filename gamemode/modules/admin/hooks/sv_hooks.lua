local MODULE = MODULE or {}

function MODULE:PlayerReady(client)
    local usergroup = client:GetUsergroup()
    client:SetUserGroup(usergroup)
end

function MODULE:PhysgunPickup(client, entity)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Pickup Players", nil) ) then
        return false
    end

    return true
end

function MODULE:OnPhysgunPickup(client, entity)
    if ( CAMI.PlayerHasAccess(client, "Parallax - Pickup Players", nil) and entity:IsPlayer() ) then
        entity:SetMoveType(MOVETYPE_NOCLIP)
    end
end

function MODULE:PhysgunDrop(client, entity)
    if ( CAMI.PlayerHasAccess(client, "Parallax - Pickup Players", nil) and entity:IsPlayer() ) then
        entity:SetMoveType(MOVETYPE_WALK)
    end
end

function MODULE:EntityTakeDamage(target, dmgInfo)
    if ( target:IsPlayer() and target:GetMoveType() == MOVETYPE_NOCLIP ) then
        return true
    end
end

function MODULE:PlayerSpawnEffect(client, model)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Spawn Effects", nil) ) then
        return false
    end

    return true
end

function MODULE:PlayerSpawnNPC(client, model)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Spawn NPCs", nil) ) then
        return false
    end

    return true
end

function MODULE:PlayerSpawnProp(client, model)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Spawn Props", nil) ) then
        return false
    end

    return true
end

function MODULE:PlayerSpawnRagdoll(client, model)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Spawn Ragdolls", nil) ) then
        return false
    end

    return true
end

function MODULE:PlayerSpawnSENT(client, model)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Spawn SENTs", nil) ) then
        return false
    end

    return true
end

function MODULE:PlayerSpawnSWEP(client, model)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Spawn Weapons", nil) ) then
        return false
    end

    return true
end

function MODULE:PlayerSpawnVehicle(client, model)
    if ( !CAMI.PlayerHasAccess(client, "Parallax - Spawn Vehicles", nil) ) then
        return false
    end

    return true
end
