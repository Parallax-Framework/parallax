local MODULE = MODULE

function MODULE:PostPlayerReady(client)
    if ( !IsValid(client) or client:IsBot() ) then return end

    if ( !game.IsDedicated() ) then
        self:SetUserGroup(client, "superadmin")
        return
    end

    local usergroup = client:GetDBVar("usergroup", "user")
    if ( !CAMI.GetUsergroup(usergroup) ) then
        usergroup = "user" -- Fallback to default user group if not found
        ax.util:PrintWarning("Usergroup '" .. usergroup .. "' not found for " .. tostring(client) .. ". Defaulting to 'user'.")
        client:SetDBVar("usergroup", usergroup)
        client:SaveDB()
    end

    client:SetUserGroup(usergroup)

    ax.util:Print(tostring(client) .. " is assigned to usergroup '" .. usergroup .. "'.")
end

function MODULE:SaveData()
    for _, client in player.Iterator() do
        if ( !IsValid(client) or client:IsBot() ) then continue end

        local usergroup = client:GetUserGroup()
        if ( usergroup and CAMI.GetUsergroup(usergroup) ) then
            client:SetDBVar("usergroup", usergroup)
            client:SaveDB()
            ax.util:Print("Saving usergroup '" .. usergroup .. "' for " .. tostring(client) .. "...")
        else
            ax.util:PrintWarning("Invalid usergroup for " .. tostring(client) .. ". Not saving usergroup!")
        end
    end
end