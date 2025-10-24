local MODULE = MODULE

local function UpdateClientAnimations(client)
    if ( !IsValid(client) ) then return end

    local clientTable = client:GetTable()
    if ( !clientTable ) then return end

    local holdType = client:GetHoldType()
    local model = client:GetModel()
    local modelClass = ax.animations:GetModelClass(model)
    local animTable = ax.animations.stored[modelClass]

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
    if ( !IsValid(client) or !IsValid(newWeapon) ) then return end

    timer.Simple(0, function()
        if ( IsValid(client) ) then
            UpdateClientAnimations(client)
        end
    end)
end

function MODULE:PlayerNoClip(client, toggle)
    if ( !IsValid(client) ) then return end

    timer.Simple(0, function()
        if ( IsValid(client) ) then
            UpdateClientAnimations(client)
        end
    end)
end
