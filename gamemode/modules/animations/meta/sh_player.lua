--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

function ax.player.meta:IsFemale()
    local modelClass = ax.animations:GetModelClass(self:GetModel())
    if ( !isstring(modelClass) or modelClass == "" ) then return false end

    if ( ax.util:FindString(modelClass, "female") ) then
        return true
    end

    return false
end

function ax.player.meta:GetHoldType()
    if ( !ax.util:IsValidPlayer(self) ) then return "normal" end

    local weapon = self:GetActiveWeapon()
    if ( type(weapon) != "Weapon" ) then return "normal" end

    local holdType = weapon:GetHoldType()
    if ( !holdType ) then return "normal" end

    -- Check for the weapon defining a custom hold type through a method
    if ( isfunction(weapon.GetCustomHoldType) ) then
        local customHoldType = weapon:GetCustomHoldType(self)
        if ( isstring(customHoldType) ) then
            return customHoldType
        end
    end

    -- Check for hooks that may modify the hold type
    local hookedHoldType = hook.Run("GetPlayerHoldType", self, weapon, holdType)
    if ( isstring(hookedHoldType) ) then
        return hookedHoldType
    end

    return HOLDTYPE_TRANSLATOR[holdType] or holdType
end

local LOOP_CANCEL_BUTTONS = bit.bor(IN_JUMP, IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT)
local FORCED_SEQUENCE_RESOLVE_TIMEOUT = 2

local function GetForcedSequenceTimerName(client)
    return "ax.sequence." .. client:SteamID64()
end

local function GetForcedSequenceResolveTimerName(client)
    return "ax.sequence.resolve." .. client:SteamID64()
end

if ( CLIENT ) then
    function ax.player.meta:ClearForcedSequenceResolution()
        local clientTable = self:GetTable()
        clientTable.axForcedSequence = nil

        self:SetRelay("sequence.id", nil, true)
    end

    function ax.player.meta:ResolveForcedSequence(sequence)
        sequence = sequence != nil and sequence or self:GetRelay("sequence.identifier")
        if ( sequence == nil ) then
            self:ClearForcedSequenceResolution()
            return nil, 0
        end

        local clientTable = self:GetTable()
        local model = tostring(self:GetModel() or "")
        local cacheKey = tostring(sequence) .. "::" .. model
        local cached = clientTable.axForcedSequence
        if ( istable(cached) and cached.key == cacheKey ) then
            self:SetRelay("sequence.id", cached.id, true)
            return cached.id, cached.duration
        end

        local sequenceID = -1
        if ( isnumber(sequence) ) then
            sequenceID = math.floor(sequence)
        elseif ( isstring(sequence) and sequence != "" ) then
            sequenceID = self:LookupSequence(sequence)
            if ( sequenceID == -1 ) then
                local lower = ( utf8 and utf8.lower ) or string.lower
                local lowered = lower(sequence)
                if ( lowered != sequence ) then
                    sequenceID = self:LookupSequence(lowered)
                end
            end
        end

        local duration = sequenceID >= 0 and math.max(self:SequenceDuration(sequenceID), 0) or 0
        local resolvedID = sequenceID >= 0 and sequenceID or nil

        clientTable.axForcedSequence = {
            key = cacheKey,
            id = resolvedID,
            duration = duration
        }

        self:SetRelay("sequence.id", resolvedID, true)

        return resolvedID, duration
    end
else
    function ax.player.meta:ClearForcedSequenceResolution()
    end

    function ax.player.meta:ResolveForcedSequence(sequence)
        return nil, 0
    end
end

