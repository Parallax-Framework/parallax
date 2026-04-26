--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.localization:AddPhrase("en", "tab.help.credits", "Credits")

ax.localization:AddPhrase("en", "credit.framework_dev", "Framework Developer")
ax.localization:AddPhrase("en", "credit.contributor", "Contributor")
ax.localization:AddPhrase("en", "credit.brainfucker", "Brainfucker")

ax.localization:AddPhrase("en", "credit.hero.title", "Parallax Framework")
ax.localization:AddPhrase("en", "credit.hero.subtitle", "Built by the people credited below.")
ax.localization:AddPhrase("en", "credit.hero.chips", "%d Developers  ·  %d Contributors  ·  %d Brainfuckers")

ax.localization:AddPhrase("en", "credit.section.developers.title", "Framework Developers")
ax.localization:AddPhrase("en", "credit.section.developers.subtitle", "Core authors of the framework.")
ax.localization:AddPhrase("en", "credit.section.contributors.title", "Contributors")
ax.localization:AddPhrase("en", "credit.section.contributors.subtitle", "Shipped features, fixes, and improvements.")
ax.localization:AddPhrase("en", "credit.section.brainfuckers.title", "Brainfuckers")
ax.localization:AddPhrase("en", "credit.section.brainfuckers.subtitle", "Made us think harder than we wanted to.")

ax.localization:AddPhrase("en", "credit.action.viewProfile", "View Profile  →")

local CREDITS = {
    developers = {
        { steamId = "76561197963057641", name = "riggs9162" },
        { steamId = "76561198373309941", name = "bloodycop6385" }
    },
    contributors = {
        { steamId = "76561199122803303", name = "Winkarst-cpu" },
        { steamId = "76561199208575979", name = "Flexgg13" },
        { steamId = "76561198151383580", name = "cuboxis" },
        { steamId = "76561198165619447", name = "KarmaLN" },
        { steamId = "76561199522528952", name = "wilderwesten" },
        { steamId = "76561197996534315", name = "scotnay" } -- Ngl, bro never sent a pr but he did inspire us to start the project, so we put him in here anyway
    },
    brainfuckers = {
        { steamId = "76561198882429953", name = "reallordmax" }
    }
}

local ROLE_ORDER = { "developers", "contributors", "brainfuckers" }

local ROLE_META = {
    developers = {
        titleKey = "credit.section.developers.title",
        subtitleKey = "credit.section.developers.subtitle",
        roleKey = "credit.framework_dev",
        accentKey = "progress"
    },
    contributors = {
        titleKey = "credit.section.contributors.title",
        subtitleKey = "credit.section.contributors.subtitle",
        roleKey = "credit.contributor",
        accentKey = "highlight"
    },
    brainfuckers = {
        titleKey = "credit.section.brainfuckers.title",
        subtitleKey = "credit.section.brainfuckers.subtitle",
        roleKey = "credit.brainfucker",
        accentKey = "text"
    }
}

local CARD_RADIUS = math.max(8, ax.util:ScreenScale(5))
local CARD_ACCENT = math.max(2, ax.util:ScreenScale(2))
local CARD_SPACING = ax.util:ScreenScaleH(6)

local function GetCounts()
    return {
        developers = #CREDITS.developers,
        contributors = #CREDITS.contributors,
        brainfuckers = #CREDITS.brainfuckers,
        total = #CREDITS.developers + #CREDITS.contributors + #CREDITS.brainfuckers
    }
end

