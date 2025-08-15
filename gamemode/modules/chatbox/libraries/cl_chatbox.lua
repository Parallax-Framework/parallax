local MODULE = MODULE

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
    local font = hook.Run("GetChatFont", chatType) or "ax.chatbox.text"
    local maxWidth = ax.gui.chatbox:GetWide() - 20

    local markupStr = ""

    for i = 1, #arguments do
        local v = arguments[i]
        if ( ax.type:Sanitise(ax.type.color, v) ) then
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

    local panel = ax.gui.chatbox.history:Add("EditablePanel")
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