--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

ax.net:Hook("container.password.submit", function(client, entity, password)
	if ( !ax.util:IsValidPlayer(client) ) then
		return
	end

	local retryDelay = math.max(tonumber(ax.config:Get("container.password.retry_delay", 1)) or 1, 0)
	if ( client.axNextContainerPassword and client.axNextContainerPassword > CurTime() ) then
		return
	end

	client.axNextContainerPassword = CurTime() + retryDelay
	password = string.Trim(tostring(password or ""))

	if ( !IsValid(entity) or entity:GetClass() != "ax_container" ) then
		return
	end

	if ( client:GetPos():DistToSqr(entity:GetPos()) >= 16384 ) then
		return
	end

	entity.PasswordAttempts = entity.PasswordAttempts or {}

	local steamID = client:SteamID()
	local attempts = entity.PasswordAttempts[steamID] or 0
	local attemptLimit = math.max(math.floor(tonumber(ax.config:Get("container.password.attempt_limit", 10)) or 10), 1)
	if ( attempts >= attemptLimit ) then
		client:Notify(ax.localization:GetPhrase("container.password.limit"), "error")
		return
	end

	if ( password == tostring(entity.password or "") ) then
		entity.PasswordAttempts[steamID] = 0
		entity:OpenInventory(client)
		return
	end

	entity.PasswordAttempts[steamID] = attempts + 1
	client:Notify(ax.localization:GetPhrase("container.password.incorrect"), "error")
end, true)

ax.net:Hook("container.close", function(client, entity)
	if ( !ax.util:IsValidPlayer(client) ) then
		return
	end

	if ( !IsValid(entity) ) then
		MODULE:CloseContainerForClient(client)
		return
	end

	if ( entity:GetClass() != "ax_container" or client.axOpenContainer != entity ) then
		return
	end

	MODULE:CloseContainerForClient(client, entity)
end, true)
