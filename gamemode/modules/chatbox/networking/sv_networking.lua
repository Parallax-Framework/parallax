util.AddNetworkString("ax.chatbox.send")
net.Receive("ax.chatbox.send", function(len, client)
    if ( CurTime() - (client.axLastChat or 0) < 0.1 ) then return end
    client.axLastChat = CurTime()

    local text = net.ReadString()
    client:Say(text, false)

    client:SetNWString("axChatText", "")
    client:SetNWString("axChatType", "")
end)

util.AddNetworkString("ax.chatbox.text.changed")
net.Receive("ax.chatbox.text.changed", function(len, client)
    local clientTable = client:GetTable()
    if ( CurTime() - (clientTable.axLastChatChange or 0) < 0.01 ) then return end
    clientTable.axLastChatChange = CurTime()

    local text = net.ReadString()
    local chatType = net.ReadString()

    client:SetNWString("axChatText", text)
    client:SetNWString("axChatType", chatType)

    hook.Run("ChatboxOnTextChanged", text, chatType)
end)
