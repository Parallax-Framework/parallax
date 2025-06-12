--- Cached Screen Width and Height
-- Caches the screen width and height to avoid repeated calls to ScrW() and ScrH().
-- @Srlion

local cScrW = ScrW()
local cScrH = ScrH()

function ScrW()
    return cScrW
end

function ScrH()
    return cScrH
end

hook.Add("OnScreenSizeChanged", "UpdateScreenSize", function(_, _, newW, newH)
    cScrW = newW
    cScrH = newH
end)