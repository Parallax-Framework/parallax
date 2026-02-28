--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local function CompareFactions(a, b)
    local nameA = string.lower(tostring(a.value.name or a.value.id or a.key))
    local nameB = string.lower(tostring(b.value.name or b.value.id or b.key))

    if ( nameA == nameB ) then
        return tostring(a.key) < tostring(b.key)
    end

    return nameA < nameB
end

local function GetFactionSearchText(faction)
    local parts = {}

    if ( isstring(faction.name) and faction.name != "" ) then
        parts[#parts + 1] = faction.name
    end

    if ( isstring(faction.id) and faction.id != "" ) then
        parts[#parts + 1] = faction.id
    end

    if ( isstring(faction.description) and faction.description != "" ) then
        parts[#parts + 1] = faction.description
    end

    for _, classData in pairs(faction.Classes or {}) do
        if ( isstring(classData.name) and classData.name != "" ) then
            parts[#parts + 1] = classData.name
        elseif ( isstring(classData.id) and classData.id != "" ) then
            parts[#parts + 1] = classData.id
        end
    end

    for _, rankData in pairs(faction.Ranks or {}) do
        if ( isstring(rankData.name) and rankData.name != "" ) then
            parts[#parts + 1] = rankData.name
        elseif ( isstring(rankData.id) and rankData.id != "" ) then
            parts[#parts + 1] = rankData.id
        end
    end

    return table.concat(parts, " ")
end

local function AddFactionCard(parent, width, faction, currentFaction)
    local classCount = istable(faction.Classes) and table.Count(faction.Classes) or 0
    local rankCount = istable(faction.Ranks) and table.Count(faction.Ranks) or 0
    local isCurrent = currentFaction == faction.index
    local accentColor = isCurrent and ax.theme:GetGlass().progress or ax.theme:GetGlass().highlight
    local accessText = faction.isDefault and "Open" or "Whitelist"
    local description = faction.description or "No description available."
    local lines = {
        {
            text = description,
            font = "ax.small",
            strong = true
        },
        {
            text = "Classes: " .. classCount .. "   Ranks: " .. rankCount,
            font = "ax.small"
        },
        {
            text = faction.isDefault and "This faction is generally open to normal players." or "This faction usually needs a whitelist or a staff transfer.",
            font = "ax.small"
        }
    }

    if ( isCurrent ) then
        lines[#lines + 1] = {
            text = "This is your current faction.",
            font = "ax.small",
            strong = true,
            color = ax.theme:GetGlass().text
        }
    end

    ax.help:AddCompactCard(parent, width, {
        title = faction.name or faction.id or "Unknown Faction",
        subtitle = faction.id or "",
        badge = accessText,
        accentColor = accentColor,
        badgeColor = accentColor,
        lines = lines
    })
end

local function PopulateFactions(this, panel)
    local client = ax.client
    local currentFaction = IsValid(client) and client:GetFaction() or nil

    ax.help:CreateSearchLayout(panel, "Search factions...", function(scroller, query, width)
        local factions = ax.util:GetSortedEntries(ax.faction:GetAll(), CompareFactions)
        local matches = {}

        for i = 1, #factions do
            local faction = factions[i].value

            if ( ax.util:SearchMatches(query, GetFactionSearchText(faction)) ) then
                matches[#matches + 1] = faction
            end
        end

        if ( query == "" ) then
            ax.help:AddCompactCard(scroller, width, {
                title = "Factions",
                accentColor = ax.theme:GetGlass().highlight,
                lines = {
                    {text = "Browse the character groups loaded by this schema.", font = "ax.small", strong = true},
                    {text = "Search by faction name, description, class, or rank.", font = "ax.small"}
                }
            })
        end

        if ( matches[1] == nil ) then
            ax.help:AddEmptyState(scroller, width, "No Matching Factions", "Try a different search or clear the filter.", ax.theme:GetGlass().highlight)
            return
        end

        for i = 1, #matches do
            AddFactionCard(scroller, width, matches[i], currentFaction)
        end
    end)
end

hook.Remove("PopulateHelpCategories", "ax.tab.help.factions")
hook.Add("PopulateHelpCategories", "ax.tab.help.factions", function(categories)
    categories["factions"] = {
        sort = 30,
        name = "Factions",
        Populate = PopulateFactions
    }
end)
