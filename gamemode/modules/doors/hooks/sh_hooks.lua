local MODULE = MODULE

function MODULE:CanPlayerPurchaseDoor(client, door)
end

function MODULE:CanPlayerSellDoor(client, door)
end

function MODULE:CanPlayerSellAllDoors(client)
    return true
end

function MODULE:CanPlayerAccessDoor(client, door, accessGroup)
    local doorFactions = door:GetRelay("allowedFactions", {})
    if ( doorFactions[client:Team()] ) then return true end

    local doorClasses = door:GetRelay("allowedClasses", {})
    if ( doorClasses[client:GetChar():GetClass()] ) then return true end

    local doorRanks = door:GetRelay("allowedRanks", {})
    if ( doorRanks[client:GetChar():GetRank()] ) then return true end

    return false
end
