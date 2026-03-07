--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local function CompareModules(a, b)
    local nameA = string.lower(tostring(a.value.name or a.value.uniqueID or a.key))
    local nameB = string.lower(tostring(b.value.name or b.value.uniqueID or b.key))

    if ( nameA == nameB ) then
        return tostring(a.key) < tostring(b.key)
    end

    return nameA < nameB
end

local function AddModuleCard(parent, width, module)
    local isCore = module.scope == "framework"
    local glass = ax.theme:GetGlass()
    local metrics = ax.theme:GetMetrics()
    local accentColor = isCore and ax.theme:ScaleAlpha(glass.panelBorder, metrics.borderOpacity) or ax.theme:ScaleAlpha(glass.highlight, metrics.opacity)
    local summary = module.description or "No public description is available for this system yet."

    ax.help:AddCompactCard(parent, width, {
        title = module.name or module.uniqueID or "Unknown Module",
        subtitle = "Created by " .. (module.author or "Unknown"),
        badge = isCore and "Core" or "Server",
        accentColor = accentColor,
        badgeColor = accentColor,
        lines = {
            {
                text = summary,
                font = "ax.small",
                strong = true
            }
        }
    })
end

local function PopulateModules(this, panel)
    ax.help:CreateSearchLayout(panel, "Search active systems...", function(scroller, query, width)
        local coreModules = ax.util:GetSortedEntries(ax.module:GetByScope("framework"), CompareModules)
        local serverModules = ax.util:GetSortedEntries(ax.module:GetByScope("schema"), CompareModules)
        local matchedCore = {}
        local matchedServer = {}

        for i = 1, #coreModules do
            local module = coreModules[i].value

            if ( ax.util:SearchMatches(query, module.name, module.uniqueID, module.description) ) then
                matchedCore[#matchedCore + 1] = module
            end
        end

        for i = 1, #serverModules do
            local module = serverModules[i].value

            if ( ax.util:SearchMatches(query, module.name, module.uniqueID, module.description) ) then
                matchedServer[#matchedServer + 1] = module
            end
        end

        if ( query == "" ) then
            local glass = ax.theme:GetGlass()
            local metrics = ax.theme:GetMetrics()
            local borderColor = ax.theme:ScaleAlpha(glass.panelBorder, metrics.borderOpacity)
            local highlightColor = ax.theme:ScaleAlpha(glass.highlight, metrics.opacity)
            ax.help:AddCompactCard(scroller, width, {
                title = "Active Systems",
                accentColor = borderColor,
                lines = {
                    {text = "This page shows the gameplay systems currently loaded on the server.", font = "ax.small", strong = true},
                    {text = "Core systems come with Parallax. Server features are added by the active schema.", font = "ax.small"}
                }
            })

            ax.help:AddStatsCard(scroller, "Loaded", {
                {label = "Core systems", value = #matchedCore, color = borderColor},
                {label = "Server features", value = #matchedServer, color = highlightColor}
            }, borderColor)
        end

        if ( matchedCore[1] == nil and matchedServer[1] == nil ) then
            local borderColor = ax.theme:ScaleAlpha(ax.theme:GetGlass().panelBorder, ax.theme:GetMetrics().borderOpacity)
            ax.help:AddEmptyState(scroller, width, "No Matching Systems", "Try another search or clear the filter.", borderColor)
            return
        end

        if ( matchedCore[1] != nil ) then
            ax.help:AddSectionLabel(scroller, "Core Systems", "Framework systems shared by Parallax servers.")
            ax.help:AddSpacer(scroller, ax.util:ScreenScaleH(2))

            for i = 1, #matchedCore do
                AddModuleCard(scroller, width, matchedCore[i])
            end
        end

        if ( matchedServer[1] != nil ) then
            ax.help:AddSectionLabel(scroller, "Server Features", "Schema-specific systems active on this server.")
            ax.help:AddSpacer(scroller, ax.util:ScreenScaleH(2))

            for i = 1, #matchedServer do
                AddModuleCard(scroller, width, matchedServer[i])
            end
        end
    end)
end

hook.Remove("PopulateHelpCategories", "ax.tab.help.modules")
hook.Add("PopulateHelpCategories", "ax.tab.help.modules", function(categories)
    categories["modules"] = {
        sort = 40,
        name = "Modules",
        Populate = PopulateModules
    }
end)
