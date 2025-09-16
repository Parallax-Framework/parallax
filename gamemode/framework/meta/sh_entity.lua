local ENTITY = FindMetaTable("Entity")

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