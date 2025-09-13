util.AddNetworkString("ax.chatbox.send")
net.Receive("ax.chatbox.send", function(len, client)
    if ( !client:RateLimit("chatbox.send", 0.1) ) then return end

    local text = net.ReadString()
    if ( text == "" ) then return end

    -- Special occasion for OOC and LOOC chat
    if ( string.StartsWith(text, "//") ) then
        text = string.sub(text, 3)

        ax.chat:Send(client, "ooc", string.Trim(text))
        return
    elseif ( string.StartsWith(text, ".//") ) then
        text = string.sub(text, 4)

        ax.chat:Send(client, "looc", string.Trim(text))
        return
    end

    -- Check if this is a command
    local isCommand = false
    for k, v in ipairs(ax.command.prefixes) do
        if ( string.StartsWith(text, v) ) then
            isCommand = true
            break
        end
    end

    if ( isCommand ) then
        local name, rawArgs = ax.command:Parse(text)
        if ( name and name != "" and ax.command.registry[name] ) then
            local ok, result = ax.command:Run(client, name, rawArgs)

            if ( !ok ) then
                client:Notify(result or "Unknown error", "error")
            elseif ( result and result != "" ) then
                client:Notify(tostring(result))
            end
        else
            client:Notify(tostring(name) .. " is not a valid command.", "warning")
        end

        return
    end

    -- Format regular chat messages
    if ( hook.Run("ShouldFormatMessage", client, text) != false ) then
        text = ax.chat:Format(text)
    end

    ax.chat:Send(client, "ic", text)

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
