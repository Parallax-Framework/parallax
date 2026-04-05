local ENTITY = FindMetaTable("Entity")

local MODEL_CHAIRS = {}
for _, v in pairs(list.Get("Vehicles") ) do
    if ( v.Category == "Chairs" and v.Model ) then
        MODEL_CHAIRS[string.lower(v.Model)] = true
    end
end

--- Returns true if the entity's model is a chair from the Vehicles list.
-- The check is performed against a pre-built lookup table (`MODEL_CHAIRS`) populated at file load time from `list.Get("Vehicles")`, filtered to the `"Chairs"` category. Comparison is case-insensitive.
-- @realm shared
-- @return boolean True if the entity's model matches a registered chair model.
function ENTITY:IsChair()
    local model = string.lower( self:GetModel() or "" )
    return MODEL_CHAIRS[model]
end

--- Enforces a named rate limit on this entity.
-- Stores timestamps in `entity.axRateLimits[name]`. On each call:
-- - If a limit was previously set and has not yet expired, returns `false` plus the remaining cooldown time in seconds.
-- - Otherwise, records the new expiry time (`CurTime() + delay`) and returns `true`.
-- When `delay` is 0 or omitted, no timestamp is recorded and the call always returns true (one-shot check with no cooldown).
-- The rate limit state persists on the entity table across calls.
-- Prints an error and returns false when `name` is invalid.
-- @realm shared
-- @param name string A unique identifier for this rate limit (e.g. `"player.interact"`).
-- @param delay number The cooldown duration in seconds. Pass 0 or omit to perform a pass-through check with no cooldown.
-- @return boolean True if the action is allowed, false if rate-limited.
-- @return number|nil The remaining cooldown in seconds when rate-limited.
function ENTITY:RateLimit(name, delay)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("Invalid rate limit name provided to ENTITY:RateLimit()")
        return false
    end

    local data = self:GetTable()
    if ( !data.axRateLimits ) then data.axRateLimits = {} end

    local curTime = CurTime()

    if ( data.axRateLimits[name] and data.axRateLimits[name] > curTime ) then
        return false, data.axRateLimits[name] - curTime -- Rate limit exceeded.
    end

    if ( isnumber(delay) and delay > 0 ) then
        data.axRateLimits[name] = curTime + delay
    end

    return true -- Rate limit passed.
end

--- Clears a named rate limit so the next call to `RateLimit` passes immediately.
-- Removes the stored expiry timestamp for `name` from `entity.axRateLimits`.
-- Safe to call even if the limit is not set or has already expired. Returns true on success, false on invalid input.
-- @realm shared
-- @param name string The rate limit identifier to clear (must match the name used when the limit was set via `RateLimit`).
-- @return boolean True on success, false when `name` is invalid.
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

