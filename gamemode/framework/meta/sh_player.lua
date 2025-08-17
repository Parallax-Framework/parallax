--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local client = FindMetaTable("Player")

local steamName = steamName or client.Name
function client:Name()
    local character = self:GetCharacter()
    return character and character.name or steamName(self)
end

function client:SteamName()
    return steamName(self)
end

function client:GetCharacter()
    return self:GetTable().axCharacter
end

function client:GetCharacters()
    return self:GetTable().axCharacters or {}
end

function client:GetFaction()
    return self:Team()
end

function client:GetFactionData()
    local factionData = ax.faction:Get(self:GetFaction())
    return factionData
end

function client:RateLimit(name, delay)
    local data = self:GetTable()

    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("Invalid rate limit name provided to Player:RateLimit()")
        return false
    end

    if ( !isnumber(delay) or delay <= 0 ) then
        ax.util:PrintError("Invalid rate limit delay provided to Player:RateLimit()")
        return false
    end

    if ( !data.axRateLimits ) then data.axRateLimits = {} end

    local curTime = CurTime()

    if ( data.axRateLimits[name] > curTime ) then
        return false, data.axRateLimits[name] - curTime -- Rate limit exceeded.
    end

    data.axRateLimits[name] = curTime + delay
    return true -- Rate limit passed.
end

function client:ResetRateLimit(name)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("Invalid rate limit name provided to Player:ResetRateLimit()")
        return false
    end

    local data = self:GetTable()
    if ( !data.axRateLimits ) then return true end

    data.axRateLimits[name] = nil
    return true
end

if ( SERVER ) then
    util.AddNetworkString("ax.player.playGesture")
else
    net.Receive("ax.player.playGesture", function(len)
        local client = net.ReadPlayer()
        local slot = net.ReadUInt(8)
        local sequence = net.ReadUInt(16)
        client:PlayGesture(slot, sequence)
    end)
end

function client:PlayGesture(slot, sequence)
    if ( !isnumber(slot) or slot < 0 or slot > 6 ) then
        ax.util:PrintError("Invalid gesture slot provided to Player:PlayGesture()")
        return nil
    end

    if ( isstring(sequence) ) then
        sequence = self:LookupSequence(sequence)
        ax.util:PrintDebug("Player:PlayGesture() - Converted string sequence to ID:", sequence)
    end

    sequence = sequence or -1

    if ( !isnumber(sequence) or sequence < 0 ) then
        ax.util:PrintError("Invalid gesture sequence provided to Player:PlayGesture()")
        return nil
    end

    if ( CLIENT ) then
        self:AddVCDSequenceToGestureSlot(slot, sequence, 0, true)
    else
        net.Start("ax.player.playGesture")
            net.WritePlayer(self)
            net.WriteUInt(slot, 8)
            net.WriteUInt(sequence, 16)
        net.Send(self)
    end
end