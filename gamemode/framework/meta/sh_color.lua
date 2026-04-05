local color = FindMetaTable( "Color" )

--- Returns true if the color is perceived as dark by a human viewer.
-- Computes the W3C-standard relative luminance using the formula: `0.299 * R + 0.587 * G + 0.114 * B` (weights reflect human eye sensitivity to each channel). The result is compared against `minimumThreshold`: values below the threshold are considered dark.
-- The default threshold of 186 is a widely-used cutoff for choosing between white and black text on a coloured background.
-- @realm shared
-- @param minimumThreshold number|nil The brightness cutoff (0–255). Values below this are considered dark. Defaults to 186.
-- @return boolean True if the color's perceived brightness is below the threshold.
-- @usage if ( color:IsDark() ) then
--     draw.SimpleText("Hello", "Default", x, y, Color(255, 255, 255))
-- else
--     draw.SimpleText("Hello", "Default", x, y, Color(0, 0, 0))
-- end
function color:IsDark( minimumThreshold )
    minimumThreshold = minimumThreshold or 186
    return ( self.r * 0.299 + self.g * 0.587 + self.b * 0.114 ) < minimumThreshold
end
