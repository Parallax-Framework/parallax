function ax.player.meta:IsFemale()
    local modelClass = ax.animations:GetModelClass(self:GetModel())
    if ( !isstring(modelClass) or modelClass == "" ) then
        return false
    end

    if ( ax.util:FindString(modelClass, "female") ) then
        return true
    end

    return false
end

function ax.player.meta:GetHoldType()
    if ( !IsValid(self) ) then return "normal" end

    local weapon = self:GetActiveWeapon()
    if ( !IsValid(weapon) ) then return "normal" end

    local holdType = weapon:GetHoldType()
    if ( !holdType ) then return "normal" end

    -- Check for hooks that may modify the hold type
    local hookedHoldType = hook.Run("GetPlayerHoldType", self, weapon, holdType)
    if ( isstring(hookedHoldType) ) then
        return hookedHoldType
    end

    return HOLDTYPE_TRANSLATOR[holdType] or holdType
end

if ( SERVER ) then
    ax.animations.forcedSequenceCallbacks = ax.animations.forcedSequenceCallbacks or {}

    function ax.player.meta:LeaveSequence()
        local prevent = hook.Run("PrePlayerLeaveSequence", self)
        if ( prevent != nil and prevent == false ) then return end

        net.Start("ax.sequence.reset")
            net.WritePlayer(self)
        net.Broadcast()

        local callback = ax.animations.forcedSequenceCallbacks[self:SteamID64()]
        ax.animations.forcedSequenceCallbacks[self:SteamID64()] = nil

        self:SetRelay("sequence.forced", nil)
        self:SetMoveType(MOVETYPE_WALK)

        if ( isfunction(callback) ) then
            callback(self)
        end

        hook.Run("PostPlayerLeaveSequence", self)
    end

    function ax.player.meta:ForceSequence(sequence, callback, time, noFreeze)
        local prevent = hook.Run("PrePlayerForceSequence", self, sequence, callback, time, noFreeze)
        if ( prevent != nil and prevent == false ) then return end

        if ( sequence == nil ) then
            net.Start("ax.sequence.reset")
                net.WritePlayer(self)
            net.Broadcast()

            return
        end

        local sequenceID = self:LookupSequence(sequence)
        if ( sequenceID == -1 ) then
            ax.util:PrintError("Invalid sequence \"" .. sequence .. "\"!")
            return
        end

        local sequenceTime = isnumber(time) and time or self:SequenceDuration(sequenceID)

        self:SetCycle(0)
        self:SetPlaybackRate(1)
        self:SetRelay("sequence.forced", sequenceID)

        ax.animations.forcedSequenceCallbacks[self:SteamID64()] = callback or nil

        if ( !noFreeze ) then
            self:SetMoveType(MOVETYPE_NONE)
        end

        if ( sequenceTime > 0 ) then
            timer.Create("ax.sequence." .. self:SteamID64(), sequenceTime, 1, function()
                self:LeaveSequence()
            end)

            return sequenceTime
        end

        hook.Run("PostPlayerForceSequence", self, sequence, callback, time, noFreeze)
    end
end
