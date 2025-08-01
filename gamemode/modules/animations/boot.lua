local MODULE = MODULE

MODULE.Name = "Animations"
MODULE.Description = "Handles player animations."
MODULE.Author = "Riggs"

local meta = FindMetaTable("Player")
local IsFemaleInternal = IsFemaleInternal or meta.IsFemale

function meta:IsFemale()
    local modelClass = ax.animations:GetModelClass(self:GetModel())
    if ( !isstring(modelClass) or modelClass == "" ) then
        return IsFemaleInternal(self)
    end

    if ( ax.util:FindString(modelClass, "female") ) then
        return true
    end

    return IsFemaleInternal(self)
end

if ( SERVER ) then
    function meta:LeaveSequence()
        local prevent = hook.Run("PrePlayerLeaveSequence", self)
        if ( prevent != nil and prevent == false ) then return end

        net.Start("ax.sequence.reset")
            net.WritePlayer(self)
        net.Broadcast()

        self:SetRelay("sequence.callback", nil)
        self:SetRelay("sequence.forced", nil)
        self:SetMoveType(MOVETYPE_WALK)

        local callback = self:GetRelay("sequence.callback")
        if ( isfunction(callback) ) then
            callback(self)
        end

        hook.Run("PostPlayerLeaveSequence", self)
    end

    function meta:ForceSequence(sequence, callback, time, noFreeze)
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
        self:SetRelay("sequence.callback", callback or nil)

        if ( !noFreeze ) then
            self:SetMoveType(MOVETYPE_NONE)
        end

        if ( sequenceTime > 0 ) then
            timer.Create("ax.Sequence." .. self:SteamID64(), sequenceTime, 1, function()
                self:LeaveSequence()
            end)

            return sequenceTime
        end

        hook.Run("PostPlayerForceSequence", self, sequence, callback, time, noFreeze)
    end
end
