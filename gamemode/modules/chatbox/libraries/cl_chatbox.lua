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

--- Count visible characters (excluding markup tags)
local function CountVisibleChars(text)
    return #string.gsub(text, "<[^>]+>", "")
end

--- Reveal text up to character limit while preserving markup
local function RevealText(text, maxChars)
    if ( maxChars <= 0 ) then return "" end

    local result, visible, inTag = "", 0, false

    for i = 1, #text do
        local char = string.sub(text, i, i)

        if ( char == "<" ) then
            inTag = true
        elseif ( char == ">" ) then
            inTag = false
        elseif ( !inTag ) then
            if ( visible >= maxChars ) then break end
            visible = visible + 1
        end

        result = result .. char
    end

    return result
end

--- Inject color tags around text while preserving font tags
function ax.chat:InjectColorTags(text, color)
    local result, pos = "", 1
    local colorTag = string.format("<color=%d,%d,%d>%%s</color>", color.r, color.g, color.b)

    while pos <= #text do
        local tagStart = string.find(text, "<", pos, true)

        if ( !tagStart ) then
            return result .. string.format(colorTag, string.sub(text, pos))
        end

        if ( tagStart > pos ) then
            result = result .. string.format(colorTag, string.sub(text, pos, tagStart - 1))
        end

        local tagEnd = string.find(text, ">", tagStart, true)
        result = result .. string.sub(text, tagStart, tagEnd or #text)
        pos = (tagEnd or #text) + 1
    end

    return result
end

--- Create message panel with animated text reveal
function ax.chat:CreateMessagePanel(markupText, maxWidth, revealSpeed)
    if ( !IsValid(ax.gui.chatbox) ) then
        ax.gui.chatbox = vgui.Create("ax.chatbox")
    end

    local panel = ax.gui.chatbox.history:Add("EditablePanel")
    panel:Dock(TOP)

    panel.markupText = markupText
    panel.maxWidth = maxWidth
    panel.lastWidth = maxWidth
    panel.totalChars = CountVisibleChars(markupText)
    panel.revealedChars = 0
    panel.revealSpeed = revealSpeed or 100
    panel.created = CurTime()
    panel.alpha = 1

    panel.markup = markup.Parse(RevealText(markupText, 0), maxWidth)
    panel:SetTall(panel.markup and panel.markup:GetHeight() or 16)

    function panel:Paint(w, h)
        surface.SetAlphaMultiplier(self.alpha)
        if ( self.markup ) then self.markup:Draw(0, 0) end
        surface.SetAlphaMultiplier(1)
    end

    function panel:Think()
        -- Check if chatbox width has changed and reparse markup
        if ( IsValid(ax.gui.chatbox) ) then
            local newWidth = ax.gui.chatbox:GetWide() - 20
            if ( newWidth != self.lastWidth ) then
                self.lastWidth = newWidth
                self.maxWidth = newWidth
                self.markup = markup.Parse(RevealText(self.markupText, math.floor(self.revealedChars)), self.maxWidth)
                if ( self.markup ) then self:SetTall(self.markup:GetHeight()) end
            end
        end

        if ( self.revealedChars < self.totalChars ) then
            self.revealedChars = math.min(self.totalChars, self.revealedChars + FrameTime() * self.revealSpeed)
            self.markup = markup.Parse(RevealText(self.markupText, math.floor(self.revealedChars)), self.maxWidth)
            if ( self.markup ) then self:SetTall(self.markup:GetHeight()) end
        end

        if ( ax.gui.chatbox:GetAlpha() != 255 ) then
            local dt = CurTime() - self.created
            self.alpha = dt >= 8 and math.max(0, 1 - (dt - 8) / 4) or 1
        else
            self.alpha = 1
        end
    end

    print("Chat Message Panel Created: " .. markupText)

    return panel
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
        if ( !IsValid(ax.gui.chatbox) ) then
            ax.gui.chatbox = vgui.Create("ax.chatbox")
            timer.Simple(0.1, function() chat.AddText(unpack(arguments)) end)
            return
        end

        local color = Color(255, 255, 255)
        local text = ""

        -- Add timestamp
        if ( ax.option:Get("chat.timestamps", true) ) then
            local ts = Color(150, 150, 150)
            text = string.format("<font=ax.small.shadow><color=%d,%d,%d>[%s] </color></font>", ts.r, ts.g, ts.b, os.date("%H:%M"))
        end

        print("chat.AddText called with arguments:", unpack(arguments))

        -- Build markup from arguments
        for _, v in ipairs(arguments) do
            if ( ax.type:Sanitise(ax.type.color, v) ) then
                color = v
            elseif ( IsValid(v) and v:IsPlayer() ) then
                local tc = team.GetColor(v:Team())
                text = text .. string.format("<color=%d,%d,%d>%s</color>", tc.r, tc.g, tc.b, v:Nick())
            elseif ( isstring(v) ) then
                if ( string.find(v, "<font=") ) then
                    text = text .. ax.chat:InjectColorTags(v, color)
                else
                    text = text .. string.format("<color=%d,%d,%d>%s</color>", color.r, color.g, color.b, v)
                end
            else
                text = text .. string.format("<color=%d,%d,%d>%s</color>", color.r, color.g, color.b, tostring(v))
            end
        end

        -- Ensure there is a fallback font wrapper so markup.Parse always has a font.
        -- If the text is not already wrapped in a top-level <font=...>...</font>,
        -- wrap the entire markup in the default chat font. This covers the case
        -- where we add a timestamp (<font=...>...</font>) but the rest of the
        -- message isn't wrapped, which would prevent markup.Parse from having
        -- a stable top-level font context.
        local defaultFont = hook.Run("GetChatFont", ax.chat.currentType or "ic") or "ax.small.shadow"
        local function IsFullyWrappedByFont(str)
            if ( !isstring(str) ) then return false end
            -- allow optional leading/trailing whitespace
            return string.match(str, "^%s*<font=[^>]+>.-</font>%s*$") != nil
        end

        if ( !IsFullyWrappedByFont(text) ) then
            text = "<font=" .. defaultFont .. ">" .. text .. "</font>"
        end

        local panel = ax.chat:CreateMessagePanel(text, ax.gui.chatbox:GetWide() - 20, 100)
        ax.chat.messages[#ax.chat.messages + 1] = panel
        ax.chat.currentType = nil

        ax.chat:PlayReceiveSound()
        ax.chat:ScrollHistoryToBottom(panel)

        print("Chat Message Added: " .. text)
    end
end

-- Apply the override initially
ax.chat:OverrideChatAddText()
