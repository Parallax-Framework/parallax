--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

---@class ax.color
--- The interface palette: a cinematic monochrome grade over near-black violet-tinted surfaces. These are constants read directly as `ax.color.panel`, not resolved through a selectable theme, because the interface commits to one look.
--- Violet appears only as a cast in the deep shadows, so mid and high tones read neutral and colour stays reserved for status.
ax.color = ax.color or {}

-- Surfaces, darkest to lightest. Every one carries the same violet hue; saturation falls away as lightness rises.
ax.color.void = Color(6, 5, 9)
ax.color.base = Color(10, 8, 14)
ax.color.inset = Color(8, 6, 11)
ax.color.panel = Color(15, 12, 21)
ax.color.raised = Color(21, 17, 29)
ax.color.overlay = Color(27, 22, 37)

-- Hairline rules. Solid rather than translucent so they stay crisp against any surface beneath them.
ax.color.line = Color(38, 32, 50)
ax.color.lineStrong = Color(56, 48, 72)
ax.color.lineFocus = Color(96, 84, 122)

-- Interactive fills. Brightness alone carries state, which is what keeps the grade monochrome.
ax.color.fill = Color(21, 17, 29)
ax.color.fillHover = Color(30, 25, 40)
ax.color.fillActive = Color(40, 34, 53)
ax.color.fillSelected = Color(48, 40, 64)

-- Type ramp.
ax.color.textBright = Color(240, 238, 245)
ax.color.text = Color(198, 193, 208)
ax.color.textMuted = Color(138, 132, 152)
ax.color.textFaint = Color(94, 88, 108)
ax.color.textDisabled = Color(68, 63, 80)

-- Accent, kept desaturated enough to sit inside the grade rather than on top of it.
ax.color.accent = Color(140, 120, 190)
ax.color.accentMuted = Color(88, 76, 118)

-- Status. Colour is an event here, not decoration, so these are the only saturated tokens.
ax.color.danger = Color(196, 88, 96)
ax.color.warning = Color(196, 154, 88)
ax.color.success = Color(112, 164, 136)
ax.color.info = Color(112, 138, 180)

-- Full-screen dim laid behind modal surfaces. There is no blur pass, so the dim alone carries the separation -- and surface alpha composites steeply enough here that anything below ~240 still leaves the content behind it plainly readable.
ax.color.scrim = Color(4, 3, 6, 244)

-- Text shadow for HUD copy drawn over the world rather than over a panel.
ax.color.shadow = Color(0, 0, 0, 200)

---@class ax.ui
--- Layout metrics for the interface. Corners are square by contract, so there is no radius here to configure.
ax.ui = ax.ui or {}

--- Spacing scale in 1080p-reference pixels, resolved through the player's interface scale at call time.
local SPACE = {
    xs = 2,
    sm = 4,
    md = 8,
    lg = 12,
    xl = 18,
    xxl = 28,
}

--- Returns the hairline width for the current display; 1px at 1080p and 2px at 2160p, which keeps its apparent weight constant instead of letting it vanish on high-density screens.
---@realm client
---@return number width Hairline width in pixels, never below 1.
function ax.ui:Hairline()
    return math.max(1, math.floor(ScrH() / 1080))
end

--- Resolves a spacing step to scaled pixels.
---@realm client
---@param key string Step name: `"xs"`, `"sm"`, `"md"`, `"lg"`, `"xl"` or `"xxl"`.
---@return number size Scaled size in pixels, or 0 when the step is unknown.
function ax.ui:Space(key)
    local base = SPACE[key]
    if ( !base ) then
        ax.util:PrintWarning("ax.ui:Space: unknown spacing step '" .. tostring(key) .. "'")
        return 0
    end

    return ax.util:ScreenScale(base)
end

--- Blends two colours; used for hover and focus transitions so state reads as a brightness shift rather than a hue change. Cache the result where you can, since this allocates.
---@realm client
---@param from Color Colour at fraction 0.
---@param to Color Colour at fraction 1.
---@param fraction number Blend position in 0-1, clamped.
---@return Color color The blended colour.
function ax.ui:Mix(from, to, fraction)
    local frac = math.Clamp(fraction, 0, 1)

    return Color(
        Lerp(frac, from.r, to.r),
        Lerp(frac, from.g, to.g),
        Lerp(frac, from.b, to.b),
        Lerp(frac, from.a or 255, to.a or 255)
    )
end
