-- LVS is gay and already used the ShouldDrawThirdPerson hook, so we have to use a different name
function MODULE:ShouldUseThirdPerson(client)
    if ( !client:Alive() or client:InVehicle() ) then
        return false
    end

    return true
end

function MODULE:CalcView(client, origin, angles, fov)
    if ( hook.Run("ShouldUseThirdPerson", client) == false ) then return end

    local view = {}
    view.origin = origin + angles:Forward() * -50 + angles:Right() * 25
    view.angles = angles
    view.fov = fov
    view.drawviewer = true

    return view
end

function MODULE:ShouldDrawLocalPlayer(client)
    if ( hook.Run("ShouldUseThirdPerson", client) == false or ax.client == client ) then return end

    return true
end

print("Third Person module loaded successfully.")