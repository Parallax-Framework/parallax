--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Client-side theme registry and glass UI rendering helpers.
-- Provides theme palette lookups, user-configurable glass metrics, and shared
-- drawing helpers used throughout the framework UI.
-- @module ax.theme

ax.theme = ax.theme or {}
ax.theme.themes = ax.theme.themes or {}

ax.theme.themes.dark = {
    glass = {
        panel = Color(18, 22, 28, 180),
        panelBorder = Color(120, 140, 180, 70),
        header = Color(26, 32, 40, 210),
        button = Color(26, 32, 40, 170),
        buttonHover = Color(38, 48, 62, 210),
        buttonActive = Color(55, 70, 92, 230),
        buttonBorder = Color(140, 160, 200, 85),
        input = Color(22, 28, 36, 180),
        inputBorder = Color(120, 140, 180, 80),
        menu = Color(24, 30, 38, 200),
        menuBorder = Color(120, 140, 180, 80),
        overlay = Color(12, 16, 20, 90),
        overlayStrong = Color(12, 16, 20, 150),
        progress = Color(120, 180, 220, 200),
        highlight = Color(90, 140, 200, 120),
        gradientTop = Color(50, 70, 100, 45),
        gradientBottom = Color(12, 18, 30, 60),
        gradientLeft = Color(35, 55, 85, 30),
        gradientRight = Color(35, 55, 85, 30),
        tabBackdrop = Color(12, 16, 20, 35),
        text = Color(230, 235, 245, 255),
        textHover = Color(245, 250, 255, 255),
        textMuted = Color(180, 190, 205, 255),
        comboboxHoveredArrow = Color(255, 255, 255, 200)
    }
}

ax.theme.themes.light = {
    glass = {
        panel = Color(200, 210, 225, 200),
        panelBorder = Color(120, 140, 170, 120),
        header = Color(190, 203, 220, 225),
        button = Color(195, 207, 222, 190),
        buttonHover = Color(180, 192, 210, 230),
        buttonActive = Color(160, 172, 195, 245),
        buttonBorder = Color(110, 135, 165, 140),
        input = Color(215, 223, 235, 200),
        inputBorder = Color(120, 140, 170, 140),
        menu = Color(207, 217, 232, 220),
        menuBorder = Color(120, 140, 170, 140),
        overlay = Color(225, 232, 242, 100),
        overlayStrong = Color(215, 223, 235, 150),
        progress = Color(65, 120, 180, 225),
        highlight = Color(85, 140, 200, 160),
        gradientTop = Color(175, 195, 220, 60),
        gradientBottom = Color(205, 220, 235, 85),
        gradientLeft = Color(185, 205, 230, 50),
        gradientRight = Color(185, 205, 230, 50),
        tabBackdrop = Color(225, 232, 242, 60),
        text = Color(20, 25, 35, 255),
        textHover = Color(5, 10, 20, 255),
        textMuted = Color(70, 85, 105, 255),
        comboboxHoveredArrow = Color(20, 25, 35, 200)
    }
}

ax.theme.themes.blue = {
    glass = {
        panel = Color(12, 18, 32, 180),
        panelBorder = Color(80, 120, 180, 85),
        header = Color(18, 26, 42, 210),
        button = Color(18, 26, 42, 170),
        buttonHover = Color(28, 42, 68, 210),
        buttonActive = Color(42, 62, 95, 230),
        buttonBorder = Color(100, 140, 200, 100),
        input = Color(15, 22, 38, 180),
        inputBorder = Color(80, 120, 180, 90),
        menu = Color(16, 24, 40, 200),
        menuBorder = Color(80, 120, 180, 90),
        overlay = Color(8, 12, 22, 100),
        overlayStrong = Color(8, 12, 22, 160),
        progress = Color(100, 160, 240, 220),
        highlight = Color(80, 140, 220, 140),
        gradientTop = Color(30, 60, 110, 50),
        gradientBottom = Color(8, 16, 35, 70),
        gradientLeft = Color(20, 45, 90, 35),
        gradientRight = Color(20, 45, 90, 35),
        tabBackdrop = Color(8, 12, 22, 40),
        text = Color(220, 235, 255, 255),
        textHover = Color(240, 250, 255, 255),
        textMuted = Color(160, 180, 210, 255),
        comboboxHoveredArrow = Color(220, 235, 255, 200)
    }
}

