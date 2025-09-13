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

function MODULE:ChatboxOnTextChanged(text, chatType)
    net.Start("ax.chatbox.text.changed")
        net.WriteString(text)
        net.WriteString(chatType)
    net.SendToServer()
end

function MODULE:PostDrawTranslucentRenderables()
    -- Draw a text above the player who is typing to indicate that they are typing.
    for _, client in player.Iterator() do
        local text = client:GetNWString("axChatText", "")
        if ( text == "" ) then continue end

        if ( string.StartsWith(text, "/") or string.StartsWith(text, ".") ) then continue end

        local pos = client:EyePos() + Vector(0, 0, 8)
        local typing = "Typing..."

        cam.Start3D2D(pos, Angle(0, EyeAngles().y - 90, 90), 0.05)
            draw.SimpleTextOutlined(typing, "ax.huge.italic", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
        cam.End3D2D()
    end
end