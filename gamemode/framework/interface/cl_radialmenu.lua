--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Shared client-side radial menu utilities and base panel rendering.
-- Provides common geometry helpers, easing, glass rendering, and a reusable
-- panel class for schema and framework radial menus.
-- @module ax.radialmenu

ax.radialmenu = ax.radialmenu or {}

function ax.radialmenu:GetAnimationFraction(speed)
    local animationsEnabled = true

    if ( ax.option ) then
        animationsEnabled = ax.option:Get("performance.animations", ax.option:Get("performanceAnimations", true))
    end

    if ( !animationsEnabled ) then
        return 1
    end

    return math.min(1, FrameTime() * speed)
end

function ax.radialmenu:EaseNumber(current, target, speed, easing)
    local fraction = ax.radialmenu:GetAnimationFraction(speed)

    if ( fraction >= 1 ) then
        return target
    end

    if ( ax.ease and ax.ease.Lerp ) then
        return ax.ease:Lerp(easing or "OutQuad", fraction, current, target)
    end

    return ax.ease:Lerp("Linear", fraction, current, target)
end

function ax.radialmenu:AlphaColor(color, alpha)
    if ( !color ) then
        return Color(255, 255, 255, alpha or 255)
    end

    return Color(color.r, color.g, color.b, alpha or color.a or 255)
end

function ax.radialmenu:BlendColors(from, to, fraction)
    fraction = math.Clamp(fraction or 0, 0, 1)
    from = from or color_white
    to = to or color_white

    return Color(
        ax.ease:Lerp("Linear", fraction, from.r, to.r),
        ax.ease:Lerp("Linear", fraction, from.g, to.g),
        ax.ease:Lerp("Linear", fraction, from.b, to.b),
        ax.ease:Lerp("Linear", fraction, from.a or 255, to.a or 255)
    )
end

function ax.radialmenu:GetTextWidth(font, text)
    surface.SetFont(font)

    local width = surface.GetTextSize(tostring(text or ""))

    return width
end

function ax.radialmenu:GetTextHeight(font, sample)
    surface.SetFont(font)

    local _, height = surface.GetTextSize(sample or "Hg")

    return height
end

function ax.radialmenu:FitTextToWidth(font, text, maxWidth)
    text = tostring(text or "")
    maxWidth = math.max(1, maxWidth or 1)

    surface.SetFont(font)

    local textWidth = surface.GetTextSize(text)

    if ( textWidth <= maxWidth ) then
        return text
    end

    local ellipsis = "..."
    local ellipsisWidth = surface.GetTextSize(ellipsis)

    if ( ellipsisWidth >= maxWidth ) then
        return ellipsis
    end

    for length = #text, 1, -1 do
        local candidate = string.sub(text, 1, length) .. ellipsis
        local candidateWidth = surface.GetTextSize(candidate)

        if ( candidateWidth <= maxWidth ) then
            return candidate
        end
    end

    return ellipsis
end