ax.theme.themes.purple = {
    glass = {
        panel = Color(22, 16, 32, 180),
        panelBorder = Color(140, 100, 180, 85),
        header = Color(32, 24, 46, 210),
        button = Color(32, 24, 46, 170),
        buttonHover = Color(48, 36, 68, 210),
        buttonActive = Color(68, 52, 92, 230),
        buttonBorder = Color(160, 120, 200, 100),
        input = Color(26, 20, 38, 180),
        inputBorder = Color(140, 100, 180, 90),
        menu = Color(28, 22, 42, 200),
        menuBorder = Color(140, 100, 180, 90),
        overlay = Color(14, 10, 22, 100),
        overlayStrong = Color(14, 10, 22, 160),
        progress = Color(180, 120, 240, 220),
        highlight = Color(160, 100, 220, 140),
        gradientTop = Color(60, 40, 100, 50),
        gradientBottom = Color(16, 12, 35, 70),
        gradientLeft = Color(45, 30, 85, 35),
        gradientRight = Color(45, 30, 85, 35),
        tabBackdrop = Color(14, 10, 22, 40),
        text = Color(235, 220, 255, 255),
        textHover = Color(250, 240, 255, 255),
        textMuted = Color(180, 160, 210, 255),
        comboboxHoveredArrow = Color(235, 220, 255, 200)
    }
}

ax.theme.themes.green = {
    glass = {
        panel = Color(16, 24, 20, 180),
        panelBorder = Color(100, 160, 120, 85),
        header = Color(22, 34, 28, 210),
        button = Color(22, 34, 28, 170),
        buttonHover = Color(32, 50, 40, 210),
        buttonActive = Color(48, 72, 58, 230),
        buttonBorder = Color(120, 180, 140, 100),
        input = Color(18, 28, 24, 180),
        inputBorder = Color(100, 160, 120, 90),
        menu = Color(20, 32, 26, 200),
        menuBorder = Color(100, 160, 120, 90),
        overlay = Color(10, 16, 14, 100),
        overlayStrong = Color(10, 16, 14, 160),
        progress = Color(120, 220, 160, 220),
        highlight = Color(100, 200, 140, 140),
        gradientTop = Color(40, 80, 60, 50),
        gradientBottom = Color(12, 24, 18, 70),
        gradientLeft = Color(30, 65, 45, 35),
        gradientRight = Color(30, 65, 45, 35),
        tabBackdrop = Color(10, 16, 14, 40),
        text = Color(220, 245, 230, 255),
        textHover = Color(240, 255, 245, 255),
        textMuted = Color(160, 200, 175, 255),
        comboboxHoveredArrow = Color(220, 245, 230, 200)
    }
}

ax.theme.themes.red = {
    glass = {
        panel = Color(28, 16, 18, 180),
        panelBorder = Color(180, 100, 110, 85),
        header = Color(38, 22, 26, 210),
        button = Color(38, 22, 26, 170),
        buttonHover = Color(56, 32, 38, 210),
        buttonActive = Color(78, 48, 55, 230),
        buttonBorder = Color(200, 120, 130, 100),
        input = Color(32, 18, 22, 180),
        inputBorder = Color(180, 100, 110, 90),
        menu = Color(34, 20, 24, 200),
        menuBorder = Color(180, 100, 110, 90),
        overlay = Color(18, 10, 12, 100),
        overlayStrong = Color(18, 10, 12, 160),
        progress = Color(240, 120, 140, 220),
        highlight = Color(220, 100, 120, 140),
        gradientTop = Color(80, 40, 50, 50),
        gradientBottom = Color(24, 12, 16, 70),
        gradientLeft = Color(65, 30, 40, 35),
        gradientRight = Color(65, 30, 40, 35),
        tabBackdrop = Color(18, 10, 12, 40),
        text = Color(245, 220, 225, 255),
        textHover = Color(255, 240, 245, 255),
        textMuted = Color(200, 160, 170, 255),
        comboboxHoveredArrow = Color(245, 220, 225, 200)
    }
}

