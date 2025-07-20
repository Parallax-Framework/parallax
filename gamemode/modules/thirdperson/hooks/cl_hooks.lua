function MODULE:ShouldDrawThirdPerson(client)
    if ( !IsValid(client) or !client:IsPlayer() ) then
        return false
    end

    if ( !client:Alive() or client:InVehicle() or client:GetObserverMode() != OBS_MODE_NONE ) then
        return false
    end

    return true
end

function MODULE:CalcView(client, origin, angles, fov)
    if ( !hook.Run("ShouldDrawThirdPerson", client) ) then return end

    local view = {}
    view.origin = origin + angles:Forward() * -50 + angles:Right() * 25
    view.angles = angles
    view.fov = fov

    return view
end

function MODULE:ShouldDrawLocalPlayer(client)
    if ( !hook.Run("ShouldDrawThirdPerson", client) ) then return end

    return true
end

print("Third Person module loaded successfully.")