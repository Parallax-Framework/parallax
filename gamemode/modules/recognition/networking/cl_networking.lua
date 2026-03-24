--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Client-side net receivers for the recognition module.
-- @module ax.recognition (net, client)

--- Server notifies the local client that someone just introduced themselves.
-- Only the alias is sent — the introducer's real identity is intentionally withheld.
ax.net:Hook("recognition.introduced_notify", function(alias)
    if ( !isstring(alias) ) then return end

    ax.notification:Add(ax.localization:GetPhrase("recognition.notify.introduced", alias))
end)

--- Server confirms a forget request was applied. Remove the entry from the local
-- in-memory familiarity table and refresh the journal without a round-trip.
ax.net:Hook("recognition.forget_confirm", function(strKey)
    if ( !isstring(strKey) ) then return end

    local char = ax.client:GetCharacter()
    if ( !char ) then return end

    local familiarity = ax.character:GetVar(char, "familiarity")
    if ( !istable(familiarity) ) then return end

    familiarity[strKey] = nil
    familiarity[tonumber(strKey)] = nil

    if ( IsValid(ax.gui.journal) ) then
        ax.gui.journal:Refresh()
    end
end)
