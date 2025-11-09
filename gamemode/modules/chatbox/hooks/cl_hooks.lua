--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:InitPostEntity()
    -- Create a 1 minute timer, which overrides the chat.AddText function to use our chatbox
    -- Because something else might override it after we do, we repeat this multiple times to ensure ours sticks
    timer.Create("ax.chatbox.override.addtext", 1, 60, function()
        ax.chat:OverrideChatAddText()
    end)
end

function MODULE:GetChatboxSize()
    return ax.option:Get("chatbox.width"), ax.option:Get("chatbox.height")
end

function MODULE:GetChatboxPos()
    return ax.option:Get("chatbox.x"), ax.option:Get("chatbox.y")
end

function MODULE:PlayerBindPress(client, bind, pressed)
    bind = utf8.lower(bind)

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
        if ( !IsValid(client) or !client:Alive() ) then continue end

        local distToSqr = client:EyePos():DistToSqr(EyePos())
        if ( distToSqr > 256 ^ 2 ) then continue end

        local text = client:GetRelay("chatText", "")
        if ( text == "" ) then continue end

        local pos = client:EyePos() + Vector(0, 0, 8)
        local typing = "Typing"

        local head = client:LookupBone("ValveBiped.Bip01_Head1")
        if ( head ) then
            pos = client:GetBonePosition(head) + Vector(0, 0, 12)
        end

        if ( string.StartsWith(text, "/me") ) then
            typing = "Performing"
        elseif ( hook.Run("GetTypingIndicatorText", client, text) ) then
            typing = hook.Run("GetTypingIndicatorText", client, text) or "Typing"
        elseif ( string.StartsWith(text, "/") or string.StartsWith(text, ".") ) then
            continue
        end

        -- Add incremental dots to the typing text
        local numDots = math.floor((CurTime() * 2) % 4)
        typing = typing .. string.rep(".", numDots)

        cam.Start3D2D(pos, Angle(0, EyeAngles().y - 90, 90), 0.05)
            draw.SimpleTextOutlined(typing, "ax.huge.italic", 0, 0, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
        cam.End3D2D()
    end
end

function MODULE:GetTypingIndicatorText(client, text)
    if ( string.StartsWith(text, "/whisper") or string.StartsWith(text, "/w") ) then
        return "Whispering"
    elseif ( string.StartsWith(text, "/yell") or string.StartsWith(text, "/y") or string.StartsWith(text, "/shout") ) then
        return "Yelling"
    end
end
