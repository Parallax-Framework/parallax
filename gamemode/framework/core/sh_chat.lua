--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Helper function to check if speaker is looking at a target player
local function GetLookTarget(speaker)
    if ( !IsValid(speaker) or !speaker:IsPlayer() ) then return nil end

    local trace = speaker:GetEyeTrace()
    if ( IsValid(trace.Entity) and trace.Entity:IsPlayer() ) then
        return trace.Entity
    end

    return nil
end

--[[

A list of things to improve the chat to a level of serious quality.

```Font & Colour```
Arial, Weighted at 600 should be the standard.
## Yelling (255, 255, 150) (Larger)
Talking (255, 255, 150) (Normal)
-# Whispering (230, 230, 150) (Smaller)
/me (255, 255, 175)

Looking At (150, 175, 175)
Looking At Whispering (130, 155, 230)
Looking At /me (175, 175, 255)

/localevent, /event (200, 100, 50)
/broadcast (150, 125, 175)
/dispatch (150, 100, 100)
/request (175, 125, 100)
/radio (75, 150, 50)
/tac (50, 75, 150)

[LOOC] (225, 50, 50)
/roll (150, 75, 75)
/pm (125, 150, 75)
Notify (175, 200, 255)
Time Stamps (150, 150, 150)

```Logic```
-All new messages should appear at the bottom of the chatbox and move up. Instead of first initial messages appearing at the top.
-There should be support added for **Bolding**, *Italics*, ~~Strikethrough~~ and __Underline__. (---) gets replaced into (—).
-The chatbox should be able to be scaled and reset to its original position with a button (🔄).
-Chat command display need a cleaner, fresh display that doesn't detract from the chat all that much and is more readable on what that command does.

```Additional```
-***says*** alone is boring. Add: more words like **exclaims**, **proclaims**, **expresses**, **asserts**, **speaks**, **discloses**, **utters**, **conveys**, **states**, **comments**, **remarks** and **declares**. `(John Smith exclaims "Hey.")`
-***whispers*** is also boring alone. Add: **mutters**, **undertones**, **murmurs** and **mumbles**. `(John Smith mutters "Hey...")`
-***yells***. Add: **shouts**, **howls**, **screams** and **roars**. `(John Smith shouts "Hey!")`
-***radios***. Add: **transmits**, **emits**, **relays**, **delivers**, **communicates** and **wires** `(John Smith emits on 100.0 "Hey!")`

]]

local expressions = {
    ["ic"] = {
        "says",
        "exclaims",
        "proclaims",
        "expresses",
        "asserts",
        "speaks",
        "discloses",
        "utters",
        "conveys",
        "states",
        "comments",
        "remarks",
        "declares"
    },
    ["yell"] = {
        "yells",
        "shouts",
        "howls",
        "screams",
        "roars"
    },
    ["whisper"] = {
        "whispers",
        "mutters",
        "undertones",
        "murmurs",
        "mumbles"
    }
}

