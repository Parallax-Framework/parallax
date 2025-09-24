net.Receive("ax.animations.update", function()
    local client = net.ReadPlayer()
    local animations = net.ReadTable()
    local holdType = net.ReadString()

    if ( !IsValid(client) ) then return end

    local clientTable = client:GetTable()

    clientTable.axAnimations = animations
    clientTable.axHoldType = holdType
    clientTable.axLastAct = -1

    -- Turn IK off and then on, but only if we're not in noclip
    client:SetIK(false)
    timer.Simple(0.1, function()
        if ( IsValid(client) ) then
            client:SetIK(client:GetMoveType() != MOVETYPE_NOCLIP)
        end
    end)
end)

net.Receive("ax.sequence.reset", function()
    local client = net.ReadPlayer()
    if ( !IsValid(client) ) then return end

    hook.Run("PostPlayerLeaveSequence", client)
end)

net.Receive("ax.sequence.set", function()
    local client = net.ReadPlayer()
    if ( !IsValid(client) ) then return end

    hook.Run("PostPlayerForceSequence", client)
end)