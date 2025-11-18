local ENTITY = FindMetaTable("Entity")

local MODEL_CHAIRS = {}
for _, v in pairs( list.Get( "Vehicles" ) ) do
    if ( v.Category == "Chairs" and v.Model ) then
        MODEL_CHAIRS[string.lower(v.Model)] = true
    end
end

function ENTITY:IsChair()
    local model = string.lower( self:GetModel() or "" )
    return MODEL_CHAIRS[model]
end

function ENTITY:RateLimit(name, delay)
    local data = self:GetTable()

    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("Invalid rate limit name provided to ENTITY:RateLimit()")
        return false
    end

    if ( !isnumber(delay) or delay <= 0 ) then
        ax.util:PrintError("Invalid rate limit delay provided to ENTITY:RateLimit()")
        return false
    end

    if ( !data.axRateLimits ) then data.axRateLimits = {} end

    local curTime = CurTime()

    if ( data.axRateLimits[name] and data.axRateLimits[name] > curTime ) then
        return false, data.axRateLimits[name] - curTime -- Rate limit exceeded.
    end

    data.axRateLimits[name] = curTime + delay

    return true -- Rate limit passed.
end

function ENTITY:ResetRateLimit(name)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("Invalid rate limit name provided to ENTITY:ResetRateLimit()")
        return false
    end

    local data = self:GetTable()
    if ( !data.axRateLimits ) then return true end

    data.axRateLimits[name] = nil
    return true
end

--- Emit a sequence of sounds in order, similar to Entity:EmitSound but queued.
-- @param soundNames Table of sound file names (strings).
-- @param soundLevel (Optional) Sound level (default: 75).
-- @param pitchPercent (Optional) Pitch percentage (default: 100).
-- @param volume (Optional) Volume scalar (default: 1).
-- @param channel (Optional) Channel to emit on, e.g., CHAN_AUTO (default).
-- @param soundFlags (Optional) EmitSound flags (default: 0).
-- @param dsp (Optional) DSP preset (default: 0).
-- @param filter (Optional) CRecipientFilter to restrict who hears it.
function ENTITY:EmitQueuedSound(soundNames, soundLevel, pitchPercent, volume, channel, soundFlags, dsp, filter)
    soundLevel = soundLevel or 75
    pitchPercent = pitchPercent or 100
    volume = volume or 1
    channel = channel or CHAN_AUTO
    soundFlags = soundFlags or 0
    dsp = dsp or 0

    if ( !istable(soundNames) ) then
        self:PrintError("EmitQueuedSound expected table of sound names.")
        return
    end

    local ent = self
    local delay = 0
    local totalDuration = 0

    for _, snd in ipairs(soundNames) do
        local duration = SoundDuration(snd) or 0
        duration = duration + 0.1 -- small buffer to prevent clipping
        totalDuration = totalDuration + duration

        timer.Simple(delay, function()
            if ( !IsValid(ent) ) then return end

            ent:EmitSound(snd, soundLevel, pitchPercent, volume, channel, soundFlags, dsp, filter)
        end)

        delay = delay + duration
    end

    return totalDuration
end

if ( SERVER ) then
    function ENTITY:IsLocked()
        if ( self:IsVehicle() ) then
            return self:GetInternalVariable( "VehicleLocked" )
        else
            return self:GetInternalVariable( "m_bLocked" )
        end

        return false
    end

    function ENTITY:GetDoorPartner()
        if ( self:GetClass() != "prop_door_rotating" ) then return NULL end

        return self:GetInternalVariable( "m_hMaster" )
    end
end
