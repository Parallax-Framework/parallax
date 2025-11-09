--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.chat = ax.chat or {}
ax.chat.messages = ax.chat.messages or {}

function ax.chat:BuildMarkup(revealedChars, segments)
    -- Builds a markup-safe string from segments, revealing up to revealedChars characters
    local out = ""
    local remaining = revealedChars or 0
    for _, seg in ipairs(segments) do
        local t = seg.text or ""
        local len = #t
        if ( remaining >= len ) then
            out = out .. string.format("<color=%d %d %d>%s</color>", seg.color.r, seg.color.g, seg.color.b, t)
            remaining = remaining - len
        elseif ( remaining > 0 ) then
            out = out .. string.format("<color=%d %d %d>%s</color>", seg.color.r, seg.color.g, seg.color.b, string.sub(t, 1, remaining))
            break
        else
            break
        end
    end

    return out
end

function ax.chat:BuildSegments(arguments, defaultColor)
    -- Converts chat AddText arguments into segments suitable for BuildMarkup
    local segments = {}
    local currentColor = defaultColor or Color(255, 255, 255)

    for i = 1, #arguments do
        local v = arguments[i]
        if ( ax.type:Sanitise(ax.type.color, v) ) then
            currentColor = v
        elseif ( IsValid(v) and isfunction(v.IsPlayer) and v:IsPlayer() ) then
            local c = team.GetColor(v:Team())
            segments[#segments + 1] = { color = Color(c.r, c.g, c.b), text = v:Nick() }
        else
            segments[#segments + 1] = { color = Color(currentColor.r, currentColor.g, currentColor.b), text = tostring(v) }
        end
    end

    local totalChars = 0
    for _, seg in ipairs(segments) do totalChars = totalChars + #(seg.text or "") end

    return segments, totalChars, currentColor
end

function ax.chat:CreateMessagePanel(segments, totalChars, font, maxWidth, revealSpeed)
    -- Create and return a configured message panel for the chat history.
    local rich = markup.Parse("<font=" .. font .. ">" .. ax.chat:BuildMarkup(0, segments) .. "</font>", maxWidth)

    local panel = ax.gui.chatbox.history:Add("EditablePanel")
    if ( rich ) then
        panel:SetTall(rich:GetHeight())
    else
        panel:SetTall(16)
    end
    panel:Dock(TOP)

    panel.alpha = 1
    panel.created = CurTime()
    panel.revealedChars = 0
    panel.totalChars = totalChars or 0
    panel.revealSpeed = revealSpeed or 100 -- characters per second, tweakable

    function panel:SizeToContents()
        local shown = math.floor(self.revealedChars)
        rich = markup.Parse("<font=" .. font .. ">" .. ax.chat:BuildMarkup(shown, segments) .. "</font>", maxWidth)
        if ( rich ) then
            self:SetTall(rich:GetHeight())
        end
    end

    function panel:Paint(w, h)
        surface.SetAlphaMultiplier(self.alpha)

        if ( rich ) then
            rich:Draw(0, 0)
        end

        surface.SetAlphaMultiplier(1)
    end

    function panel:Think()
        if ( self.revealedChars < self.totalChars ) then
            self.revealedChars = math.min(self.totalChars, self.revealedChars + FrameTime() * self.revealSpeed)
            rich = markup.Parse("<font=" .. font .. ">" .. ax.chat:BuildMarkup(math.floor(self.revealedChars), segments) .. "</font>", maxWidth)
            if ( rich ) then
                self:SetTall(rich:GetHeight())
            end
        end

        if ( ax.gui.chatbox:GetAlpha() != 255 ) then
            local dt = CurTime() - self.created
            if ( dt >= 8 ) then
                self.alpha = math.max(0, 1 - (dt - 8) / 4)
            end
        else
            self.alpha = 1
        end
    end

    return panel, rich
end

function ax.chat:PlayReceiveSound()
    if ( ax.client and ax.client.EmitSound ) then
        ax.client:EmitSound("ui/hint.wav", 75, 100, 0.1, CHAN_AUTO)
    else
        pcall(function() surface.PlaySound("ui/hint.wav") end)
    end
end

function ax.chat:ScrollHistoryToBottom(panel)
    timer.Simple(0.1, function()
        if ( !IsValid(panel) ) then return end

        local history = ax.gui.chatbox and ax.gui.chatbox.history
        if ( !history ) then return end

        local scrollBar = history:GetVBar()
        if ( scrollBar ) then
            scrollBar:AnimateTo(scrollBar.CanvasSize, 0.2, 0, 0.2)
        end
    end)
end

function ax.chat:OverrideChatAddText()
    chat.AddTextInternal = chat.AddTextInternal or chat.AddText

    function chat.AddText(...)
        local arguments = { ... }

        -- Check if chatbox exists, if not create it first
        if ( !IsValid(ax.gui.chatbox) ) then
            ax.gui.chatbox = vgui.Create("ax.chatbox")

            -- Queue the message to be added after the chatbox is ready
            timer.Simple(0.1, function()
                chat.AddText(unpack(arguments))
            end)

            return
        end

        local currentColor = Color(255, 255, 255)
        local chatType = ax.chat.currentType or "ic"
        local font = "ax.regular"

        -- Search the arguments for a custom font input using <font=FontName>message</font>
        for i = 1, #arguments do
            local v = arguments[i]
            if ( isstring(v) ) then
                local fontTag = string.match(v, "<font=([^>]+)>")
                if ( fontTag ) then
                    font = fontTag
                    arguments[i] = string.gsub(v, "<font=[^>]+>", "")
                    arguments[i] = string.gsub(arguments[i], "</font>", "")
                    break
                end
            end
        end

        local overrideFont = hook.Run("GetChatFont", chatType)
        if ( overrideFont ) then
            font = overrideFont
        end

        local maxWidth = ax.gui.chatbox:GetWide() - 20

        -- Add a timestamp if enabled
        if ( ax.option:Get("chat.timestamps", true) ) then
            local timeStr = os.date("%H:%M")
            arguments = { Color(150, 150, 150), "[" .. timeStr .. "] ", unpack(arguments) }
        end

        local segments, totalChars = ax.chat:BuildSegments(arguments, currentColor)

        local panel = ax.chat:CreateMessagePanel(segments, totalChars, font, maxWidth, 100)

        ax.chat.messages[#ax.chat.messages + 1] = panel
        ax.chat.currentType = nil -- Reset the current chat type after adding the message

        ax.chat:PlayReceiveSound()
        ax.chat:ScrollHistoryToBottom(panel)
    end
end

-- Apply the override initially
ax.chat:OverrideChatAddText()
