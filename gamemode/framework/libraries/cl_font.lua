ax.font = ax.font or {}
ax.font.stored = ax.font.stored or {}

surface.axCreateFont = surface.axCreateFont or surface.CreateFont

function surface.CreateFont(name, data)
    if ( !isstring(name) or !istable(data) ) then
        ax.util:PrintError("Invalid parameters for surface.CreateFont: " .. tostring(name) .. ", " .. tostring(data))
        return
    end

    if ( string.sub(name, 1, 3) == "ax." or string.StartsWith(name, "Parallax") ) then
        ax.font.stored[name] = data
    end

    surface.axCreateFont(name, data)
end