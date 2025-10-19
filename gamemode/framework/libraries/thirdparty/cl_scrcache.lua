--- Cached Screen Width and Height
-- Caches the screen width and height to avoid repeated calls to ScrW() and ScrH().
-- @Srlion & Winkarst

local cScrW = ScrW()
local cScrH = ScrH()

function ScrW()
    return cScrW
end

function ScrH()
    return cScrH
end

-- Clean up existing hook to prevent duplicates on reload
hook.Remove("OnScreenSizeChanged", "ax.screensize.changed")

hook.Add("OnScreenSizeChanged", "ax.screensize.changed", function(_, _, newW, newH)
    cScrW = newW
    cScrH = newH
end)
