--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.tooltip = ax.tooltip or {}

local TOOLTIP_MARGIN = 12
local TOOLTIP_GAP = 10
local TOOLTIP_WIDTH_MIN = 240
local TOOLTIP_WIDTH_MAX = 360

local function ScaleAlpha(color, scale)
    if ( !color ) then return nil end

    scale = math.Clamp(scale or 1, 0, 1)
    return Color(color.r, color.g, color.b, math.Clamp((color.a or 255) * scale, 0, 255))
end

local function GetTooltipPanel()
    if ( IsValid(ax.tooltip.panel) ) then
        return ax.tooltip.panel
    end

    ax.tooltip.panel = vgui.Create("ax.tooltip", vgui.GetWorldPanel())
    return ax.tooltip.panel
end

function ax.tooltip:Show(owner, data)
    if ( !IsValid(owner) ) then return end
    if ( !istable(data) ) then return end

    GetTooltipPanel():Open(owner, data)
end

function ax.tooltip:Hide(owner, immediate)
    local panel = GetTooltipPanel()

    if ( IsValid(owner) and panel.ownerPanel != owner ) then
        return
    end

    panel:Close(immediate)
end

do
    local PANEL_META = FindMetaTable("Panel")

    function PANEL_META:SetAxTooltip(data)
        self.axTooltipData = data
    end

    function PANEL_META:GetAxTooltip()
        return self.axTooltipData
    end

    function PANEL_META:ShowAxTooltip()
        local data = self.axTooltipData
        if ( data == nil ) then return end

        if ( isfunction(data) ) then
            local ok, resolved = ax.util:SafeCall(data, self)
            if ( !ok ) then return end

            data = resolved
        end

        if ( !istable(data) ) then return end

        ax.tooltip:Show(self, data)
    end

    function PANEL_META:HideAxTooltip(immediate)
        ax.tooltip:Hide(self, immediate)
    end
end

local PANEL = {}

function PANEL:Init()
    self:SetVisible(false)
    self:SetMouseInputEnabled(false)
    self:SetKeyboardInputEnabled(false)
    self:SetDrawOnTop(true)
    self:SetZPos(32767)

    self.ownerPanel = nil
    self.payload = {}
    self.opacity = 0
    self.offsetX = 0
    self.offsetY = 0
    self.positionX = 0
    self.positionY = 0
    self.anchorSide = 1
    self.radius = math.max(8, ax.util:Scale(10))
    self.padding = ax.util:Scale(12)
    self.badgePadding = ax.util:Scale(8)
    self.badgeHeight = math.max(20, ax.util:Scale(20))
    self.accentWidth = math.max(2, ax.util:Scale(3))
    self.contentWidth = 0
    self.titleLines = {}
    self.descriptionLines = {}
    self.metaLines = {}
    self.footerLines = {}
end

function PANEL:Open(owner, data)
    if ( !IsValid(owner) ) then return end

    self.ownerPanel = owner
    self.payload = table.Copy(data)
    self:Rebuild()

    local x, y, side = self:ResolveTargetPosition()
    self.anchorSide = side
    self.positionX = x
    self.positionY = y

    self.offsetX = side * ax.util:Scale(8)
    self.offsetY = ax.util:Scale(4)
    self.opacity = 0

    self:SetVisible(true)
    self:CancelAllAnimations()
    self:Motion(0.18, {
        Target = {
            opacity = 1,
            offsetX = 0,
            offsetY = 0
        },
        Easing = "OutQuint"
    })
end

function PANEL:Close(immediate)
    self:CancelAllAnimations()

    if ( immediate ) then
        self.ownerPanel = nil
        self:SetVisible(false)
        self.opacity = 0
        self.offsetX = 0
        self.offsetY = 0
        return
    end

    local direction = self.anchorSide or 1

    self:Motion(0.12, {
        Target = {
            opacity = 0,
            offsetX = direction * ax.util:Scale(6),
            offsetY = ax.util:Scale(2)
        },
        Easing = "OutQuad",
        OnComplete = function(panel)
            if ( !IsValid(panel) ) then return end

            panel.ownerPanel = nil
            panel:SetVisible(false)
        end
    })
end

