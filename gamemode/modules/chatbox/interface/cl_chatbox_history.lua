--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

function ax.chatbox.history:GetEntryLimit(panel)
    local value = tonumber(ax.config:Get("chatbox.history_size", ax.chatbox.util.constants.ENTRY_HISTORY_LIMIT_DEFAULT)) or ax.chatbox.util.constants.ENTRY_HISTORY_LIMIT_DEFAULT
    return math.max(8, math.floor(value))
end

function ax.chatbox.history:AddEntry(panel, text)
    if ( !isstring(text) or text == "" ) then
        return
    end

    panel.historyCache = panel.historyCache or {}
    panel.historyCache[#panel.historyCache + 1] = text

    local limit = self:GetEntryLimit(panel)
    while ( #panel.historyCache > limit ) do
        table.remove(panel.historyCache, 1)
    end
end

function ax.chatbox.history:GetEntry(panel, index)
    if ( !panel.historyCache or #panel.historyCache == 0 ) then
        return nil
    end

    local internalIndex = #panel.historyCache - index + 1
    if ( internalIndex < 1 or internalIndex > #panel.historyCache ) then
        return nil
    end

    return panel.historyCache[internalIndex]
end

function ax.chatbox.history:HandleCtrlBackspace(entry)
    local text = entry:GetText() or ""
    local caret = entry:GetCaretPos() or 0

    caret = math.Clamp(caret, 0, #text)
    if ( caret <= 0 ) then
        return true
    end

    local left = string.sub(text, 1, caret)
    local right = string.sub(text, caret + 1)

    left = string.gsub(left, "%s+$", "")
    left = string.gsub(left, "[^%s]+$", "")

    entry:SetText(left .. right)
    entry:SetCaretPos(#left)

    return true
end

function ax.chatbox.history:HandleNavigation(panel, entry, key)
    if ( !panel.historyCache or #panel.historyCache == 0 ) then
        return false
    end

    panel.historyIndex = panel.historyIndex or 0

    if ( key == KEY_UP ) then
        panel.historyIndex = math.min(#panel.historyCache, panel.historyIndex + 1)
    else
        panel.historyIndex = math.max(0, panel.historyIndex - 1)
    end

    if ( panel.historyIndex > 0 ) then
        local value = self:GetEntry(panel, panel.historyIndex) or ""
        entry:SetText(value)
        entry:SetCaretPos(#value)
    else
        entry:SetText("")
    end

    return true
end
