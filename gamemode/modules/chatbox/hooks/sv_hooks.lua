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

    local rawText = string.Trim(text)
    if ( rawText == "" ) then return "" end

    -- Special occasion for OOC and LOOC chat
    if ( string.StartsWith(rawText, "//") ) then
        local msg = string.Trim(string.sub(rawText, 3))

        ax.chat:Send(client, "ooc", msg)
        return ""
    elseif ( string.StartsWith(rawText, ".//") ) then
        local msg = string.Trim(string.sub(rawText, 4))

        ax.chat:Send(client, "looc", msg)
        return ""
    end

    -- Check if this is a command
    local isCommand = false
    for k, v in ipairs(ax.command.prefixes) do
        if ( string.StartsWith(rawText, v) ) then
            isCommand = true
            break
        end
    end

    if ( isCommand ) then
        local name, rawArgs = ax.command:Parse(rawText)
        local commandFound = tobool(ax.command.registry[name])
        if ( !commandFound ) then
            local registryKeys = table.GetKeys(ax.command.registry)
            for _, commandName in ipairs(registryKeys) do
                if ( string.lower(commandName) == string.lower(name) ) then
                    name = commandName
                    commandFound = true
                    break
                end
            end
        end

        if ( name and name != "" and commandFound ) then
            -- Run the command inside pcall to avoid a server-side error killing the hook
            local ok, runOk, result = pcall(function()
                return ax.command:Run(client, name, rawArgs)
            end)

            if ( !ok ) then
                client:Notify("Command execution failed.", "error")
            else
                -- runOk/result come from ax.command:Run
                if ( !runOk ) then
                    client:Notify(result or "Unknown error", "error")
                elseif ( result and result != "" ) then
                    client:Notify(tostring(result))
                end
            end
        else
            client:Notify(tostring(name) .. " is not a valid command.", "warning")
        end

        return ""
    end

    local processed = hook.Run("PlayerMessageSend", client, "ic", rawText) or rawText

    -- Formatting is handled by each chat type's OnRun/OnFormatForListener.
    -- Keep the hook for opt-out, but do not pre-format here to avoid double-formatting.
    hook.Run("ShouldFormatMessage", client, processed)

    ax.chat:Send(client, "ic", processed)

    hook.Run("PlayerMessageSent", client, "ic", processed)

    return ""
end