function PANEL:GetMaxWidth()
    return math.Clamp(ScrW() * 0.18, ax.util:Scale(TOOLTIP_WIDTH_MIN), ax.util:Scale(TOOLTIP_WIDTH_MAX))
end

function PANEL:ResolveTargetPosition()
    if ( !IsValid(self.ownerPanel) ) then
        return TOOLTIP_MARGIN, TOOLTIP_MARGIN, 1
    end

    local x, y = self.ownerPanel:LocalToScreen(0, 0)
    local width, height = self.ownerPanel:GetSize()
    local margin = ax.util:Scale(TOOLTIP_MARGIN)
    local gap = ax.util:Scale(TOOLTIP_GAP)
    local targetX = x + width + gap
    local side = 1

    if ( targetX + self:GetWide() > ScrW() - margin ) then
        targetX = x - self:GetWide() - gap
        side = -1
    end

    if ( targetX < margin ) then
        targetX = math.Clamp(x + (width * 0.5) - (self:GetWide() * 0.5), margin, ScrW() - self:GetWide() - margin)
        side = 0
    end

    local targetY = math.Clamp(y + (height * 0.5) - (self:GetTall() * 0.5), margin, ScrH() - self:GetTall() - margin)

    return targetX, targetY, side
end

function PANEL:Rebuild()
    local titleFont = "ax.regular.bold"
    local descriptionFont = "ax.small"
    local metaFont = "ax.small.italic"
    local footerFont = "ax.small"
    local padding = ax.util:Scale(12)
    local badgeWidth = 0
    local contentWidth = self:GetMaxWidth() - (padding * 2)
    local badgeText = tostring(self.payload.badge or "")

    if ( badgeText != "" ) then
        badgeWidth = ax.util:GetTextWidth("ax.small.bold", badgeText) + self.badgePadding * 2 + ax.util:Scale(4)
        contentWidth = math.max(ax.util:Scale(140), contentWidth - badgeWidth)
    end

    self.padding = padding
    self.badgeText = badgeText
    self.contentWidth = contentWidth

    self.titleLines = ax.util:GetWrappedText(tostring(self.payload.title or ""), titleFont, contentWidth) or {}
    self.descriptionLines = {}
    self.metaLines = {}
    self.footerLines = {}

    if ( isstring(self.payload.description) and self.payload.description != "" ) then
        self.descriptionLines = ax.util:GetWrappedText(self.payload.description, descriptionFont, self:GetMaxWidth() - (padding * 2)) or {}
    end

    if ( isstring(self.payload.meta) and self.payload.meta != "" ) then
        self.metaLines = ax.util:GetWrappedText(self.payload.meta, metaFont, self:GetMaxWidth() - (padding * 2)) or {}
    end

    if ( isstring(self.payload.footer) and self.payload.footer != "" ) then
        self.footerLines = ax.util:GetWrappedText(self.payload.footer, footerFont, self:GetMaxWidth() - (padding * 2)) or {}
    end

    local titleHeight = #self.titleLines * ax.util:GetTextHeight(titleFont)
    local descriptionHeight = #self.descriptionLines * ax.util:GetTextHeight(descriptionFont)
    local metaHeight = #self.metaLines * ax.util:GetTextHeight(metaFont)
    local footerHeight = #self.footerLines * ax.util:GetTextHeight(footerFont)
    local contentHeight = padding * 2 + titleHeight

    if ( descriptionHeight > 0 ) then
        contentHeight = contentHeight + ax.util:Scale(6) + descriptionHeight
    end

    if ( metaHeight > 0 ) then
        contentHeight = contentHeight + ax.util:Scale(6) + metaHeight
    end

    if ( footerHeight > 0 ) then
        contentHeight = contentHeight + ax.util:Scale(6) + footerHeight
    end

    local width = math.max(self:GetMaxWidth(), badgeWidth + padding * 2 + ax.util:Scale(96))
    local height = math.max(contentHeight, self.badgeHeight + padding * 2)

    self:SetSize(width, height)
end

function PANEL:Think()
    if ( !self:IsVisible() ) then return end

    if ( !IsValid(self.ownerPanel) or !self.ownerPanel:IsVisible() ) then
        self:Close(true)
        return
    end

    local targetX, targetY = self:ResolveTargetPosition()
    local fraction = math.Clamp(FrameTime() * 18, 0, 1)

    self.positionX = Lerp(fraction, self.positionX or targetX, targetX)
    self.positionY = Lerp(fraction, self.positionY or targetY, targetY)

    self:SetPos(self.positionX + (self.offsetX or 0), self.positionY + (self.offsetY or 0))
