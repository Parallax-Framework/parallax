--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.chatbox = ax.chatbox or {}
ax.chatbox.bottom = ax.chatbox.bottom or {}
ax.chatbox.history = ax.chatbox.history or {}

function ax.chatbox.bottom:GetMessageLengthLimit()
    local value = tonumber(ax.config:Get("chatbox.max_message_length", ax.chatbox.util.constants.MESSAGE_LENGTH_LIMIT_DEFAULT)) or ax.chatbox.util.constants.MESSAGE_LENGTH_LIMIT_DEFAULT
    return math.max(16, math.floor(value))
end

function ax.chatbox.bottom:Build(panel)
    local padding = ScreenScale(ax.chatbox.util.constants.SCREEN_PADDING_SCALE)

    panel.bottom = panel:Add("DPanel")
    panel.bottom:Dock(BOTTOM)
    panel.bottom:DockMargin(padding, padding, padding, padding)
    panel.bottom.Paint = function(_, width, height)
        local glass = ax.theme:GetGlass()
        local metrics = ax.theme:GetMetrics()

        ax.theme:DrawGlassPanel(0, 0, width, height, {
            radius = math.max(4, metrics.roundness * 0.6),
            blur = 0.9,
            flags = ax.render.SHAPE_IOS,
            fill = glass.input,
            border = glass.inputBorder
        })
    end

    panel.entry = panel.bottom:Add("ax.text.entry")
    panel.entry:Dock(FILL)
    panel.entry:SetFont("ax.small")
    panel.entry:SetTall(draw.GetFontHeight("ax.small") + 8)
    panel.entry:SetPlaceholderText(ax.chatbox.util:GetPhrase("chatbox.entry.placeholder", "Say something..."))
    panel.entry:SetDrawLanguageID(false)
    panel.entry:SetTabbingDisabled(true)
    panel.entry.Paint = function(this, width, height)
        this:PaintInternal(width, height)
    end

    panel.bottom:SetTall(ScreenScale(8))
end

function ax.chatbox.bottom:BindCallbacks(panel)
    panel.entry.OnEnter = function(this)
        local text = this:GetValue() or ""
        if ( text != "" ) then
            text = string.gsub(text, "<font.->", "")
            text = string.gsub(text, "</font>", "")

            local limit = self:GetMessageLengthLimit()
            if ( #text > limit ) then
                text = string.sub(text, 1, limit)
            end

            ax.net:Start("chat.message", text)

            local historyModule = ax.chatbox.history
            if ( historyModule and historyModule.AddEntry ) then
                historyModule:AddEntry(panel, text)
            end
            panel.historyIndex = 0

            this:SetText("")
            this:SetCaretPos(0)
        end

        panel:SetVisible(false)
    end

    panel.entry.OnChange = function(this)
        if ( panel.entryLockCount and panel.entryLockCount > 0 ) then
            return
        end

        local recommendation = ax.chatbox.recommendations
        if ( recommendation and recommendation.QueueUpdate ) then
            recommendation:QueueUpdate(panel, this:GetValue() or "")
        end
    end

    panel.entry.OnKeyCode = function(this, key)
        if ( key == KEY_TAB ) then
            panel:CycleRecommendations()
            return true
        end

        if ( key == KEY_BACKSPACE and (input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)) ) then
            local historyModule = ax.chatbox.history
            if ( historyModule and historyModule.HandleCtrlBackspace ) then
                return historyModule:HandleCtrlBackspace(this)
            end

            return false
        end

        if ( key == KEY_UP or key == KEY_DOWN ) then
            local historyModule = ax.chatbox.history
            if ( historyModule and historyModule.HandleNavigation ) then
                return historyModule:HandleNavigation(panel, this, key)
            end

            return false
        end
    end
end
