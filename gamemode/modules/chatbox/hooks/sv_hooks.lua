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

    print("Chat Preprocess: " .. text)

    local chatType, text = ax.chat:Parse(text)
    if ( chatType == "ic" ) then
        if ( ax.command:Parse(text) ) then
            print("Chat Preprocess: Command detected, suppressing chat message.")
            return ""
        end
    end

    return text
end
