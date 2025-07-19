gameevent.Listen("OnRequestFullUpdate")
hook.Add("OnRequestFullUpdate", "ax.OnRequestFullUpdate", function(data)
    if ( !istable(data) or !isnumber(data.userid) ) then return end

    local client = Player(data.userid)
    if ( !IsValid(client) ) then return end

    local clientTable = client:GetTable()
    if ( clientTable.axReady ) then return end

    clientTable.axReady = true

    timer.Simple(0, function()
        if ( !IsValid(client) ) then return end

        hook.Run("PlayerReady", client)
    end)
end)

function GM:PlayerReady(client)

end