local MODULE = MODULE

MODULE.Name = "Muzzle Cam"
MODULE.Author = "kek"
MODULE.Description = "Adds a small muzzle-driven camera sway effect to the player's viewmodel"

if ( SERVER ) then return end

CreateClientConVar("muzzlecam_scale", "1", true, false)

local weapon_exclusion_list = {
    ["gmod_tool"] = true,
    ["weapon_physcannon"] = true,
    ["weapon_physgun"] = true,
}

local weapon_prefix_exclusion_list = {
    "arc9_",
    "mg_",
    "tacrp_",
}

local excluded_acts = {
    [ACT_VM_HOLSTER] = true,
}

local lastMuzzleAng = Angle(0, 0, 0)
local muzzleVel = Angle(0, 0, 0)
local viewOffset = Angle(0, 0, 0)

function MODULE:CalcView(client, pos, ang, fov)
    if ( !IsValid(client) or !client:Alive() or client:ShouldDrawLocalPlayer() ) then return end

    local wep = client:GetActiveWeapon()
    if ( !IsValid(wep) ) then return end

    local wepClass = wep:GetClass()

    if weapon_exclusion_list[wepClass] then return end

    for _, prefix in ipairs(weapon_prefix_exclusion_list) do
        if ( string.StartWith(wepClass, prefix) ) then
            return
        end
    end

    local vm = client:GetViewModel()
    if ( !IsValid(vm) ) then return end

    local seq = vm:GetSequence()
    local act = vm:GetSequenceActivity(seq)
    if ( excluded_acts[act] ) then return end

    local attID = vm:LookupAttachment("muzzle")
    if ( attID <= 0 ) then return end

    local att = vm:GetAttachment(attID)
    if ( !att or !att.Ang ) then return end

    local scale = GetConVar("muzzlecam_scale"):GetFloat()
    if ( scale <= 0 ) then return end

    local muzzleAng = vm:WorldToLocalAngles(att.Ang)
    local ft = FrameTime()
    local delta = lastMuzzleAng - muzzleAng
    delta:Normalize()

    muzzleVel = muzzleVel + delta * 2 * scale

    muzzleVel.p = math.Approach(muzzleVel.p, -viewOffset.p * 2, ft * 20)
    muzzleVel.p = math.Clamp(muzzleVel.p, -scale * 5, scale * 5)

    muzzleVel.y = math.Approach(muzzleVel.y, -viewOffset.y * 2, ft * 20)
    muzzleVel.y = math.Clamp(muzzleVel.y, -scale * 5, scale * 5)

    muzzleVel.r = math.Approach(muzzleVel.r, -viewOffset.r * 2, ft * 20)
    muzzleVel.r = math.Clamp(muzzleVel.r, -scale * 5, scale * 5)

    viewOffset.p = math.Clamp(viewOffset.p + muzzleVel.p * ft, -90, 90)
    viewOffset.y = math.Clamp(viewOffset.y + muzzleVel.y * ft, -90, 90)
    viewOffset.r = math.Clamp(viewOffset.r + muzzleVel.r * ft, -90, 90)

    viewOffset.p = math.Approach(viewOffset.p, 0, ft * math.abs(viewOffset.p) * 16)
    viewOffset.y = math.Approach(viewOffset.y, 0, ft * math.abs(viewOffset.y) * 16)
    viewOffset.r = math.Approach(viewOffset.r, 0, ft * math.abs(viewOffset.r) * 16)

    lastMuzzleAng = muzzleAng

    return {
        origin = pos,
        angles = ang + viewOffset,
        fov = fov
    }
end