--- Chat library
-- @module ax.chat

ax.chat = ax.chat or {}
ax.chat.classes = ax.chat.classes or {}

function ax.chat:Register(uniqueID, chatData)
    if ( !isstring(uniqueID) ) then
        ax.util:PrintError("Attempted to register a chat class without a unique ID!")
        return false
    end

    if ( !istable(chatData) ) then
        ax.util:PrintError("Attempted to register a chat class without data!")
        return false
    end

    if ( !isfunction(chatData.OnChatAdd) ) then
        chatData.OnChatAdd = function(info, speaker, text)
            chat.AddText(ax.color:Get("text"), speaker:Name() .. " says \"" .. text .. "\"")
            chat.PlaySound()
        end
    end

    if ( chatData.Prefixes and #chatData.Prefixes > 0 ) then
        ax.command:Register(uniqueID, {
            Description = chatData.Description or "",
            Prefixes = chatData.Prefixes,
            OnTextChanged = chatData.OnTextChanged,
            OnChatTypeChanged = chatData.OnChatTypeChanged,
            Callback = function(info, client, arguments)
                local text = table.concat(arguments, " ")
                if ( !isstring(text) or #text < 1 ) then
                    client:Notify("You must provide a message to send!")
                    return false
                end

                self:SendSpeaker(client, uniqueID, text)
            end
        })
    end

    self.classes[uniqueID] = chatData
end

function ax.chat:Get(uniqueID)
    return self.classes[uniqueID]
end