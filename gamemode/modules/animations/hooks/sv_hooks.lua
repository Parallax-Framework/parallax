local MODULE = MODULE

local function UpdateClientAnimations(client)
    if ( !IsValid(client) ) then return end

    local clientTable = client:GetTable()
    if ( !clientTable ) then return end

    local holdType = client:GetHoldType()
    local animTable = ax.animations.stored[ax.animations:GetModelClass(client:GetModel())]
    if ( animTable and animTable[holdType] ) then
        clientTable.axAnimations = animTable[holdType]
    else
        clientTable.axAnimations = {}
    end

    net.Start("ax.animations.update")
        net.WritePlayer(client)
        net.WriteTable(clientTable.axAnimations)
        net.WriteString(holdType)
    net.Send(client)
end

function MODULE:PostEntitySetModel(ent, model)
    if ( !IsValid(ent) or !ent:IsPlayer() ) then return end

    UpdateClientAnimations(ent)
end

function MODULE:PlayerLoadout(client)
    if ( !IsValid(client) ) then return end

    UpdateClientAnimations(client)
end

function MODULE:PlayerSwitchWeapon(client, oldWeapon, newWeapon)
    timer.Simple(0, function()
        if ( !IsValid(client) or !IsValid(newWeapon) ) then return end
        UpdateClientAnimations(client)
    end)
end

function MODULE:PlayerNoClip(client, toggle)
    if ( !IsValid(client) ) then return end

    timer.Simple(0, function()
        if ( !IsValid(client) ) then return end
        UpdateClientAnimations(client)
    end)
end