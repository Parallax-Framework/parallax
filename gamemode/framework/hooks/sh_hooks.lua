function GM:Initialize()
    ax.schema:Initialize()
end

local reloaded = false
function GM:OnReloaded()
    if ( reloaded ) then return end
    reloaded = true

    ax.schema:Initialize()
end