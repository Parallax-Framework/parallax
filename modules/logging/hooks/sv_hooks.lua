local MODULE = MODULE

function MODULE:DoPlayerDeath(client, attacker, dmginfo)
    if ( !IsValid(client) ) then return end

    local attackerName = "world"
    local weaponName = "world"

    if ( IsValid(attacker) ) then
        attackerName = self:Format(attacker)

        if ( attacker.GetActiveWeapon and IsValid(attacker:GetActiveWeapon()) ) then
            weaponName = attacker:GetActiveWeapon():GetClass()
        elseif ( attacker:IsPlayer() and attacker:InVehicle() ) then
            weaponName = attacker:GetVehicle():GetClass()
        end
    end

    self:Send(ax.color:Get("red"), self:Format(client) .. " was killed by " .. attackerName .. " using " .. weaponName)
end

function MODULE:EntityTakeDamage(ent, dmginfo)
    if ( !IsValid(ent) or !ent:IsPlayer() ) then return end

    local attacker = dmginfo:GetAttacker()
    if ( !IsValid(attacker) ) then return end

    self:Send(ax.color:Get("orange"), self:Format(ent) .. " took " .. dmginfo:GetDamage() .. " damage from " .. self:Format(attacker))
end

function MODULE:PlayerInitialSpawn(client)
    self:Send(self:Format(client) .. " connected")
end

function MODULE:PlayerDisconnected(client)
    self:Send(self:Format(client) .. " disconnected")
end

function MODULE:PlayerSwitchWeapon(client, oldWeapon, newWeapon)
    if ( !IsValid(client) ) then return end

    if ( IsValid(oldWeapon) ) then
        self:Send(self:Format(client) .. " switched from " .. self:Format(oldWeapon) .. " to " .. self:Format(newWeapon))
    else
        self:Send(self:Format(client) .. " switched to " .. self:Format(newWeapon))
    end
end

function MODULE:PlayerSay(client, text)
    self:Send(self:Format(client) .. " said: " .. text)
end

function MODULE:PlayerSpawn(client)
    self:Send(self:Format(client) .. " spawned")
end

function MODULE:PlayerSpawnedProp(client, model, entity)
    self:Send(self:Format(client) .. " spawned a prop (" .. self:Format(entity) .. ")")
end

function MODULE:PlayerSpawnedSENT(client, entity)
    self:Send(self:Format(client) .. " spawned a SENT (" .. self:Format(entity) .. ")")
end

function MODULE:PlayerSpawnedRagdoll(client, model, entity)
    self:Send(self:Format(client) .. " spawned a ragdoll (" .. self:Format(entity) .. ")")
end

function MODULE:PlayerSpawnedVehicle(client, entity)
    self:Send(self:Format(client) .. " spawned a vehicle (" .. self:Format(entity) .. ")")
end

function MODULE:PlayerSpawnedEffect(client, model, entity)
    self:Send(self:Format(client) .. " spawned an effect (" .. self:Format(entity) .. ")")
end

function MODULE:PlayerSpawnedNPC(client, entity)
    self:Send(self:Format(client) .. " spawned an NPC (" .. self:Format(entity) .. ")")
end

function MODULE:PlayerSpawnedSWEP(client, entity)
    self:Send(self:Format(client) .. " spawned a SWEP (" .. self:Format(entity) .. ")")
end

MODULE.PlayerGiveSWEP = MODULE.PlayerSpawnedSWEP

function MODULE:PostPlayerConfigChanged(client, key, value, oldValue)
    if ( key == "logging" ) then
        if ( value == true ) then
            self:Send(ax.color:Get("green"), self:Format(client) .. " enabled logging")
        else
            self:Send(ax.color:Get("red"), self:Format(client) .. " disabled logging")
        end
    else
        self:Send(ax.color:Get("yellow"), self:Format(client) .. " changed config \"" .. key .. "\" from \"" .. tostring(oldValue) .. "\" to \"" .. tostring(value) .. "\"")
    end
end

function MODULE:PostPlayerConfigReset(client, key)
    self:Send(ax.color:Get("yellow"), self:Format(client) .. " reset config \"" .. key .. "\"")
end