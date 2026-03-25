--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Client-side recognition: nameplate/chat display overrides, alias input panel, and journal tab.
-- @module ax.recognition (client)

local UNKNOWN_COLOR_FALLBACK = Color(150, 150, 150)

--- Return the muted display colour used for unrecognised character names.
-- @realm client
-- @return Color
local function GetUnknownColor()
    local cfg = ax.config:Get("recognition_unknown_colour", UNKNOWN_COLOR_FALLBACK)
    return IsColor(cfg) and cfg or UNKNOWN_COLOR_FALLBACK
end

--- Derive the familiarity tier that the local character has toward `targetChar`.
-- Returns 0 (STRANGER) when no record exists, unless the target is globally recognised.
-- @realm client
-- @param localChar table Local player's character instance
-- @param targetChar table Target character instance
-- @return number Tier integer (0–4)
local function GetLocalTier(localChar, targetChar)
    if ( ax.recognition:IsGloballyRecognized(targetChar) ) then
        return ax.recognition.TIERS.ACQUAINTED
    end

    local record = ax.recognition:GetRecord(localChar, targetChar:GetID())
    if ( !istable(record) ) then return 0 end

    local tier = ax.recognition:GetTier(record.score or 0)

    if ( !isstring(record.alias) ) then
        tier = math.min(tier, ax.recognition.TIERS.SEEN)
    end

    return tier
end

--- Format a UNIX timestamp as a human-readable relative time string.
-- @realm client
-- @param timestamp number UNIX timestamp
-- @return string e.g. "just now", "3 hours ago", "5 days ago"
local function FormatRelativeTime(timestamp)
    local diff = os.time() - (tonumber(timestamp) or 0)

    if ( diff < 60 ) then return ax.localization:GetPhrase("recognition.time.just_now") end
    if ( diff < 3600 ) then return ax.localization:GetPhrase("recognition.time.minutes_ago", math.floor(diff / 60)) end
    if ( diff < 86400 ) then return ax.localization:GetPhrase("recognition.time.hours_ago", math.floor(diff / 3600)) end
    if ( diff < 604800 ) then return ax.localization:GetPhrase("recognition.time.days_ago", math.floor(diff / 86400)) end

    return ax.localization:GetPhrase("recognition.time.weeks_ago", math.floor(diff / 604800))
end

--- Mirror the chat targeting lookup used by the core chat formatter.
-- @realm client
-- @param speaker Player
-- @return Player|nil
local function GetLookTarget(speaker)
    if ( !ax.util:IsValidPlayer(speaker) ) then return nil end

    local trace = speaker:GetEyeTrace()
    if ( !IsValid(trace.Entity) or !ax.util:IsValidPlayer(trace.Entity) ) then return nil end

    return trace.Entity
end

--- Resolve the display name a viewer should see for a given player.
-- @realm client
-- @param viewer Player The client receiving the message
-- @param subject Player The player whose name should be resolved
-- @return string
local function GetRecognizedChatName(viewer, subject)
    if ( !ax.util:IsValidPlayer(subject) ) then return "" end

    local displayName = hook.Run("GetEntityDisplayText", subject)
    if ( isstring(displayName) and displayName != "" ) then
        return displayName
    end

    return subject:Nick()
end

