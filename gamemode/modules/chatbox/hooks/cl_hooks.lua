local MODULE = MODULE

function MODULE:GetChatboxSize()
    local width = ScrW() * 0.3
    local height = ScrH() * 0.3

    return width, height
end

function MODULE:GetChatboxPos()
    local _, height = self:GetChatboxSize()
    local x = ScrW() * 0.0125
    local y = ScrH() * 0.025
    y = ScrH() - height - y

    return x, y
end

function MODULE:PlayerBindPress(client, bind, pressed)
    bind = bind:lower()

    if ( ax.util:FindString(bind, "messagemode") and pressed ) then
        if ( !IsValid(ax.gui.chatbox) ) then
            ax.gui.chatbox = vgui.Create("ax.chatbox")
        end

        ax.gui.chatbox:SetVisible(true)
        return true
    end
end

function MODULE:StartChat()
end

function MODULE:FinishChat()
end