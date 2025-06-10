local playerSteamID64 = {}
local playerSteamID = {}
local playerAccountID = {}

hook.Add("OnEntityCreated", "ax.impr.OnEntityCreated", function(ent)
    if ( !ent:IsPlayer() ) then return end

    playerSteamID64[ent:SteamID64()] = ent
    playerSteamID[ent:SteamID()] = ent
    playerAccountID[ent:AccountID()] = ent
end)

hook.Add("EntityRemoved", "ax.impr.EntityRemoved", function(ent)
    if ( !ent:IsPlayer() ) then return end

    playerSteamID64[ent:SteamID64()] = nil
    playerSteamID[ent:SteamID()] = nil
    playerAccountID[ent:AccountID()] = nil
end)

local intern_getBySteamID64 = player.GetBySteamID64
local intern_getBySteamID = player.GetBySteamID
local intern_getByAccountID = player.GetByAccountID

function player.GetBySteamID64(steamID64)
    local ent = playerSteamID64[steamID64]
    if ( !IsValid(ent) ) then
        local client = intern_getBySteamID64(steamID64)
        playerSteamID64[steamID64] = client

        return client
    end

    return ent
end

function player.GetBySteamID(steamID)
    steamID = string.upper(steamID)

    local ent = playerSteamID[steamID]
    if ( !IsValid(ent) ) then
        local client = intern_getBySteamID(steamID)
        playerSteamID[steamID] = client

        return client
    end

    return ent
end

function player.GetByAccountID(accountID)
    local ent = playerAccountID[accountID]
    if ( !IsValid(ent) ) then
        local client = intern_getByAccountID(accountID)
        playerAccountID[accountID] = client

        return client
    end

    return ent
end