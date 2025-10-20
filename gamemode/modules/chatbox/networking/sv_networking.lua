--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

util.AddNetworkString("ax.chatbox.send")
net.Receive("ax.chatbox.send", function(len, client)
    if ( !client:RateLimit("chatbox.send", 0.1) ) then return end

    hook.Run("PlayerSay", client, net.ReadString(), false)

    client:SetRelay("chatText", "")
    client:SetRelay("chatType", "")
end)

util.AddNetworkString("ax.chatbox.text.changed")
net.Receive("ax.chatbox.text.changed", function(len, client)
    if ( !client:RateLimit("chatbox.text.changed", 0.01) ) then return end

    local text = net.ReadString()
    local chatType = net.ReadString()

    client:SetRelay("chatText", text)
    client:SetRelay("chatType", chatType)

    hook.Run("ChatboxOnTextChanged", text, chatType)
end)
