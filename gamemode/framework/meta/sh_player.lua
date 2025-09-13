--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]


local steamName = steamName or ax.player.meta.GetName
function ax.player.meta:GetName()
    local character = self:GetCharacter()
    return character and character:GetName() or steamName(self)
end

ax.player.meta.Name = ax.player.meta.GetName
ax.player.meta.Nick = ax.player.meta.GetName

function ax.player.meta:SteamName()
    return steamName(self)
end

function ax.player.meta:GetCharacter()
    return self:GetTable().axCharacter
end

function ax.player.meta:GetCharacters()
    return self:GetTable().axCharacters or {}
end

function ax.player.meta:GetFaction()
    local teamIndex = self:Team()
    if ( ax.faction:IsValid(teamIndex) ) then
        return teamIndex
    end

    return nil
end

function ax.player.meta:GetFactionData()
    local factionData = ax.faction:Get(self:GetFaction())
    return factionData
end

function ax.player.meta:RateLimit(name, delay)
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

    if ( data.axRateLimits[name] and data.axRateLimits[name] > curTime ) then
        return false, data.axRateLimits[name] - curTime -- Rate limit exceeded.
    end

    data.axRateLimits[name] = curTime + delay
    return true -- Rate limit passed.
end

function ax.player.meta:ResetRateLimit(name)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("Invalid rate limit name provided to Player:ResetRateLimit()")
        return false
    end

    local data = self:GetTable()
    if ( !data.axRateLimits ) then return true end

    data.axRateLimits[name] = nil
    return true
end

function ax.player.meta:PlayGesture(slot, sequence)
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
        ax.util:PrintWarning("Invalid gesture sequence provided to Player:PlayGesture()")
        return nil
    end

    if ( CLIENT ) then
        self:AddVCDSequenceToGestureSlot(slot, sequence, 0, true)
    else
        net.Start("ax.player.playGesture")
            net.WritePlayer(self)
            net.WriteUInt(slot, 8)
            net.WriteUInt(sequence, 16)
        net.SendPVS(self:GetPos())
    end
end

function ax.player.meta:GetData(key, fallback)
    if ( !istable(self.vars.data) ) then self.vars.data = {} end

    return self.vars.data[key] == nil and fallback or self.vars.data[key]
end

if ( SERVER ) then
    function ax.player.meta:SetData(key, value, isNetworked, recipients)
        if ( !istable(self.vars.data) ) then self.vars.data = {} end

        self.vars.data[key] = value

        if ( !isNetworked ) then
            net.Start("ax.player.var")
                net.WritePlayer(self)
                net.WriteString(key)
                net.WriteType(value)
            if ( recipients ) then
                net.Send(recipients)
            else
                net.Broadcast()
            end
        end
    end

    function ax.player.meta:Save()
        if ( !istable(self.vars.data) ) then self.vars.data = {} end

        -- Build an update query for the players table using the registered schema
        local query = mysql:Update("ax_players")
        query:Where("id", self:GetID())

        -- Ensure the data table exists and always save it as JSON
        query:Update("data", util.TableToJSON(self.vars.data or {}))

        -- Iterate registered vars and persist fields that declare a database column
        for name, meta in pairs(ax.player.vars or {}) do
            if ( istable(meta) and meta.field ) then
                local val = nil

                if ( istable(self.vars) ) then
                    val = self.vars[name]
                end

                -- Fall back to default if not present
                if ( val == nil and meta.default != nil ) then
                    val = meta.default
                end

                -- Serialize tables to JSON for storage
                if ( istable(val) ) then
                    val = util.TableToJSON(val)
                end

                query:Update(meta.field, val)

                ax.util:PrintDebug("Saving player field '" .. meta.field .. "' with value: " .. tostring(val))
            end
        end

        query:Execute()
    end
end

if ( SERVER ) then
    util.AddNetworkString( "ax.player.chatPrint" )
    util.AddNetworkString( "ax.player.playGesture" )
else
    net.Receive("ax.player.chatPrint", function(len)
        local messages = net.ReadTable()
        chat.AddText(unpack(messages))
    end)

    net.Receive("ax.player.playGesture", function(len)
        local sender = net.ReadPlayer()
        local slot = net.ReadUInt(8)
        local sequence = net.ReadUInt(16)
        sender:PlayGesture(slot, sequence)
    end)
end

ax.player.meta.ChatPrintInternal = ax.player.meta.ChatPrintInternal or ax.player.meta.ChatPrint
function ax.player.meta:ChatPrint(...)
    if ( SERVER ) then
        net.Start("ax.player.chatPrint")
            net.WriteTable({...})
        net.Send(self)
    else
        chat.AddText(...)
    end
end