--- Emits a sequence of sounds one after another, timed by their durations.
-- Iterates `soundNames` and schedules each sound with `timer.Simple`, accumulating delays based on `SoundDuration` plus a 100 ms buffer to prevent clipping between back-to-back clips. All sounds share the same level, pitch, volume, channel, flags, DSP, and filter settings. Returns the total playback duration in seconds. The entity is validity-checked inside each timer callback — sounds that fire after the entity has been removed are silently skipped.
-- @realm shared
-- @param soundNames table An ordered array of sound file paths to play.
-- @param soundLevel number|nil Sound propagation level in dB. Default: 75.
-- @param pitchPercent number|nil Pitch as a percentage. Default: 100.
-- @param volume number|nil Volume scalar (0–1). Default: 1.
-- @param channel number|nil Sound channel constant (`CHAN_*`). Default: `CHAN_AUTO`.
-- @param soundFlags number|nil `EmitSound` flags bitmask. Default: 0.
-- @param dsp number|nil DSP preset index. Default: 0.
-- @param filter CRecipientFilter|nil Optional recipient filter to limit who hears the sounds.
-- @return number The total duration of the queued sound sequence in seconds.
-- @usage ent:EmitQueuedSound({ "vo/line1.wav", "vo/line2.wav" }, 75, 100, 1)
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
    --- Returns whether the entity is in a locked state.
    -- Reads the internal engine variable that tracks lock state: `VehicleLocked` for vehicle entities, `m_bLocked` for doors and other lockable props.
    -- @realm server
    -- @return boolean True if the entity is locked.
    function ENTITY:IsLocked()
        if ( self:IsVehicle() ) then
            return self:GetInternalVariable( "VehicleLocked" )
        end

        return self:GetInternalVariable( "m_bLocked" )
    end

    --- Returns the paired partner door for a rotating door entity.
    -- Only meaningful for `prop_door_rotating` entities. Caches the result in `selfTable.m_hPartner` after the first lookup. The search inspects `m_hMaster` on all doors of the same class to find the one that references this door as its master. Returns `NULL` when the entity is not a rotating door or no partner is found.
    -- @realm server
    -- @return Entity The partner door entity, or `NULL` if none.
    function ENTITY:GetDoorPartner()
        if ( self:GetClass() != "prop_door_rotating" ) then return NULL end

        local selfTable = self:GetTable()
        if ( IsValid(selfTable.m_hPartner) ) then
            return selfTable.m_hPartner
        end

        local doors = ents.FindByClass(self:GetClass())
        if ( doors[1] == nil ) then return NULL end

        for i = 1, #doors do
            local door = doors[i]
            if ( door == self ) then continue end

            if ( door:GetInternalVariable("m_hMaster") == self ) then
                selfTable.m_hPartner = door
                return door
            end
        end

        return NULL
    end

    --- Blasts a door open by creating a physics-enabled dummy and hiding the original.
    -- Creates a `prop_physics` clone of the door at the same position and angle, inheriting model, color, material, skin, and bodygroups. The original door entity is hidden (`SetNoDraw`, `SetNotSolid`) and fired open, while the dummy receives the specified `velocity`. After `lifeTime` seconds the dummy fades out (alpha reduced 1 per 0.1s) and is removed, restoring the original door's draw and solid state via a `CallOnRemove` callback. If the door has a partner (via `GetDoorPartner`), it is blasted recursively unless `bIgnorePartner` is true. Returns immediately for non-door entities.
    -- @realm server
    -- @param velocity Vector|nil The initial velocity applied to the dummy prop. Defaults to a random vector scaled by 100.
    -- @param lifeTime number|nil Seconds before the dummy fades out and the original door is restored. Defaults to 120.
    -- @param bIgnorePartner boolean|nil When true, the partner door is not blasted.
    -- @return Entity|nil The created dummy prop entity, or nil on failure.
    function ENTITY:BlastDoor(velocity, lifeTime, bIgnorePartner)
        if ( !self:IsDoor() ) then return end

        if ( IsValid(self.axDoorDummy) ) then
            self.axDoorDummy:Remove()
        end

        velocity = velocity or VectorRand() * 100
        lifeTime = lifeTime or 120

        local partner = self:GetDoorPartner()
        if ( IsValid(partner) and !bIgnorePartner ) then
            partner:BlastDoor(velocity, lifeTime, true)
        end

        local color = self:GetColor()

        local dummy = ents.Create("prop_physics")
        dummy:SetModel(self:GetModel())
        dummy:SetPos(self:GetPos())
        dummy:SetAngles(self:GetAngles())
        dummy:Spawn()
        dummy:SetColor(color)
        dummy:SetMaterial(self:GetMaterial())
        dummy:SetSkin(self:GetSkin() or 0)
        dummy:SetRenderMode(RENDERMODE_TRANSALPHA)
        dummy:CallOnRemove("restoreDoor", function()
            if ( IsValid(self) ) then
                self:SetNotSolid(false)
                self:SetNoDraw(false)
                self:DrawShadow(true)
                self.ignoreUse = false

                for _, v in ipairs(self:GetChildren()) do
                    v:SetNotSolid(false)
                    v:SetNoDraw(false)

                    if ( v.OnDoorRestored ) then
                        v:OnDoorRestored(self)
                    end
                end
            end
        end)
        dummy:SetOwner(self)
        dummy:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        self:Fire("unlock")
        self:Fire("open")
        self:SetNotSolid(true)
        self:SetNoDraw(true)
        self:DrawShadow(false)
        self.ignoreUse = true
        self.axDoorDummy = dummy
        self:DeleteOnRemove(dummy)

        dummy:InheritBodygroups(self)

        for _, v in ipairs(self:GetChildren()) do
            v:SetNotSolid(true)
            v:SetNoDraw(true)

            if ( v.OnDoorBlasted ) then
                v:OnDoorBlasted(self)
            end
        end

        dummy:GetPhysicsObject():SetVelocity(velocity)

        local uniqueID = "doorRestore" .. self:EntIndex()
        local uniqueID2 = "doorOpener" .. self:EntIndex()

        timer.Create(uniqueID2, 1, 0, function()
            if ( IsValid(self) and IsValid(self.axDoorDummy) ) then
                self:Fire("open")
            else
                timer.Remove(uniqueID2)
            end
        end)

        timer.Create(uniqueID, lifeTime, 1, function()
            if ( !IsValid(self) or !IsValid(dummy) ) then return end

            uniqueID = "dummyFade" .. dummy:EntIndex()
            local alpha = 255

            timer.Create(uniqueID, 0.1, 255, function()
                if ( IsValid(dummy) ) then
                    alpha = alpha - 1
                    dummy:SetColor(ColorAlpha(color, alpha))

                    if ( alpha <= 0 ) then
                        SafeRemoveEntity(dummy)
                    end
                else
                    timer.Remove(uniqueID)
                end
            end)
        end)

        return dummy
    end
end
