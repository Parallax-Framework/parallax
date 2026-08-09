--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local function CountEntries(entries)
    if ( !istable(entries) ) then
        return 0
    end

    return table.Count(entries)
end

local function PopulateOverview(this, panel)
    local scroller = ax.help:CreateScroller(panel)
    local client = ax.client
    local character = IsValid(client) and client:GetCharacter() or nil
    local factionData = IsValid(client) and client.GetFactionData and client:GetFactionData() or nil
    local classData = IsValid(client) and client.GetClassData and client:GetClassData() or nil
    local rankData = IsValid(client) and client.GetRankData and client:GetRankData() or nil
    local publicCommands = ax.command:GetPublic()
    local coreModules = ax.module:GetByScope("framework")
    local serverModules = ax.module:GetByScope("schema")
    local width = ax.help:GetContentWidth(panel)

    local glass = ax.theme:GetGlass()
    local metrics = ax.theme:GetMetrics()
    local progressColor = ax.theme:ScaleAlpha(glass.progress, metrics.opacity)
    local highlightColor = ax.theme:ScaleAlpha(glass.highlight, metrics.opacity)
    local borderColor = ax.theme:ScaleAlpha(glass.panelBorder, metrics.borderOpacity)

    ax.help:AddCompactCard(scroller, width, {
        title = "Help",
        titleFont = "ax.large.bold.italic",
        badge = "Player Guide",
        accentColor = progressColor,
        badgeColor = progressColor,
        lines = {
            {
                text = "This help menu is for regular players. Use Commands for public chat commands, Factions for character groups, and Modules for the systems running on this server.",
                font = "ax.small",
                strong = true
            },
            {
                text = "Each searchable page updates as you type.",
                font = "ax.small"
            }
        }
    })

    ax.help:AddStatsCard(scroller, "At A Glance", {
        {label = "Public commands", value = CountEntries(publicCommands), color = progressColor},
        {label = "Factions", value = CountEntries(ax.faction:GetAll())},
        {label = "Core systems", value = CountEntries(coreModules)},
        {label = "Server features", value = CountEntries(serverModules)}
    }, progressColor)

    if ( character ) then
        ax.help:AddCompactCard(scroller, width, {
            title = "Current Character",
            accentColor = highlightColor,
            lines = {
                {text = "Name: " .. ax.util:CapTextWord(character:GetName() or "Unknown", 32), font = "ax.small", strong = true},
                {text = "Faction: " .. ((factionData and factionData.name) or "Unassigned"), font = "ax.small"},
                {text = "Class: " .. ((classData and classData.name) or "None"), font = "ax.small"},
                {text = "Rank: " .. ((rankData and rankData.name) or "None"), font = "ax.small"}
            }
        })
    else
        ax.help:AddCompactCard(scroller, width, {
            title = "No Active Character",
            accentColor = highlightColor,
            lines = {
                {
                    text = "Character-specific information appears here after you load into the server.",
                    font = "ax.small"
                }
            }
        })
    end

    ax.help:AddCompactCard(scroller, width, {
        title = "Quick Tips",
        accentColor = borderColor,
        lines = {
            {text = "Commands: browse only the commands regular players can use.", font = "ax.small"},
            {text = "Factions: check which groups are open and which usually need staff approval.", font = "ax.small"},
            {text = "Modules: see the active gameplay systems and schema features.", font = "ax.small"}
        }
    })
end

hook.Remove("PopulateHelpCategories", "ax.tab.help.overview")
hook.Add("PopulateHelpCategories", "ax.tab.help.overview", function(categories)
    categories["overview"] = {
        sort = 10,
        name = "Overview",
        Populate = PopulateOverview
    }
end)
