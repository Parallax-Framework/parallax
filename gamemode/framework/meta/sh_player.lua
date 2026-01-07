--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Player meta functions
-- @module ax.player.meta

ax.player.meta.GetNameInternal = ax.player.meta.GetNameInternal or ax.player.meta.GetName
function ax.player.meta:GetName()
    local character = self:GetCharacter()
    return character and character:GetName() or self:GetNameInternal()
end

ax.player.meta.Name = ax.player.meta.GetName
ax.player.meta.NameInternal = ax.player.meta.GetNameInternal
ax.player.meta.Nick = ax.player.meta.GetName
ax.player.meta.NickInternal = ax.player.meta.GetNameInternal

function ax.player.meta:SteamName()
    return self:GetNameInternal()
end

function ax.player.meta:GetCharacter()
    return self:GetTable().axCharacter
end

ax.player.meta.GetChar = ax.player.meta.GetCharacter

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

function ax.player.meta:GetClassData()
    local char = self:GetCharacter()
    if ( !char ) then return nil end

    local classID = char:GetClass()
    if ( classID ) then
        return ax.class:Get(classID)
    end

    return nil
end

-- Cache for gesture sequence lookups to avoid repeated LookupSequence calls
ax.player.gestureCache = ax.player.gestureCache or {}

function ax.player.meta:PlayGesture(slot, sequence)
    if ( !isnumber(slot) or slot < 0 or slot > 6 ) then
        ax.util:PrintError("Invalid gesture slot provided to Player:PlayGesture()")
        return nil
    end

    if ( isstring(sequence) ) then
        local modelPath = self:GetModel()
        local cacheKey = modelPath .. ":" .. sequence

        -- Check cache first
        if ( ax.player.gestureCache[cacheKey] ) then
            sequence = ax.player.gestureCache[cacheKey]
            ax.util:PrintDebug("Player:PlayGesture() - Using cached sequence ID:", sequence)
        else
            -- Lookup and cache the result
            sequence = self:LookupSequence(sequence)
            ax.player.gestureCache[cacheKey] = sequence
            ax.util:PrintDebug("Player:PlayGesture() - Converted string sequence to ID and cached:", sequence)
        end
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
    local clientTable = self:GetTable()
    if ( !istable(clientTable.axVars) ) then clientTable.axVars = {} end
    if ( !istable(clientTable.axVars.data) ) then clientTable.axVars.data = {} end

    return clientTable.axVars.data[key] == nil and fallback or clientTable.axVars.data[key]
end

if ( SERVER ) then
    function ax.player.meta:SetData(key, value, bNoNetworking, recipients)
        local clientTable = self:GetTable()
        if ( !istable(clientTable.axVars) ) then clientTable.axVars = {} end
        if ( !istable(clientTable.axVars.data) ) then clientTable.axVars.data = {} end

        clientTable.axVars.data[key] = value

        if ( !bNoNetworking ) then
            net.Start("ax.player.data")
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
        local clientTable = self:GetTable()
        if ( !istable(clientTable.axVars) ) then clientTable.axVars = {} end
        if ( !istable(clientTable.axVars.data) ) then clientTable.axVars.data = {} end

        -- Build an update query for the players table using the registered schema
        local query = mysql:Update("ax_players")
        query:Where("steamid64", self:SteamID64())

        -- Ensure the data table exists and always save it as JSON
        query:Update("data", util.TableToJSON(clientTable.axVars.data or {}))

        -- Iterate registered vars and persist fields that declare a database column
        for name, meta in pairs(ax.player.vars or {}) do
            if ( istable(meta) and meta.field ) then
                local val = nil

                if ( istable(clientTable.axVars) ) then
                    val = clientTable.axVars[name]
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

    function ax.player.meta:EnsurePlayer(callback)
        local steamID64 = self:SteamID64()

        local function finish(ok)
            if ( isfunction(callback) ) then
                callback(ok)
            else
                ax.util:PrintDebug("No callback provided to Player:EnsurePlayer() for " .. steamID64)
            end
        end

        local query = mysql:Select("ax_players")
            query:Where("steamid64", steamID64)
            query:Callback(function(result, status)
                if ( result == false ) then
                    ax.util:PrintError("Failed to query players for " .. steamID64)
                    finish(false)
                    return
                end

                if ( result[1] == nil ) then
                    ax.util:PrintDebug("No player row found for " .. steamID64 .. ", creating one.")

                    local insert = mysql:Insert("ax_players")
                        insert:Insert("steamid64", steamID64)
                        insert:Insert("name", self:SteamName())
                        insert:Insert("last_join", os.time())
                        insert:Insert("last_leave", 0)
                        insert:Insert("play_time", 0)
                        insert:Insert("data", "[]")
                    insert:Callback(function(res, st, lastID)
                        if ( res == false ) then
                            ax.util:PrintError("Failed to create player row for " .. steamID64)
                            finish(false)
                            return
                        end

                        ax.util:PrintDebug("Created player row for " .. steamID64 .. " with id " .. tostring(lastID))
                        finish(true)
                    end)
                    insert:Execute()
                else
                    ax.util:PrintDebug("Player row found for " .. steamID64 .. ", ensuring data is valid.")
                    finish(true)
                end
            end)
        query:Execute()
    end
else
    function ax.player.meta:EnsurePlayer(callback)
        local clientTable = self:GetTable()
        if ( clientTable.axReady ) then
            if ( isfunction(callback) ) then callback(true) end
            return
        end

        clientTable.axEnsureCallbacks = clientTable.axEnsureCallbacks or {}
        clientTable.axEnsureCallbacks[#clientTable.axEnsureCallbacks + 1] = callback
    end
end

function ax.player.meta:GetSessionPlayTime()
    local joinTime = self:GetTable().axJoinTime
    if ( !joinTime ) then return 0 end

    return os.difftime(os.time(), joinTime)
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
        if ( !IsValid(sender) ) then return end

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

--- Player:Notify - Convenience for sending a toast to this player.
-- @realm server
function ax.player.meta:Notify(text, type, length)
    if ( SERVER ) then
        ax.notification:Send(self, text, type, length)
    else
        ax.notification:Add(text, type, length)
    end
end

function ax.player.meta:SyncRelay()
    for k, v in pairs( ax.relay.data["global"] or {} ) do
        self:SetRelay( k, v, false, self )
    end

    for entityIndex, data in pairs( ax.relay.data ) do
        if ( entityIndex == "global" ) then continue end

        local ent = Entity( tonumber( entityIndex ) or 0 )
        if ( !IsValid( ent ) or ( ent:IsPlayer() and ent:SteamID64() != entityIndex ) ) then continue end

        for k, v in pairs( data ) do
            ent:SetRelay( k, v, false, self )
        end
    end
end
