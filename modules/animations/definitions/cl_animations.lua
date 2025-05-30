ax.net:Hook("animations.update", function(client, animations, holdType)
    if ( !IsValid(client) ) then return end

    client.axAnimations = animations
    client.axHoldType = holdType
    client.axLastAct = -1

    -- ew...
    client:SetIK(false)
end)