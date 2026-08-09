--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

---@class ax.font
--- Font registry for the Parallax interface. Families are named `ax.<size>` with optional `.bold`, `.italic` and `.shadow` suffixes applied in that fixed order, so `ax.small.bold` and `ax.large.bold.italic` are valid but a reordered suffix is not.
---@field stored table Font data keyed by the registered font name.
ax.font = ax.font or {}
ax.font.stored = ax.font.stored or {}

ax.font.face = "Inter"

--- Size ramp in pixels at a 1080p reference height, scaled to the player's display and font scale options at load time.
ax.font.sizes = {
    tiny = 11,
    small = 13,
    regular = 15,
    medium = 17,
    large = 21,
    massive = 27,
    huge = 34,
    giant = 46,
}

local SMALL_FAMILIES = {
    tiny = true,
    small = true,
    regular = true,
    medium = true,
}

local BIG_FAMILIES = {
    large = true,
    massive = true,
    huge = true,
    giant = true,
}

--- Style suffixes in canonical order; each entry is generated once rather than in every possible ordering.
local VARIANTS = {
    { suffix = "", bold = false, italic = false, shadow = false },
    { suffix = ".bold", bold = true, italic = false, shadow = false },
    { suffix = ".italic", bold = false, italic = true, shadow = false },
    { suffix = ".shadow", bold = false, italic = false, shadow = true },
    { suffix = ".bold.italic", bold = true, italic = true, shadow = false },
    { suffix = ".bold.shadow", bold = true, italic = false, shadow = true },
    { suffix = ".italic.shadow", bold = false, italic = true, shadow = true },
    { suffix = ".bold.italic.shadow", bold = true, italic = true, shadow = true },
}

--- Scales a 1080p-reference pixel size to the current display height.
---@realm client
---@param value number Size in pixels at 1080p.
---@return number size The scaled size, never below 1.
function ax.font:Scale(value)
    return math.max(value * (ScrH() / 1080), 1)
end

--- Creates every style variant of a font family and registers them under `ax.<name>`.
---@realm client
---@param name string Family name, e.g. `"regular"` or `"small.admin"`.
---@param face string Font face to use, e.g. `"Inter"`.
---@param size number Final pixel size; pass the value through `ax.font:Scale` first if it is a 1080p reference size.
---@param data? table Extra `surface.CreateFont` fields merged into every variant.
function ax.font:CreateFamily(name, face, size, data)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("ax.font:CreateFamily: invalid family name")
        return
    end

    if ( !isstring(face) or !isnumber(size) or size <= 0 ) then
        ax.util:PrintError("ax.font:CreateFamily: invalid face or size for family '" .. tostring(name) .. "'")
        return
    end

    for i = 1, #VARIANTS do
        local variant = VARIANTS[i]
        local fontName = "ax." .. name .. variant.suffix

        local fontData = {
            font = face,
            size = size,
            weight = variant.bold and 700 or 400,
            italic = variant.italic,
            shadow = variant.shadow,
            antialias = true,
            extended = true,
        }

        if ( istable(data) ) then
            table.Merge(fontData, data)
        end

        self.stored[fontName] = fontData

        surface.CreateFont(fontName, fontData)
    end
end

--- Rebuilds the whole font set; called on initialise, on hot-reload, and whenever a font scale option changes.
---@realm client
function ax.font:Load()
    local generalScale = ax.option and ax.option:Get("fontScaleGeneral", 1) or 1
    local smallScale = ax.option and ax.option:Get("fontScaleSmall", 1) or 1
    local bigScale = ax.option and ax.option:Get("fontScaleBig", 1) or 1

    for name, base in pairs(self.sizes) do
        local scale = generalScale

        if ( SMALL_FAMILIES[name] ) then
            scale = scale * smallScale
        elseif ( BIG_FAMILIES[name] ) then
            scale = scale * bigScale
        end

        self:CreateFamily(name, self.face, self:Scale(base * scale))
    end

    hook.Run("LoadFonts")
end

--- Returns every registered font name, sorted, for a settings picker to list.
---@realm client
---@return table names Sorted array of font names.
function ax.font:GetAvailable()
    local names = {}

    for name in pairs(self.stored) do
        names[#names + 1] = name
    end

    table.sort(names)

    return names
end
