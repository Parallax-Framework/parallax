--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}
local HELP = ax.help or {}

local HELP_CARD_SPACING = ax.util:ScreenScaleH(6)
local HELP_CARD_PADDING = ax.util:ScreenScale(12)
local HELP_CARD_RADIUS = math.max(8, ax.util:ScreenScale(5))
local HELP_CARD_ACCENT = math.max(2, ax.util:ScreenScale(2))
local HELP_LINE_GAP = ax.util:ScreenScaleH(1)

function PANEL:Init()
    self:Dock(FILL)
    self:InvalidateParent(true)
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.tab.help", PANEL, "ax.transition.pages")

local function GetWrappedLines(text, font, maxWidth)
    text = tostring(text or "")
    maxWidth = math.max(maxWidth or 0, ax.util:ScreenScale(128))

    return ax.util:GetWrappedText(text, font, maxWidth) or {text}
end

local function CompareCategoryEntries(a, b)
    local dataA = a.value
    local dataB = b.value
    local sortA = (istable(dataA) and isnumber(dataA.sort)) and dataA.sort or math.huge
    local sortB = (istable(dataB) and isnumber(dataB.sort)) and dataB.sort or math.huge

    if ( sortA != sortB ) then
        return sortA < sortB
    end

    local nameA = string.lower(tostring((istable(dataA) and dataA.name) or a.key))
    local nameB = string.lower(tostring((istable(dataB) and dataB.name) or b.key))

    if ( nameA == nameB ) then
        return tostring(a.key) < tostring(b.key)
    end

    return nameA < nameB
end

function HELP:GetContentWidth(panel)
    local width = IsValid(panel) and panel:GetWide() or 0

    if ( width <= 0 ) then
        width = ScrW() - ax.util:ScreenScale(96)
    end

    return math.max(width, ax.util:ScreenScale(320))
end

function HELP:CreateScroller(panel)
    local scroller = panel:Add("ax.scroller.vertical")
    scroller:Dock(FILL)

    return scroller
end

function HELP:AddSpacer(parent, amount)
    local spacer = parent:Add("EditablePanel")
    spacer:Dock(TOP)
    spacer:SetTall(amount or HELP_CARD_SPACING)
    spacer.Paint = nil

    return spacer
end

function HELP:AddSectionLabel(parent, title, subtitle)
    local titleLabel = parent:Add("ax.text")
    titleLabel:Dock(TOP)
    titleLabel:DockMargin(0, 0, 0, -ax.util:ScreenScaleH(3))
    titleLabel:SetFont("ax.large.bold.italic")
    titleLabel:SetText(title, true)

    if ( isstring(subtitle) and subtitle != "" ) then
        local subtitleLabel = parent:Add("ax.text")
        subtitleLabel:Dock(TOP)
        subtitleLabel:DockMargin(0, 0, 0, ax.util:ScreenScaleH(2))
        subtitleLabel:SetFont("ax.small")
        subtitleLabel:SetText(subtitle, true)
        subtitleLabel:SetTextColor(ax.theme:GetGlass().textMuted)
    end
end

function HELP:AddPaintCard(parent, height, accentColor, paintFunc)
    local card = parent:Add("EditablePanel")
    card:Dock(TOP)
    card:DockMargin(0, 0, 0, HELP_CARD_SPACING)
    card:SetTall(height)

    card.Paint = function(this, width, panelHeight)
        local glass = ax.theme:GetGlass()
        local metrics = ax.theme:GetMetrics()

        ax.theme:DrawGlassPanel(0, 0, width, panelHeight, {
            radius = HELP_CARD_RADIUS,
            blur = 0.75
        })

        local scaledGradTop = ax.theme:ScaleAlpha(glass.gradientTop, metrics.gradientOpacity)
        local scaledGradBottom = ax.theme:ScaleAlpha(glass.gradientBottom, metrics.gradientOpacity)
        ax.theme:DrawGlassGradients(0, 0, width, panelHeight, {
            top = ColorAlpha(scaledGradTop, math.min(scaledGradTop.a, 26)),
            bottom = ColorAlpha(scaledGradBottom, math.min(scaledGradBottom.a, 34))
        })

        surface.SetDrawColor(accentColor or ax.theme:ScaleAlpha(glass.progress, metrics.opacity))
        surface.DrawRect(0, 0, HELP_CARD_ACCENT, panelHeight)

        if ( isfunction(paintFunc) ) then
            paintFunc(this, width, panelHeight, glass)
        end
    end

    return card
end

