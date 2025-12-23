--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

util.AddNetworkString("ax.chat.send")
net.Receive("ax.chat.send", function(len, client)
    if ( !client:RateLimit("chat.send", 0.01) ) then return end

    -- Read and sanitize the chat message incase bad actors try to exploit this.
    local output = net.ReadString()
    output = string.gsub(output, "[^%w%s%p]", "")
    output = string.Trim(output)
    output = string.gsub(output, "<.->", "")

    hook.Run("PlayerSay", client, output, false)

    client:SetRelay("chatText", "")
    client:SetRelay("chatType", "")
end)

util.AddNetworkString("ax.chat.text.changed")
net.Receive("ax.chat.text.changed", function(len, client)
    if ( !client:RateLimit("chat.text.changed", 0.01) ) then return end

    local text = net.ReadString()
    local chatType = net.ReadString()

    text = string.gsub(text, "[^%w%s%p]", "")
    text = string.Trim(text)
    text = string.gsub(text, "<.->", "")

    client:SetRelay("chatText", text)
    client:SetRelay("chatType", chatType)

    hook.Run("ChatboxOnTextChanged", text, chatType)
end)
