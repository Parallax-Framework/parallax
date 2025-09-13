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
    return character and character:GetName() or steamName(self)
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
    local teamIndex = self:Team()
    if ( ax.faction:IsValid(teamIndex) ) then
        return teamIndex
    end

    return nil
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

    if ( data.axRateLimits[name] and data.axRateLimits[name] > curTime ) then
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
        local sender = net.ReadPlayer()
        local slot = net.ReadUInt(8)
        local sequence = net.ReadUInt(16)
        sender:PlayGesture(slot, sequence)
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
        net.SendPVS( self:GetPos() )
    end
end

function client:SetData( key, value, bNoNetworking, recipients )
    if ( !isstring(key) or key == "" ) then
        ax.util:PrintError("Invalid key provided to Player:SetData()")
        return false
    end

    if ( recipients == nil ) then
        recipients = self
    end

    local data = self:GetTable()
    if ( !data.axData ) then data.axData = {} end

    data.axData[key] = value

    if ( !bNoNetworking ) then
        net.Start("ax.player.setData")
            net.WritePlayer(self)
            net.WriteString(key)
            net.WriteType(value)
        net.Send(recipients)
    end

    return true
end

function client:GetData( key, fallback )
    if ( !isstring(key) or key == "" ) then
        ax.util:PrintError("Invalid key provided to Player:GetData()")
        return fallback
    end

    local data = self:GetTable()
    if ( !data.axData ) then data.axData = {} end

    return data.axData[key] != nil and data.axData[key] or fallback
end

if ( SERVER ) then
    util.AddNetworkString("ax.player.chatPrint")
    util.AddNetworkString( "ax.player.setData" )

    function client:LoadData( callback )
        local name = self:SteamName()
        local steamID64 = self:SteamID64()

        local query = mysql:Select( "ax_players" )
            query:Select( "data" )
            query:Where( "steamid", steamID64 )
            query:Callback( function( result )
                if ( IsValid( self ) and istable( result ) and result[1] != nil and result[1].data ) then
                    local clientTable = self:GetTable()
                    clientTable.axData = util.JSONToTable( result[1].data ) or {}

                    if ( isfunction( callback ) ) then
                        callback( clientTable.axData )
                    end
                else
                    local insertQuery = mysql:Insert( "ax_players" )
                        insertQuery:Insert( "steamid", steamID64 )
                        insertQuery:Insert( "name", name )
                        insertQuery:Insert( "data", "[]" )
                    insertQuery:Execute()

                    if ( isfunction( callback ) ) then
                        callback( {} )
                    end
                end
            end )
        query:Execute()
    end

    function client:SaveData()
        local steamID64 = self:SteamID64()
        local data = self:GetTable().axData or {}

        local updateQuery = mysql:Update( "ax_players" )
            updateQuery:Update( "data", util.TableToJSON( data ) )
            updateQuery:Where( "steamid", steamID64 )
        updateQuery:Execute()

        return true
    end
else
    net.Receive("ax.player.chatPrint", function(len)
        local messages = net.ReadTable()
        chat.AddText(unpack(messages))
    end)

    net.Receive( "ax.player.setData", function( len )
        local ply = net.ReadPlayer()
        local key = net.ReadString()
        local value = net.ReadType()

        if ( IsValid( ply ) and isstring( key ) and key != "" ) then
            local data = ply:GetTable()
            if ( !data.axData ) then data.axData = {} end

            data.axData[key] = value
        end
    end)
end

client.ChatPrintInternal = client.ChatPrintInternal or client.ChatPrint
function client:ChatPrint(...)
    if ( SERVER ) then
        net.Start("ax.player.chatPrint")
            net.WriteTable({...})
        net.Send(self)
    else
        chat.AddText(...)
    end
end
