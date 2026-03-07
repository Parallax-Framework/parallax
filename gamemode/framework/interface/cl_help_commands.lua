--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local function CompareCommands(a, b)
    local nameA = string.lower(tostring(a.value.displayName or a.value.name or a.key))
    local nameB = string.lower(tostring(b.value.displayName or b.value.name or b.key))

    if ( nameA == nameB ) then
        return tostring(a.key) < tostring(b.key)
    end

    return nameA < nameB
end

local function GetCommandAliasString(def)
    if ( istable(def.alias) and def.alias[1] != nil ) then
        return table.concat(def.alias, ", ")
    elseif ( isstring(def.alias) and def.alias != "" ) then
        return def.alias
    end

    return ""
end

local function AddCommandCard(parent, width, def)
    local aliases = GetCommandAliasString(def)
    local usage = (ax.command.prefixes and ax.command.prefixes[1] or "/") .. ax.command:Help(def.name or "")
    local lines = {
        {
            text = def.description or "No description available.",
            font = "ax.small",
            strong = true
        },
        {
            text = "Use: " .. usage,
            font = "ax.small"
        }
    }

    if ( aliases != "" ) then
        lines[#lines + 1] = {
            text = "Aliases: " .. aliases,
            font = "ax.small"
        }
    end

    ax.help:AddCompactCard(parent, width, {
        title = "/" .. (def.name or "command"),
        accentColor = ax.theme:ScaleAlpha(ax.theme:GetGlass().progress, ax.theme:GetMetrics().opacity),
        badgeColor = ax.theme:ScaleAlpha(ax.theme:GetGlass().progress, ax.theme:GetMetrics().opacity),
        lines = lines
    })
end

local function PopulateCommands(this, panel)
    ax.help:CreateSearchLayout(panel, "Search player commands...", function(scroller, query, width)
        local commands = ax.util:GetSortedEntries(ax.command:GetPublic(), CompareCommands)
        local matches = {}

        for i = 1, #commands do
            local def = commands[i].value
            local aliases = GetCommandAliasString(def)

            if ( ax.util:SearchMatches(query, def.name, def.displayName, def.description, aliases) ) then
                matches[#matches + 1] = def
            end
        end

        if ( query == "" ) then
            local glass = ax.theme:GetGlass()
            local metrics = ax.theme:GetMetrics()
            local progressColor = ax.theme:ScaleAlpha(glass.progress, metrics.opacity)
            ax.help:AddCompactCard(scroller, width, {
                title = "Player Commands",
                accentColor = progressColor,
                lines = {
                    {text = "These are the public commands available to ordinary players on this server.", font = "ax.small", strong = true},
                    {text = "Search by command name, alias, or description.", font = "ax.small"}
                }
            })

            ax.help:AddStatsCard(scroller, "Available", {
                {label = "Public commands", value = #matches, color = progressColor}
            }, progressColor)
        end

        if ( matches[1] == nil ) then
            local progressColor = ax.theme:ScaleAlpha(ax.theme:GetGlass().progress, ax.theme:GetMetrics().opacity)
            ax.help:AddEmptyState(scroller, width, "No Matching Commands", "Try a different word or clear the search field.", progressColor)
            return
        end

        for i = 1, #matches do
            AddCommandCard(scroller, width, matches[i])
        end
    end)
end

hook.Remove("PopulateHelpCategories", "ax.tab.help.commands")
hook.Add("PopulateHelpCategories", "ax.tab.help.commands", function(categories)
    categories["commands"] = {
        sort = 20,
        name = "Commands",
        Populate = PopulateCommands
    }
end)
