local playerSteamID64 = {}
local playerSteamID = {}
local playerAccountID = {}

-- Clean up existing hooks to prevent duplicates on reload
hook.Remove("OnEntityCreated", "ax.Impr.OnEntityCreated")
hook.Remove("EntityRemoved", "ax.Impr.EntityRemoved")

hook.Add("OnEntityCreated", "ax.Impr.OnEntityCreated", function(ent)
    if ( !ent:IsPlayer() ) then return end

    playerSteamID64[ent:SteamID64()] = ent
    playerSteamID[ent:SteamID()] = ent
    playerAccountID[ent:AccountID()] = ent
end)

hook.Add("EntityRemoved", "ax.Impr.EntityRemoved", function(ent)
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
        if ( ax.util:IsValidPlayer(client) ) then
            playerSteamID64[steamID64] = client
        end

        return client
    end

    return ent
end

function player.GetBySteamID(steamID)
    steamID = utf8.upper(steamID)

    local ent = playerSteamID[steamID]
    if ( !IsValid(ent) ) then
        local client = intern_getBySteamID(steamID)
        if ( ax.util:IsValidPlayer(client) ) then
            playerSteamID[steamID] = client
        end

        return client
    end

    return ent
end

function player.GetByAccountID(accountID)
    local ent = playerAccountID[accountID]
    if ( !IsValid(ent) ) then
        local client = intern_getByAccountID(accountID)
        if ( ax.util:IsValidPlayer(client) ) then
            playerAccountID[accountID] = client
        end

        return client
    end

    return ent
end
