--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

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
    local useRandomVerbs = SERVER and ax.option:Get(listener, "chat.randomized.verbs", true) or ax.option:Get("chat.randomized.verbs", true)
    if ( useRandomVerbs ) then
        return expressions[chatType][math.random(#expressions[chatType])]
    else
        return expressions[chatType][1] -- Return default verb (first in array)
    end
end

-- Server-side tracking for OOC/LOOC usage to enforce delay and rate limits
AX_OOC_TRACK = AX_OOC_TRACK or {}

local function CheckOOCAllowed(client)
    if ( CLIENT ) then return true end

    local steam64 = client:SteamID64() or tostring(client:SteamID())
    local now = os.time()

    -- Respect global enable toggle
    if ( !ax.config:Get("chat.ooc.enabled", true) ) then
        client:ChatPrint(ax.localization:GetPhrase("notify.chat.ooc.disabled"))
        return false
    end

    local delay = math.max(0, ax.config:Get("chat.ooc.delay", 5) or 0)
    local rateLimit = math.max(0, ax.config:Get("chat.ooc.rate_limit", 10) or 0)

    local info = AX_OOC_TRACK[steam64] or { last = 0, times = {} }

    -- Enforce simple per-message delay (seconds)
    if ( delay > 0 ) then
        local since = now - (info.last or 0)
        if ( since < delay ) then
            local wait = math.ceil(delay - since)
            client:ChatPrint(string.format(ax.localization:GetPhrase("notify.chat.ooc.wait"), wait))
            return false
        end
    end

    -- Enforce rate limit per 10 minutes (600 seconds)
    if ( rateLimit > 0 ) then
        local window = 600
        local newtimes = {}
        for _, t in ipairs(info.times or {}) do
            if ( now - t <= window ) then table.insert(newtimes, t) end
        end

        if ( #newtimes >= rateLimit ) then
            client:ChatPrint(string.format(ax.localization:GetPhrase("notify.chat.ooc.rate_limited"), rateLimit, window / 60))
            AX_OOC_TRACK[steam64] = { last = info.last or 0, times = newtimes }
            return false
        end

        table.insert(newtimes, now)
        info.times = newtimes
    end

    info.last = now
    AX_OOC_TRACK[steam64] = info
    return true
end

ax.chat:Add("ic", {
    displayName = "IC",
    description = "Speak in-character",
    OnRun = function(this, client, message)
        local icColor = ax.config:Get("chat.ic.color")
        return icColor, client:Nick() .. " " .. expressions["ic"][math.random(#expressions["ic"])] .. ", \"" .. ax.chat:FormatWithMarkdown(message) .. "\""
    end,
    OnFormatForListener = function(this, speaker, listener, message, data)
        local icColor = ax.config:Get("chat.ic.color")
        local verb = GetVerb(listener, "ic")
        local formattedMessage = ax.chat:FormatWithMarkdown(message)
        local target = GetLookTarget(speaker)

        if ( ax.util:IsValidPlayer(target) ) then
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
        return speaker:EyePos():DistToSqr(listener:EyePos()) <= distance * distance
    end
})

ax.chat:Add("roll", {
    displayName = "Roll",
    description = "Roll a dice",
    OnRun = function(this, client, text, data)
        local rollColor = ax.config:Get("chat.roll.color", Color(150, 75, 75))
        return rollColor, client:Nick() .. " rolls a " .. data.result .. " on a " .. data.sides .. "-sided dice."
    end,
    CanHear = function(this, speaker, listener)
        local distance = ax.config:Get("chat.me.distance", 400)
        return speaker:EyePos():DistToSqr(listener:EyePos()) <= distance * distance
    end
})

ax.chat:Add("yell", {
    displayName = "Yell",
    description = "Yell at someone",
    prefix = {"/y", "/shout"},
    OnRun = function(this, client, message)
        local yellColor = ax.config:Get("chat.yell.color")
        local baseFont = "ax.medium.shadow"
        return yellColor, "<font=" .. baseFont .. ">" .. client:Nick() .. " " .. expressions["yell"][math.random(#expressions["yell"])] .. ", \"" .. utf8.upper(ax.chat:FormatWithMarkdown(message, baseFont)) .. "\"</font>"
    end,
    OnFormatForListener = function(this, speaker, listener, message, data)
        local yellColor = ax.config:Get("chat.yell.color")
        local verb = GetVerb(listener, "yell")
        local baseFont = "ax.medium.shadow"
        local formattedMessage = utf8.upper(ax.chat:FormatWithMarkdown(message, baseFont))
        local target = GetLookTarget(speaker)

        if ( ax.util:IsValidPlayer(target) ) then
            if ( target == listener ) then
                -- Speaker is looking at this listener
                return yellColor, "<font=" .. baseFont .. ">" .. speaker:Nick() .. " " .. verb .. " to you, \"" .. formattedMessage .. "\"</font>"
            elseif ( listener == speaker ) then
                -- This is the speaker seeing their own message
                return yellColor, "<font=" .. baseFont .. ">" .. speaker:Nick() .. " " .. verb .. " to " .. target:Nick() .. ", \"" .. formattedMessage .. "\"</font>"
            else
                -- Other listeners see who the speaker is talking to
                return yellColor, "<font=" .. baseFont .. ">" .. speaker:Nick() .. " " .. verb .. " to " .. target:Nick() .. ", \"" .. formattedMessage .. "\"</font>"
            end
        end

        -- Default message (no target)
        return yellColor, "<font=" .. baseFont .. ">" .. speaker:Nick() .. " " .. verb .. ", \"" .. formattedMessage .. "\"</font>"
    end,
    CanHear = function(this, speaker, listener)
        local distance = ax.config:Get("chat.yell.distance", 700)
        return speaker:GetPos():DistToSqr(listener:GetPos()) <= distance * distance
    end
})

ax.chat:Add("whisper", {
    displayName = "Whisper",
    description = "Whisper to someone nearby",
    prefix = {"/w", "/whisper"},
    OnRun = function(this, client, message)
        local whisperColor = ax.config:Get("chat.whisper.color")
        local baseFont = "ax.small.shadow"
        return whisperColor, "<font=" .. baseFont .. ">" .. client:Nick() .. " " .. expressions["whisper"][math.random(#expressions["whisper"])] .. ", \"" .. ax.chat:FormatWithMarkdown(message, baseFont) .. "\"</font>"
    end,
    OnFormatForListener = function(this, speaker, listener, message, data)
        local whisperColor = ax.config:Get("chat.whisper.color")
        local verb = GetVerb(listener, "whisper")
        local baseFont = "ax.small.shadow"
        local formattedMessage = ax.chat:FormatWithMarkdown(message, baseFont)
        local target = GetLookTarget(speaker)

        if ( ax.util:IsValidPlayer(target) ) then
            if ( target == listener ) then
                -- Speaker is looking at this listener
                return whisperColor, "<font=" .. baseFont .. ">" .. speaker:Nick() .. " " .. verb .. " to you, \"" .. formattedMessage .. "\"</font>"
            elseif ( listener == speaker ) then
                -- This is the speaker seeing their own message
                return whisperColor, "<font=" .. baseFont .. ">" .. speaker:Nick() .. " " .. verb .. " to " .. target:Nick() .. ", \"" .. formattedMessage .. "\"</font>"
            else
                -- Other listeners see who the speaker is talking to
                return whisperColor, "<font=" .. baseFont .. ">" .. speaker:Nick() .. " " .. verb .. " to " .. target:Nick() .. ", \"" .. formattedMessage .. "\"</font>"
            end
        end

        -- Default message (no target)
        return whisperColor, "<font=" .. baseFont .. ">" .. speaker:Nick() .. " " .. verb .. ", \"" .. formattedMessage .. "\"</font>"
    end,
    CanHear = function(this, speaker, listener)
        local distance = ax.config:Get("chat.whisper.distance", 200)
        return speaker:GetPos():DistToSqr(listener:GetPos()) <= distance * distance
    end
})

ax.chat:Add("looc", {
    displayName = "Local Out of Character",
    description = "Speak local out of character",
    OnRun = function(this, client, message)
        if ( SERVER and !CheckOOCAllowed(client) ) then return end

        local oocColor = ax.config:Get("chat.ooc.color", Color(225, 50, 50))
        local nameColor = hook.Run("GetChatNameColor", client) or color_white
        return oocColor, "[LOOC] ", nameColor, client:SteamName() .. ": " .. message
    end,
    CanHear = function(this, speaker, listener)
        local distance = ax.config:Get("chat.ooc.distance", 600)
        return listener:GetCharacter() == nil or speaker:GetPos():DistToSqr(listener:GetPos()) <= distance * distance
    end,
    noSpaceAfter = true,
    prefix = {".//", "[[", "/LOOC"}
})

ax.chat:Add("ooc", {
    displayName = "Out of Character",
    description = "Speak out of character",
    OnRun = function(this, client, message)
        if ( SERVER and !CheckOOCAllowed(client) ) then return end

        local oocColor = ax.config:Get("chat.ooc.color", Color(225, 50, 50))
        local nameColor = hook.Run("GetChatNameColor", client) or color_white
        return oocColor, "[OOC] ", nameColor, client:SteamName() .. ": " .. message
    end,
    CanHear = function(this, speaker, listener)
        return true
    end,
    prefix = {"//", "/OOC"},
    noSpaceAfter = true
})

ax.chat:Add("me", {
    description = "Perform an action in third person",
    prefix = {"/me"},
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
        return speaker:GetPos():DistToSqr(listener:GetPos()) <= distance * distance
    end
})

ax.chat:Add("it", {
    description = "Describe something in third person",
    prefix = {"/it"},
    OnRun = function(this, client, message)
        local itColor = ax.config:Get("chat.it.color", Color(255, 255, 175))
        return itColor, "** " .. ax.chat:Format(message)
    end,
    CanHear = function(this, speaker, listener)
        local distance = ax.config:Get("chat.it.distance", 600)
        return speaker:GetPos():DistToSqr(listener:GetPos()) <= distance * distance
    end
})

ax.chat:Add("event", {
    description = "Announce a global event",
    prefix = {"/globalevent"},
    adminOnly = true,
    OnRun = function(this, client, message)
        local eventColor = ax.config:Get("chat.event.color", Color(200, 100, 50))
        return eventColor, "<font=ax.small.italic>" .. ax.chat:Format(message) .. "</font>"
    end,
    CanHear = function(this, speaker, listener)
        return true
    end
})