--- Replace the leading speaker name inside a formatted chat string.
-- Supports plain strings and strings wrapped in a leading font tag.
-- @realm client
-- @param formatted string
-- @param oldName string
-- @param newName string
-- @return string
local function ReplaceLeadingName(formatted, oldName, newName)
    if ( !isstring(formatted) or !isstring(oldName) or !isstring(newName) ) then return formatted end
    if ( oldName == "" or oldName == newName ) then return formatted end

    if ( string.StartWith(formatted, oldName) ) then
        return newName .. string.sub(formatted, #oldName + 1)
    end

    local fontTag = string.match(formatted, "^(<font=[^>]+>)")
    if ( isstring(fontTag) and string.StartWith(string.sub(formatted, #fontTag + 1), oldName) ) then
        return fontTag .. newName .. string.sub(formatted, #fontTag + #oldName + 1)
    end

    return formatted
end

--- Apply recognition-based speaker/target name substitutions to a formatted IC string.
-- @realm client
-- @param viewer Player The client receiving the message
-- @param speaker Player The speaking player
-- @param formatted string The already formatted chat line
-- @return string
local function ApplyRecognizedChatNames(viewer, speaker, formatted)
    if ( !ax.util:IsValidPlayer(viewer) or !ax.util:IsValidPlayer(speaker) ) then return formatted end
    if ( !isstring(formatted) or formatted == "" ) then return formatted end

    local speakerName = GetRecognizedChatName(viewer, speaker)
    local realSpeakerName = speaker:Nick()

    formatted = ReplaceLeadingName(formatted, realSpeakerName, speakerName)

    local target = GetLookTarget(speaker)
    if ( !ax.util:IsValidPlayer(target) or target == viewer ) then
        return formatted
    end

    local realTargetName = target:Nick()
    local targetName = GetRecognizedChatName(viewer, target)
    if ( !isstring(realTargetName) or realTargetName == "" or realTargetName == targetName ) then
        return formatted
    end

    formatted = string.gsub(formatted, " to " .. string.PatternSafe(realTargetName) .. ",", " to " .. targetName .. ",", 1)

    return formatted
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Nameplate override
-- ─────────────────────────────────────────────────────────────────────────────

--- Override the nameplate text for players based on familiarity.
-- Replaces the default Nick() with the stored alias or "Unknown" as appropriate.
-- @realm client
local function HandleGetPlayerDisplayName(entity, name)
    if ( !ax.util:IsValidPlayer(entity) or entity == ax.client ) then return end

    local localPlayer = ax.client
    if ( !ax.util:IsValidPlayer(localPlayer) ) then return end

    local localChar = localPlayer:GetCharacter()
    if ( !localChar ) then return end

    local targetChar = entity:GetCharacter()
    if ( !targetChar ) then return end

    local alias = ax.recognition:GetAlias(localChar, targetChar:GetID())
    local tier  = GetLocalTier(localChar, targetChar)

    local nameColor = tier >= ax.recognition.TIERS.ACQUAINTED
        and team.GetColor(entity:Team())
        or GetUnknownColor()

    return alias, nameColor
end

hook.Add("GetPlayerDisplayName", "ax.recognition.Nameplate", HandleGetPlayerDisplayName)

-- ─────────────────────────────────────────────────────────────────────────────
-- Chat name colour override
-- ─────────────────────────────────────────────────────────────────────────────

--- Tint the chat name colour for unrecognised characters (used in OOC/LOOC).
-- @realm client
local function HandleGetChatNameColor(client)
    if ( client == ax.client ) then return end
    if ( !ax.util:IsValidPlayer(ax.client) ) then return end

    local localChar = ax.client:GetCharacter()
    if ( !localChar ) then return end

    local targetChar = client:GetCharacter()
    if ( !targetChar ) then return end

    local tier = GetLocalTier(localChar, targetChar)
    if ( tier < ax.recognition.TIERS.ACQUAINTED ) then
        return GetUnknownColor()
    end
end

hook.Add("GetChatNameColor", "ax.recognition.ChatColor", HandleGetChatNameColor)

-- ─────────────────────────────────────────────────────────────────────────────
-- IC chat name substitution
-- ─────────────────────────────────────────────────────────────────────────────

--- Wrap a chat type's OnFormatForListener to substitute the speaker's real name
-- with whatever alias the local character has stored for them.
-- Uses a guard flag to prevent double-wrapping on hot-reload.
-- @realm client
-- @param chatType string Chat type key (e.g. "ic", "yell", "whisper")
local function WrapChatTypeListener(chatType)
    local chatClass = ax.chat.registry[chatType]
    if ( !istable(chatClass) ) then return end
    if ( chatClass.__recognitionWrapped ) then return end

    chatClass.__recognitionWrapped = true

    local originalRun = chatClass.OnRun
    if ( isfunction(originalRun) ) then
        chatClass.OnRun = function(this, speaker, message, data)
            local results = { originalRun(this, speaker, message, data) }

            if ( ax.util:IsValidPlayer(ax.client) and ax.util:IsValidPlayer(speaker) and isstring(results[2]) ) then
                results[2] = ApplyRecognizedChatNames(ax.client, speaker, results[2])
            end

            return unpack(results)
        end
    end

    local originalListener = chatClass.OnFormatForListener
    if ( isfunction(originalListener) ) then
        chatClass.OnFormatForListener = function(this, speaker, listener, message, data)
            local results = { originalListener(this, speaker, listener, message, data) }

            if ( ax.util:IsValidPlayer(listener) and ax.util:IsValidPlayer(speaker) and isstring(results[2]) ) then
                results[2] = ApplyRecognizedChatNames(listener, speaker, results[2])
            end

            return unpack(results)
        end
    end
end

--- Wrap IC, yell, and whisper chat types after all framework code has loaded.
local function WrapChatTypes()
    WrapChatTypeListener("ic")
    WrapChatTypeListener("yell")
    WrapChatTypeListener("whisper")
    WrapChatTypeListener("me")
end

hook.Add("OnSchemaLoaded", "ax.recognition.WrapChatTypes", WrapChatTypes)

-- ─────────────────────────────────────────────────────────────────────────────
-- Alias introduction panel
-- ─────────────────────────────────────────────────────────────────────────────

--- Open the introduction panel when the player presses USE while holding ALT.
-- Uses an eye trace to find the nearest player target.
-- @realm client
local function HandleIntroduceKey(client, bind, pressed)
    if ( !pressed ) then return end
    if ( !string.find(bind, "use", 1, true) ) then return end
    if ( !input.IsKeyDown(KEY_LALT) and !input.IsKeyDown(KEY_RALT) ) then return end

    local override = hook.Run("CanUseRecognitionIntroduce", client, bind, pressed)
    if ( override == false ) then return end
    if ( override == true ) then return true end

    if ( !ax.util:IsValidPlayer(ax.client) ) then return end

    local char = ax.client:GetCharacter()
    if ( !char ) then return end

    local trace = ax.client:GetEyeTrace()
    local target = trace and trace.Entity or nil

    if ( !IsValid(target) or !ax.util:IsValidPlayer(target) or target == ax.client ) then
        ax.notification:Add(ax.localization:GetPhrase("recognition.notify.no_target"))
        return
    end

    if ( IsValid(ax.gui.recognitionIntroduce) ) then
        ax.gui.recognitionIntroduce:Remove()
    end

    local targetChar = target:GetCharacter()
    if ( !targetChar ) then
        ax.notification:Add(ax.localization:GetPhrase("recognition.notify.no_character"))
        return
    end

    local name = hook.Run("GetEntityDisplayText", target)
    ax.gui.recognitionIntroduce = Derma_StringRequest(ax.localization:GetPhrase("recognition.introduce.title"), ax.localization:GetPhrase("recognition.introduce.prompt", name), char:GetName(), function(text)
        if ( text == "" ) then
            ax.notification:Add(ax.localization:GetPhrase("recognition.notify.alias_empty"), "error")
            return
        end

        if ( #text > 48 ) then
            ax.notification:Add(ax.localization:GetPhrase("recognition.notify.alias_too_long"), "error")
            return
        end

        ax.net:Start("recognition.introduce_request", target:EntIndex(), text)
    end)

    return true
end

hook.Add("PlayerBindPress", "ax.recognition.IntroduceKey", HandleIntroduceKey)

-- ─────────────────────────────────────────────────────────────────────────────
-- Journal panel
-- ─────────────────────────────────────────────────────────────────────────────

local TIER_PHRASE_KEYS = {
    "recognition.tier.stranger",
    "recognition.tier.seen",
    "recognition.tier.acquainted",
    "recognition.tier.known",
    "recognition.tier.trusted",
}

local TIER_COLORS = {
    Color(150, 150, 150),  -- Stranger
    Color(180, 160, 120),  -- Seen
    Color(100, 180, 100),  -- Acquainted
    Color(80,  160, 220),  -- Known
    Color(220, 180, 60),   -- Trusted
}

local JOURNAL_ROW_H    = ax.util:ScreenScaleH(32)
local JOURNAL_HEADER_H = ax.util:ScreenScaleH(16)
local JOURNAL_PAD_H    = ax.util:ScreenScale(8)
local JOURNAL_PAD_V    = ax.util:ScreenScaleH(4)
local JOURNAL_ACCENT_W = ax.util:ScreenScale(4)
local JOURNAL_RADIUS   = 6

local JOURNAL_PANEL = {}

function JOURNAL_PANEL:Init()
    if ( IsValid(ax.gui.journal) ) then
        ax.gui.journal:Remove()
    end

    ax.gui.journal = self

    self:Dock(FILL)
    self:DockPadding(JOURNAL_PAD_H, JOURNAL_PAD_V * 2, JOURNAL_PAD_H, JOURNAL_PAD_V * 2)

    local header = self:Add("EditablePanel")
    header:Dock(TOP)
    header:SetTall(JOURNAL_HEADER_H)
    header:DockMargin(0, 0, 0, JOURNAL_PAD_V * 2)
    header.Paint = function(pnl, w, h)
        local glass = ax.theme:GetGlass()
        ax.theme:DrawGlassPanel(0, 0, w, h, {
            radius = JOURNAL_RADIUS,
            blur   = 0.4,
            flags  = ax.render.SHAPE_IOS,
        })
        local muted = glass.textMuted
        draw.SimpleText(ax.localization:GetPhrase("recognition.journal.header.name"),      "ax.small.bold", JOURNAL_ACCENT_W + JOURNAL_PAD_H, h / 2, muted, TEXT_ALIGN_LEFT,   TEXT_ALIGN_CENTER)
        draw.SimpleText(ax.localization:GetPhrase("recognition.journal.header.tier"),      "ax.small",      w / 2,                            h / 2, muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(ax.localization:GetPhrase("recognition.journal.header.last_seen"), "ax.small",      w - JOURNAL_PAD_H,                h / 2, muted, TEXT_ALIGN_RIGHT,  TEXT_ALIGN_CENTER)
    end

    local scroll = self:Add("DScrollPanel")
    scroll:Dock(FILL)
    scroll:GetVBar():SetWide(0)
    self.scroll = scroll

    self:Refresh()
end

function JOURNAL_PANEL:Paint(w, h)
    ax.theme:DrawGlassPanel(0, 0, w, h, {
        radius = 8,
        blur   = 0.7,
        flags  = ax.render.SHAPE_IOS,
    })
end

function JOURNAL_PANEL:Refresh()
    if ( !IsValid(self.scroll) ) then return end
    self.scroll:Clear()

    if ( !ax.util:IsValidPlayer(ax.client) ) then return end

    local char = ax.client:GetCharacter()
    if ( !char ) then return end

    local familiarity = char:GetFamiliarity()
    if ( !istable(familiarity) ) then return end

    local ownID = tostring(char:GetID())

    -- Deduplicate: JSON round-trips produce string keys while old writes used number keys.
    -- Collapse both into a single string-keyed entry, preferring the higher score and
    -- carrying over any alias from whichever side has one.
    local deduped = {}
    for rawID, record in pairs(familiarity) do
        if ( !istable(record) ) then continue end

        local key = tostring(tonumber(rawID) or rawID)
        local existing = deduped[key]
        if ( !existing ) then
            deduped[key] = record
        else
            if ( (record.score or 0) > (existing.score or 0) ) then existing.score = record.score end
            if ( isstring(record.alias) and !isstring(existing.alias) ) then existing.alias = record.alias end
            if ( (record.lastSeen or 0) > (existing.lastSeen or 0) ) then existing.lastSeen = record.lastSeen end
        end
    end

    -- Collect and sort: highest tier first, then alias alphabetically.
    -- Exclude own character ID so the player never sees themselves in the journal.
    local entries = {}
    for targetID, record in pairs(deduped) do
        if ( targetID != ownID ) then
            entries[#entries + 1] = { targetID = targetID, record = record }
        end
    end

    table.sort(entries, function(a, b)
        local tierA = ax.recognition:GetTier(a.record.score or 0)
        local tierB = ax.recognition:GetTier(b.record.score or 0)
        if ( tierA != tierB ) then return tierA > tierB end
        local aliasA = string.lower(a.record.alias or "")
        local aliasB = string.lower(b.record.alias or "")
        return aliasA < aliasB
    end)

    if ( #entries == 0 ) then
        local empty = self.scroll:Add("ax.text")
        empty:Dock(TOP)
        empty:DockMargin(0, ax.util:ScreenScaleH(8), 0, 0)
        empty:SetFont("ax.regular.italic")
        empty:SetText(ax.localization:GetPhrase("recognition.journal.empty"), true)
        empty:SetTextColor(ax.theme:GetGlass().textMuted)
        empty:SetContentAlignment(5)
        return
    end

    for _, entry in ipairs(entries) do
        local record    = entry.record
        local tier      = ax.recognition:GetTier(record.score or 0)
        local alias     = record.alias or ax.localization:GetPhrase("unknown")
        local tierLabel = ax.localization:GetPhrase(TIER_PHRASE_KEYS[tier + 1] or "unknown")
        local tierColor = TIER_COLORS[tier + 1] or color_white
        local lastSeen  = FormatRelativeTime(record.lastSeen or 0)

        local row = self.scroll:Add("EditablePanel")
        row:Dock(TOP)
        row:SetTall(JOURNAL_ROW_H)
        row:DockMargin(0, 0, 0, JOURNAL_PAD_V)
        row:SetMouseInputEnabled(true)
        row:SetCursor("hand")

        local targetID = entry.targetID
        row.OnMousePressed = function(pnl, mouseCode)
            if ( mouseCode != MOUSE_RIGHT ) then return end
            local menu = DermaMenu()
            menu:AddOption(ax.localization:GetPhrase("recognition.journal.forget"), function()
                ax.net:Start("recognition.forget_request", targetID)
            end):SetIcon("icon16/delete.png")
            menu:Open()
        end

        row.Paint = function(pnl, w, h)
            local glass = ax.theme:GetGlass()
            local fill = pnl:IsHovered() and glass.buttonHover or glass.button

            ax.theme:DrawGlassPanel(0, 0, w, h, {
                radius = JOURNAL_RADIUS,
                blur   = 0.5,
                fill   = fill,
                flags  = ax.render.SHAPE_IOS,
            })

            surface.SetDrawColor(tierColor.r, tierColor.g, tierColor.b, 200)
            surface.DrawRect(0, 0, JOURNAL_ACCENT_W, h)

            draw.SimpleText(alias,     "ax.regular.bold", JOURNAL_ACCENT_W + JOURNAL_PAD_H, h / 2, color_white,     TEXT_ALIGN_LEFT,   TEXT_ALIGN_CENTER)
            draw.SimpleText(tierLabel, "ax.small",        w / 2,                            h / 2, tierColor,       TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(lastSeen,  "ax.small",        w - JOURNAL_PAD_H,                h / 2, glass.textMuted, TEXT_ALIGN_RIGHT,  TEXT_ALIGN_CENTER)
        end
    end
end

vgui.Register("ax.recognition.journal", JOURNAL_PANEL, "EditablePanel")

--- Inject the recognition journal as a tab in the Parallax tab menu.
hook.Add("PopulateTabButtons", "ax.recognition.Journal", function(buttons)
    if ( !ax.util:IsValidPlayer(ax.client) ) then return end

    local char = ax.client:GetCharacter()
    if ( !char ) then return end

    buttons["recognition"] = {
        Populate = function(this, panel)
            local journalPanel = panel:Add("ax.recognition.journal")
            journalPanel:Dock(FILL)
        end
    }
end)

--- Refresh the journal panel when a new character var update is received.
-- This keeps the list current after familiarity changes are synced.
local function RefreshJournal(char)
    local localChar = ax.client:GetCharacter()
    if ( !istable(localChar) or localChar:GetID() != char:GetID() ) then return end

    -- Defer to next frame to let the data settle before refreshing.
    timer.Simple(0, function()
        if ( IsValid(ax.gui.journal) ) then
            ax.gui.journal:Refresh()
        end
    end)
end

hook.Add("CharacterDataChanged", "ax.recognition.JournalRefresh", function(char, name, key, value)
    if ( name != "familiarity" ) then return end

    RefreshJournal(char)
end)

hook.Add("OnCharacterVarChanged", "ax.recognition.JournalRefreshVar", function(char, name, value)
    if ( name != "familiarity" ) then return end

    RefreshJournal(char)
end)
