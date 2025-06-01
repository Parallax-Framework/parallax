DeriveGamemode("sandbox")

ax = ax or {util = {}, gui = {}, meta = {}, config = {}}

include("core/types.lua")
include("core/util.lua")
include("core/boot.lua")

LocalPlayerInternal = LocalPlayer
function LocalPlayer()
    if ( IsValid(ax.client) ) then
        return ax.client
    end

    return LocalPlayerInternal()
end

timer.Remove("HintSystem_OpeningMenu")
timer.Remove("HintSystem_Annoy1")
timer.Remove("HintSystem_Annoy2")

