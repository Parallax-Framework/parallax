--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.chat:Register("ic", {
    CanHear = function(self, speaker, listener)
        local radius = ax.config:Get("chat.radius.ic", 384)
        return speaker:GetPos():DistToSqr(listener:GetPos()) < radius ^ 2
    end,
    OnChatAdd = function(self, speaker, text)
        chat.AddText(ax.color:Get("chat"), speaker:Name() .. " says \"" .. ax.chat:Format(text) .. "\"")
        chat.PlaySound()
    end
})

ax.chat:Register("whisper", {
    Font = "ax.chat.italic",
    Prefixes = {"W", "Whisper"},
    CanHear = function(self, speaker, listener)
        local radius = ax.config:Get("chat.radius.whisper", 96)
        return speaker:GetPos():DistToSqr(listener:GetPos()) < radius ^ 2
    end,
    OnChatAdd = function(self, speaker, text)
        chat.AddText(ax.color:Get("chat.whisper"), speaker:Name() .. " whispers \"" .. ax.chat:Format(text) .. "\"")
        chat.PlaySound()
    end
})

ax.chat:Register("yell", {
    Font = "ax.chat.bold",
    Prefixes = {"Y", "Yell"},
    CanHear = function(self, speaker, listener)
        local radius = ax.config:Get("chat.radius.yell", 1024)
        return speaker:GetPos():DistToSqr(listener:GetPos()) < radius ^ 2
    end,
    OnChatAdd = function(self, speaker, text)
        chat.AddText(ax.color:Get("chat.yell"), speaker:Name() .. " yells \"" .. ax.chat:Format(text) .. "\"")
        chat.PlaySound()
    end
})

ax.chat:Register("me", {
    Prefixes = {"Me", "Action"},
    CanHear = function(self, speaker, listener)
        local radius = ax.config:Get("chat.radius.me", 512)
        return speaker:GetPos():DistToSqr(listener:GetPos()) < radius ^ 2
    end,
    OnChatAdd = function(self, speaker, text)
        local formattedText = ax.chat:Format(text)
        formattedText = string.lower(string.sub(formattedText, 1, 1)) .. string.sub(formattedText, 2)
        chat.AddText(ax.color:Get("chat.action"), speaker:Name() .. " " .. formattedText)
        chat.PlaySound()
    end
})

ax.chat:Register("it", {
    Prefixes = {"It"},
    CanHear = function(self, speaker, listener)
        local radius = ax.config:Get("chat.radius.it", 512)
        return speaker:GetPos():DistToSqr(listener:GetPos()) < radius ^ 2
    end,
    OnChatAdd = function(self, speaker, text)
        chat.AddText(ax.color:Get("chat.action"), ax.chat:Format(text))
        chat.PlaySound()
    end
})

ax.chat:Register("ooc", {
    Prefixes = {"/", "OOC"},
    CanHear = function(self, speaker, listener)
        return ax.config:Get("chat.ooc")
    end,
    OnChatAdd = function(self, speaker, text)
        local tagColor = ax.color:Get("chat.ooc")
        local textColor = ax.color:Get("text")
        local nameColor = hook.Run("GetNameColor", speaker) or textColor
        chat.AddText(tagColor, "[OOC] ", nameColor, speaker:SteamName(), textColor, ": " .. ax.chat:Format(text))
    end
})

ax.chat:Register("looc", {
    Prefixes = {"LOOC"},
    CanHear = function(self, speaker, listener)
        local radius = ax.config:Get("chat.radius.looc", 512)
        return speaker:GetPos():DistToSqr(listener:GetPos()) < radius ^ 2
    end,
    OnChatAdd = function(self, speaker, text)
        local tagColor = ax.color:Get("chat.ooc")
        local textColor = ax.color:Get("text")
        local nameColor = team.GetColor(speaker:Team()) or textColor
        chat.AddText(tagColor, "[LOOC] ", nameColor, speaker:Name(), textColor, ": " .. ax.chat:Format(text))
    end
})

hook.Run("PostRegisterChatClasses")