if ( SERVER ) then
    ax.animations.forcedSequenceCallbacks = ax.animations.forcedSequenceCallbacks or {}
    ax.animations.forcedSequencePending = ax.animations.forcedSequencePending or {}

    function ax.animations:ClearForcedSequencePending(client)
        if ( !ax.util:IsValidPlayer(client) ) then return end

        self.forcedSequencePending[client:SteamID64()] = nil
        timer.Remove(GetForcedSequenceResolveTimerName(client))
    end

    function ax.animations:ApplyForcedSequenceTiming(client, sequence, sequenceTime)
        if ( !ax.util:IsValidPlayer(client) ) then
            return 0
        end

        sequenceTime = math.max(tonumber(sequenceTime) or 0, 0)

        timer.Remove(GetForcedSequenceTimerName(client))
        timer.Remove(GetForcedSequenceResolveTimerName(client))

        local isLooping = sequenceTime == 0
        client:SetRelay("sequence.looping", isLooping and true or nil)
        client.axSequenceCancelPrimed = isLooping and false or nil

        if ( sequenceTime > 0 ) then
            timer.Create(GetForcedSequenceTimerName(client), sequenceTime, 1, function()
                if ( !ax.util:IsValidPlayer(client) ) then return end

                client:LeaveSequence()

                ax.util:PrintDebug("Player " .. client:Name() .. " has been automatically removed from forced sequence \"" .. tostring(sequence) .. "\" after " .. string.NiceTime(sequenceTime) .. ".")
            end)

            ax.util:PrintDebug("Player " .. client:Name() .. " will be forced into sequence \"" .. tostring(sequence) .. "\" for " .. string.NiceTime(sequenceTime) .. ".")
            return sequenceTime
        end

        ax.util:PrintDebug("Player " .. client:Name() .. " will remain in forced sequence \"" .. tostring(sequence) .. "\" until they cancel it.")

        return sequenceTime
    end

    function ax.animations:ResolveForcedSequencePending(client, serial, sequenceTime)
        if ( !ax.util:IsValidPlayer(client) ) then
            return false, "Invalid player."
        end

        local pending = self.forcedSequencePending[client:SteamID64()]
        if ( !istable(pending) ) then
            return false, "No pending forced sequence resolve."
        end

        if ( pending.serial != serial ) then
            return false, "Stale forced sequence resolve."
        end

        if ( client:GetRelay("sequence.identifier") != pending.identifier ) then
            return false, "Forced sequence changed before resolve completed."
        end

        self.forcedSequencePending[client:SteamID64()] = nil

        return true, self:ApplyForcedSequenceTiming(client, pending.identifier, sequenceTime)
    end

    function ax.player.meta:LeaveSequence()
        local prevent = hook.Run("PrePlayerLeaveSequence", self)
        if ( prevent != nil and prevent == false ) then return end

        local callback = ax.animations.forcedSequenceCallbacks[self:SteamID64()]

        timer.Remove(GetForcedSequenceTimerName(self))
        timer.Remove(GetForcedSequenceResolveTimerName(self))

        self:SetRelay("sequence.id", nil)
        self:SetRelay("sequence.identifier", nil)
        self:SetRelay("sequence.looping", nil)
        self:SetRelay("sequence.frozen", nil)
        self:SetRelay("sequence.serial", nil)
        self.axSequenceCancelPrimed = nil

        ax.animations:ClearForcedSequencePending(self)
        ax.net:Start(nil, "sequence.reset", self)

        if ( isfunction(callback) ) then
            callback(self)
        end

        ax.animations.forcedSequenceCallbacks[self:SteamID64()] = nil

        hook.Run("PostPlayerLeaveSequence", self)
    end

    function ax.player.meta:ForceSequence(sequence, callback, time, noFreeze)
        local prevent = hook.Run("PrePlayerForceSequence", self, sequence, callback, time, noFreeze)
        if ( prevent != nil and prevent == false ) then
            ax.util:PrintDebug("ForceSequence was prevented by a hook for player " .. self:Name() .. "!")
            return
        end

        if ( sequence == nil ) then
            self:LeaveSequence()
            ax.util:PrintDebug("ForceSequence called with nil sequence for player " .. self:Name() .. ", treating as reset.")
            return
        end

        if ( !isstring(sequence) and !isnumber(sequence) ) then
            ax.util:PrintError("Invalid sequence provided to ForceSequence: " .. tostring(sequence))
            return
        end

        local sequenceTime = isnumber(time) and math.max(time, 0) or nil
        local steamID64 = self:SteamID64()
        local serial = (tonumber(self.axForcedSequenceSerial) or 0) + 1
        self.axForcedSequenceSerial = serial

        timer.Remove(GetForcedSequenceTimerName(self))
        timer.Remove(GetForcedSequenceResolveTimerName(self))
        ax.animations:ClearForcedSequencePending(self)

        self:SetCycle(0)
        self:SetPlaybackRate(1)
        self:SetRelay("sequence.frozen", noFreeze and true or nil)
        self:SetRelay("sequence.id", nil)
        self:SetRelay("sequence.identifier", sequence)
        self:SetRelay("sequence.looping", nil)
        self:SetRelay("sequence.serial", serial)
        self.axSequenceCancelPrimed = nil

        ax.animations.forcedSequenceCallbacks[steamID64] = callback or nil

        if ( sequenceTime != nil ) then
            ax.animations:ApplyForcedSequenceTiming(self, sequence, sequenceTime)
        else
            ax.animations.forcedSequencePending[steamID64] = {
                identifier = sequence,
                serial = serial
            }

            timer.Create(GetForcedSequenceResolveTimerName(self), FORCED_SEQUENCE_RESOLVE_TIMEOUT, 1, function()
                local pending = ax.animations.forcedSequencePending[steamID64]
                if ( !istable(pending) or pending.serial != serial ) then return end
                if ( !ax.util:IsValidPlayer(self) ) then return end

                ax.util:PrintWarning("Timed out waiting for client-authoritative resolve of forced sequence \"" .. tostring(sequence) .. "\" for player " .. self:Name() .. ".")
                self:LeaveSequence()
            end)

            ax.util:PrintDebug("Waiting for client-authoritative resolve of forced sequence \"" .. tostring(sequence) .. "\" for player " .. self:Name() .. ".")
        end

        ax.net:Start(nil, "sequence.set", self, sequence, serial)

        hook.Run("PostPlayerForceSequence", self, sequence, callback, time, noFreeze)

        return sequenceTime
    end
end

hook.Add("StartCommand", "ax.animations.preventMovementDuringSequence", function(client, userCmd)
    if ( !ax.util:IsValidPlayer(client) ) then return end
    if ( client:GetRelay("sequence.identifier") == nil ) then return end

    -- Prevent movement and actions during a forced sequence
    userCmd:ClearMovement()
    userCmd:RemoveKey(IN_JUMP)
end)

hook.Add("StartCommand", "ax.animations.cancelLoopSequence", function(client, userCmd)
    if ( !ax.util:IsValidPlayer(client) ) then return end
    local buttons = bit.band(userCmd:GetButtons(), LOOP_CANCEL_BUTTONS)
    if ( !client:GetRelay("sequence.looping") or client:GetRelay("sequence.identifier") == nil ) then return end

    local isTryingToCancel = buttons != 0 or userCmd:GetForwardMove() != 0 or userCmd:GetSideMove() != 0

    if ( !client.axSequenceCancelPrimed ) then
        if ( isTryingToCancel ) then return end

        client.axSequenceCancelPrimed = true
        return
    end

    if ( !isTryingToCancel or CLIENT ) then return end

    client:LeaveSequence()
end)
