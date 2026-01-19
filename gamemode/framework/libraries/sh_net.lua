--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- ax.net
-- Streaming data layer using sfs. NetStream-style API.
-- @realm shared

ax.net = ax.net or {}
ax.net.stored = ax.net.stored or {}
ax.net.cooldown = ax.net.cooldown or {}

-- TODO: Maybe some queue system, this shit can send too much messages at once

--- Hooks a network message.
-- @string name Unique identifier.
-- @func callback Callback with player, unpacked arguments.
function ax.net:Hook(name, callback, bNoDelay)
    self.stored[name] = {callback, bNoDelay or false}
end

if ( SERVER ) then
    util.AddNetworkString("ax.net.msg")

    function ax.net:WritePayload(name, arguments)
        local encoded = sfs.encode(arguments)

        if ( !isstring(encoded) or #encoded < 1 ) then
            return false
        end

        net.Start("ax.net.msg")
        net.WriteString(name)
        net.WriteData(encoded, #encoded)

        return true
    end

    -- per request of eon.
    function ax.net:StartPVS(position, name, ...)
        if ( !isvector(position) or !self:WritePayload(name, {...}) ) then return end

        net.SendPVS(position)

        ax.util:PrintDebug("[NET] Sent '" .. name .. "' to PVS at " .. tostring(position))
    end

    function ax.net:StartPAS(position, name, ...)
        if ( !isvector(position) or !self:WritePayload(name, {...}) ) then return end

        net.SendPAS(position)

        ax.util:PrintDebug("[NET] Sent '" .. name .. "' to PAS at " .. tostring(position))
    end

    --- Starts a stream.
    -- @param target Player, table, vector or nil (nil = broadcast or to server).
    -- @string name Hook name.
    -- @vararg Arguments to send.
    function ax.net:Start(target, name, ...)
        local arguments = {...}
        if ( !self:WritePayload(name, arguments) ) then
            return
        end

        -- Fast paths
        if ( target == nil ) then
            net.Broadcast()
            ax.util:PrintDebug("[NET] Sent '" .. name .. "' to all clients")
            return
        end

        if ( type(target) == "Player" ) then
            net.Send(target)
            ax.util:PrintDebug("[NET] Sent '" .. name .. "' to " .. target:Nick())
            return
        end

        if ( istable(target) ) then
            local recipients = {}
            local targetCount = #target

            for i = 1, targetCount do
                local v = target[i]

                if ( type(v) == "Player" ) then
                    recipients[#recipients + 1] = v
                end
            end

            if ( recipients[1] != nil ) then
                net.Send(recipients)
                ax.util:PrintDebug("[NET] Sent '" .. name .. "' to " .. #recipients .. " recipients")
            end

            return
        end

        -- Fallback: broadcast if caller passed garbage
        net.Broadcast()

        ax.util:PrintWarning("ax.net:Start called with invalid target, broadcasting to all clients instead")
    end
else
    --- Starts a stream.
    -- @param target Player, table, vector or nil (nil = broadcast or to server).
    -- @string name Hook name.
    -- @vararg Arguments to send.
    function ax.net:Start(name, ...)
        local arguments = {...}
        local encoded = sfs.encode(arguments)
        if ( !isstring(encoded) or #encoded < 1 ) then return end

        net.Start("ax.net.msg")
            net.WriteString(name)
            net.WriteData(encoded, #encoded)
        net.SendToServer()

        ax.util:PrintDebug("[NET] Sent '" .. name .. "' to server")
    end
end

net.Receive("ax.net.msg", function(len, client)
    local name = net.ReadString()

    local bytesLeft = net.BytesLeft and net.BytesLeft() or math.floor((len / 8) - (#name + 1))
    if ( !isnumber(bytesLeft) or bytesLeft <= 0 ) then return end

    local raw = net.ReadData(bytesLeft)
    local ok, decoded = pcall(sfs.decode, raw)
    if ( !ok or !istable(decoded) ) then
        ax.util:PrintError("[NET] Decode failed for '" .. name .. "'")
        return
    end

    local stored = ax.net.stored[name]
    if ( !istable(stored) or #stored < 1 ) then
        ax.util:PrintError("[NET] No handler for '" .. name .. "'")
        return
    end

    local callback = stored[1]
    if ( !isfunction(callback) ) then
        ax.util:PrintError("[NET] No handler for '" .. name .. "'")
        return
    end

    if ( SERVER ) then
        local configCooldown = ax.config:Get("networking.cooldown", 0.1)
        if ( !stored[2] and isnumber(configCooldown) and configCooldown > 0 ) then
            local steam64 = client:SteamID64()
            if ( !istable(ax.net.cooldown[steam64]) ) then ax.net.cooldown[steam64] = {} end
            if ( !isnumber(ax.net.cooldown[steam64][name]) ) then ax.net.cooldown[steam64][name] = 0 end

            local coolDown = ax.net.cooldown[steam64][name]
            if ( isnumber(coolDown) and coolDown > CurTime() ) then
                ax.util:PrintWarning("[NET] '" .. name .. "' is on cooldown for " .. math.ceil(coolDown - CurTime()) .. " seconds, ignoring request from " .. (tostring(client) or "unknown"))

                return
            end

            ax.net.cooldown[steam64][name] = CurTime() + (configCooldown or 0.1)
        end

        callback(client, unpack(decoded))
    else
        callback(unpack(decoded))
    end

    ax.util:PrintDebug("[NET] Received '" .. name .. "' from " .. (SERVER and client:Nick() or "server"))
end)

--[[
--- Example usage:
if ( SERVER ) then
    ax.net:Hook("test", function(client, val, val2)
        if ( istable(val) ) then
            print(client, "sent table:", table.concat(val, ", "))
            return
        end

        print(client, "sent:", val, val2)
    end)
else
    ax.net:Hook("test", function(val, val2)
        print("your steamid is:", val)
        print("server says:", val2)
    end)
end

if ( CLIENT ) then
    ax.net:Start("test", {89})
    ax.net:Start("test", "hello", "world")
else
    ax.net:Start(client, "test", client:SteamID(), "server says hi")
end
]]