function HELP:AddCompactCard(parent, width, data)
    local maxWidth = width - HELP_CARD_PADDING * 2 - HELP_CARD_ACCENT - ax.util:ScreenScale(8)
    local titleFont = data.titleFont or "ax.regular.bold"
    local subtitleFont = data.subtitleFont or "ax.small.italic"
    local badgeFont = data.badgeFont or "ax.small.bold"
    local xOffset = HELP_CARD_PADDING + HELP_CARD_ACCENT + ax.util:ScreenScale(6)
    local titleHeight = ax.util:GetTextHeight(titleFont)
    local subtitleHeight = ax.util:GetTextHeight(subtitleFont)
    local renderedLines = {}
    local height = HELP_CARD_PADDING * 2 + titleHeight
    local subtitleLines = {}

    if ( isstring(data.subtitle) and data.subtitle != "" ) then
        subtitleLines = GetWrappedLines(data.subtitle, subtitleFont, maxWidth)
        height = height + ax.util:ScreenScaleH(2) + (#subtitleLines * (subtitleHeight + HELP_LINE_GAP))
    end

    for i = 1, #(data.lines or {}) do
        local line = data.lines[i]
        local lineData = isstring(line) and { text = line } or table.Copy(line)
        local font = lineData.font or "ax.small"
        local lineHeight = ax.util:GetTextHeight(font)
        local wrapped = lineData.wrap == false and {tostring(lineData.text or "")} or GetWrappedLines(lineData.text, font, maxWidth)

        for j = 1, #wrapped do
            renderedLines[#renderedLines + 1] = {
                text = wrapped[j],
                font = font,
                color = lineData.color,
                strong = lineData.strong,
                height = lineHeight
            }
        end
    end

    if ( renderedLines[1] != nil ) then
        height = height + ax.util:ScreenScaleH(6)

        for i = 1, #renderedLines do
            height = height + renderedLines[i].height + HELP_LINE_GAP
        end
    end

    self:AddPaintCard(parent, height, data.accentColor, function(this, cardWidth, cardHeight, glass)
        local x = xOffset
        local y = HELP_CARD_PADDING
        local badgeColor = data.badgeColor or data.accentColor or glass.progress

        draw.SimpleText(data.title or "", titleFont, x, y, glass.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        if ( isstring(data.badge) and data.badge != "" ) then
            draw.SimpleText(data.badge, badgeFont, cardWidth - HELP_CARD_PADDING, y + ax.util:ScreenScaleH(1), badgeColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end

        y = y + titleHeight

        if ( subtitleLines[1] != nil ) then
            y = y + ax.util:ScreenScaleH(2)

            for i = 1, #subtitleLines do
                draw.SimpleText(subtitleLines[i], subtitleFont, x, y, glass.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                y = y + subtitleHeight + HELP_LINE_GAP
            end
        end

        if ( renderedLines[1] != nil ) then
            y = y + ax.util:ScreenScaleH(4)

            for i = 1, #renderedLines do
                local line = renderedLines[i]
                local color = line.color or (line.strong and glass.text or glass.textMuted)

                draw.SimpleText(line.text, line.font, x, y, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                y = y + line.height + HELP_LINE_GAP
            end
        end
    end)
end

function HELP:AddStatsCard(parent, title, rows, accentColor)
    local titleFont = "ax.regular.bold"
    local rowFont = "ax.small"
    local titleHeight = ax.util:GetTextHeight(titleFont)
    local rowHeight = ax.util:GetTextHeight(rowFont)
    local height = HELP_CARD_PADDING * 2 + titleHeight + ax.util:ScreenScaleH(6) + (#rows * (rowHeight + ax.util:ScreenScaleH(5)))

    self:AddPaintCard(parent, height, accentColor, function(this, width, panelHeight, glass)
        local x = HELP_CARD_PADDING + HELP_CARD_ACCENT + ax.util:ScreenScale(6)
        local y = HELP_CARD_PADDING
        local right = width - HELP_CARD_PADDING

        draw.SimpleText(title, titleFont, x, y, glass.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        y = y + titleHeight + ax.util:ScreenScaleH(6)

        for i = 1, #rows do
            local row = rows[i]

            draw.SimpleText(row.label, rowFont, x, y, glass.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(tostring(row.value), rowFont, right, y, row.color or glass.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

            y = y + rowHeight + ax.util:ScreenScaleH(2)

            if ( i < #rows ) then
                local metrics = ax.theme:GetMetrics()
                local scaledBorder = ax.theme:ScaleAlpha(glass.panelBorder, metrics.borderOpacity)
                surface.SetDrawColor(ColorAlpha(scaledBorder, math.min(scaledBorder.a, 65)))
                surface.DrawRect(x, y, right - x, 1)
                y = y + ax.util:ScreenScaleH(3)
            end
        end
    end)
end

function HELP:AddEmptyState(parent, width, title, body, accentColor)
    self:AddCompactCard(parent, width, {
        title = title,
        accentColor = accentColor or ax.theme:ScaleAlpha(ax.theme:GetGlass().highlight, ax.theme:GetMetrics().opacity),
        lines = {
            {
                text = body,
                font = "ax.small"
            }
        }
    })
end

function HELP:CreateSearchLayout(panel, placeholder, populate)
    local wrapper = panel:Add("EditablePanel")
    wrapper:Dock(FILL)
    wrapper.Paint = nil

    local search = wrapper:Add("ax.text.entry")
    search:Dock(TOP)
    search:DockMargin(0, 0, 0, HELP_CARD_SPACING)
    search:SetPlaceholderText(placeholder)

    local scroller = wrapper:Add("ax.scroller.vertical")
    scroller:Dock(FILL)

    local function Rebuild()
        scroller:Clear()
        populate(scroller, ax.util:NormalizeSearchString(search:GetValue()), self:GetContentWidth(wrapper))

        scroller.ScrollTarget = 0
        scroller.ScrollLerp = 0
        scroller:InvalidateLayout(true)
    end

    search.OnValueChange = function()
        Rebuild()
    end

    search.OnEnter = function()
        Rebuild()
    end

    Rebuild()

    return wrapper, search, scroller
end

ax.help = HELP

hook.Remove("PopulateTabButtons", "ax.tab.help")
hook.Remove("PopulateHelpCategories", "ax.tab.help")

hook.Add("PopulateTabButtons", "ax.tab.help", function(buttons)
    buttons["help"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.help")
        end,
        Sections = {}
    }

    local categories = {}
    hook.Run("PopulateHelpCategories", categories)

    local sortedCategories = ax.util:GetSortedEntries(categories, CompareCategoryEntries)

    for i = 1, #sortedCategories do
        local entry = sortedCategories[i]
        buttons["help"].Sections[entry.key] = entry.value
    end
end)
