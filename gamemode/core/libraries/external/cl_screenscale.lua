--- Cached Screen Scale
-- Caches ScrW && ScrH to improve performance.
-- @Winkarst

-- TODO: Remove after https://github.com/Facepunch/garrysmod/pull/2309 is merged.

local scrW, scrH = ScrW() / 640.0, ScrH() / 480.0

function ScreenScale(width)
	return width * scrW
end

function ScreenScaleH(height)
	return height * scrH
end

SScale = ScreenScale

hook.Add("OnScreenSizeChanged", "CachedScreenScale", function(oldWidth, oldHeight, newWidth, newHeight)
	scrW, scrH = newWidth / 640, newHeight / 480
end)