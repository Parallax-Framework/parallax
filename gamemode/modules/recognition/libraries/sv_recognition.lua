--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Server-side recognition logic: proximity ticks, chat bonuses, introductions, decay, and admin tools.
-- @module ax.recognition (server extension)

CAMI.RegisterPrivilege({
    Name = "Parallax - Recognition",
    MinAccess = "admin",
    Description = "Allows management of character familiarity records.",
})

--- Award familiarity score from `client`'s character toward `targetClient`'s character, and vice versa.
-- Fires tier-crossing hooks when the score crosses a threshold boundary.
-- Networking is sent only to the respective character owners.
-- @realm server
-- @param client Player The first player
-- @param char table The first player's character
-- @param targetClient Player The second player
-- @param targetChar table The second player's character
-- @param amount number Score to add (both directions)
local function AwardScore(client, char, targetClient, targetChar, amount)
    local charID = char:GetID()
    local targetID = targetChar:GetID()

    -- Never award score between a player and their own character.
    if ( charID == targetID ) then return end

    local function ApplyGain(owner, ownerChar, otherClient, otherCharID, delta)
        local familiarity = ax.character:GetVar(ownerChar, "familiarity")
        if ( !istable(familiarity) ) then familiarity = {} end

        -- Keys are stored as strings after the JSON-round-trip fix; try both forms.
        local record = familiarity[tostring(otherCharID)] or familiarity[otherCharID]
        if ( !istable(record) ) then
            record = { score = 0, alias = nil, lastSeen = 0 }
        end

        local oldScore = record.score or 0
        local oldTier = ax.recognition:GetTier(oldScore)

        record.score = math.min(2000, oldScore + delta)
        record.lastSeen = os.time()

        ax.character:SetVar(ownerChar, "familiarity", tostring(otherCharID), {
            dataValue  = record,
            recipients = owner,
        })

        local newTier = ax.recognition:GetTier(record.score)
        if ( newTier == oldTier ) then return end

        hook.Run("OnFamiliarityChanged", owner, otherClient, oldTier, newTier)

        if ( newTier >= ax.recognition.TIERS.KNOWN and oldTier < ax.recognition.TIERS.KNOWN ) then
            hook.Run("OnCharacterKnown", owner, otherClient)
        end

        if ( newTier >= ax.recognition.TIERS.TRUSTED and oldTier < ax.recognition.TIERS.TRUSTED ) then
            hook.Run("OnCharacterTrusted", owner, otherClient)
        end
    end

    ApplyGain(client, char, targetClient, targetID, amount)
    ApplyGain(targetClient, targetChar, client, charID, amount)
end

--- Perform a proximity familiarity tick for a single player.
-- Checks all nearby players using the IC chat hear distance and awards passive score.
-- @realm server
-- @param client Player The player to process
local function HandleProximityTick(client)
    if ( !ax.util:IsValidPlayer(client) or !client:Alive() ) then return end

    local clientTable = client:GetTable()
    local interval = tonumber(ax.config:Get("recognition_tick_interval", 3)) or 3

    if ( clientTable.axRecogNextTick and clientTable.axRecogNextTick > CurTime() ) then return end
    clientTable.axRecogNextTick = CurTime() + interval

    local char = client:GetCharacter()
    if ( !char ) then return end

    local icChat = ax.chat.registry["ic"]
    if ( !istable(icChat) ) then return end

    local passiveGain = tonumber(ax.config:Get("recognition_passive_gain", 1)) or 1

    for _, target in ipairs(player.GetAll()) do
        if ( target == client or !ax.util:IsValidPlayer(target) or !target:Alive() ) then continue end

        if ( !icChat:CanHear(client, target) ) then continue end

        local targetChar = target:GetCharacter()
        if ( !targetChar ) then continue end

        AwardScore(client, char, target, targetChar, passiveGain)
    end
end

hook.Add("PlayerThink", "ax.recognition.ProximityTick", HandleProximityTick)