function ax.radialmenu:LimitWrappedLines(lines, maxLines)
    if ( !istable(lines) or #lines == 0 ) then
        return { "" }
    end

    maxLines = math.max(1, maxLines or #lines)

    if ( #lines <= maxLines ) then
        return lines
    end

    local limited = {}

    for i = 1, maxLines do
        limited[i] = lines[i]
    end

    limited[maxLines] = tostring(limited[maxLines] or "") .. "..."

    return limited
end

function ax.radialmenu:NormalizeAngle(angle)
    angle = angle % 360

    if ( angle < 0 ) then
        angle = angle + 360
    end

    return angle
end

function ax.radialmenu:AngleWithin(angle, startAngle, endAngle)
    angle = ax.radialmenu:NormalizeAngle(angle)
    startAngle = ax.radialmenu:NormalizeAngle(startAngle)
    endAngle = ax.radialmenu:NormalizeAngle(endAngle)

    if ( startAngle <= endAngle ) then
        return angle >= startAngle and angle <= endAngle
    end

    return angle >= startAngle or angle <= endAngle
end

function ax.radialmenu:PolarToScreen(centerX, centerY, radius, angle)
    local radians = math.rad(angle - 90)

    return centerX + math.cos(radians) * radius, centerY + math.sin(radians) * radius
end

function ax.radialmenu:DrawRingSegment(centerX, centerY, innerRadius, outerRadius, startAngle, endAngle, color, segmentSteps)
    if ( !color or color.a <= 0 or endAngle <= startAngle ) then return end

    local steps = math.max(6, math.ceil((endAngle - startAngle) / (segmentSteps or 64)))

    draw.NoTexture()
    surface.SetDrawColor(color)

    for i = 0, steps - 1 do
        local fractionA = i / steps
        local fractionB = (i + 1) / steps
        local angleA = ax.ease:Lerp("Linear", fractionA, startAngle, endAngle)
        local angleB = ax.ease:Lerp("Linear", fractionB, startAngle, endAngle)
        local outerAX, outerAY = ax.radialmenu:PolarToScreen(centerX, centerY, outerRadius, angleA)
        local outerBX, outerBY = ax.radialmenu:PolarToScreen(centerX, centerY, outerRadius, angleB)
        local innerAX, innerAY = ax.radialmenu:PolarToScreen(centerX, centerY, innerRadius, angleA)
        local innerBX, innerBY = ax.radialmenu:PolarToScreen(centerX, centerY, innerRadius, angleB)

        surface.DrawPoly({
            { x = outerAX, y = outerAY },
            { x = outerBX, y = outerBY },
            { x = innerBX, y = innerBY },
        })

        surface.DrawPoly({
            { x = outerAX, y = outerAY },
            { x = innerBX, y = innerBY },
            { x = innerAX, y = innerAY },
        })
    end
end

function ax.radialmenu:DrawDivider(centerX, centerY, innerRadius, outerRadius, angle, color)
    if ( !color or color.a <= 0 ) then return end

    local startX, startY = ax.radialmenu:PolarToScreen(centerX, centerY, innerRadius, angle)
    local endX, endY = ax.radialmenu:PolarToScreen(centerX, centerY, outerRadius, angle)

    surface.SetDrawColor(color)
    surface.DrawLine(startX, startY, endX, endY)
end

function ax.radialmenu.SortEntries(a, b)
    local orderA = a.sort or (a.data and a.data.sort) or 100
    local orderB = b.sort or (b.data and b.data.sort) or 100

    if ( orderA != orderB ) then
        return orderA < orderB
    end

    local nameA = tostring((a.data and a.data.name) or a.name or a.id)
    local nameB = tostring((b.data and b.data.name) or b.name or b.id)

    if ( nameA != nameB ) then
        return nameA < nameB
    end

    return a.id < b.id
end

function ax.radialmenu:CreateSectionBucket(sectionMap, sections, sectionId, meta, countKey)
    local section = sectionMap[sectionId]

    if ( section ) then
        return section
    end

    section = {
        id = sectionId,
        name = meta.name,
        description = meta.description,
        color = meta.color,
        order = meta.order,
        items = {},
    }
    section[countKey or "itemCount"] = 0

    sectionMap[sectionId] = section
    sections[#sections + 1] = section

    return section
end

function ax.radialmenu:FinalizeWheelData(sections, context, options)
    options = options or {}

    table.sort(sections, function(a, b)
        if ( a.order != b.order ) then
            return a.order < b.order
        end

        return a.name < b.name
    end)

    local totalItems = 0

    for i = 1, #sections do
        local section = sections[i]
        table.sort(section.items, options.sortEntries or ax.radialmenu.SortEntries)
        totalItems = totalItems + #section.items
    end

    if ( totalItems == 0 ) then
        return {
            sections = {},
            items = {},
            count = 0,
            mode = context and context.mode or nil,
            group = context and context.group or nil,
            groupId = context and context.groupId or nil,
            defaultItemId = context and context.defaultItemId or nil,
        }
    end

    local sectionGap = options.sectionGap or 8
    local resolvedSectionGap = (#sections > 1) and sectionGap or 0
    local itemGap = options.itemGap or 1
    local minSegmentAngle = options.minSegmentAngle or 12
    local totalGap = (#sections * resolvedSectionGap) + (totalItems * itemGap)
    local segmentAngle = math.max(minSegmentAngle, (360 - totalGap) / totalItems)
    local cursor = 0
    local flatItems = {}

    for i = 1, #sections do
        local section = sections[i]
        cursor = cursor + resolvedSectionGap * 0.5
        section.startAngle = cursor

        for j = 1, #section.items do
            local item = section.items[j]
            item.section = section
            item.startAngle = cursor
            item.endAngle = cursor + segmentAngle + itemGap
            item.drawStartAngle = item.startAngle + itemGap * 0.5
            item.drawEndAngle = item.endAngle - itemGap * 0.5
            item.midAngle = (item.drawStartAngle + item.drawEndAngle) * 0.5

            flatItems[#flatItems + 1] = item

            cursor = item.endAngle
        end

        section.endAngle = cursor
        section.midAngle = (section.startAngle + section.endAngle) * 0.5
        cursor = cursor + resolvedSectionGap * 0.5
    end

    return {
        sections = sections,
        items = flatItems,
        count = totalItems,
        mode = context and context.mode or nil,
        group = context and context.group or nil,
        groupId = context and context.groupId or nil,
        defaultItemId = context and context.defaultItemId or nil,
    }
end

local PANEL = {}

function PANEL:InitializeRadialMenu(options)
    self.radialOptions = options or {}
    self.wheelData = self.wheelData or {
        sections = {},
        items = {},
        count = 0,
    }
    self.itemAnimations = self.itemAnimations or {}
    self.sectionAnimations = self.sectionAnimations or {}
    self.openFraction = self.openFraction or 0
    self.previewFraction = self.previewFraction or 0
    self.previewItem = self.previewItem or nil
    self.hoveredItem = nil
    self.hoveredSection = nil
    self.suppressNextHoverSound = true

    local guiKey = self:GetRadialMenuGUIKey()
    if ( guiKey and IsValid(ax.gui[guiKey]) and ax.gui[guiKey] != self ) then
        ax.gui[guiKey]:Remove()
    end

    if ( guiKey ) then
        ax.gui[guiKey] = self
    end

    self:SetSize(ScrW(), ScrH())
    self:SetPos(0, 0)
    self:SetAlpha(255)
    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(true)
    self:MakePopup()

    gui.EnableScreenClicker(true)
end

function PANEL:GetRadialMenuOption(key, default)
    if ( !istable(self.radialOptions) ) then
        return default
    end

    local value = self.radialOptions[key]

    if ( value == nil ) then
        return default
    end

    return value
end

function PANEL:GetRadialMenuGUIKey()
    return self:GetRadialMenuOption("guiKey", nil)
end

function PANEL:OnRemove()
    gui.EnableScreenClicker(false)

    local guiKey = self:GetRadialMenuGUIKey()
    if ( guiKey and ax.gui[guiKey] == self ) then
        ax.gui[guiKey] = nil
    end
end

function PANEL:GetSegmentSteps()
    local configuredSteps = self:GetRadialMenuOption("segmentSteps", nil)

    if ( isnumber(configuredSteps) and configuredSteps > 0 ) then
        return configuredSteps
    end

    local itemCount = istable(self.wheelData) and tonumber(self.wheelData.count) or 0

    if ( itemCount <= 4 ) then
        return 3
    end

    if ( itemCount <= 6 ) then
        return 4
    end

    if ( itemCount <= 8 ) then
        return 5
    end

    if ( itemCount <= 12 ) then
        return 6
    end

    if ( itemCount <= 18 ) then
        return 8
    end

    return 10
end

function PANEL:GetItemGap()
    return self:GetRadialMenuOption("itemGap", 1)
end

function PANEL:GetSectionGap()
    return self:GetRadialMenuOption("sectionGap", 8)
end

function PANEL:GetFavoriteMap()
    return {}
end

function PANEL:FindWheelItem(itemId)
    if ( !isstring(itemId) or !istable(self.wheelData) or !istable(self.wheelData.items) ) then
        return nil
    end

    for i = 1, #self.wheelData.items do
        local item = self.wheelData.items[i]
        if ( item.id == itemId ) then
            return item
        end
    end

    return nil
end

function PANEL:SetResolvedWheelData(wheelData, preferredItemId)
    self.wheelData = wheelData or {
        sections = {},
        items = {},
        count = 0,
    }
    self.hoveredItem = nil
    self.itemAnimations = {}
    self.sectionAnimations = {}
    self.suppressNextHoverSound = true

    local previewItem = preferredItemId and self:FindWheelItem(preferredItemId) or nil

    if ( !previewItem and self.wheelData.defaultItemId ) then
        previewItem = self:FindWheelItem(self.wheelData.defaultItemId)
    end

    self.previewItem = previewItem or self.wheelData.items[1]
    self.hoveredSection = self.previewItem and self.previewItem.section or self.wheelData.sections[1]
end

function PANEL:EmitUISound(soundName)
    if ( !isstring(soundName) or soundName == "" ) then return end
    if ( !ax.client or !ax.client.EmitSound ) then return end

    ax.client:EmitSound(soundName)
end

function PANEL:GetActiveWheelItem()
    return self.hoveredItem or self.previewItem
end

function PANEL:GetLayoutMetrics(width, height)
    width = width or self:GetWide()
    height = height or self:GetTall()

    local base = math.min(width, height)
    local widthRatio = math.Clamp(width / 1920, 0.72, 1.5)
    local heightRatio = math.Clamp(height / 1080, 0.72, 1.5)
    local paddingScale = math.min(widthRatio, heightRatio)
    local reveal = 0.92 + self.openFraction * 0.08
    local ringOuter = math.Clamp(base * (0.295 + widthRatio * 0.02), ax.util:ScreenScale(112), ax.util:ScreenScale(188)) * reveal
    local ringInner = math.Clamp(base * (0.17 + widthRatio * 0.012), ax.util:ScreenScale(72), ax.util:ScreenScale(126)) * reveal
    local previewSize = math.Clamp(base * 0.3, ax.util:ScreenScale(102), ax.util:ScreenScale(166))
    local panelWidth = math.Clamp(base * 0.34, ax.util:ScreenScale(154), ax.util:ScreenScale(228))
    local panelHeight = math.Clamp(base * 0.34, ax.util:ScreenScaleH(126), ax.util:ScreenScaleH(228))
    local gap = math.max(ax.util:ScreenScale(12), base * 0.02)
    local centerX = width * 0.5
    local centerY = height * 0.5 - panelHeight * 0.03
    local slide = (1 - self.openFraction) * math.max(ax.util:ScreenScale(8), base * 0.015)
    local hintWidth = math.max(panelWidth * 1.5, ax.util:ScreenScale(240))

    return {
        centerX = centerX,
        centerY = centerY,
        ringOuter = ringOuter,
        ringInner = ringInner,
        previewSize = previewSize,
        previewX = centerX - previewSize * 0.5,
        previewY = centerY - previewSize * 0.5,
        leftX = centerX - ringOuter - gap - panelWidth - slide,
        rightX = centerX + ringOuter + gap + slide,
        panelY = centerY - panelHeight * 0.5 + (1 - self.openFraction) * ax.util:ScreenScaleH(8),
        panelWidth = panelWidth,
        panelHeight = panelHeight,
        hintWidth = hintWidth,
        hintHeight = ax.util:ScreenScaleH(32),
        hintX = centerX - hintWidth * 0.5,
        hintY = height - math.max(ax.util:ScreenScaleH(42), base * (0.06 + (1 - paddingScale) * 0.05)),
        deadzone = ringInner - ax.util:ScreenScale(8),
        edgePadding = ax.util:ScreenScale(16),
    }
end

function PANEL:Dismiss(shouldCommit)
    if ( self.dismissed ) then return end

    if ( shouldCommit and isfunction(self.CommitItem) and self:CommitItem(self.hoveredItem, false) ) then
        return
    end

    self:EmitUISound("ax.gui.menu.close")
    self.dismissed = true
    self:Remove()
end

function PANEL:OnKeyCodePressed(keyCode)
    if ( keyCode == KEY_ESCAPE ) then
        self:Dismiss(false)
    end
end

function PANEL:HandleHoverChanged(previousItem, hoveredItem)
end

function PANEL:UpdateRadialMenu(layout)
end

function PANEL:UpdateHoverState(layout)
    if ( self.wheelData.count == 0 ) then
        self.hoveredItem = nil
        self.hoveredSection = nil
        return
    end

    local mouseX, mouseY = gui.MouseX(), gui.MouseY()

    if ( mouseX < 0 or mouseY < 0 ) then
        mouseX = layout.centerX
        mouseY = layout.centerY
    end

    local dx = mouseX - layout.centerX
    local dy = mouseY - layout.centerY
    local distance = math.sqrt(dx * dx + dy * dy)
    local angle = ax.radialmenu:NormalizeAngle(math.deg(math.atan2(dy, dx)) + 90)

    self.mouseX = mouseX
    self.mouseY = mouseY
    self.mouseAngle = angle
    self.mouseDistance = distance

    local hovered = nil

    if ( distance >= layout.deadzone and distance <= layout.ringOuter + layout.edgePadding ) then
        for i = 1, #self.wheelData.items do
            local item = self.wheelData.items[i]
            if ( ax.radialmenu:AngleWithin(angle, item.startAngle, item.endAngle) ) then
                hovered = item
                break
            end
        end
    end

    local previousItem = self.hoveredItem
    local previousHoveredId = previousItem and previousItem.id or nil

    self.hoveredItem = hovered

    if ( hovered ) then
        self.previewItem = hovered
        self.hoveredSection = hovered.section
    elseif ( self.previewItem ) then
        self.hoveredSection = self.previewItem.section
    else
        self.hoveredSection = nil
    end

    local hoveredId = hovered and hovered.id or nil

    self:HandleHoverChanged(previousItem, hovered)

    if ( hoveredId != previousHoveredId ) then
        if ( self.suppressNextHoverSound ) then
            self.suppressNextHoverSound = false
        elseif ( hoveredId ) then
            self:EmitUISound("ax.gui.button.enter")
        end
    end
end

function PANEL:Think()
    if ( self:GetWide() != ScrW() or self:GetTall() != ScrH() ) then
        self:SetSize(ScrW(), ScrH())
    end

    self.openFraction = ax.radialmenu:EaseNumber(self.openFraction, 1, 9, "OutCubic")
    self.previewFraction = ax.radialmenu:EaseNumber(self.previewFraction, self.hoveredItem and 1 or 0.45, 8, "OutQuad")

    local layout = self:GetLayoutMetrics()
    self:UpdateHoverState(layout)
    self:UpdateRadialMenu(layout)

    for i = 1, #self.wheelData.items do
        local item = self.wheelData.items[i]
        local target = 0

        if ( self.hoveredItem == item ) then
            target = 1
        elseif ( self.previewItem == item ) then
            target = 0.3
        end

        self.itemAnimations[item.id] = ax.radialmenu:EaseNumber(self.itemAnimations[item.id] or 0, target, 10, "OutQuad")
    end

    for i = 1, #self.wheelData.sections do
        local section = self.wheelData.sections[i]
        local target = 0.18

        if ( self.hoveredSection == section ) then
            target = 1
        elseif ( self.previewItem and self.previewItem.section == section ) then
            target = 0.45
        end

        self.sectionAnimations[section.id] = ax.radialmenu:EaseNumber(self.sectionAnimations[section.id] or 0, target, 9, "OutQuad")
    end
end

function PANEL:PaintBackdrop(width, height, glass)
    ax.theme:DrawGlassBackdrop(0, 0, width, height, {
        radius = 0,
        blur = 1.15,
        fill = ax.radialmenu:AlphaColor(glass.overlayStrong or glass.overlay, math.max(70, 170 * self.openFraction)),
    })

    ax.theme:DrawGlassGradients(0, 0, width, height, {
        left = ax.radialmenu:AlphaColor(glass.gradientLeft, math.min(70, 48 * self.openFraction)),
        right = ax.radialmenu:AlphaColor(glass.gradientRight, math.min(70, 48 * self.openFraction)),
        top = ax.radialmenu:AlphaColor(glass.gradientTop, math.min(80, 58 * self.openFraction)),
        bottom = ax.radialmenu:AlphaColor(glass.gradientBottom, math.min(90, 64 * self.openFraction)),
    })
end

function PANEL:GetWheelTitle()
    return "Radial Menu"
end

function PANEL:GetWheelSubtitle()
    return "Move into the ring to preview"
end

function PANEL:GetWheelItemSecondaryLabel(item)
    return item and item.section and string.upper(item.section.name or "") or ""
end

function PANEL:PaintWheelCenter(layout, glass)
    local centerX = layout.centerX
    local centerY = layout.centerY
    local activeItem = self:GetActiveWheelItem()
    local titleColor = activeItem and ax.radialmenu:AlphaColor(activeItem.section.color, 235) or glass.text

    draw.SimpleText(self:GetWheelTitle(), "ax.large.bold", centerX, centerY - layout.previewSize * 0.66, titleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(self:GetWheelSubtitle(), "ax.small", centerX, centerY - layout.previewSize * 0.56, glass.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function PANEL:PaintWheel(layout, glass)
    local centerX = layout.centerX
    local centerY = layout.centerY
    local ringWidth = layout.ringOuter - layout.ringInner
    local ringDiameter = layout.ringOuter * 2 + ax.util:ScreenScale(16)
    local outlineColor = ax.radialmenu:AlphaColor(glass.panelBorder, 95)
    local primaryLineHeight = ax.radialmenu:GetTextHeight("ax.small.bold")

    ax.render().Circle(centerX, centerY, ringDiameter)
        :Outline(ringWidth + 22)
        :Blur(1.15)
        :Color(ax.radialmenu:AlphaColor(glass.overlayStrong or glass.overlay, 220))
        :Draw()

    ax.render.DrawCircleOutlined(centerX, centerY, layout.ringOuter * 2 + ax.util:ScreenScale(6), ax.radialmenu:AlphaColor(glass.panelBorder, 70), 1.5)
    ax.render.DrawCircleOutlined(centerX, centerY, layout.ringInner * 2 - ax.util:ScreenScale(2), ax.radialmenu:AlphaColor(glass.panelBorder, 55), 1)

    for i = 1, #self.wheelData.items do
        local item = self.wheelData.items[i]
        local itemFraction = self.itemAnimations[item.id] or 0
        local accent = item.section.color
        local fillColor = ax.radialmenu:BlendColors(
            ax.radialmenu:AlphaColor(glass.button, 92),
            ax.radialmenu:AlphaColor(accent, 185),
            math.min(1, 0.2 + itemFraction * 0.8)
        )
        local borderColor = ax.radialmenu:BlendColors(
            ax.radialmenu:AlphaColor(glass.buttonBorder or glass.panelBorder, 40),
            ax.radialmenu:AlphaColor(accent, 220),
            math.min(1, 0.25 + itemFraction * 0.75)
        )
        local expandedOuter = layout.ringOuter + itemFraction * ax.util:ScreenScale(6)

        ax.radialmenu:DrawRingSegment(centerX, centerY, layout.ringInner, expandedOuter, item.drawStartAngle, item.drawEndAngle, fillColor, self:GetSegmentSteps())
        ax.radialmenu:DrawDivider(centerX, centerY, layout.ringInner + ax.util:ScreenScale(2), expandedOuter, item.startAngle, ax.radialmenu:AlphaColor(outlineColor, 90))
        ax.radialmenu:DrawDivider(centerX, centerY, layout.ringInner + ax.util:ScreenScale(2), expandedOuter, item.endAngle, ax.radialmenu:AlphaColor(outlineColor, 55))

        if ( itemFraction > 0.01 ) then
            ax.radialmenu:DrawRingSegment(centerX, centerY, expandedOuter - ax.util:ScreenScale(4), expandedOuter + ax.util:ScreenScale(2), item.drawStartAngle, item.drawEndAngle, ax.radialmenu:AlphaColor(borderColor, 190), self:GetSegmentSteps())
        end

        local labelRadius = layout.ringInner + ringWidth * (0.52 + itemFraction * 0.08)
        local labelX, labelY = ax.radialmenu:PolarToScreen(centerX, centerY, labelRadius, item.midAngle)
        local labelMaxWidth = math.max(ax.util:ScreenScale(42), ringWidth * 0.8)
        local primaryLabel = tostring(item.data.name or item.id)
        local primaryLines = ax.radialmenu:LimitWrappedLines(ax.util:GetWrappedText(primaryLabel, "ax.small.bold", labelMaxWidth) or {
            ax.radialmenu:FitTextToWidth("ax.small.bold", primaryLabel, labelMaxWidth),
        }, 2)
        local showSecondary = itemFraction > 0.08 or self.hoveredItem == item
        local secondaryAlpha = showSecondary and (140 + itemFraction * 80) or 0
        local primaryStartY = labelY - ((#primaryLines - 1) * primaryLineHeight * 0.5)

        for i = 1, #primaryLines do
            local line = primaryLines[i]
            draw.SimpleText(line, "ax.small.bold", labelX, primaryStartY + (i - 1) * primaryLineHeight - ax.util:ScreenScaleH(2),
                itemFraction > 0.05 and glass.textHover or glass.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        if ( secondaryAlpha > 0 ) then
            draw.SimpleText(self:GetWheelItemSecondaryLabel(item), "ax.tiny.bold", labelX, primaryStartY + (#primaryLines * primaryLineHeight) + ax.util:ScreenScaleH(1),
                ax.radialmenu:AlphaColor(item.section.color, secondaryAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    ax.render.DrawCircle(centerX, centerY, layout.ringInner * 2 - ax.util:ScreenScale(10), ax.radialmenu:AlphaColor(glass.panel, 185))
    ax.render.DrawCircleOutlined(centerX, centerY, layout.ringInner * 2 - ax.util:ScreenScale(10), ax.radialmenu:AlphaColor(glass.panelBorder, 85), 1)

    self:PaintWheelCenter(layout, glass)
end

function PANEL:ShouldPaintSectionsPanel()
    return true
end

function PANEL:GetSectionsPanelTitle()
    return "Sections"
end

function PANEL:GetSectionsPanelSubtitle()
    return "Grouped for faster selection and clearer scanning."
end

function PANEL:GetSectionCountLabel(section)
    return tostring(#(section.items or {})) .. " items"
end

function PANEL:PaintSectionsPanel(layout, glass, metrics)
    local x, y = layout.leftX, layout.panelY
    local width, height = layout.panelWidth, layout.panelHeight
    local padding = ax.util:ScreenScale(10)
    local sections = self.wheelData.sections or {}
    local sectionCount = math.max(1, #sections)
    local titleHeight = ax.radialmenu:GetTextHeight("ax.large.bold")
    local subtitleLineHeight = ax.radialmenu:GetTextHeight("ax.small")
    local rowTitleHeight = ax.radialmenu:GetTextHeight("ax.regular.bold")
    local rowDescriptionHeight = ax.radialmenu:GetTextHeight("ax.tiny") / 1.5
    local subtitleText = self:GetSectionsPanelSubtitle()
    local subtitleLines = ax.radialmenu:LimitWrappedLines(ax.util:GetWrappedText(subtitleText, "ax.small", width - padding * 2) or { subtitleText }, width < ax.util:ScreenScale(174) and 1 or 2)
    local subtitleY = y + padding + titleHeight + ax.util:ScreenScaleH(3)
    local rowGap = math.Clamp(math.floor(height * 0.018), ax.util:ScreenScaleH(3), ax.util:ScreenScaleH(6))
    local headerHeight = titleHeight + ax.util:ScreenScaleH(3) + (#subtitleLines * subtitleLineHeight)
    local rowY = y + padding + headerHeight + ax.util:ScreenScaleH(8)
    local availableHeight = math.max(42, (y + height - padding) - rowY)
    local rowHeight = math.Clamp(math.floor((availableHeight - rowGap * (sectionCount - 1)) / sectionCount), ax.util:ScreenScaleH(24), ax.util:ScreenScaleH(42))

    ax.render.DrawShadows(metrics.roundness + 2, x, y, width, height, ax.radialmenu:AlphaColor(glass.highlight or glass.progress, 28), 18, 26, ax.render.SHAPE_IOS)
    ax.theme:DrawGlassPanel(x, y, width, height, {
        radius = metrics.roundness + 2,
        blur = 1.05,
        flags = ax.render.SHAPE_IOS,
        fill = glass.menu or glass.panel,
        border = glass.menuBorder or glass.panelBorder,
    })

    ax.theme:DrawGlassGradients(x, y, width, height, {
        top = ax.radialmenu:AlphaColor(glass.gradientTop, 40),
        bottom = ax.radialmenu:AlphaColor(glass.gradientBottom, 58),
    })

    draw.SimpleText(self:GetSectionsPanelTitle(), "ax.large.bold", x + padding, y + padding, glass.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    for i = 1, #subtitleLines do
        local line = subtitleLines[i]
        draw.SimpleText(line, "ax.small", x + padding, subtitleY + (i - 1) * subtitleLineHeight, glass.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    for i = 1, #sections do
        local section = sections[i]
        local fraction = self.sectionAnimations[section.id] or 0
        local rowFill = ax.radialmenu:BlendColors(
            ax.radialmenu:AlphaColor(glass.button, 98),
            ax.radialmenu:AlphaColor(section.color, 105 + fraction * 60),
            math.min(1, 0.22 + fraction * 0.55)
        )
        local rowBorder = ax.radialmenu:BlendColors(
            ax.radialmenu:AlphaColor(glass.buttonBorder or glass.panelBorder, 50),
            ax.radialmenu:AlphaColor(section.color, 220),
            math.min(1, 0.3 + fraction * 0.7)
        )
        local rowX = x + padding
        local rowWidth = width - padding * 2
        local countLabel = self:GetSectionCountLabel(section)
        local countWidth = ax.radialmenu:GetTextWidth("ax.small.bold", countLabel) + ax.util:ScreenScale(10)
        local descWidth = math.max(ax.util:ScreenScale(42), rowWidth - ax.util:ScreenScale(24) - countWidth)
        local maxDescriptionLines = math.max(1, math.floor((rowHeight - ax.util:ScreenScaleH(9) - rowTitleHeight - ax.util:ScreenScaleH(2)) / rowDescriptionHeight))
        local descriptionText = tostring(section.description or "")
        local descriptionLines

        if ( maxDescriptionLines <= 1 ) then
            descriptionLines = {
                ax.radialmenu:FitTextToWidth("ax.tiny", descriptionText, descWidth),
            }
        else
            descriptionLines = ax.radialmenu:LimitWrappedLines(ax.util:GetWrappedText(descriptionText, "ax.tiny", descWidth) or { descriptionText }, maxDescriptionLines)
        end

        ax.theme:DrawGlassButton(rowX, rowY, rowWidth, rowHeight, {
            radius = math.max(8, metrics.roundness),
            blur = 0.85,
            fill = rowFill,
            border = rowBorder,
        })

        ax.render.Draw(ax.util:ScreenScale(3), rowX + ax.util:ScreenScale(4), rowY + ax.util:ScreenScaleH(4), ax.util:ScreenScale(3), rowHeight - ax.util:ScreenScaleH(8), ax.radialmenu:AlphaColor(section.color, 220))

        draw.SimpleText(section.name, "ax.regular.bold", rowX + ax.util:ScreenScale(14), rowY + rowHeight / 2 + ax.util:ScreenScaleH(2), fraction > 0.5 and glass.textHover or glass.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

        for i = 1, #descriptionLines do
            local line = descriptionLines[i]
            draw.SimpleText(line, "ax.tiny", rowX + ax.util:ScreenScale(14), rowY + rowHeight / 2 + (i - 1) * rowDescriptionHeight, glass.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        draw.SimpleText(countLabel, "ax.small.bold", rowX + rowWidth - ax.util:ScreenScale(8), rowY + rowHeight / 2, ax.radialmenu:AlphaColor(section.color, 235), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

        rowY = rowY + rowHeight + rowGap
    end
end

function PANEL:ShouldPaintInfoPanel()
    return true
end

function PANEL:GetInfoItem()
    return self.previewItem
end

function PANEL:GetInfoTitle(item)
    return item and (item.data.name or item.id) or "No Items Registered"
end

function PANEL:GetInfoDescription(item)
    return item and item.data.description or "Register items in the module to populate this radial menu."
end

function PANEL:GetInfoSectionLabel(item)
    return item and item.section and item.section.name or "Empty"
end

function PANEL:GetInfoTypeLabel(item)
    return item and "Item" or "Unavailable"
end

function PANEL:GetInfoMetaLabel(item)
    return "Sequence"
end

function PANEL:GetInfoMetaValue(item)
    return item and tostring(item.data.sequence or "n/a") or "n/a"
end

function PANEL:GetInfoFooter(item)
    if ( item ) then
        return "Left click to activate the selected item."
    end

    return "Right click or ESC cancels this radial menu."
end

function PANEL:GetInfoFooterHint(item)
    if ( item ) then
        return "Right click or ESC to cancel."
    end

    return "Add items to restore this radial menu."
end

function PANEL:PaintInfoPanel(layout, glass, metrics)
    local x, y = layout.rightX, layout.panelY
    local width, height = layout.panelWidth, layout.panelHeight
    local padding = ax.util:ScreenScale(10)
    local item = self:GetInfoItem()
    local accent = item and item.section.color or (glass.progress or glass.highlight)
    local title = self:GetInfoTitle(item)
    local description = self:GetInfoDescription(item)
    local sectionLabel = self:GetInfoSectionLabel(item)
    local typeLabel = self:GetInfoTypeLabel(item)
    local metaLabel = self:GetInfoMetaLabel(item)
    local metaValue = self:GetInfoMetaValue(item)
    local wrapped = ax.util:GetWrappedText(description, "ax.regular", width - padding * 2) or { description }
    local headerHeight = ax.radialmenu:GetTextHeight("ax.large.bold")
    local titleLineHeight = ax.radialmenu:GetTextHeight("ax.medium.bold")
    local regularLineHeight = ax.radialmenu:GetTextHeight("ax.regular")
    local smallLineHeight = ax.radialmenu:GetTextHeight("ax.small")
    local titleLines = ax.radialmenu:LimitWrappedLines(ax.util:GetWrappedText(title, "ax.medium.bold", width - padding * 2) or { title }, 2)
    local titleY = y + padding + headerHeight + ax.util:ScreenScaleH(3)

    ax.render.DrawShadows(metrics.roundness + 2, x, y, width, height, ax.radialmenu:AlphaColor(accent, 28), 18, 26, ax.render.SHAPE_IOS)
    ax.theme:DrawGlassPanel(x, y, width, height, {
        radius = metrics.roundness + 2,
        blur = 1.05,
        flags = ax.render.SHAPE_IOS,
        fill = glass.panel,
        border = glass.panelBorder,
    })

    ax.theme:DrawGlassGradients(x, y, width, height, {
        top = ax.radialmenu:AlphaColor(accent, 26),
        bottom = ax.radialmenu:AlphaColor(glass.gradientBottom, 52),
    })

    draw.SimpleText("Selection", "ax.large.bold", x + padding, y + padding, glass.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    for i = 1, #titleLines do
        local line = titleLines[i]
        draw.SimpleText(line, "ax.medium.bold", x + padding, titleY + (i - 1) * titleLineHeight, ax.radialmenu:AlphaColor(accent, 235), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local tagY = titleY + (#titleLines * titleLineHeight) + 12
    local tagSpacing = ax.util:ScreenScale(4)
    local sectionTagWidth = math.Clamp(ax.radialmenu:GetTextWidth("ax.tiny.bold", sectionLabel) + ax.util:ScreenScale(14), ax.util:ScreenScale(42), ax.util:ScreenScale(84))
    local typeTagWidth = math.Clamp(ax.radialmenu:GetTextWidth("ax.tiny.bold", typeLabel) + ax.util:ScreenScale(14), ax.util:ScreenScale(42), ax.util:ScreenScale(60))
    local stackTags = sectionTagWidth + typeTagWidth + tagSpacing > (width - padding * 2)

    local function DrawTag(text, tagX, tagYPos, tagWidth, tagColor)
        ax.theme:DrawGlassButton(tagX, tagYPos, tagWidth, ax.util:ScreenScaleH(14), {
            radius = 10,
            blur = 0.65,
            fill = ax.radialmenu:BlendColors(ax.radialmenu:AlphaColor(glass.button, 92), ax.radialmenu:AlphaColor(tagColor, 120), 0.45),
            border = ax.radialmenu:AlphaColor(tagColor, 220),
        })

        draw.SimpleText(ax.radialmenu:FitTextToWidth("ax.tiny.bold", text, tagWidth - ax.util:ScreenScale(7)), "ax.tiny.bold", tagX + tagWidth * 0.5, tagYPos + ax.util:ScreenScaleH(7), glass.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    DrawTag(sectionLabel, x + padding, tagY, sectionTagWidth, accent)

    if ( stackTags ) then
        DrawTag(typeLabel, x + padding, tagY + ax.util:ScreenScaleH(18), typeTagWidth, glass.progress or accent)
    else
        DrawTag(typeLabel, x + padding + sectionTagWidth + tagSpacing, tagY, typeTagWidth, glass.progress or accent)
    end

    local sequenceLabelY = tagY + (stackTags and ax.util:ScreenScaleH(35) or ax.util:ScreenScaleH(20))
    draw.SimpleText(metaLabel, "ax.small.bold", x + padding, sequenceLabelY, glass.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(metaValue, "ax.regular.bold", x + padding, sequenceLabelY + smallLineHeight + ax.util:ScreenScaleH(1), glass.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local textY = sequenceLabelY + smallLineHeight + regularLineHeight + ax.util:ScreenScaleH(8)
    local maxDescriptionLines = math.max(2, math.floor((y + height - ax.util:ScreenScaleH(54) - textY) / regularLineHeight))
    local limitedDescription = ax.radialmenu:LimitWrappedLines(wrapped, maxDescriptionLines)

    for i = 1, #limitedDescription do
        local line = limitedDescription[i]
        draw.SimpleText(line, "ax.regular", x + padding, textY, glass.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        textY = textY + regularLineHeight
    end

    draw.SimpleText(self:GetInfoFooter(item), "ax.small", x + padding, y + height - ax.util:ScreenScaleH(28), glass.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(self:GetInfoFooterHint(item), "ax.small.bold", x + padding, y + height - ax.util:ScreenScaleH(18), glass.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function PANEL:ShouldPaintHintPanel()
    return true
end

function PANEL:GetHintTitle()
    return "RADIAL MENU"
end

function PANEL:GetHintText()
    return "Right click or ESC to cancel"
end

function PANEL:PaintHintPanel(layout, glass, metrics)
    local x, y = layout.hintX, layout.hintY
    local width, height = layout.hintWidth, layout.hintHeight

    ax.theme:DrawGlassPanel(x, y, width, height, {
        radius = metrics.roundness + 2,
        blur = 0.95,
        flags = ax.render.SHAPE_IOS,
        fill = ax.radialmenu:AlphaColor(glass.panel, 170),
        border = ax.radialmenu:AlphaColor(glass.panelBorder, 90),
    })

    ax.theme:DrawGlassGradients(x, y, width, height, {
        top = ax.radialmenu:AlphaColor(glass.gradientTop, 28),
        bottom = ax.radialmenu:AlphaColor(glass.gradientBottom, 42),
    })

    draw.SimpleText(self:GetHintTitle(), "ax.small.bold", x + ax.util:ScreenScale(10), y + ax.util:ScreenScaleH(7), glass.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(self:GetHintText(), "ax.small", x + ax.util:ScreenScale(10), y + ax.util:ScreenScaleH(17), glass.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function PANEL:ShouldPaintPointer()
    return true
end

function PANEL:PaintPointer(layout, glass)
    if ( !self.mouseX or !self.mouseY ) then return end
    if ( !self.hoveredItem ) then return end
    if ( !self.mouseDistance or self.mouseDistance < layout.deadzone - 18 or self.mouseDistance > layout.ringOuter + layout.edgePadding ) then return end

    local pointerColor = self.hoveredItem.section.color or (self.previewItem and self.previewItem.section.color) or glass.progress
    ax.render().Circle(self.mouseX, self.mouseY, ax.util:ScreenScale(5))
        :Outline(2)
        :Blur(0.35)
        :Color(ax.radialmenu:AlphaColor(pointerColor, 130))
        :Draw()
    ax.render.DrawCircle(self.mouseX, self.mouseY, ax.util:ScreenScale(2), ax.radialmenu:AlphaColor(pointerColor, 185))
end

function PANEL:ShouldPaintPreview()
    return false
end

function PANEL:GetEmptyTitle()
    return "No items registered"
end

function PANEL:GetEmptyDescription()
    return "Populate this radial menu to use it."
end

function PANEL:PaintEmptyState(width, height, glass, metrics)
    local panelWidth = math.max(ax.util:ScreenScale(230), width * 0.28)
    local panelHeight = math.max(ax.util:ScreenScaleH(62), height * 0.11)
    local x = width * 0.5 - panelWidth * 0.5
    local y = height * 0.5 - panelHeight * 0.5

    ax.theme:DrawGlassPanel(x, y, panelWidth, panelHeight, {
        radius = metrics.roundness + 2,
        blur = 1.05,
        flags = ax.render.SHAPE_IOS,
        fill = glass.panel,
        border = glass.panelBorder,
    })

    draw.SimpleText(self:GetEmptyTitle(), "ax.large.bold", width * 0.5, y + 30, glass.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(self:GetEmptyDescription(), "ax.regular", width * 0.5, y + 62, glass.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function PANEL:Paint(width, height)
    local glass = ax.theme:GetGlass()
    local metrics = ax.theme:GetMetrics()

    self:PaintBackdrop(width, height, glass)

    if ( self.wheelData.count == 0 ) then
        self:PaintEmptyState(width, height, glass, metrics)
        return true
    end

    local layout = self:GetLayoutMetrics(width, height)

    if ( self:ShouldPaintSectionsPanel() ) then
        self:PaintSectionsPanel(layout, glass, metrics)
    end

    if ( self:ShouldPaintInfoPanel() ) then
        self:PaintInfoPanel(layout, glass, metrics)
    end

    if ( self:ShouldPaintHintPanel() ) then
        self:PaintHintPanel(layout, glass, metrics)
    end

    self:PaintWheel(layout, glass)

    if ( self:ShouldPaintPointer() ) then
        self:PaintPointer(layout, glass)
    end

    if ( self:ShouldPaintPreview() and isfunction(self.PaintPreview) ) then
        self:PaintPreview(layout, glass, metrics)
    end

    return true
end

vgui.Register("ax.radial.menu", PANEL, "EditablePanel")