ax.theme.themes.orange = {
    glass = {
        panel = Color(30, 20, 12, 180),
        panelBorder = Color(205, 140, 80, 85),
        header = Color(42, 28, 16, 210),
        button = Color(42, 28, 16, 170),
        buttonHover = Color(62, 40, 22, 210),
        buttonActive = Color(88, 56, 30, 230),
        buttonBorder = Color(225, 160, 95, 100),
        input = Color(34, 22, 14, 180),
        inputBorder = Color(205, 140, 80, 90),
        menu = Color(36, 24, 15, 200),
        menuBorder = Color(205, 140, 80, 90),
        overlay = Color(20, 12, 8, 100),
        overlayStrong = Color(20, 12, 8, 160),
        progress = Color(255, 170, 90, 220),
        highlight = Color(240, 150, 70, 140),
        gradientTop = Color(95, 55, 25, 50),
        gradientBottom = Color(30, 16, 8, 70),
        gradientLeft = Color(75, 40, 18, 35),
        gradientRight = Color(75, 40, 18, 35),
        tabBackdrop = Color(20, 12, 8, 40),
        text = Color(255, 234, 214, 255),
        textHover = Color(255, 245, 230, 255),
        textMuted = Color(220, 185, 150, 255),
        comboboxHoveredArrow = Color(255, 234, 214, 200)
    }
}

--- Clone a color with its alpha channel scaled.
-- @local
-- @param color Color Source color to scale
-- @param[opt=1] scale number Alpha multiplier
-- @return Color|nil scaledColor Scaled color copy, or `nil` when no color is given
local function ScaleAlpha(color, scale)
    if ( !color ) then return nil end
    scale = scale or 1
    return Color(color.r, color.g, color.b, math.Clamp(color.a * scale, 0, 255))
end

--- Get the active theme identifier from client options.
-- Falls back to `"dark"` when the options library is unavailable.
-- @realm client
-- @return string themeId
function ax.theme:GetThemeId()
    if ( ax.option ) then
        return ax.option:Get("interface.theme", "dark")
    end

    return "dark"
end

--- Get a theme definition by id.
-- Returns the active theme when no id is supplied, and falls back to the dark
-- theme when the requested id does not exist.
-- @realm client
-- @param[opt] id string Theme identifier
-- @return table theme Theme definition table
function ax.theme:Get(id)
    id = id or self:GetThemeId()

    return self.themes[id] or self.themes.dark
end

--- Get user-configured glass UI metrics.
-- Reads blur, roundness, and opacity scaling values from the options system.
-- @realm client
-- @return table metrics Resolved glass metrics
function ax.theme:GetMetrics()
    local blur = ax.option and ax.option:Get("interface.glass.blur", 1.0) or 1.0
    local roundness = ax.option and ax.option:Get("interface.glass.roundness", 8) or 8
    local opacity = ax.option and ax.option:Get("interface.glass.opacity", 1.0) or 1.0
    local borderOpacity = ax.option and ax.option:Get("interface.glass.borderOpacity", 1.0) or 1.0
    local gradientOpacity = ax.option and ax.option:Get("interface.glass.gradientOpacity", 1.0) or 1.0

    return {
        blur = blur,
        roundness = roundness,
        opacity = opacity,
        borderOpacity = borderOpacity,
        gradientOpacity = gradientOpacity
    }
end

--- Get the active glass color palette.
-- @realm client
-- @return table glass Raw glass palette for the current theme
function ax.theme:GetGlass()
    local theme = self:Get()
    return theme.glass or {}
end

--- Scale a color's alpha channel.
-- @realm client
-- @param color Color Source color to scale
-- @param scale number Alpha multiplier
-- @return Color|nil scaledColor Scaled color copy, or `nil` when no color is given
function ax.theme:ScaleAlpha(color, scale)
    return ScaleAlpha(color, scale)
end

--- Draw a rounded glass panel with optional blur and outline.
-- @realm client
-- @param x number Panel X position
-- @param y number Panel Y position
-- @param w number Panel width
-- @param h number Panel height
-- @param[opt] options table Override options (radius, blur, flags, fill, border)
function ax.theme:DrawGlassPanel(x, y, w, h, options)
    options = options or {}

    local glass = self:GetGlass()
    local metrics = self:GetMetrics()
    local radius = options.radius
    if ( radius == nil ) then
        radius = metrics.roundness
    end

    local blur = (options.blur == nil and 1 or options.blur) * metrics.blur
    local flags = options.flags or ax.render.SHAPE_IOS
    local fill = options.fill or ScaleAlpha(glass.panel, metrics.opacity)
    local border = options.border or ScaleAlpha(glass.panelBorder, metrics.borderOpacity)

    if ( blur > 0 ) then
        ax.render().Rect(x, y, w, h)
            :Rad(radius)
            :Flags(flags)
            :Blur(blur)
            :Draw()
    end

    if ( fill ) then
        ax.render.Draw(radius, x, y, w, h, fill, flags)
    end

    if ( border and border.a > 0 ) then
        ax.render.DrawOutlined(radius, x, y, w, h, border, 1, flags)
    end
