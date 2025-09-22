local MODULE = MODULE

MODULE.Name = "Third Person"
MODULE.Description = "Adds third-person camera functionality to the gamemode."
MODULE.Author = "Riggs"

ax.option:Add("thirdperson", ax.type.bool, false, { category = "Camera" })
ax.option:Add("thirdperson_x", ax.type.number, 25, { category = "Camera" })
ax.option:Add("thirdperson_y", ax.type.number, 0, { category = "Camera" })
ax.option:Add("thirdperson_z", ax.type.number, -50, { category = "Camera" })
local FIXED_RADIUS = 6

-- LVS is gay and already used the ShouldDrawThirdPerson hook, so we have to use a different name
function MODULE:ShouldUseThirdPerson(client)
    if ( !client:Alive() or client:InVehicle() ) then
        return false
    end

    return ax.option:Get("thirdperson")
end

ax.viewstack:RegisterModifier("thirdperson", function(client, view)
    if ( hook.Run("ShouldUseThirdPerson", client) == false ) then return end

    -- start from the player's eye position
    local startPos = client:EyePos()
    local ang = view.angles

    -- desired camera offset relative to view angles
    local desiredPos = startPos + ang:Forward() * ax.option:Get("thirdperson_z") + ang:Right() * ax.option:Get("thirdperson_x") + ang:Up() * ax.option:Get("thirdperson_y")

    local tr = util.TraceHull({
        start = startPos,
        endpos = desiredPos,
        mins = Vector(-FIXED_RADIUS, -FIXED_RADIUS, -FIXED_RADIUS),
        maxs = Vector(FIXED_RADIUS, FIXED_RADIUS, FIXED_RADIUS),
        filter = client,
        mask = MASK_SOLID
    })

    if ( tr.Hit ) then
        desiredPos = tr.HitPos - ang:Forward() * FIXED_RADIUS
    end

    return {
        origin = desiredPos,
        angles = ang,
        fov = view.fov,
        drawviewer = true
    }
end, 1)

concommand.Add("ax_thirdperson_toggle", function(client, cmd, args)
    ax.option:Set("thirdperson", !ax.option:Get("thirdperson"))
end)
