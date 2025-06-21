local playerSteamID64 = {}
local playerSteamID = {}
local playerAccountID = {}

hook.Add("OnEntityCreated", "Parallax.Impr.OnEntityCreated", function(ent)
    if ( !ent:IsPlayer() ) then return end

    playerSteamID64[ent:SteamID64()] = ent
    playerSteamID[ent:SteamID()] = ent
    playerAccountID[ent:AccountID()] = ent
end)

hook.Add("EntityRemoved", "Parallax.Impr.EntityRemoved", function(ent)
    if ( !ent:IsPlayer() ) then return end

    playerSteamID64[ent:SteamID64()] = nil
    playerSteamID[ent:SteamID()] = nil
    playerAccountID[ent:AccountID()] = nil
end)

local intern_getBySteamID64 = intern_getBySteamID64 or player.GetBySteamID64
local intern_getBySteamID = intern_getBySteamID or player.GetBySteamID
local intern_getByAccountID = intern_getByAccountID or player.GetByAccountID

function player.GetBySteamID64(steamID64)
    local ent = playerSteamID64[steamID64]
    if ( !IsValid(ent) ) then
        local client = intern_getBySteamID64(steamID64)
        playerSteamID64[steamID64] = client

        return client or false
    end

    return ent or false
end

function player.GetBySteamID(steamID)
    steamID = string.upper(steamID)

    local ent = playerSteamID[steamID]
    if ( !IsValid(ent) ) then
        local client = intern_getBySteamID(steamID)
        playerSteamID[steamID] = client

        return client or false
    end

    return ent or false
end

function player.GetByAccountID(accountID)
    local ent = playerAccountID[accountID]
    if ( !IsValid(ent) ) then
        local client = intern_getByAccountID(accountID)
        playerAccountID[accountID] = client

        return client or false
    end

    return ent or false
end