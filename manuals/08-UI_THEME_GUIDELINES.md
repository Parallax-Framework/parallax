# UI Theme Guidelines

A reference for developers creating user interfaces in the Parallax Framework. All UI must use the glass theme system — do not hardcode colors, fonts, or sizes.

## Table of Contents
- [Overview](#overview)
- [Theme & Color System](#theme--color-system)
- [Font System](#font-system)
- [Drawing Primitives](#drawing-primitives)
- [Component Reference](#component-reference)
- [Layout & Spacing](#layout--spacing)
- [Animation Patterns](#animation-patterns)
- [Custom Panel Recipe](#custom-panel-recipe)
- [Color Mapping Reference](#color-mapping-reference)
- [Common Mistakes](#common-mistakes)

---

## Overview

Parallax uses a **glass-themed UI system** built on a custom rendering library (`ax.render`) and a theme manager (`ax.theme`). Every visual element — panels, buttons, inputs, menus — draws from the same color palette, scales to screen resolution, and animates with consistent easing.

**Core source files:**

| File | Purpose |
|------|---------|
| `gamemode/framework/libraries/cl_theme.lua` | Color palettes, `DrawGlass*` functions, metrics |
| `gamemode/framework/libraries/cl_font.lua` | Font registration and size tiers |
| `gamemode/framework/libraries/thirdparty/cl_rndx.lua` | Low-level render builder and flags |
| `gamemode/framework/interface/cl_button.lua` | `ax.button`, `ax.button.icon` |
| `gamemode/framework/interface/cl_frame.lua` | `ax.frame` |
| `gamemode/framework/interface/cl_text.lua` | `ax.text`, `ax.text.entry`, `ax.text.typewriter` |
| `gamemode/framework/interface/cl_tab.lua` | `ax.tab` |
| `gamemode/framework/interface/cl_combobox.lua` | `ax.combobox`, `ax.dmenu` |
| `gamemode/framework/interface/cl_tooltip.lua` | `ax.tooltip` |
| `gamemode/framework/interface/cl_scroller.lua` | `ax.scroller` |
| `gamemode/framework/interface/cl_derma.lua` | `Derma_Message`, `Derma_Query`, `Derma_StringRequest` |

---

## Theme & Color System

### Retrieving the Active Theme

```lua
local glass   = ax.theme:GetGlass()    -- color palette for the current theme
local metrics = ax.theme:GetMetrics()  -- user-configurable visual adjustments
```

Always retrieve these inside `Paint()` or at call time — never cache them across frames, as the user can change themes at runtime.

### Color Keys

Every key below exists on the `glass` table returned by `ax.theme:GetGlass()`.

| Key | Purpose |
|-----|---------|
| `glass.panel` | Panel and container backgrounds |
| `glass.panelBorder` | Panel border outlines |
| `glass.header` | Window header section backgrounds |
| `glass.button` | Button default (idle) fill |
| `glass.buttonHover` | Button fill on hover |
| `glass.buttonActive` | Button fill when pressed |
| `glass.buttonBorder` | Button border outline |
| `glass.input` | Text entry field backgrounds |
| `glass.inputBorder` | Text entry border |
| `glass.menu` | Context menu and dropdown backgrounds |
| `glass.menuBorder` | Context menu border |
| `glass.overlay` | Translucent modal/overlay backdrops |
| `glass.overlayStrong` | Stronger modal backdrop (more opaque) |
| `glass.progress` | Progress bars and accent fills |
| `glass.highlight` | Highlighted or selected elements |
| `glass.gradientTop` | Top-edge gradient tint |
| `glass.gradientBottom` | Bottom-edge gradient tint |
| `glass.gradientLeft` | Left-edge gradient tint |
| `glass.gradientRight` | Right-edge gradient tint |
| `glass.tabBackdrop` | Full-screen tab menu backdrop |
| `glass.text` | Primary text color |
| `glass.textHover` | Text color during hover |
| `glass.textMuted` | Secondary/disabled text color |
| `glass.comboboxHoveredArrow` | Combobox chevron color on hover |

### Theme Metrics

```lua
local metrics = ax.theme:GetMetrics()
-- metrics.blur            -- Global blur intensity multiplier (default 1.0)
-- metrics.roundness       -- Global corner radius in pixels (default 8)
-- metrics.opacity         -- Overall alpha scale (default 1.0)
-- metrics.borderOpacity   -- Border alpha scale (default 1.0)
-- metrics.gradientOpacity -- Gradient alpha scale (default 1.0)
```

Always multiply blur and alpha values by the relevant metric so users' settings are respected:

```lua
fill   = ax.theme:ScaleAlpha( glass.panel, metrics.opacity )
border = ax.theme:ScaleAlpha( glass.panelBorder, metrics.borderOpacity )
blur   = 1.1 * metrics.blur
```

### Alpha Scaling

```lua
-- Returns a copy of color with its alpha multiplied by factor
local tinted = ax.theme:ScaleAlpha( glass.panel, 0.5 )
```

Use this instead of `ColorAlpha()` when you want to respect the user's opacity setting.

### Available Themes

`dark` (default), `light`, `blue`, `purple`, `green`, `red`, `orange`

---

## Font System

### Naming Convention

```
ax.[size]
ax.[size].[style]
ax.[size].[style1].[style2]
```

Styles can be combined in any order: `bold`, `italic`, `black`, `shadow`.

**Examples:**

```lua
"ax.regular"             -- base font, no styles
"ax.regular.bold"        -- bold weight
"ax.large.bold.italic"   -- large bold italic
"ax.small.shadow"        -- small with drop shadow
"ax.huge.bold.shadow"    -- huge bold with shadow
```

### Size Tiers

All sizes are scaled from a 1080p reference height at runtime.

| Name | Base Size | Typical Use |
|------|-----------|-------------|
| `tiny` | 5px | Fine print, badges |
| `small` | 7px | Tooltips, meta text, secondary labels |
| `regular` | 9px | Default body text, buttons |
| `medium` | 11px | Slightly emphasized body text |
| `large` | 15px | Window titles, section headers |
| `massive` | 21px | Large headers |
| `huge` | 25px | Key HUD values (ammo count, etc.) |
| `giant` | 35px | Splash screens, main menu titles |

### Common Font Assignments

| Context | Font |
|---------|------|
| Button default | `"ax.regular"` |
| Button hovered | `"ax.regular.bold"` |
| Window title | `"ax.large"` |
| Tooltip title | `"ax.regular.bold"` |
| Tooltip body | `"ax.small"` |
| Tooltip meta | `"ax.small.italic"` |
| HUD weapon name | `"ax.regular.bold.italic"` |
| HUD ammo count | `"ax.huge.bold"` |

---

## Drawing Primitives

### `ax.render` Builder

The low-level drawing API uses a fluent builder pattern.

```lua
-- Draw a filled rounded rectangle
ax.render().Rect( x, y, w, h )
    :Rad( radius )            -- corner radius
    :Flags( ax.render.SHAPE_IOS )
    :Blur( amount )           -- blur strength (0 = none)
    :Draw()

-- Draw a filled shape directly (no blur)
ax.render.Draw( radius, x, y, w, h, color, flags )

-- Draw an outline only
ax.render.DrawOutlined( radius, x, y, w, h, color, thickness, flags )

-- Draw with a material (e.g. icons, vignette)
ax.render.DrawMaterial( radius, x, y, w, h, color, material, flags )
```

### Shape Flags

```lua
ax.render.SHAPE_IOS   -- Default: modern rounded rectangle
ax.render.SHAPE_CIRCLE
ax.render.SHAPE_FIGMA
```

### Corner Mask Flags

Combine with `bit.bor()` to skip specific corners:

```lua
ax.render.NO_TL  -- no top-left radius
ax.render.NO_TR  -- no top-right radius
ax.render.NO_BL  -- no bottom-left radius
ax.render.NO_BR  -- no bottom-right radius
```

### `ax.theme` Glass Helpers

Prefer these over calling `ax.render` directly — they handle blur, fill, border, and metric scaling automatically.

```lua
-- Standard panel background
ax.theme:DrawGlassPanel( x, y, w, h, {
    radius = metrics.roundness,     -- defaults to metrics.roundness
    blur   = 1.1,                   -- multiplied by metrics.blur internally
    flags  = ax.render.SHAPE_IOS,
    fill   = ax.theme:ScaleAlpha( glass.panel, metrics.opacity ),
    border = ax.theme:ScaleAlpha( glass.panelBorder, metrics.borderOpacity ),
} )

-- Button surface (slightly softer blur, adaptive radius)
ax.theme:DrawGlassButton( x, y, w, h, {
    fill   = color,
    blur   = 0.85,
    border = glass.buttonBorder,
} )

-- Full-screen or large modal backdrop
ax.theme:DrawGlassBackdrop( x, y, w, h, {
    radius = 0,
    blur   = 1.1,
    fill   = ax.theme:ScaleAlpha( glass.overlay, metrics.opacity ),
} )

-- Edge gradients (atmospheric depth)
ax.theme:DrawGlassGradients( x, y, w, h, {
    left   = glass.gradientLeft,
    right  = glass.gradientRight,
    top    = glass.gradientTop,
    bottom = glass.gradientBottom,
} )
```

---

## Component Reference

All framework VGUI elements are registered under `ax.*` and can be added with `self:Add("ax.button")`, etc.

### `ax.frame`

Draggable window with title bar and close button.

| Property | Value |
|----------|-------|
| Default size | 50% of screen width × height |
| Corner radius | 12px (fixed) |
| Header height | ~58px |
| Content DockPadding | `12, 64, 12, 12` (L, T, R, B) scaled |
| Title font | `"ax.large"` |
| Close button size | 40×40px, margin 8px top-right |
| Background blur | Animated from creation time |

```lua
local frame = vgui.Create( "ax.frame" )
frame:SetTitle( "My Window" )
frame:SetSize( ax.util:ScreenScale( 400 ), ax.util:ScreenScaleH( 300 ) )
frame:Center()
frame:MakePopup()
```

### `ax.button` / `ax.button.icon`

State-driven button with animated hover/press transitions.

| Property | Value |
|----------|-------|
| Default font | `"ax.regular"` |
| Hovered font | `"ax.regular.bold"` |
| Horizontal padding (SizeToContents) | +16px scaled |
| Vertical padding (SizeToContents) | +8px scaled |
| Border radius | `math.max( 4, math.min( 12, h * 0.35 ) )` |
| Blur multiplier | 0.85× |
| Hover easing | `"OutQuint"`, 0.25 s |
| Hover sound | `"ax.gui.button.enter"` |
| Click sound | `"ax.gui.button.click"` |

Button state is driven by an `inertia` value (0–1):

| Inertia | Color Used |
|---------|-----------|
| ≤ 0.25 | `glass.button` (idle) |
| 0.25–0.80 | `glass.buttonHover` |
| > 0.80 | `glass.buttonActive` (pressed) |

`ax.button.icon` adds an icon with configurable alignment (`"left"`, `"right"`, `"center"`) and spacing of 4px scaled.

```lua
local btn = panel:Add( "ax.button" )
btn:SetText( "Confirm" )
btn:SizeToContents()
btn:Dock( BOTTOM )
btn:DockMargin( 0, ax.util:ScreenScaleH( 8 ), 0, 0 )
```

### `ax.text`

Label that pads itself on `SizeToContents()`.

| Property | Value |
|----------|-------|
| SizeToContents padding | +8px width, +4px height |
| Default font | `"ax.regular"` |
| Default color | `glass.text` |

```lua
local lbl = panel:Add( "ax.text" )
lbl:SetText( "Hello" )
lbl:SetFont( "ax.regular.bold" )
lbl:SizeToContents()
lbl:Dock( TOP )
```

### `ax.text.entry`

Single-line text input field.

| Property | Value |
|----------|-------|
| Default height | `draw.GetFontHeight( "ax.regular" ) + 8` |
| Border radius | `math.max( 4, math.min( 8, h * 0.35 ) )` |
| Blur multiplier | 0.6× |
| Fill | `glass.input` |
| Border | `glass.inputBorder` |
| Cursor & highlight color | `color_white` |

### `ax.text.typewriter`

Same as `ax.text` but animates characters appearing one at a time. Use for narrative/atmospheric text.

### `ax.tab`

Full-screen tab menu system with a top button bar and optional sub-button bar.

| Property | Value |
|----------|-------|
| Button bar height | ~40px scaled |
| Content X offset | 24px scaled |
| Content Y offset | button bar height + 32px scaled |
| Content W offset | −48px scaled |
| Content H offset | −button bar height − 64px scaled |
| Tab fade duration | 0.25 s |

Tab backdrop uses blur `1.4 ×` the current backdrop value, rendered with `ax.render.SHAPE_IOS` at radius `0`.

### `ax.combobox`

Dropdown selector.

| Property | Value |
|----------|-------|
| Default height | 22px |
| Border radius | `math.max( 4, math.min( 8, h * 0.35 ) )` |
| Blur multiplier | 0.7× |
| Disabled text | `glass.textMuted` |
| Arrow icon | `"parallax/icons/chevron-down.png"` |

### `ax.dmenu`

Context/right-click menu.

| Property | Value |
|----------|-------|
| Corner radius | 8px |
| Blur multiplier | 0.9× |
| Fill | `glass.menu` |
| Border | `glass.menuBorder` |

### `ax.tooltip`

Hover tooltip with structured sections.

| Property | Value |
|----------|-------|
| Max width (responsive) | `max( 240px, min( 360px, ScrW() * 0.18 ) )` scaled |
| Padding | 12px scaled |
| Corner radius | `math.max( 8, ax.util:Scale( 10 ) )` |
| Gap from target | 10px scaled |
| Screen edge margin | 12px scaled |
| Accent border width | `math.max( 2, ax.util:Scale( 3 ) )` |
| Open animation | 0.18 s |
| Close animation | 0.12 s |

Section priority order (top to bottom):

1. **Badge** — small accent-colored label, top-right
2. **Title** — `"ax.regular.bold"`
3. **Description** — `"ax.small"`
4. **Meta** — `"ax.small.italic"`
5. **Footer** — `"ax.small"`

### `ax.scroller`

Scrollable container. Use as a parent for vertically-stacked lists. Handles overflow clipping and a styled scrollbar automatically.

---

## Layout & Spacing

### Screen Scaling

**Always** wrap pixel values through the scaling utilities. Never write raw pixel values for positions, margins, or sizes that should be resolution-independent.

```lua
ax.util:ScreenScale( value )   -- scales based on screen width  (reference: 1920)
ax.util:ScreenScaleH( value )  -- scales based on screen height (reference: 1080)
ax.util:Scale( value )         -- generic scale
```

### Recommended Spacing Constants (pre-scaling)

| Size | Value | Use Case |
|------|-------|----------|
| XS | 4px | Icon-to-text gap, tight margins |
| S | 8px | Button inner padding, small gaps |
| M | 12px | Panel padding, tooltip padding |
| L | 16px | Main container padding |
| XL | 24px | Tab offsets, section separators |
| XXL | 32–64px | Full layout offsets |

### Docking Pattern

```lua
-- Panel with padded content area
panel:DockPadding( ax.util:ScreenScale( 12 ), ax.util:ScreenScaleH( 12 ),
                   ax.util:ScreenScale( 12 ), ax.util:ScreenScaleH( 12 ) )

-- Child with right margin between siblings
child:Dock( LEFT )
child:DockMargin( 0, 0, ax.util:ScreenScale( 4 ), 0 )
```

### Frame Content Padding

The standard `ax.frame` sets `DockPadding( 12, 64, 12, 12 )` (all scaled). Any content added directly to the frame respects this automatically.

---

## Animation Patterns

### `panel:Motion()`

```lua
panel:Motion( duration, {
    Target = { property = targetValue },
    Easing = "OutQuint",
    Think = function(vars)
        -- called every frame with interpolated values
        self:SetSomeValue( vars.property )
    end,
    OnComplete = function(panel)
        -- called once when animation ends
    end,
} )
```

### `panel:AlphaTo()`

```lua
panel:AlphaTo( targetAlpha, duration, delay, callback )

-- Fade in
panel:AlphaTo( 255, 0.1, 0 )

-- Fade out then remove
panel:AlphaTo( 0, 0.2, 0, function()
    panel:Remove()
end )
```

### Standard Durations

| Context | Duration |
|---------|----------|
| Button hover / press | 0.25 s |
| Tab page transition | 0.25 s |
| Tooltip open | 0.18 s |
| Tooltip close | 0.12 s |
| Dialog backdrop blur | 1.0 s (lerp) |

### Easing

| Easing | When to Use |
|--------|------------|
| `"OutQuint"` | Standard interactive animations — feels smooth and snappy |
| `"OutQuad"` | Slightly faster deceleration for small, tight animations |
| `"Linear"` | Only for looped or progress-style animations |

---

## Custom Panel Recipe

A minimal panel that correctly follows all framework conventions:

```lua
-- cl_my_panel.lua (client-only)

local PANEL = {}

function PANEL:Init()
    -- Disable default Derma painting
    self:SetPaintBackgroundEnabled( false )
    self:SetPaintBorderEnabled( false )
    self:SetMouseInputEnabled( true )

    -- Title label
    self.title = self:Add( "ax.text" )
    self.title:SetFont( "ax.large" )
    self.title:SetText( "My Panel" )
    self.title:SizeToContents()
    self.title:Dock( TOP )
    self.title:DockMargin( 0, 0, 0, ax.util:ScreenScaleH( 8 ) )

    -- Action button
    self.confirm = self:Add( "ax.button" )
    self.confirm:SetText( "Confirm" )
    self.confirm:SizeToContents()
    self.confirm:Dock( BOTTOM )
    self.confirm:DockMargin( 0, ax.util:ScreenScaleH( 8 ), 0, 0 )
    self.confirm.DoClick = function()
        -- handle action
    end

    -- Padding for content
    self:DockPadding(
        ax.util:ScreenScale( 12 ),
        ax.util:ScreenScaleH( 12 ),
        ax.util:ScreenScale( 12 ),
        ax.util:ScreenScaleH( 12 )
    )
end

function PANEL:Paint(width, height)
    local glass   = ax.theme:GetGlass()
    local metrics = ax.theme:GetMetrics()

    ax.theme:DrawGlassPanel( 0, 0, width, height, {
        radius = metrics.roundness,
        blur   = 1.1,
        flags  = ax.render.SHAPE_IOS,
        fill   = ax.theme:ScaleAlpha( glass.panel, metrics.opacity ),
        border = ax.theme:ScaleAlpha( glass.panelBorder, metrics.borderOpacity ),
    } )
end

vgui.Register( "my_schema.myPanel", PANEL, "EditablePanel" )
```

To open as a window, wrap it in `ax.frame`:

```lua
local frame = vgui.Create( "ax.frame" )
frame:SetTitle( "My Panel" )
frame:SetSize( ax.util:ScreenScale( 400 ), ax.util:ScreenScaleH( 300 ) )
frame:Center()
frame:MakePopup()

local content = frame:Add( "my_schema.myPanel" )
content:Dock( FILL )
```

---

## Color Mapping Reference

| Context | Fill | Text | Border | Hover Fill |
|---------|------|------|--------|-----------|
| Panel | `glass.panel` | `glass.text` | `glass.panelBorder` | — |
| Header | `glass.header` | `glass.text` | `glass.panelBorder` | — |
| Button | `glass.button` | `glass.text` | `glass.buttonBorder` | `glass.buttonHover` |
| Button (pressed) | `glass.buttonActive` | `glass.textHover` | `glass.buttonBorder` | — |
| Text Entry | `glass.input` | `glass.text` | `glass.inputBorder` | — |
| Dropdown / Menu | `glass.menu` | `glass.text` | `glass.menuBorder` | `glass.buttonHover` |
| Modal Backdrop | `glass.overlay` | — | — | — |
| Strong Backdrop | `glass.overlayStrong` | — | — | — |
| Highlight / Selected | `glass.highlight` | `glass.text` | — | — |
| Progress | `glass.progress` | — | — | — |
| Disabled / Secondary | `glass.panel` | `glass.textMuted` | `glass.panelBorder` | — |

---

## Common Mistakes

### Hardcoding colors

```lua
-- Wrong
surface.SetDrawColor( 18, 22, 28, 180 )

-- Right
local glass = ax.theme:GetGlass()
ax.theme:DrawGlassPanel( 0, 0, w, h, { fill = glass.panel } )
```

### Skipping screen scaling

```lua
-- Wrong
element:SetTall( 34 )

-- Right
element:SetTall( ax.util:ScreenScaleH( 34 ) )
```

### Ignoring metrics in alpha

```lua
-- Wrong
fill = glass.panel

-- Right
fill = ax.theme:ScaleAlpha( glass.panel, metrics.opacity )
```

### Drawing outside Paint bounds

Paint functions receive `width` and `height` — always draw relative to `(0, 0)`, never use `self:GetPos()` or absolute screen coordinates inside Paint.

```lua
-- Wrong
function PANEL:Paint()
    local x, y = self:GetPos()
    surface.DrawRect( x, y, 100, 100 )
end

-- Right
function PANEL:Paint(width, height)
    surface.DrawRect( 0, 0, width, height )
end
```

### Caching glass outside Paint

```lua
-- Wrong (stale after theme change)
local glass = ax.theme:GetGlass()
function PANEL:Paint(w, h)
    draw.SimpleText( "hi", "ax.regular", 0, 0, glass.text )
end

-- Right
function PANEL:Paint(w, h)
    local glass = ax.theme:GetGlass()
    draw.SimpleText( "hi", "ax.regular", 0, 0, glass.text )
end
```

### Using raw Derma elements without glass styling

Panels that use `DPanel`, `DButton`, or `DLabel` without overriding their `Paint` functions will render with the default Derma skin and look out of place. Either use the `ax.*` equivalents or explicitly override `Paint` with `ax.theme:DrawGlass*` calls.

---

**Version**: 1.0
**Last Updated**: 2026-04-05