--- Apply chat interaction bonus score when a player sends an IC message.
-- Bonus is awarded between the speaker and every player who can hear the message.
-- @realm server
local function HandleChatBonus(speaker, chatType, rawText, text, receivers, data)
    if ( !ax.util:IsValidPlayer(speaker) ) then return end

    local bonus = 0

    if ( chatType == "ic" ) then
        bonus = tonumber(ax.config:Get("recognition_ic_bonus", 3)) or 3
    elseif ( chatType == "whisper" ) then
        bonus = tonumber(ax.config:Get("recognition_whisper_bonus", 5)) or 5
    elseif ( chatType == "yell" ) then
        bonus = tonumber(ax.config:Get("recognition_yell_bonus", 1)) or 1
    end

    if ( bonus <= 0 or !istable(receivers) ) then return end

    local char = speaker:GetCharacter()
    if ( !char ) then return end

    for _, receiver in ipairs(receivers) do
        if ( receiver == speaker or !ax.util:IsValidPlayer(receiver) ) then continue end

        local targetChar = receiver:GetCharacter()
        if ( !targetChar ) then continue end

        AwardScore(speaker, char, receiver, targetChar, bonus)
    end
end

hook.Add("PlayerMessageSend", "ax.recognition.ChatBonus", HandleChatBonus)

