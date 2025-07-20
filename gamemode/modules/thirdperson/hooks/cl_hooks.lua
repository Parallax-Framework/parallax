function MODULE:CalcView(client, origin, angles, fov)
    local view = {}
    view.origin = origin + angles:Forward() * -50 + angles:Right() * 25
    view.angles = angles
    view.fov = fov

    return view
end

function MODULE:ShouldDrawLocalPlayer(client)
    return true
end

print("Third Person module loaded successfully.")