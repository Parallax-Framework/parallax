--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

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

    self:Send(ax.color:Get("red"), client:PrettyPrint(true) .. " was killed by " .. attackerName .. " using " .. weaponName)
end

function MODULE:EntityTakeDamage(ent, dmginfo)
    if ( !IsValid(ent) or !ent:IsPlayer() ) then return end

    local attacker = dmginfo:GetAttacker()
    if ( !IsValid(attacker) ) then return end

    self:Send(ax.color:Get("orange"), self:Format(ent) .. " took " .. dmginfo:GetDamage() .. " damage from " .. self:Format(attacker))
end

function MODULE:PlayerInitialSpawn(client)
    self:Send(client:PrettyPrint(true) .. " connected")
end

function MODULE:PlayerDisconnected(client)
    self:Send(client:PrettyPrint(true) .. " disconnected")
end

function MODULE:PlayerSwitchWeapon(client, oldWeapon, newWeapon)
    if ( !IsValid(client) ) then return end

    if ( IsValid(oldWeapon) ) then
        self:Send(client:PrettyPrint(true) .. " switched from " .. self:Format(oldWeapon) .. " to " .. self:Format(newWeapon))
    else
        self:Send(client:PrettyPrint(true) .. " switched to " .. self:Format(newWeapon))
    end
end

function MODULE:PlayerSay(client, text)
    self:Send(client:PrettyPrint(true) .. " said: " .. text)
end

function MODULE:PlayerSpawn(client)
    self:Send(client:PrettyPrint(true) .. " spawned")
end

function MODULE:PlayerSpawnedProp(client, model, entity)
    self:Send(client:PrettyPrint(true) .. " spawned a prop (" .. self:Format(entity) .. ")")
end

function MODULE:PlayerSpawnedSENT(client, entity)
    self:Send(client:PrettyPrint(true) .. " spawned a SENT (" .. self:Format(entity) .. ")")
end

function MODULE:PlayerSpawnedRagdoll(client, model, entity)
    self:Send(client:PrettyPrint(true) .. " spawned a ragdoll (" .. self:Format(entity) .. ")")
end

function MODULE:PlayerSpawnedVehicle(client, entity)
    self:Send(client:PrettyPrint(true) .. " spawned a vehicle (" .. self:Format(entity) .. ")")
end

function MODULE:PlayerSpawnedEffect(client, model, entity)
    self:Send(client:PrettyPrint(true) .. " spawned an effect (" .. self:Format(entity) .. ")")
end

function MODULE:PlayerSpawnedNPC(client, entity)
    self:Send(client:PrettyPrint(true) .. " spawned an NPC (" .. self:Format(entity) .. ")")
end

function MODULE:PlayerSpawnedSWEP(client, entity)
    self:Send(client:PrettyPrint(true) .. " spawned a SWEP (" .. self:Format(entity) .. ")")
end

MODULE.PlayerGiveSWEP = MODULE.PlayerSpawnedSWEP

function MODULE:PostPlayerConfigChanged(client, key, value, oldValue)
    if ( key == "logging" ) then
        if ( value == true ) then
            self:Send(ax.color:Get("green"), client:PrettyPrint(true) .. " enabled logging")
        else
            self:Send(ax.color:Get("red"), client:PrettyPrint(true) .. " disabled logging")
        end
    else
        self:Send(ax.color:Get("yellow"), client:PrettyPrint(true) .. " changed config \"" .. tostring(key) .. "\" from \"" .. tostring(oldValue) .. "\" to \"" .. tostring(value) .. "\"")
    end
end

function MODULE:PostPlayerConfigReset(client, key)
    self:Send(ax.color:Get("yellow"), client:PrettyPrint(true) .. " reset config \"" .. tostring(key) .. "\"")
end