end

function PANEL:Paint(width, height)
    local alpha = math.Clamp(self.opacity or 0, 0, 1)
    if ( alpha <= 0 ) then return end

    local glass = ax.theme:GetGlass()
    local metrics = ax.theme:GetMetrics()
    
    -- Apply user's opacity preferences first
    local scaledHighlight = ax.theme:ScaleAlpha(glass.highlight, metrics.opacity)
    local scaledProgress = ax.theme:ScaleAlpha(glass.progress, metrics.opacity)
    local scaledMenu = ax.theme:ScaleAlpha(glass.menu or glass.panel, metrics.opacity)
    local scaledMenuBorder = ax.theme:ScaleAlpha(glass.menuBorder or glass.panelBorder, metrics.borderOpacity)
    
    -- Then apply animation alpha on top of user settings
    local accent = self.payload.accentColor or scaledHighlight or scaledProgress
    local fill = ScaleAlpha(scaledMenu, alpha)
    local border = ScaleAlpha(scaledMenuBorder, alpha)
    local textColor = ScaleAlpha(glass.text, alpha)
    local mutedColor = ScaleAlpha(glass.textMuted, alpha)
    local accentSoft = ScaleAlpha(accent, alpha * 0.35)
    local accentStrong = ScaleAlpha(accent, alpha * 0.8)

    ax.theme:DrawGlassPanel(0, 0, width, height, {
        radius = self.radius,
        blur = 0.9,
        fill = fill,
        border = border
    })

    ax.theme:DrawGlassGradients(0, 0, width, height, {
        left = ScaleAlpha(glass.gradientLeft, alpha * 0.45),
        right = ScaleAlpha(glass.gradientRight, alpha * 0.35)
    })

    ax.render.Draw(self.radius, 0, 0, self.accentWidth, height, accentSoft, ax.render.SHAPE_IOS)

    local x = self.padding
    local y = self.padding
    local titleFont = "ax.regular.bold"
    local descriptionFont = "ax.small"
    local metaFont = "ax.small.italic"
    local footerFont = "ax.small"
    local titleHeight = ax.util:GetTextHeight(titleFont)
    local descriptionHeight = ax.util:GetTextHeight(descriptionFont)
    local metaHeight = ax.util:GetTextHeight(metaFont)
    local footerHeight = ax.util:GetTextHeight(footerFont)

    if ( self.badgeText != "" ) then
        local badgeWidth = ax.util:GetTextWidth("ax.small.bold", self.badgeText) + self.badgePadding * 2
        local badgeX = width - self.padding - badgeWidth
        local badgeY = self.padding

        ax.theme:DrawGlassButton(badgeX, badgeY, badgeWidth, self.badgeHeight, {
            radius = self.badgeHeight * 0.5,
            blur = 0.55,
            fill = accentSoft,
            border = accentStrong
        })

        draw.SimpleText(self.badgeText, "ax.small.bold", badgeX + (badgeWidth * 0.5), badgeY + (self.badgeHeight * 0.5), textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    for i = 1, #self.titleLines do
        draw.SimpleText(self.titleLines[i], titleFont, x, y, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        y = y + titleHeight
    end

    if ( #self.descriptionLines > 0 ) then
        y = y + ax.util:Scale(6)

        for i = 1, #self.descriptionLines do
            draw.SimpleText(self.descriptionLines[i], descriptionFont, x, y, mutedColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            y = y + descriptionHeight
        end
    end

    if ( #self.metaLines > 0 ) then
        y = y + ax.util:Scale(6)

        for i = 1, #self.metaLines do
            draw.SimpleText(self.metaLines[i], metaFont, x, y, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            y = y + metaHeight
        end
    end

    if ( #self.footerLines > 0 ) then
        y = y + ax.util:Scale(6)

        for i = 1, #self.footerLines do
            draw.SimpleText(self.footerLines[i], footerFont, x, y, mutedColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            y = y + footerHeight
        end
    end
end

vgui.Register("ax.tooltip", PANEL, "EditablePanel")
