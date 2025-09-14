util.AddNetworkString("ax.chatbox.send")
net.Receive("ax.chatbox.send", function(len, client)
    if ( !client:RateLimit("chatbox.send", 0.1) ) then return end

    hook.Run("PlayerSay", client, net.ReadString(), false)

    client:SetNWString("axChatText", "")
    client:SetNWString("axChatType", "")
end)

util.AddNetworkString("ax.chatbox.text.changed")
net.Receive("ax.chatbox.text.changed", function(len, client)
    if ( !client:RateLimit("chatbox.text.changed", 0.01) ) then return end

    local text = net.ReadString()
    local chatType = net.ReadString()

    client:SetNWString("axChatText", text)
    client:SetNWString("axChatType", chatType)

    hook.Run("ChatboxOnTextChanged", text, chatType)
end)
