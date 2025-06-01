--- Colors library
-- @module ax.color

ax.color = {}
ax.color.stored = {}
local colorObject = FindMetaTable("Color")

--- Registers a new color.
-- @realm shared
-- @param info A table containing information about the color.
function ax.color:Register(name, color)
    if ( !isstring(name) or #name == 0 ) then
        ax.util:PrintError("Attempted to register a color without a name!")
        return false
    end

    if ( !IsColor(color) ) then
        ax.util:PrintError("Attempted to register a color without a color!")
        return false
    end

    local bResult = hook.Run("PreColorRegistered", name, color)
    if ( bResult == false ) then return false end

    self.stored[name] = color
    hook.Run("OnColorRegistered", name, color)
end

--- Gets a color by its name.
-- @realm shared
-- @param name The name of the color.
-- @return The color.
function ax.color:Get(name)
    local storedColor = self.stored[name]
    if ( IsColor(storedColor) or ( istable(storedColor) and isnumber(storedColor.r) and isnumber(storedColor.g) and isnumber(storedColor.b) and isnumber(storedColor.a) ) ) then
        return storedColor:Copy()
    end

    ax.util:PrintError("Attempted to get an invalid color!")
    return nil
end

--- Dims a color by a specified fraction.
-- @realm shared
-- @param col Color The color to dim.
-- @param frac number The fraction to dim the color by.
-- @return Color The dimmed color.
function ax.color:Dim(col, frac)
    return setmetatable({r = col.r * frac, g = col.g * frac, b = col.b * frac, a = col.a}, colorObject)
end

--- Returns whether or not a color is dark.
-- @realm shared
-- @param col Color The color to check.
-- @return boolean True if the color is dark, false otherwise.
-- @note A color is considered dark if its luminance is less than 0.5.
function ax.color:IsDark(col)
    if ( !IsColor(col) ) then
        ax.util:PrintError("Attempted to check if a color is dark without a valid color!")
        return false
    end

    local r, g, b = col.r / 255, col.g / 255, col.b / 255

    local luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
    return luminance < 0.5
end

if ( CLIENT ) then
    concommand.Add("ax_list_colors", function(client, cmd, arguments)
        for k, v in pairs(ax.color.stored) do
            ax.util:Print("Color: " .. k .. " >> ", ax.color:Get("cyan"), v, " Color Sample")
        end
    end)
end