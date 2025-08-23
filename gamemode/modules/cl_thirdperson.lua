local MODULE = MODULE

MODULE.Name = "Third Person"
MODULE.Description = "Adds third-person camera functionality to the gamemode."
MODULE.Author = "Riggs"

local thirdpersonEnable = CreateClientConVar("ax_thirdperson_enable", "0", true, false, "Enable or disable third person mode.", 0, 1)
local thirdpersonX = CreateClientConVar("ax_thirdperson_x", "25", true, false, "X offset for third person camera.", 0, 100)
local thirdpersonY = CreateClientConVar("ax_thirdperson_y", "0", true, false, "Y offset for third person camera.", -100, 100)
local thirdpersonZ = CreateClientConVar("ax_thirdperson_z", "-50", true, false, "Z offset for third person camera.", -100, 0)

-- LVS is gay and already used the ShouldDrawThirdPerson hook, so we have to use a different name
function MODULE:ShouldUseThirdPerson(client)
    if ( !client:Alive() or client:InVehicle() ) then
        return false
    end

    return thirdpersonEnable:GetBool()
end

ax.viewstack:RegisterModifier("thirdperson", function(client, view)
    if ( hook.Run("ShouldUseThirdPerson", client) == false ) then return end

    return {
        origin = view.origin + view.angles:Forward() * thirdpersonZ:GetFloat() + view.angles:Right() * thirdpersonX:GetFloat() + view.angles:Up() * thirdpersonY:GetFloat(),
        angles = view.angles,
        fov = view.fov
    }
end, 1)

function MODULE:ShouldDrawLocalPlayer(client)
    if ( hook.Run("ShouldUseThirdPerson", client) == false ) then return end

    return true
end