local MODULE = MODULE

function MODULE:GetHoldType(client)
    if ( !IsValid(client) ) then return "none" end

    local weapon = client:GetActiveWeapon()
    if ( !IsValid(weapon) ) then return "none" end

    local holdType = weapon:GetHoldType()
    if ( !holdType ) then return "none" end

    return HOLDTYPE_TRANSLATOR[holdType] or holdType
end

function MODULE:PostEntitySetModel(ent, model)
    if ( !IsValid(ent) or !ent:IsPlayer() ) then return end

    local client = ent
    local clientTable = client:GetTable()
    if ( !clientTable ) then return end

    local holdType = self:GetHoldType(client)
    local animTable = ax.animations.stored[ax.animations:GetModelClass(model)]
    if ( animTable and animTable[holdType] ) then
        clientTable.axAnimations = animTable[holdType]
    else
        clientTable.axAnimations = {}
    end

    net.Start("ax.animations.update")
        net.WritePlayer(client)
        net.WriteTable(clientTable.axAnimations)
        net.WriteString(holdType)
    net.Broadcast()
end

function MODULE:PlayerLoadout(client)
    if ( !IsValid(client) ) then return end

    local clientTable = client:GetTable()
    if ( !clientTable ) then return end

    local holdType = self:GetHoldType(client)
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
    net.Broadcast()
end

function MODULE:PlayerSwitchWeapon(client, oldWeapon, newWeapon)
    if ( !IsValid(client) ) then return end
    if ( !IsValid(newWeapon) ) then return end

    local clientTable = client:GetTable()
    if ( !clientTable ) then return end

    local holdType = self:GetHoldType(client)
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
    net.Broadcast()
end