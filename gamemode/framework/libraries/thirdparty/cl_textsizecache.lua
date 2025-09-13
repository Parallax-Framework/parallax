local textSizeCache = {}

local oldSetFont = oldSetFont or surface.SetFont
local oldGetTextSize = oldGetTextSize or surface.GetTextSize

local activeFont = "Default"

function surface.SetFont(font)
    if ( activeFont != font ) then
        activeFont = font
    end

    oldSetFont(font)
end

function surface.GetTextSize(text)
    if ( textSizeCache[ text .. activeFont ] ) then
        return textSizeCache[ text .. activeFont ][ 1 ], textSizeCache[ text .. activeFont ][ 2 ]
    end

    local w, h = oldGetTextSize( text )
    textSizeCache[ text .. activeFont ] = { w, h }
    return w, h
end

-- Invalidate cache on screen size
hook.Add( "OnScreenSizeChanged", "ax.textsizecache.clear.screensize", function()
    textSizeCache = {}
end )

-- Invalidate cache on font load ( example: font28's size gets changed in code )
hook.Add( "LoadFonts", "ax.textsizecache.clear.fonts", function()
    textSizeCache = {}
end )
