--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.net = ax.net or {}
ax.net.messages = ax.net.messages or {}

-- ax.net
-- Streaming data layer using sfs. NetStream-style API.
-- @realm shared

function ax.net:Hook(netMessage, callback)
	if ( SERVER ) then
		util.AddNetworkString(netMessage)
	end

	self.messages[util.NetworkStringToID(netMessage)] = callback
end

if ( SERVER ) then
	util.AddNetworkString("ax.net.send")

	function ax.net:Send(receivers, netMessage, ...)
		local args = {...}
		local encode = sfs.encode(args)
		if ( #encode <= 0 ) then return end

		net.Start(netMessage)
			net.WriteUInt(util.NetworkStringToID(netMessage), 8)
			net.WriteData(encode, #encode)
		net.Send(receivers)
	end

	function ax.net:SendPVS(position, netMessage, ...)
		local args = {...}
		local encode = sfs.encode(args)
		if ( #encode <= 0 ) then return end

		net.Start(netMessage)
			net.WriteUInt(util.NetworkStringToID(netMessage), 8)
			net.WriteData(encode, #encode)
		net.SendPVS(position)
	end

	function ax.net:SendPAS(position, netMessage, ...)
		local args = {...}
		local encode = sfs.encode(args)
		if ( #encode <= 0 ) then return end

		net.Start(netMessage)
			net.WriteUInt(util.NetworkStringToID(netMessage), 8)
			net.WriteData(encode, #encode)
		net.SendPAS(position)
	end

	function ax.net:Broadcast(netMessage, ...)
		local args = {...}
		local encode = sfs.encode(args)
		if ( #encode <= 0 ) then return end

		net.Start(netMessage)
			net.WriteUInt(util.NetworkStringToID(netMessage), 8)
			net.WriteData(encode, #encode)
		net.Broadcast()
	end
else
	function ax.net:Send(netMessage, ...)
		local args = {...}
		local encode = sfs.encode(args)
		if ( #encode <= 0 ) then return end

		net.Start("ax.net.send")
			net.WriteUInt(util.NetworkStringToID(netMessage), 8)
			net.WriteData(encode, #encode)
		net.SendToServer()
	end
end

net.Receive("ax.net.send", function(length, client)
	local netMessage = util.NetworkIDToString(net.ReadUInt(8))

--- Starts a stream.
-- @param target Player, table, vector or nil (nil = broadcast or to server).
-- @string name Hook name.
-- @vararg Arguments to send.
if ( SERVER ) then
    function ax.net:Start(target, name, ...)
        local arguments = {...}
        local encoded = sfs.encode(arguments)

        if ( !isstring(encoded) or #encoded < 1 ) then
            return
        end

        net.Start("ax.net.msg")
        net.WriteString(name)
        net.WriteData(encoded, #encoded)

        -- Fast paths
        if ( target == nil ) then
            net.Broadcast()
            return
        end

        if ( isvector(target) ) then
            net.SendPVS(target)
            return
        end

        if ( IsValid(target) and target:IsPlayer() ) then
            net.Send(target)
            return
        end

        if ( istable(target) ) then
            local recipients = {}
            local targetCount = #target

            for i = 1, targetCount do
                local v = target[i]

                if ( IsValid(v) and v:IsPlayer() ) then
                    recipients[#recipients + 1] = v
                end
            end

            if ( #recipients > 0 ) then
                net.Send(recipients)
            end

            return
        end

        -- Fallback: broadcast if caller passed garbage
        net.Broadcast()
    end
else
    function ax.net:Start(name, ...)
        local arguments = {...}
        local encoded = sfs.encode(arguments)
        if ( !isstring(encoded) or #encoded < 1 ) then return end

        net.Start("ax.net.msg")
            net.WriteString(name)
            net.WriteData(encoded, #encoded)
        net.SendToServer()
    end
end

net.Receive("ax.net.msg", function(len, client)
    local name = net.ReadString()

    local bytesLeft = net.BytesLeft and net.BytesLeft() or math.floor((len / 8) - (#name + 1))
    if ( !isnumber(bytesLeft) or bytesLeft <= 0 ) then return end

    local raw = net.ReadData(bytesLeft)
    local ok, decoded = pcall(sfs.decode, raw)
    if ( !ok or !istable(decoded) ) then
        ax.util:PrintError("[Networking] Decode failed for '" .. name .. "'")
        return
    end

    local stored = ax.net.stored[name]
    if ( !istable(stored) or #stored < 1 ) then
        ax.util:PrintError("[Networking] No handler for '" .. name .. "'")
        return
    end

    local callback = stored[1]
    if ( !isfunction(callback) ) then
        ax.util:PrintError("[Networking] No handler for '" .. name .. "'")
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
                ax.util:PrintWarning("[Networking] '" .. name .. "' is on cooldown for " .. math.ceil(coolDown - CurTime()) .. " seconds, ignoring request from " .. (tostring(client) or "unknown"))

                return
            end

            ax.net.cooldown[steam64][name] = CurTime() + (configCooldown or 0.1)
        end

        callback(client, unpack(decoded))
    else
        callback(unpack(decoded))
    end

    if ( ax.config:Get("debug.networking") ) then
        ax.util:Print("[Networking] Received '" .. name .. "' from " .. (SERVER and client:Nick() or "server"))
    end
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
