--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Recognition system for tracking character familiarity, aliases, and name display.
-- Characters begin as strangers and accumulate familiarity through proximity and IC
-- chat interaction. At sufficient familiarity, introductions unlock the alias shown on
-- nameplates and in IC chat. Faction-level global recognition bypasses per-character scores.
-- @module ax.recognition

ax.recognition = ax.recognition or {}

--- Familiarity tier identifiers.
-- @realm shared
ax.recognition.TIERS = {
    STRANGER   = 0,
    SEEN       = 1,
    ACQUAINTED = 2,
    KNOWN      = 3,
    TRUSTED    = 4,
}

--- Minimum score required to reach each tier.
-- Index position (1-based) maps to tier value (0-based), so THRESHOLDS[1] = 0 (STRANGER),
-- THRESHOLDS[3] = 500 (ACQUAINTED), etc.
-- @realm shared
ax.recognition.THRESHOLDS = { 0, 250, 500, 1000, 1500 }

--- Normalize a familiarity table to canonical string keys and sanitized records.
-- This prevents JSON/network round-trips from collapsing mixed numeric/string keys
-- (e.g. `123` and `"123"`) into duplicate object keys, which can silently discard
-- aliases after reconnects.
-- @realm shared
-- @param familiarity table Familiarity map keyed by target character ID
-- @return boolean True when the table was modified in-place
function ax.recognition:NormalizeFamiliarity(familiarity)
    if ( !istable(familiarity) ) then return false end

    local normalized = {}
    local bChanged = false

    for rawID, rawRecord in pairs(familiarity) do
        local numID = tonumber(rawID)
        if ( !numID or !istable(rawRecord) ) then
            bChanged = true
            continue
        end

        local alias = isstring(rawRecord.alias) and string.Trim(rawRecord.alias) or nil
        if ( alias == "" ) then
            alias = nil
        end

        local key = tostring(numID)
        local record = {
            score = tonumber(rawRecord.score) or 0,
            alias = alias,
            lastSeen = tonumber(rawRecord.lastSeen) or 0,
        }

        local existing = normalized[key]
        if ( !existing ) then
            normalized[key] = record
        else
            if ( record.score > existing.score ) then
                existing.score = record.score
            end

            if ( !isstring(existing.alias) and isstring(record.alias) ) then
                existing.alias = record.alias
            end

            if ( record.lastSeen > existing.lastSeen ) then
                existing.lastSeen = record.lastSeen
            end

            bChanged = true
        end

        if ( rawID != key ) then
            bChanged = true
        end

        if (
            rawRecord.score != record.score or
            rawRecord.alias != record.alias or
            rawRecord.lastSeen != record.lastSeen
        ) then
            bChanged = true
        end
    end

    if ( !bChanged ) then
        return false
    end

    table.Empty(familiarity)

    for key, record in pairs(normalized) do
        familiarity[key] = record
    end

    return true
end

--- Derive the familiarity tier for a given raw score.
-- @realm shared
-- @param score number Raw familiarity score (0–200+)
-- @return number Tier integer (0 = STRANGER … 4 = TRUSTED)
function ax.recognition:GetTier(score)
    score = tonumber(score) or 0

    local tier = 0
    local thresholds = self.THRESHOLDS

    for i = #thresholds, 1, -1 do
        if ( score >= thresholds[i] ) then
            tier = i - 1
            break
        end
    end

    return tier
end

--- Retrieve the familiarity record that `char` holds for `targetID`.
-- @realm shared
-- @param char table The perceiver's character instance
-- @param targetID number The target character's ID
-- @return table|nil Record `{ score, alias, lastSeen }`, or nil if none exists
function ax.recognition:GetRecord(char, targetID)
    if ( !istable(char) ) then return nil end

    local numID = tonumber(targetID)
    if ( !numID ) then return nil end

    local familiarity = ax.character:GetVar(char, "familiarity")
    if ( !istable(familiarity) ) then return nil end

    self:NormalizeFamiliarity(familiarity)

    return familiarity[tostring(numID)]
end

--- Resolve the display name that `char` uses for the character with ID `targetID`.
-- Returns the stored alias at ACQUAINTED or above. At SEEN returns the target's description.
-- At STRANGER returns "Unknown". Globally recognised faction members always show their real name.
-- @realm shared
-- @param char table The perceiver's character instance
-- @param targetID number The target character's ID
-- @return string Display name or fallback string
function ax.recognition:GetAlias(char, targetID)
    if ( !istable(char) or !isnumber(targetID) ) then return ax.localization:GetPhrase("unknown") end

    local targetChar = ax.character:Get(targetID)

    if ( istable(targetChar) and self:IsGloballyRecognized(targetChar) ) then
        return targetChar:GetName()
    end

    local record = self:GetRecord(char, targetID)
    if ( !istable(record) ) then return ax.localization:GetPhrase("unknown") end

    local tier = self:GetTier(record.score or 0)

    if ( tier >= self.TIERS.ACQUAINTED and isstring(record.alias) ) then
        return record.alias
    end

    if ( tier >= self.TIERS.SEEN ) then
        local desc = istable(targetChar) and targetChar:GetDescription() or nil
        return (isstring(desc) and desc != "") and desc or ax.localization:GetPhrase("unknown")
    end

    return ax.localization:GetPhrase("unknown")
end

