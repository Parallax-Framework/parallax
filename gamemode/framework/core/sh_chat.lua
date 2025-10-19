--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.chat:Add("ic", {
    displayName = "IC",
    description = "Speak in-character",
    noCommand = true,
    OnRun = function(this, client, message)
        local icColor = ax.config:Get("chatColorIC", Color(230, 230, 110, 255))
        return icColor, client:Nick() .. " says, \"" .. ax.chat:Format(message) .. "\""
    end,
    CanHear = function(this, speaker, listener)
        local distance = ax.config:Get("chatICDistance", 400)
        return speaker:GetPos():Distance(listener:GetPos()) <= distance
    end
})

ax.chat:Add("yell", {
    displayName = "Yell",
    description = "Yell at someone",
    OnRun = function(this, client, message)
        local yellColor = ax.config:Get("chatColorYell", Color(255, 175, 0))
        return yellColor, string.format("<font=ax.chatbox.text.bold>%s</font>", client:Nick() .. " yells, \"" .. ax.chat:Format(string.upper(message)) .. "\"")
    end,
    CanHear = function(this, speaker, listener)
        local distance = ax.config:Get("chatYellDistance", 700)
        return speaker:GetPos():Distance(listener:GetPos()) <= distance
    end
})

ax.chat:Add("looc", {
    displayName = "Local Out of Character",
    description = "Speak local out of character",
    OnRun = function(this, client, message)
        local oocColor = ax.config:Get("chatColorOOC", Color(110, 10, 10))
        return oocColor, "(LOOC) ", color_white, client:SteamName() .. ": " .. message
    end,
    CanHear = function(this, speaker, listener)
        local distance = ax.config:Get("chatOOCDistance", 600)
        return listener:GetCharacter() == nil or speaker:GetPos():Distance(listener:GetPos()) <= distance
    end
})

ax.chat:Add("ooc", {
    displayName = "Out of Character",
    description = "Speak out of character",
    OnRun = function(this, client, message)
        local oocColor = ax.config:Get("chatColorOOC", Color(110, 10, 10))
        return oocColor, "(OOC) ", color_white, client:SteamName() .. ": " .. message
    end,
    CanHear = function(this, speaker, listener)
        return true
    end
})

ax.chat:Add("me", {
    description = "Perform an action in third person",
    OnRun = function(this, client, message)
        local txt = ax.chat:Format(message)
        if ( #txt > 0 ) then
            txt = txt:sub(1,1):lower() .. txt:sub(2)
        end

        return "* " .. client:Nick() .. " " .. txt
    end,
    CanHear = function(this, speaker, listener)
        local distance = ax.config:Get("chatMeDistance", 600)
        return speaker:GetPos():Distance(listener:GetPos()) <= distance
    end
})
