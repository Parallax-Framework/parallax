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

chat.AddTextInternal = chat.AddTextInternal or chat.AddText

function chat.AddText(...)
    if ( !IsValid(ax.gui.chatbox) ) then
        chat.AddTextInternal(...)
        return
    end

    local arguments = {...}
    local currentColor = Color(255, 255, 255)
    local chatType = ax.chat.currentType
    local font = "ax.chatbox.text"

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

    if ( hook.Run("GetChatFont", chatType) ) then
        font = hook.Run("GetChatFont", chatType)
    end

    local maxWidth = ax.gui.chatbox:GetWide() - 20

    -- Add a timestamp if enabled
    if ( ax.option:Get("chat.timestamps", true) ) then
        local timeStr = os.date("%H:%M")
        arguments = { Color(150, 150, 150), "[" .. timeStr .. "] ", unpack(arguments) }
    end

    -- Build segments so we can reveal text with a typewriter effect safely (keeps tags intact)
    local segments = {}
    for i = 1, #arguments do
        local v = arguments[i]
        if ( ax.type:Sanitise(ax.type.color, v) ) then
            currentColor = v
        elseif ( IsValid(v) and v:IsPlayer() ) then
            local c = team.GetColor(v:Team())
            segments[#segments + 1] = { color = Color(c.r, c.g, c.b), text = v:Nick() }
        else
            segments[#segments + 1] = { color = Color(currentColor.r, currentColor.g, currentColor.b), text = tostring(v) }
        end
    end

    local function buildMarkup(revealedChars)
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

    local totalChars = 0
    for _, seg in ipairs(segments) do totalChars = totalChars + #(seg.text or "") end

    local rich = markup.Parse("<font=" .. font .. ">" .. buildMarkup(0) .. "</font>", maxWidth)

    local panel = ax.gui.chatbox.history:Add("EditablePanel")
    panel:SetTall(rich:GetHeight())
    panel:Dock(TOP)

    panel.alpha = 1
    panel.created = CurTime()
    panel.revealedChars = 0
    panel.totalChars = totalChars
    panel.revealSpeed = 100 -- characters per second, tweakable

    function panel:SizeToContents()
        rich = markup.Parse("<font=" .. font .. ">" .. buildMarkup(math.floor(self.revealedChars)) .. "</font>", maxWidth)
        self:SetTall(rich:GetHeight())
    end

    function panel:Paint(w, h)
        surface.SetAlphaMultiplier(self.alpha)

        if ( rich ) then
            rich:Draw(0, 0)
        end

        surface.SetAlphaMultiplier(1)
    end

    function panel:Think()
        -- Reveal characters over time until fully shown
        if ( self.revealedChars < self.totalChars ) then
            self.revealedChars = math.min(self.totalChars, self.revealedChars + FrameTime() * self.revealSpeed)
            rich = markup.Parse("<font=" .. font .. ">" .. buildMarkup(math.floor(self.revealedChars)) .. "</font>", maxWidth)
            self:SetTall(rich:GetHeight())
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

    ax.chat.messages[#ax.chat.messages + 1] = panel
    ax.chat.currentType = nil -- Reset the current chat type after adding the message

    ax.client:EmitSound("ui/hint.wav", 75, 100, 0.1, CHAN_AUTO)

    timer.Simple(0.1, function()
        if ( !IsValid(panel) ) then return end

        local scrollBar = ax.gui.chatbox.history:GetVBar()
        if ( scrollBar ) then
            scrollBar:AnimateTo(scrollBar.CanvasSize, 0.2, 0, 0.2)
        end
    end)
end