--- Check whether a character's faction grants global recognition.
-- When a faction sets `isGloballyRecognized = true`, all of its members are treated
-- as at least ACQUAINTED by every perceiver, regardless of individual score.
-- The optional `globalFamiliarityFloor` field on the faction sets which tier is the
-- minimum; it defaults to ACQUAINTED (2) when omitted.
-- @realm shared
-- @param targetChar table The target character instance
-- @return boolean True when the target's faction is globally recognised
function ax.recognition:IsGloballyRecognized(targetChar)
    if ( !istable(targetChar) ) then return false end

    local factionID = targetChar:GetFaction()
    local faction = ax.faction:Get(factionID)
    if ( !istable(faction) ) then return false end

    return faction.isGloballyRecognized == true
end

--- Config keys used by this module.
ax.config:Add("recognition_tick_interval",    ax.type.number, 3,                      { category = "recognition", description = "Seconds between passive proximity familiarity ticks.", min = 1, max = 60, decimals = 0 })
ax.config:Add("recognition_passive_gain",     ax.type.number, 1,                      { category = "recognition", description = "Score gained per proximity tick.", min = 0, max = 10, decimals = 0 })
ax.config:Add("recognition_ic_bonus",         ax.type.number, 3,                      { category = "recognition", description = "Bonus score per IC chat message heard.", min = 0, max = 20, decimals = 0 })
ax.config:Add("recognition_whisper_bonus",    ax.type.number, 5,                      { category = "recognition", description = "Bonus score per whisper heard.", min = 0, max = 20, decimals = 0 })
ax.config:Add("recognition_yell_bonus",       ax.type.number, 1,                      { category = "recognition", description = "Bonus score per yell heard.", min = 0, max = 20, decimals = 0 })
ax.config:Add("recognition_decay_days",       ax.type.number, 7,                      { category = "recognition", description = "Days of inactivity before score decay begins. Set to 0 to disable.", min = 0, max = 365, decimals = 0 })
ax.config:Add("recognition_decay_amount",     ax.type.number, 10,                     { category = "recognition", description = "Score lost per daily decay cycle.", min = 1, max = 100, decimals = 0 })
ax.config:Add("recognition_unknown_colour",   ax.type.color,  Color(150, 150, 150),   { category = "recognition", description = "Colour used on nameplates and in chat for unrecognised characters." })

--- Register the per-character familiarity data blob.
-- Stored as a nested table keyed by target character ID:
--   { [targetCharID] = { score = number, alias = string|nil, lastSeen = number } }
-- The `ax.type.data` field type serialises the entire table as JSON in one DB column.
ax.character:RegisterVar("familiarity", {
    default   = {},
    field     = "familiarity",
    fieldType = ax.type.data,
    bNoGetter = false,
    bNoSetter = false,
})

--- Admin command: set familiarity score between two characters.
-- Usage: /SetFamiliarity <player> <score>
-- Sets the score from the command executor's active character toward the target's character.
ax.command:Add("SetFamiliarity", {
    description = "Set your active character's familiarity score toward a target player's character.",
    adminOnly   = true,
    arguments   = {
        { name = "player", type = ax.type.player },
        { name = "score",  type = ax.type.number },
    },
    OnRun = function(def, client, target, score)
        if ( !ax.util:IsValidPlayer(client) ) then return false, ax.localization:GetPhrase("recognition.command.invalid_executor") end

        local char = client:GetCharacter()
        if ( !char ) then return false, ax.localization:GetPhrase("recognition.command.no_character") end

        if ( !ax.util:IsValidPlayer(target) ) then return false, ax.localization:GetPhrase("recognition.command.invalid_target") end

        local targetChar = target:GetCharacter()
        if ( !targetChar ) then return false, ax.localization:GetPhrase("recognition.command.target_no_character") end

        ax.recognition:AdminSetFamiliarity(client, char:GetID(), targetChar:GetID(), score)
    end
})

--- Admin command: view familiarity data for a target player's character.
-- Prints the target's true name and the familiarity record the target holds toward
-- the executor's active character.
-- Usage: /ViewFamiliarity <player>
ax.command:Add("ViewFamiliarity", {
    description = "View a player's true character name and their familiarity record toward your character.",
    adminOnly   = true,
    arguments   = {
        { name = "player", type = ax.type.player },
    },
    OnRun = function(def, client, target)
        if ( !ax.util:IsValidPlayer(client) ) then return false, ax.localization:GetPhrase("recognition.command.invalid_executor") end

        local char = client:GetCharacter()
        if ( !char ) then return false, ax.localization:GetPhrase("recognition.command.no_character") end

        if ( !ax.util:IsValidPlayer(target) ) then return false, ax.localization:GetPhrase("recognition.command.invalid_target") end

        local targetChar = target:GetCharacter()
        if ( !targetChar ) then return false, ax.localization:GetPhrase("recognition.command.target_no_character") end

        local charID = char:GetID()
        local record = ax.recognition:GetRecord(targetChar, charID)

        local trueName = targetChar:GetName()
        local score    = istable(record) and (record.score or 0) or 0
        local alias    = istable(record) and record.alias or ax.localization:GetPhrase("recognition.admin.alias_none")
        local tier     = ax.recognition:GetTier(score)

        local tierPhraseKeys = {
            "recognition.tier.stranger",
            "recognition.tier.seen",
            "recognition.tier.acquainted",
            "recognition.tier.known",
            "recognition.tier.trusted",
        }
        local tierLabel = ax.localization:GetPhrase(tierPhraseKeys[tier + 1] or "unknown")

        local lines = {
            ax.localization:GetPhrase("recognition.admin.view.header", target:SteamName(), target:SteamID()),
            ax.localization:GetPhrase("recognition.admin.view.true_name", trueName),
            ax.localization:GetPhrase("recognition.admin.view.toward_you", score, tierLabel, alias),
        }

        for _, line in ipairs(lines) do
            ax.util:PrintDebug(line)
            client:ChatPrint(line)
        end
    end
})
