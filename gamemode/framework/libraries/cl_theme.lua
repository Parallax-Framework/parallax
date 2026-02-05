--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

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
        textMuted = Color(180, 190, 205, 255)
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
        textMuted = Color(70, 85, 105, 255)
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
        textMuted = Color(160, 180, 210, 255)
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
        textMuted = Color(180, 160, 210, 255)
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
        textMuted = Color(160, 200, 175, 255)
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
        textMuted = Color(200, 160, 170, 255)
    }
}

local function ScaleAlpha(color, scale)
    if ( !color ) then return nil end
    scale = scale or 1
    return Color(color.r, color.g, color.b, math.Clamp(color.a * scale, 0, 255))
end

function ax.theme:GetThemeId()
    if ( ax.option ) then
        return ax.option:Get("interface.theme", "dark")
    end

    return "dark"
end

function ax.theme:Get(id)
    id = id or self:GetThemeId()

    return self.themes[id] or self.themes.dark
end

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

function ax.theme:GetGlass()
    local theme = self:Get()
    local glass = theme.glass or {}
    local metrics = self:GetMetrics()

    return {
        panel = ScaleAlpha(glass.panel, metrics.opacity),
        panelBorder = ScaleAlpha(glass.panelBorder, metrics.borderOpacity),
        header = ScaleAlpha(glass.header, metrics.opacity),
        button = ScaleAlpha(glass.button, metrics.opacity),
        buttonHover = ScaleAlpha(glass.buttonHover, metrics.opacity),
        buttonActive = ScaleAlpha(glass.buttonActive, metrics.opacity),
        buttonBorder = ScaleAlpha(glass.buttonBorder or glass.panelBorder, metrics.borderOpacity),
        input = ScaleAlpha(glass.input, metrics.opacity),
        inputBorder = ScaleAlpha(glass.inputBorder, metrics.borderOpacity),
        menu = ScaleAlpha(glass.menu, metrics.opacity),
        menuBorder = ScaleAlpha(glass.menuBorder, metrics.borderOpacity),
        overlay = ScaleAlpha(glass.overlay, metrics.opacity),
        overlayStrong = ScaleAlpha(glass.overlayStrong or glass.overlay, metrics.opacity),
        progress = ScaleAlpha(glass.progress, metrics.opacity),
        highlight = ScaleAlpha(glass.highlight, metrics.opacity),
        gradientTop = ScaleAlpha(glass.gradientTop, metrics.gradientOpacity),
        gradientBottom = ScaleAlpha(glass.gradientBottom, metrics.gradientOpacity),
        gradientLeft = ScaleAlpha(glass.gradientLeft, metrics.gradientOpacity),
        gradientRight = ScaleAlpha(glass.gradientRight, metrics.gradientOpacity),
        tabBackdrop = ScaleAlpha(glass.tabBackdrop or glass.overlay, metrics.opacity),
        text = glass.text or color_white,
        textHover = glass.textHover or color_white,
        textMuted = glass.textMuted or color_white
    }
end

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
    local fill = options.fill or glass.panel
    local border = options.border or glass.panelBorder

    ax.render().Rect(x, y, w, h)
        :Rad(radius)
        :Flags(flags)
        :Blur(blur)
        :Draw()

    if ( fill ) then
        ax.render.Draw(radius, x, y, w, h, fill, flags)
    end

    if ( border and border.a > 0 ) then
        ax.render.DrawOutlined(radius, x, y, w, h, border, 1, flags)
    end
end

function ax.theme:DrawGlassButton(x, y, w, h, options)
    options = options or {}

    local glass = self:GetGlass()
    local metrics = self:GetMetrics()
    local radius = options.radius or math.max(4, math.min(12, h * 0.35))
    local blur = (options.blur == nil and 0.85 or options.blur) * metrics.blur
    local flags = options.flags or ax.render.SHAPE_IOS
    local fill = options.fill or glass.button
    local border = options.border or glass.buttonBorder

    ax.render().Rect(x, y, w, h)
        :Rad(radius)
        :Flags(flags)
        :Blur(blur)
        :Draw()

    if ( fill ) then
        ax.render.Draw(radius, x, y, w, h, fill, flags)
    end

    if ( border and border.a > 0 ) then
        ax.render.DrawOutlined(radius, x, y, w, h, border, 1, flags)
    end
end

function ax.theme:DrawGlassBackdrop(x, y, w, h, options)
    options = options or {}

    local glass = self:GetGlass()
    local metrics = self:GetMetrics()
    local radius = options.radius or 0
    local blur = (options.blur == nil and 1.1 or options.blur) * metrics.blur
    local flags = options.flags or ax.render.SHAPE_IOS
    local fill = options.fill or glass.overlay
    local border = options.border

    ax.render().Rect(x, y, w, h)
        :Rad(radius)
        :Flags(flags)
        :Blur(blur)
        :Draw()

    if ( fill ) then
        ax.render.Draw(radius, x, y, w, h, fill, flags)
    end

    if ( border and border.a > 0 ) then
        ax.render.DrawOutlined(radius, x, y, w, h, border, 1, flags)
    end
end

function ax.theme:DrawGlassGradients(x, y, w, h, options)
    options = options or {}
    local glass = self:GetGlass()

    local left = options.left or glass.gradientLeft
    local right = options.right or glass.gradientRight
    local top = options.top or glass.gradientTop
    local bottom = options.bottom or glass.gradientBottom

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
