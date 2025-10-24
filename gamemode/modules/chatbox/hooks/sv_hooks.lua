--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:PlayerSay(client, text, teamChat)
    if ( text == "" ) then return "" end

    -- Special occasion for OOC and LOOC chat
    if ( string.StartsWith(text, "//") ) then
        text = string.sub(text, 3)

        ax.chat:Send(client, "ooc", string.Trim(text))
        return ""
    elseif ( string.StartsWith(text, ".//") ) then
        text = string.sub(text, 4)

        ax.chat:Send(client, "looc", string.Trim(text))
        return ""
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

        return ""
    end

    text = hook.Run("PlayerMessageSend", client, "ic", text) or text

    -- Format regular chat messages
    if ( hook.Run("ShouldFormatMessage", client, text) != false ) then
        text = ax.chat:Format(text)
    end

    ax.chat:Send(client, "ic", text)

    return ""
end
