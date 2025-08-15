util.AddNetworkString("ax.chatbox.send")
net.Receive("ax.chatbox.send", function(len, client)
    if ( CurTime() - (client.axLastChat or 0) < 0.1 ) then return end
    client.axLastChat = CurTime()

    local text = net.ReadString()
    client:Say(text, false)
end)