end

--- Draw a glass-styled button surface.
-- Uses button palette colors and a height-based default corner radius.
-- @realm client
-- @param x number Button X position
-- @param y number Button Y position
-- @param w number Button width
-- @param h number Button height
-- @param[opt] options table Override options (radius, blur, flags, fill, border)
function ax.theme:DrawGlassButton(x, y, w, h, options)
    options = options or {}

    local glass = self:GetGlass()
    local metrics = self:GetMetrics()
    local radius = options.radius or math.max(4, math.min(12, h * 0.35))
    local blur = (options.blur == nil and 0.85 or options.blur) * metrics.blur
    local flags = options.flags or ax.render.SHAPE_IOS
    local fill = options.fill or ScaleAlpha(glass.button, metrics.opacity)
    local border = options.border or ScaleAlpha(glass.buttonBorder, metrics.borderOpacity)

    if ( blur > 0 ) then
        ax.render().Rect(x, y, w, h)
            :Rad(radius)
            :Flags(flags)
            :Blur(blur)
            :Draw()
    end

    if ( fill ) then
        ax.render.Draw(radius, x, y, w, h, fill, flags)
    end

    if ( border and border.a > 0 ) then
        ax.render.DrawOutlined(radius, x, y, w, h, border, 1, flags)
    end
end

--- Draw a glass backdrop layer used for overlays and modal dimming.
-- @realm client
-- @param x number Backdrop X position
-- @param y number Backdrop Y position
-- @param w number Backdrop width
-- @param h number Backdrop height
-- @param[opt] options table Override options (radius, blur, flags, fill, border)
function ax.theme:DrawGlassBackdrop(x, y, w, h, options)
    options = options or {}

    local glass = self:GetGlass()
    local metrics = self:GetMetrics()
    local radius = options.radius or 0
    local blur = (options.blur == nil and 1.1 or options.blur) * metrics.blur
    local flags = options.flags or ax.render.SHAPE_IOS
    local fill = options.fill or ScaleAlpha(glass.overlay, metrics.opacity)
    local border = options.border

    if ( blur > 0 ) then
        ax.render().Rect(x, y, w, h)
            :Rad(radius)
            :Flags(flags)
            :Blur(blur)
            :Draw()
    end

    if ( fill ) then
        ax.render.Draw(radius, x, y, w, h, fill, flags)
    end

    if ( border and border.a > 0 ) then
        ax.render.DrawOutlined(radius, x, y, w, h, border, 1, flags)
    end
end

--- Draw directional gradient overlays for the active glass theme.
-- Any omitted direction uses the current theme gradient color for that side.
-- @realm client
-- @param x number Gradient X position
-- @param y number Gradient Y position
-- @param w number Gradient width
-- @param h number Gradient height
-- @param[opt] options table Override colors (`left`, `right`, `top`, `bottom`)
function ax.theme:DrawGlassGradients(x, y, w, h, options)
    options = options or {}
    local glass = self:GetGlass()
    local metrics = self:GetMetrics()

    local left = options.left or ScaleAlpha(glass.gradientLeft, metrics.gradientOpacity)
    local right = options.right or ScaleAlpha(glass.gradientRight, metrics.gradientOpacity)
    local top = options.top or ScaleAlpha(glass.gradientTop, metrics.gradientOpacity)
    local bottom = options.bottom or ScaleAlpha(glass.gradientBottom, metrics.gradientOpacity)

    if ( left ) then
        ax.util:DrawGradient(0, "left", x, y, w, h, left)
    end

    if ( right ) then
        ax.util:DrawGradient(0, "right", x, y, w, h, right)
    end

    if ( top ) then
        ax.util:DrawGradient(0, "top", x, y, w, h, top)
    end

    if ( bottom ) then
        ax.util:DrawGradient(0, "bottom", x, y, w, h, bottom)
    end
end
