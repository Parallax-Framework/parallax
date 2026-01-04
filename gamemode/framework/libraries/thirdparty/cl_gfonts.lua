-- Improved Font Creation Override with Proper Aliasing
-- This prevents duplicate font creation AND ensures all font references work correctly
-- ** WARNING: Please dont change the name of the file (!0_gfonts.lua) this must be loaded before everything else to work properly!! **

-- Prevent double loading or lua refresh
if _G.__GFonts_Loaded then return end
_G.__GFonts_Loaded = true

local fontCache = {}
local fontAliases = {}  -- Maps blocked font names to their cached equivalents

local _originalCreateFont = surface.CreateFont
local _originalSetFont = surface.SetFont

local function fontPropertiesMatch(props1, props2)
    return props1.font == props2.font and
        props1.size == props2.size and
        props1.weight == props2.weight and
        props1.antialias == props2.antialias and
        props1.shadow == props2.shadow and
        props1.additive == props2.additive and
        props1.outline == props2.outline and
        props1.extended == props2.extended and
        props1.scanlines == props2.scanlines and
        props1.blursize == props2.blursize
end

-- Override surface.CreateFont to implement the cache check and aliasing
function surface.CreateFont(name, fontProperties)
    -- Check if the font with the same properties already exists in the cache
    for cachedName, cachedProperties in pairs(fontCache) do
        if fontPropertiesMatch(cachedProperties, fontProperties) then
            fontAliases[name] = cachedName -- Store the alias mapping
            return
        end
    end

    -- If no match, proceed with creating the font and cache it
    fontCache[name] = fontProperties
    _originalCreateFont(name, fontProperties)
end

-- Override surface.SetFont to resolve aliases
function surface.SetFont(name)
    _originalSetFont(fontAliases[name] or name)
end

-- Also override draw.SimpleText to handle font aliases
if draw and draw.SimpleText then
    local _originalSimpleText = draw.SimpleText
    function draw.SimpleText(text, font, x, y, color, xalign, yalign)
        return _originalSimpleText(text, fontAliases[font] or font, x, y, color, xalign, yalign)
    end
end

-- Override draw.DrawText to handle font aliases
if draw and draw.DrawText then
    local _originalDrawText = draw.DrawText
    function draw.DrawText(text, font, x, y, color, xalign)
        return _originalDrawText(text, fontAliases[font] or font, x, y, color, xalign)
    end
end

-- Override draw.Text to handle font aliases
if draw and draw.Text then
    local _originalText = draw.Text
    function draw.Text(tab)
        if tab.font then
            tab.font = fontAliases[tab.font] or tab.font
        end
        return _originalText(tab)
    end
end

-- Panel:SetFontInternal alias resolution
do
    local pnlMeta = FindMetaTable("Panel")
    if pnlMeta and pnlMeta.SetFontInternal then
        local _originalSetFontInternal = pnlMeta.SetFontInternal
        function pnlMeta:SetFontInternal(fontName, ...)
            local resolved = fontAliases[fontName] or fontName
            return _originalSetFontInternal(self, resolved, ...)
        end
    else
        -- In case panels aren't ready yet, defer it
        hook.Add("Initialize", "FontAlias_PanelFontInternal", function()
            timer.Simple(0, function()
                local pnlMeta = FindMetaTable("Panel")
                if not pnlMeta or not pnlMeta.SetFontInternal then return end

                local _originalSetFontInternal = pnlMeta.SetFontInternal
                function pnlMeta:SetFontInternal(fontName, ...)
                    return _originalSetFontInternal(self, fontAliases[fontName] or fontName, ...)
                end
            end)
        end)
    end
end
