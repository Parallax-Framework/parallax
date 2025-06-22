--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Chat library
-- @module ax.chat

ax.chat = ax.chat or {}
ax.chat.messages = ax.chat.messages or {}

chat.AddTextInternal = chat.AddTextInternal or chat.AddText

function chat.AddText(...)
    if ( !IsValid(ax.gui.Chatbox) ) then
        chat.AddTextInternal(...)
        return
    end

    local arguments = {...}
    local currentColor = ax.color:Get("text")
    local font = "ax.chat"
    local maxWidth = ax.gui.Chatbox:GetWide() - 20

    local markupStr = ""

    for i = 1, #arguments do
        local v = arguments[i]
        if ( ax.util:CoerceType(ax.types.color, v) ) then
            currentColor = v
        elseif ( IsValid(v) and v:IsPlayer() ) then
            local c = team.GetColor(v:Team())
            markupStr = markupStr .. string.format("<color=%d %d %d>%s</color>", c.r, c.g, c.b, v:Nick())
        else
            markupStr = markupStr .. string.format(
                "<color=%d %d %d>%s</color>",
                currentColor.r, currentColor.g, currentColor.b, tostring(v)
            )
        end
    end

    local rich = markup.Parse("<font=" .. font .. ">" .. markupStr .. "</font>", maxWidth)

    local panel = ax.gui.Chatbox.history:Add("EditablePanel")
    panel:SetTall(rich:GetHeight())
    panel:Dock(TOP)

    panel.alpha = 1
    panel.created = CurTime()

    function panel:SizeToContents()
        rich = markup.Parse("<font=" .. font .. ">" .. markupStr .. "</font>", maxWidth)
        self:SetTall(rich:GetHeight())
    end

    function panel:Paint(w, h)
        surface.SetAlphaMultiplier(self.alpha)
        rich:Draw(0, 0)
        surface.SetAlphaMultiplier(1)
    end

    function panel:Think()
        if ( ax.gui.Chatbox:GetAlpha() != 255 ) then
            local dt = CurTime() - self.created
            if ( dt >= 8 ) then
                self.alpha = math.max(0, 1 - (dt - 8) / 4)
            end
        else
            self.alpha = 1
        end
    end

    table.insert(ax.chat.messages, panel)

    timer.Simple(0.1, function()
        if ( !IsValid(panel) ) then return end

        local scrollBar = ax.gui.Chatbox.history:GetVBar()
        if ( scrollBar ) then
            scrollBar:AnimateTo(scrollBar.CanvasSize, 0.2, 0, 0.2)
        end
    end)
end