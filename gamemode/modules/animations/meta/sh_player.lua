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

if ( SERVER ) then
    ax.animations.forcedSequenceCallbacks = ax.animations.forcedSequenceCallbacks or {}

    function ax.player.meta:LeaveSequence()
        local prevent = hook.Run("PrePlayerLeaveSequence", self)
        if ( prevent != nil and prevent == false ) then return end

        ax.net:Start(nil, "sequence.reset", self)

        local callback = ax.animations.forcedSequenceCallbacks[self:SteamID64()]

        timer.Remove("ax.sequence." .. self:SteamID64())

        self:SetRelay("sequence.id", nil)
        self:SetRelay("sequence.identifier", nil)
        self:SetRelay("sequence.looping", nil)
        self:SetRelay("sequence.frozen", nil)
        self.axSequenceCancelPrimed = nil

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
            ax.net:Start(nil, "sequence.reset", self)
            ax.util:PrintDebug("ForceSequence called with nil sequence for player " .. self:Name() .. ", treating as reset.")
            return
        end

        local sequenceID = self:LookupSequence(sequence)
        if ( sequenceID == -1 ) then
            ax.util:PrintError("Invalid sequence \"" .. sequence .. "\"!")
            return
        end

        local sequenceTime = isnumber(time) and math.max(time, 0) or self:SequenceDuration(sequenceID)
        local isLooping = sequenceTime == 0

        timer.Remove("ax.sequence." .. self:SteamID64())

        self:SetCycle(0)
        self:SetPlaybackRate(1)
        self:SetRelay("sequence.frozen", noFreeze and true or nil)
        self:SetRelay("sequence.id", sequenceID)
        self:SetRelay("sequence.identifier", sequence)
        self:SetRelay("sequence.looping", isLooping and true or nil)
        self.axSequenceCancelPrimed = isLooping and false or nil

        ax.animations.forcedSequenceCallbacks[self:SteamID64()] = callback or nil

        if ( sequenceTime > 0 ) then
            timer.Create("ax.sequence." .. self:SteamID64(), sequenceTime, 1, function()
                self:LeaveSequence()

                ax.util:PrintDebug("Player " .. self:Name() .. " has been automatically removed from forced sequence \"" .. sequence .. "\" after " .. string.NiceTime(sequenceTime) .. ".")
            end)

            ax.util:PrintDebug("Player " .. self:Name() .. " will be forced into sequence \"" .. sequence .. "\" for " .. string.NiceTime(sequenceTime) .. ".")

            return sequenceTime
        end

        ax.util:PrintDebug("Player " .. self:Name() .. " will remain in forced sequence \"" .. sequence .. "\" until they cancel it.")

        hook.Run("PostPlayerForceSequence", self, sequence, callback, time, noFreeze)

        return sequenceTime
    end
end

hook.Add("StartCommand", "ax.animations.preventMovementDuringSequence", function(client, userCmd)
    if ( !ax.util:IsValidPlayer(client) ) then return end
    if ( !client:GetRelay("sequence.id") ) then return end

    -- Prevent movement and actions during a forced sequence
    userCmd:ClearMovement()
    userCmd:RemoveKey(IN_JUMP)
end)

hook.Add("StartCommand", "ax.animations.cancelLoopSequence", function(client, userCmd)
    if ( !ax.util:IsValidPlayer(client) ) then return end
    local buttons = bit.band(userCmd:GetButtons(), LOOP_CANCEL_BUTTONS)
    if ( !client:GetRelay("sequence.looping") or !client:GetRelay("sequence.id") ) then return end

    local isTryingToCancel = buttons != 0 or userCmd:GetForwardMove() != 0 or userCmd:GetSideMove() != 0

    if ( !client.axSequenceCancelPrimed ) then
        if ( isTryingToCancel ) then return end

        client.axSequenceCancelPrimed = true
        return
    end

    if ( !isTryingToCancel or CLIENT ) then return end

    client:LeaveSequence()
end)