local function AddHeroCard(parent, counts)
    local titleFont = "ax.huge.bold"
    local subtitleFont = "ax.medium.italic"
    local chipsFont = "ax.small.bold"
    local padding = ax.util:ScreenScale(18)
    local titleHeight = ax.util:GetTextHeight(titleFont)
    local subtitleHeight = ax.util:GetTextHeight(subtitleFont)
    local chipsHeight = ax.util:GetTextHeight(chipsFont)
    local height = padding * 2 + titleHeight + ax.util:ScreenScaleH(4) + subtitleHeight + ax.util:ScreenScaleH(10) + chipsHeight
    local glass = ax.theme:GetGlass()
    local metrics = ax.theme:GetMetrics()
    local accent = ax.theme:ScaleAlpha(glass.progress, metrics.opacity)

    ax.help:AddPaintCard(parent, height, accent, function(this, width, panelHeight, g)
        local cx = width * 0.5
        local y = padding

        draw.SimpleText(ax.localization:GetPhrase("credit.hero.title"), titleFont, cx, y, g.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        y = y + titleHeight + ax.util:ScreenScaleH(4)

        draw.SimpleText(ax.localization:GetPhrase("credit.hero.subtitle"), subtitleFont, cx, y, g.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        y = y + subtitleHeight + ax.util:ScreenScaleH(10)

        local chipsText = string.format(ax.localization:GetPhrase("credit.hero.chips"), counts.developers, counts.contributors, counts.brainfuckers)
        draw.SimpleText(chipsText, chipsFont, cx, y, accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end)
end

local function AddCreditCard(parent, entry, accentColor, roleText, staggerIndex)
    local cardHeight = math.max(ax.util:ScreenScaleH(64), 84)
    local avatarSize = math.floor(cardHeight - ax.util:ScreenScaleH(20))
    local pad = ax.util:ScreenScale(12)
    local ringThickness = math.max(2, ax.util:ScreenScale(1))
    local nameFont = "ax.large.bold"
    local roleFont = "ax.small"
    local badgeFont = "ax.small.bold"
    local nameHeight = ax.util:GetTextHeight(nameFont)
    local roleHeight = ax.util:GetTextHeight(roleFont)

    local card = parent:Add("EditablePanel")
    card:Dock(TOP)
    card:DockMargin(0, 0, 0, CARD_SPACING)
    card:SetTall(cardHeight)
    card:SetCursor("hand")

    card.hoverAlpha = 0
    card.ringAlpha = 0.35
    card.entryAlpha = 0
    card.profileUrl = "https://steamcommunity.com/profiles/" .. entry.steamId .. "/"

    card:SetAlpha(0)

    local avatar = card:Add("AvatarImage")
    avatar:SetSteamID(entry.steamId, 184)
    avatar:SetSize(avatarSize, avatarSize)
    avatar:SetPos(pad + CARD_ACCENT + ax.util:ScreenScale(6), math.floor((cardHeight - avatarSize) * 0.5))
    avatar:SetMouseInputEnabled(false)

    card.avatar = avatar

    card:Motion(0.45, {
        Delay = (staggerIndex or 0) * 0.06,
        Easing = "OutCubic",
        Target = {
            entryAlpha = 255
        },
        Think = function(current)
            if ( !IsValid(card) ) then return end

            card:SetAlpha(current.entryAlpha or 0)
        end,
        OnComplete = function(this)
            if ( !IsValid(this) ) then return end

            this:SetAlpha(255)
        end
    })

    card.OnCursorEntered = function(this)
        surface.PlaySound("ax.gui.button.enter")

        this:Motion(0.2, {
            Easing = "OutQuint",
            Target = {
                hoverAlpha = 1,
                ringAlpha = 1
            }
        })
    end

    card.OnCursorExited = function(this)
        this:Motion(0.25, {
            Easing = "OutQuint",
            Target = {
                hoverAlpha = 0,
                ringAlpha = 0.35
            }
        })
    end

    card.OnMousePressed = function(this, code)
        if ( code != MOUSE_LEFT ) then return end

        surface.PlaySound("ax.gui.button.click")
        gui.OpenURL(this.profileUrl)
    end

    card.PerformLayout = function(this, width, height)
        if ( !IsValid(this.avatar) ) then return end

        this.avatar:SetPos(pad + CARD_ACCENT + ax.util:ScreenScale(6), math.floor((height - avatarSize) * 0.5))
        this.avatar:SetSize(avatarSize, avatarSize)
    end

    card.Paint = function(this, width, height)
        local glass = ax.theme:GetGlass()
        local metrics = ax.theme:GetMetrics()
        local hover = this.hoverAlpha or 0

        ax.theme:DrawGlassPanel(0, 0, width, height, {
            radius = CARD_RADIUS,
            blur = 0.75
        })

        local scaledGradTop = ax.theme:ScaleAlpha(glass.gradientTop, metrics.gradientOpacity)
        local scaledGradBottom = ax.theme:ScaleAlpha(glass.gradientBottom, metrics.gradientOpacity)
        ax.theme:DrawGlassGradients(0, 0, width, height, {
            top = ColorAlpha(scaledGradTop, math.min(scaledGradTop.a, 26 + math.floor(22 * hover))),
            bottom = ColorAlpha(scaledGradBottom, math.min(scaledGradBottom.a, 34 + math.floor(28 * hover)))
        })

        if ( hover > 0 ) then
            local tint = ax.theme:ScaleAlpha(glass.buttonHover, metrics.opacity)
            ax.render.Draw(CARD_RADIUS, 0, 0, width, height, ColorAlpha(tint, math.floor(tint.a * hover * 0.55)))
        end

        local accent = accentColor or ax.theme:ScaleAlpha(glass.progress, metrics.opacity)
        ax.render.Draw(CARD_RADIUS, 0, 0, CARD_ACCENT, height, accent, ax.render.NO_TR + ax.render.NO_BR)

        local avatarX = pad + CARD_ACCENT + ax.util:ScreenScale(6)
        local avatarY = math.floor((height - avatarSize) * 0.5)
        local ringPad = math.max(2, ax.util:ScreenScale(2))
        local ringColor = ColorAlpha(accent, math.floor(255 * (this.ringAlpha or 0.35)))

        ax.render.DrawOutlined(math.max(4, ax.util:ScreenScale(3)),
            avatarX - ringPad, avatarY - ringPad,
            avatarSize + ringPad * 2, avatarSize + ringPad * 2,
            ringColor, ringThickness)

        local textX = avatarX + avatarSize + pad
        local textRight = width - pad
        local centerY = math.floor(height * 0.5)
        local textColor = glass.text
        if ( hover > 0 ) then
            textColor = Color(
                math.min(255, textColor.r + math.floor(18 * hover)),
                math.min(255, textColor.g + math.floor(18 * hover)),
                math.min(255, textColor.b + math.floor(18 * hover)),
                textColor.a
            )
        end

        local nameY = centerY - math.floor((nameHeight + roleHeight + ax.util:ScreenScaleH(2)) * 0.5)
        draw.SimpleText(entry.name, nameFont, textX, nameY, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(roleText, roleFont, textX, nameY + nameHeight + ax.util:ScreenScaleH(2), glass.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local badgeColor = Color(accent.r, accent.g, accent.b, math.min(255, 180 + math.floor(75 * hover)))
        draw.SimpleText(ax.localization:GetPhrase("credit.action.viewProfile"), badgeFont, textRight, centerY, badgeColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    return card
end

local function AddRoleSection(parent, roleId, staggerStart)
    local meta = ROLE_META[roleId]
    if ( !meta ) then return staggerStart end

    local entries = CREDITS[roleId] or {}
    if ( entries[1] == nil ) then return staggerStart end

    local glass = ax.theme:GetGlass()
    local metrics = ax.theme:GetMetrics()
    local accentColor = ax.theme:ScaleAlpha(glass[meta.accentKey] or glass.progress, metrics.opacity)
    local roleText = ax.localization:GetPhrase(meta.roleKey)

    ax.help:AddSpacer(parent, CARD_SPACING)
    ax.help:AddSectionLabel(parent,
        ax.localization:GetPhrase(meta.titleKey),
        ax.localization:GetPhrase(meta.subtitleKey))

    local stagger = staggerStart or 0
    for i = 1, #entries do
        AddCreditCard(parent, entries[i], accentColor, roleText, stagger)
        stagger = stagger + 1
    end

    return stagger
end

local function PopulateCredits(this, panel)
    local scroller = ax.help:CreateScroller(panel)
    local counts = GetCounts()

    AddHeroCard(scroller, counts)

    local stagger = 0
    for i = 1, #ROLE_ORDER do
        stagger = AddRoleSection(scroller, ROLE_ORDER[i], stagger)
    end

    panel:SizeToContents()
end

hook.Remove("PopulateHelpCategories", "ax.tab.help.credits")
hook.Add("PopulateHelpCategories", "ax.tab.help.credits", function(categories)
    categories["credits"] = {
        sort = 999,
        name = ax.localization:GetPhrase("tab.help.credits"),
        Populate = PopulateCredits
    }
end)
