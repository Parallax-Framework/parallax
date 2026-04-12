local MODULE = MODULE

function MODULE:CanPlayerPurchaseDoor(client, door)
    return !SCHEMA:IsEntityDoor(door)
end

function MODULE:CanPlayerSellDoor(client, door)
    return !SCHEMA:IsEntityDoor(door)
end

function MODULE:CanPlayerSellAllDoors(client)
    return true
end
