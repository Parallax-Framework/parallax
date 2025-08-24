local MODULE = MODULE

MODULE.Name = "Third Person"
MODULE.Description = "Adds third-person camera functionality to the gamemode."
MODULE.Author = "Riggs"

local thirdpersonEnable = CreateClientConVar("ax_thirdperson_enable", "0", true, false, "Enable or disable third person mode.", 0, 1)
local thirdpersonX = CreateClientConVar("ax_thirdperson_x", "25", true, false, "X offset for third person camera.", 0, 100)
local thirdpersonY = CreateClientConVar("ax_thirdperson_y", "0", true, false, "Y offset for third person camera.", -100, 100)
local thirdpersonZ = CreateClientConVar("ax_thirdperson_z", "-50", true, false, "Z offset for third person camera.", -100, 0)
local FIXED_RADIUS = 6

-- LVS is gay and already used the ShouldDrawThirdPerson hook, so we have to use a different name
function MODULE:ShouldUseThirdPerson(client)
    if ( !client:Alive() or client:InVehicle() ) then
        return false
    end

    return thirdpersonEnable:GetBool()
end

ax.viewstack:RegisterModifier("thirdperson", function(client, view)
    if ( hook.Run("ShouldUseThirdPerson", client) == false ) then return end

    -- start from the player's eye position
    local startPos = client:EyePos()
    local ang = view.angles

    -- desired camera offset relative to view angles
    local desiredPos = startPos + ang:Forward() * thirdpersonZ:GetFloat() + ang:Right() * thirdpersonX:GetFloat() + ang:Up() * thirdpersonY:GetFloat()

    local FIXED_RADIUS = FIXED_RADIUS

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

function MODULE:ShouldDrawLocalPlayer(client)
    if ( hook.Run("ShouldUseThirdPerson", client) == false ) then return end

    return true
end

concommand.Add("ax_thirdperson_toggle", function(ply, cmd, args)
    thirdpersonEnable:SetBool(!thirdpersonEnable:GetBool())
end)