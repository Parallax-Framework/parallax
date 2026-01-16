--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.net = ax.net or {}
ax.net.messages = ax.net.messages or {}

function ax.net:Hook(netMessage, callback)
	self.messages[netMessage] = callback
end

if ( SERVER ) then
	util.AddNetworkString("ax.net.send")

	function ax.net:Send(receivers, netMessage, ...)
		local args = {...}
		local encode = sfs.encode(args)
		if ( #encode <= 0 ) then return end

		net.Start(netMessage)
			net.WriteString(netMessage)
			net.WriteData(encode, #encode)
		net.Send(receivers)
	end

	function ax.net:SendPVS(position, netMessage, ...)
		local args = {...}
		local encode = sfs.encode(args)
		if ( #encode <= 0 ) then return end

		net.Start(netMessage)
			net.WriteString(netMessage)
			net.WriteData(encode, #encode)
		net.SendPVS(position)
	end

	function ax.net:SendPAS(position, netMessage, ...)
		local args = {...}
		local encode = sfs.encode(args)
		if ( #encode <= 0 ) then return end

		net.Start(netMessage)
			net.WriteString(netMessage)
			net.WriteData(encode, #encode)
		net.SendPAS(position)
	end

	function ax.net:Broadcast(netMessage, ...)
		local args = {...}
		local encode = sfs.encode(args)
		if ( #encode <= 0 ) then return end

		net.Start(netMessage)
			net.WriteString(netMessage)
			net.WriteData(encode, #encode)
		net.Broadcast()
	end
else
	function ax.net:Send(netMessage, ...)
		local args = {...}
		local encode = sfs.encode(args)
		if ( #encode <= 0 ) then return end

		net.Start("ax.net.send")
			net.WriteString(netMessage)
			net.WriteData(encode, #encode)
		net.SendToServer()
	end
end

net.Receive("ax.net.send", function(length, client)
	local netMessage = net.ReadString()

	local ok, decoded = pcall(sfs.decode, net.ReadData(length / 8))
	if ( !ok or type(decoded) != "table" ) then
		ax.util:PrintError("[Networking] Decode failed for '" .. name .. "'")
		return
	end

	local callback = ax.net.messages[netMessage]
	if ( type(callback) != "function" ) then
		ax.util:PrintError("[Networking] No handler for '" .. name .. "'")
		return
	end

	if ( SERVER ) then
		callback(client, unpack(decoded))
	else
		callback(unpack(decoded))
	end
end)
