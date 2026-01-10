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
    if ( !isstring(text) ) then return "" end

    text = string.Trim(text)
    if ( text == "" ) then return "" end

    local chatType, text = ax.chat:Parse(text)
    if ( chatType == "ic" ) then
        local bHasPrefix = false
        for i = 1, #ax.command.prefixes do
            local prefix = ax.command.prefixes[i]
            if ( string.sub(text, 1, 1) == prefix ) then
                bHasPrefix = true
                break
            end
        end

        if ( bHasPrefix ) then
            local commandName, rawArgs = ax.command:Parse(text)
            if ( !isstring(commandName) or commandName == "" ) then
                client:Notify( ax.localization:GetPhrase("command.notvalid") )
                return ""
            end

            local command = ax.command.registry[commandName]
            if ( !istable(command) ) then
                client:Notify( ax.localization:GetPhrase("command.notfound") )
                return ""
            end

            local result, message = ax.command:Run(client, commandName, rawArgs)
            if ( result == false and isstring(message) and message != "" ) then
                client:Notify( message )
            end

            print("Chat Command: " .. commandName .. " Args: " .. rawArgs)
        end
    end

    print("Chat Processed: [" .. chatType .. "] " .. text)

    text = ax.chat:Send(client, chatType, text)

    hook.Run("PostPlayerSay", client, chatType, text)
    return ""
end
