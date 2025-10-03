local MODULE = MODULE

MODULE.Name = "Third Person"
MODULE.Description = "Adds third-person camera functionality to the gamemode."
MODULE.Author = "Riggs"

ax.config:Add("thirdperson", ax.type.bool, true, { category = "camera", subCategory = "thirdPerson" })
ax.option:Add("thirdperson", ax.type.bool, false, { category = "camera", subCategory = "thirdPerson" })
ax.option:Add("thirdpersonX", ax.type.number, 25, { category = "camera", subCategory = "thirdPerson" })
ax.option:Add("thirdpersonY", ax.type.number, 0, { category = "camera", subCategory = "thirdPerson" })
ax.option:Add("thirdpersonZ", ax.type.number, -50, { category = "camera", subCategory = "thirdPerson" })
ax.option:Add("thirdpersonFollowHead", ax.type.bool, true, { category = "camera", subCategory = "thirdPerson", description = "Make the third-person camera follow the player's model head movements." })

local FIXED_RADIUS = 6

-- LVS is gay and already used the ShouldDrawThirdPerson hook, so we have to use a different name
function MODULE:ShouldUseThirdPerson(client)
    if ( !client:Alive() or client:InVehicle() ) then
        return false
    end

    if ( !ax.config:Get("thirdperson") ) then
        return false
    end

    return ax.option:Get("thirdperson")
end

function MODULE:ShouldDrawLocalPlayer(client)
    if ( self:ShouldUseThirdPerson(client) ) then
        return true
    end
end

ax.viewstack:RegisterModifier("thirdperson", function(client, view)
    if ( hook.Run("ShouldUseThirdPerson", client) == false ) then return end

    -- start from the player's eye position
    local startPos = client:EyePos()
    local head = client:LookupBone("ValveBiped.Bip01_Head1")
    if ( ax.option:Get("thirdpersonFollowHead") and head ) then
        local headPos, _ = client:GetBonePosition(head)
        if ( headPos ) then
            startPos = headPos
        end
    end

    local ang = view.angles

    -- desired camera offset relative to view angles
    local desiredPos = startPos + ang:Forward() * ax.option:Get("thirdpersonZ") + ang:Right() * ax.option:Get("thirdpersonX") + ang:Up() * ax.option:Get("thirdpersonY")

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
        fov = view.fov
    }
end, 1)

concommand.Add("ax_thirdperson_toggle", function(client, cmd, args)
    ax.option:Set("thirdperson", !ax.option:Get("thirdperson"))
end)