-- Helper function to get the appropriate verb based on listener's preference
local function GetVerb(listener, chatType)
    if ( SERVER ) then
        -- On server, check the listener's option preference
        local useRandomVerbs = ax.option:Get(listener, "chat.randomized.verbs", true)
        if ( useRandomVerbs ) then
            return expressions[chatType][math.random(#expressions[chatType])]
        else
            return expressions[chatType][1] -- Return default verb (first in array)
        end
    else
        -- On client, check local player's option
        local useRandomVerbs = ax.option:Get("chat.randomized.verbs", true)
        if ( useRandomVerbs ) then
            return expressions[chatType][math.random(#expressions[chatType])]
        else
            return expressions[chatType][1]
        end
    end
end

ax.chat:Add("ic", {
    displayName = "IC",
    description = "Speak in-character",
    noCommand = true,
    OnRun = function(this, client, message)
        local icColor = ax.config:Get("chat.ic.color")
        return icColor, client:Nick() .. " " .. expressions["ic"][math.random(#expressions["ic"])] .. ", \"" .. ax.chat:Format(message) .. "\""
    end,
    OnFormatForListener = function(this, speaker, listener, message)
        local icColor = ax.config:Get("chat.ic.color")
        local verb = GetVerb(listener, "ic")
        local formattedMessage = ax.chat:Format(message)
        local target = GetLookTarget(speaker)

        if ( IsValid(target) ) then
            if ( target == listener ) then
                -- Speaker is looking at this listener
                return icColor, speaker:Nick() .. " " .. verb .. " to you, \"" .. formattedMessage .. "\""
            elseif ( listener == speaker ) then
                -- This is the speaker seeing their own message
                return icColor, speaker:Nick() .. " " .. verb .. " to " .. target:Nick() .. ", \"" .. formattedMessage .. "\""
            else
                -- Other listeners see who the speaker is talking to
                return icColor, speaker:Nick() .. " " .. verb .. " to " .. target:Nick() .. ", \"" .. formattedMessage .. "\""
            end
        end

        -- Default message (no target)
        return icColor, speaker:Nick() .. " " .. verb .. ", \"" .. formattedMessage .. "\""
    end,
    CanHear = function(this, speaker, listener)
        local distance = ax.config:Get("chat.ic.distance", 400)
        return speaker:GetPos():DistToSqr(listener:GetPos()) <= distance ^ 2
    end
})

ax.chat:Add("roll", {
    displayName = "Roll",
    description = "Roll a dice",
    noCommand = true,
    OnRun = function(this, client, result, sides)
        local rollColor = ax.config:Get("chat.roll.color", Color(150, 75, 75))
        return rollColor, string.format("<font=ax.small>%s</font>", client:Nick() .. " rolls a " .. result .. " on a " .. sides .. "-sided dice.")
    end,
    CanHear = function(this, speaker, listener)
        local distance = ax.config:Get("chat.me.distance", 400)
        return speaker:GetPos():DistToSqr(listener:GetPos()) <= distance ^ 2
    end
})

ax.chat:Add("yell", {
    displayName = "Yell",
    description = "Yell at someone",
    alias = {"y", "shout"},
    OnRun = function(this, client, message)
        local yellColor = ax.config:Get("chat.yell.color")
        return yellColor, string.format("<font=ax.medium>%s</font>", client:Nick() .. " " .. expressions["yell"][math.random(#expressions["yell"])] .. ", \"" .. utf8.upper(ax.chat:Format(message)) .. "\"")
    end,
    OnFormatForListener = function(this, speaker, listener, message)
        local yellColor = ax.config:Get("chat.yell.color")
        local verb = GetVerb(listener, "yell")
        local formattedMessage = utf8.upper(ax.chat:Format(message))
        local target = GetLookTarget(speaker)

        if ( IsValid(target) ) then
            if ( target == listener ) then
                -- Speaker is looking at this listener
                return yellColor, string.format("<font=ax.medium>%s</font>", speaker:Nick() .. " " .. verb .. " to you, \"" .. formattedMessage .. "\"")
            elseif ( listener == speaker ) then
                -- This is the speaker seeing their own message
                return yellColor, string.format("<font=ax.medium>%s</font>", speaker:Nick() .. " " .. verb .. " to " .. target:Nick() .. ", \"" .. formattedMessage .. "\"")
            else
                -- Other listeners see who the speaker is talking to
                return yellColor, string.format("<font=ax.medium>%s</font>", speaker:Nick() .. " " .. verb .. " to " .. target:Nick() .. ", \"" .. formattedMessage .. "\"")
            end
        end

        -- Default message (no target)
        return yellColor, string.format("<font=ax.medium>%s</font>", speaker:Nick() .. " " .. verb .. ", \"" .. formattedMessage .. "\"")
    end,
    CanHear = function(this, speaker, listener)
        local distance = ax.config:Get("chat.yell.distance", 700)
        return speaker:GetPos():DistToSqr(listener:GetPos()) <= distance ^ 2
    end
})

ax.chat:Add("whisper", {
    displayName = "Whisper",
    description = "Whisper to someone nearby",
    alias = {"w"},
    OnRun = function(this, client, message)
        local whisperColor = ax.config:Get("chat.whisper.color")
        return whisperColor, string.format("<font=ax.small>%s</font>", client:Nick() .. " " .. expressions["whisper"][math.random(#expressions["whisper"])] .. ", \"" .. ax.chat:Format(message) .. "\"")
    end,
    OnFormatForListener = function(this, speaker, listener, message)
        local whisperColor = ax.config:Get("chat.whisper.color")
        local verb = GetVerb(listener, "whisper")
        local formattedMessage = ax.chat:Format(message)
        local target = GetLookTarget(speaker)

        if ( IsValid(target) ) then
            if ( target == listener ) then
                -- Speaker is looking at this listener
                return whisperColor, string.format("<font=ax.small>%s</font>", speaker:Nick() .. " " .. verb .. " to you, \"" .. formattedMessage .. "\"")
            elseif ( listener == speaker ) then
                -- This is the speaker seeing their own message
                return whisperColor, string.format("<font=ax.small>%s</font>", speaker:Nick() .. " " .. verb .. " to " .. target:Nick() .. ", \"" .. formattedMessage .. "\"")
            else
                -- Other listeners see who the speaker is talking to
                return whisperColor, string.format("<font=ax.small>%s</font>", speaker:Nick() .. " " .. verb .. " to " .. target:Nick() .. ", \"" .. formattedMessage .. "\"")
            end
        end

        -- Default message (no target)
        return whisperColor, string.format("<font=ax.small>%s</font>", speaker:Nick() .. " " .. verb .. ", \"" .. formattedMessage .. "\"")
    end,
    CanHear = function(this, speaker, listener)
        local distance = ax.config:Get("chat.whisper.distance", 200)
        return speaker:GetPos():DistToSqr(listener:GetPos()) <= distance ^ 2
    end
})

ax.chat:Add("looc", {
    displayName = "Local Out of Character",
    description = "Speak local out of character",
    OnRun = function(this, client, message)
        local oocColor = ax.config:Get("chat.ooc.color", Color(225, 50, 50))
        return oocColor, "<font=ax.small>" .. "[LOOC] ", color_white, client:SteamName() .. ": " .. message .. "</font>"
    end,
    CanHear = function(this, speaker, listener)
        local distance = ax.config:Get("chat.ooc.distance", 600)
        return listener:GetCharacter() == nil or speaker:GetPos():DistToSqr(listener:GetPos()) <= distance ^ 2
    end
})

ax.chat:Add("ooc", {
    displayName = "Out of Character",
    description = "Speak out of character",
    OnRun = function(this, client, message)
        local oocColor = ax.config:Get("chat.ooc.color", Color(225, 50, 50))
        return oocColor, "<font=ax.small>" .. "[OOC] ", color_white, client:SteamName() .. ": " .. message .. "</font>"
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

        local meColor = ax.config:Get("chat.me.color", Color(255, 255, 175))
        return meColor, "** " .. client:Nick() .. " " .. txt
    end,
    CanHear = function(this, speaker, listener)
        local distance = ax.config:Get("chat.me.distance", 600)
        return speaker:GetPos():DistToSqr(listener:GetPos()) <= distance ^ 2
    end
})

ax.chat:Add("it", {
    description = "Describe something in third person",
    OnRun = function(this, client, message)
        local itColor = ax.config:Get("chat.it.color", Color(255, 255, 175))
        return itColor, "** " .. ax.chat:Format(message)
    end,
    CanHear = function(this, speaker, listener)
        local distance = ax.config:Get("chat.it.distance", 600)
        return speaker:GetPos():DistToSqr(listener:GetPos()) <= distance ^ 2
    end
})