--- Record that `client` has introduced themselves to `targetClient` using `alias`.
-- Floors the score to ACQUAINTED if currently below, then stores the alias.
-- Only the client's own familiarity record is updated; the alias is theirs to give.
-- @realm server
-- @param client Player The player performing the introduction
-- @param targetClient Player The player being introduced to
-- @param alias string The name the client is presenting (1–48 characters)
function ax.recognition:Introduce(client, targetClient, alias)
    if ( !ax.util:IsValidPlayer(client) or !ax.util:IsValidPlayer(targetClient) ) then return end

    alias = isstring(alias) and string.Trim(alias) or ""
    if ( #alias < 1 or #alias > 48 ) then
        client:Notify("recognition.notify.alias_invalid_length")
        return
    end

    local char = client:GetCharacter()
    if ( !char ) then return end

    local targetChar = targetClient:GetCharacter()
    if ( !targetChar ) then return end

    local clientID = char:GetID()

    -- The alias is stored in TARGET's familiarity record for CLIENT.
    -- TARGET is the perceiver; they now know CLIENT by the given alias.
    local targetFamiliarity = ax.character:GetVar(targetChar, "familiarity")
    if ( !istable(targetFamiliarity) ) then targetFamiliarity = {} end

    local record = targetFamiliarity[clientID]
    if ( !istable(record) ) then
        record = { score = 0, alias = nil, lastSeen = 0 }
    end

    -- Floor to ACQUAINTED so the alias is immediately visible to the target.
    local floor = ax.recognition.THRESHOLDS[ax.recognition.TIERS.ACQUAINTED + 1] or 500
    if ( (record.score or 0) < floor ) then
        record.score = floor
    end

    record.alias = alias
    record.lastSeen = os.time()

    ax.character:SetVar(targetChar, "familiarity", tostring(clientID), {
        dataValue  = record,
        recipients = targetClient,
    })

    -- Notify the target using only the alias — never the introducer's real name.
    ax.net:Start(targetClient, "recognition.introduced_notify", alias)

    hook.Run("OnCharacterIntroduced", client, targetClient, alias)

    ax.util:PrintDebug("[Recognition] " .. client:Nick() .. " introduced as '" .. alias .. "' to " .. targetClient:Nick())
end

--- Directly set the familiarity score between two characters (admin tool).
-- Score is clamped to 0–2000 and saved immediately. Fires `OnFamiliarityChanged` if the
-- tier changes. Requires the CAMI privilege "Parallax - Recognition".
-- @realm server
-- @param admin Player The admin executing the change
-- @param charID number The character whose record is being modified
-- @param targetID number The target character ID
-- @param score number The new raw score to set
function ax.recognition:AdminSetFamiliarity(admin, charID, targetID, score)
    if ( !ax.util:IsValidPlayer(admin) ) then return end

    CAMI.PlayerHasAccess(admin, "Parallax - Recognition", function(bHasAccess)
        if ( !bHasAccess ) then
            admin:Notify("recognition.notify.no_permission")
            return
        end

        local char = ax.character:Get(charID)
        if ( !istable(char) ) then
            admin:Notify(ax.localization:GetPhrase("recognition.notify.char_not_loaded", charID))
            return
        end

        score = math.Clamp(math.floor(tonumber(score) or 0), 0, 2000)

        local familiarity = ax.character:GetVar(char, "familiarity")
        if ( !istable(familiarity) ) then familiarity = {} end

        local record = familiarity[tostring(targetID)] or familiarity[targetID]
        if ( !istable(record) ) then
            record = { score = 0, alias = nil, lastSeen = 0 }
        end

        local oldTier = ax.recognition:GetTier(record.score or 0)
        record.score = score
        record.lastSeen = os.time()

        local owner = char.player
        ax.character:SetVar(char, "familiarity", tostring(targetID), {
            dataValue  = record,
            recipients = ax.util:IsValidPlayer(owner) and owner or nil,
        })

        local newTier = ax.recognition:GetTier(score)
        if ( newTier != oldTier and ax.util:IsValidPlayer(owner) ) then
            local targetChar = ax.character:Get(targetID)
            local targetOwner = istable(targetChar) and targetChar.player or nil
            hook.Run("OnFamiliarityChanged", owner, targetOwner, oldTier, newTier)
        end

        ax.util:PrintDebug(
            "[Recognition] Admin " .. admin:Nick() .. " set char " .. charID ..
            " familiarity toward " .. targetID .. " to " .. score
        )

        admin:Notify(ax.localization:GetPhrase("recognition.notify.set_success", charID, targetID, score))
    end)
end

--- Clear the in-memory next-tick timestamp when a character is unloaded.
-- @realm server
local function HandlePlayerUnloadedCharacter(client, character)
    if ( !ax.util:IsValidPlayer(client) ) then return end
    client:GetTable().axRecogNextTick = nil
end

hook.Add("PlayerUnloadedCharacter", "ax.recognition.Cleanup", HandlePlayerUnloadedCharacter)

--- Daily decay timer: reduce familiarity scores for characters that have not been seen recently.
-- Pruned records (score 0, no alias) are removed to keep the data payload small.
-- Decay is skipped entirely when `recognition_decay_days` is 0.
-- @realm server
local DECAY_TIMER = "ax.recognition.Decay"

local function RunDecay()
    local decayDays = tonumber(ax.config:Get("recognition_decay_days", 7)) or 7
    if ( decayDays <= 0 ) then return end

    local decayAmount  = tonumber(ax.config:Get("recognition_decay_amount", 10)) or 10
    local decayCutoff  = os.time() - (decayDays * 86400)

    for _, char in pairs(ax.character.instances) do
        if ( !istable(char) ) then continue end

        local familiarity = ax.character:GetVar(char, "familiarity")
        if ( !istable(familiarity) ) then continue end

        local owner = char.player
        local bDirty = false

        for targetID, record in pairs(familiarity) do
            if ( !istable(record) ) then continue end

            local lastSeen = record.lastSeen or 0
            if ( lastSeen >= decayCutoff ) then continue end

            local newScore = math.max(0, (record.score or 0) - decayAmount)
            record.score = newScore

            if ( newScore <= 0 and !isstring(record.alias) ) then
                familiarity[tostring(targetID)] = nil
                familiarity[tonumber(targetID)] = nil
            end

            bDirty = true
        end

        if ( bDirty ) then
            -- GetVar for ax.type.data returns a direct reference, so the in-place
            -- mutations above have already updated char.vars["familiarity"]. We only
            -- need to push the serialised blob to the database; no networking for decay.
            local query = mysql:Update("ax_characters")
                query:Where("id", char:GetID())
                query:Update("familiarity", util.TableToJSON(familiarity))
                query:Callback(function(result)
                    if ( result == false ) then
                        ax.util:PrintError("[Recognition] Failed to persist decay for char " .. char:GetID())
                    end
                end)
            query:Execute()
        end
    end

    ax.util:PrintDebug("[Recognition] Decay pass complete.")
end

local DECAY_INTERVAL_SECONDS = 86400 -- 24 hours
timer.Create(DECAY_TIMER, DECAY_INTERVAL_SECONDS, 0, RunDecay)
