local cfg = ax.discord.config or {}

ax.discord.relay = ax.discord.relay or {}
ax.discord.relay.hasGWSockets = ax.discord.relay.hasGWSockets or false
ax.discord.relay.hasCHTTP = ax.discord.relay.hasCHTTP or false

function ax.discord.relay:CheckDependencies()
	do
		local ok, _ = pcall(require, "gwsockets")
		ax.discord.relay.hasGWSockets = ok and istable(GWSockets or _G.GWSockets)
		if ( !ax.discord.relay.hasGWSockets and cfg.useWebSocket ) then
			ax.util:PrintError("Missing 'gwsockets' module. WebSocket relay disabled until installed.")
		end
	end

	-- gm_chttp (preferred for HTTPS to webhooks)
	ax.discord.relay.hasCHTTP = isfunction(CHTTP)
	if ( !ax.discord.relay.hasCHTTP ) then
		ax.util:PrintError("Missing 'gm_chttp' module. Falling back to HTTP() where possible.")
	end

	-- Summarize
	if ( !cfg.enabled ) then
		ax.util:Print("Discord relay is disabled via config.")
		return
	end

	if ( !(cfg.channels and next(cfg.channels)) and !(cfg.useWebSocket and cfg.webSocketURL != "")) then
		ax.util:PrintError("No webhook or websocket configured. Set channels map, Public/Private webhooks, or webSocketURL.")
	end
end

ax.discord.relay.ws = ax.discord.relay.ws or nil
function ax.discord.relay:ConnectWebSocket()
	if ( !cfg.useWebSocket or cfg.webSocketURL == "" ) then return end
	if ( !ax.discord.relay.hasGWSockets ) then return end

	if ( IsValid(ax.discord.relay.ws) ) then return end -- discard if already connected

	local socket = GWSockets and GWSockets.createWebSocket or (GWSockets and GWSockets.WebSocket or nil)
	if ( !socket ) then return end

	local ws = GWSockets.createWebSocket(cfg.webSocketURL)
	function ws:onMessage(txt)
		ax.util:PrintDebug("WebSocket message received: " .. tostring(txt))
	end

	function ws:onError(err)
		ax.util:PrintError("WebSocket error: " .. tostring(err))
	end

	function ws:onConnected()
		ax.util:PrintSuccess("WebSocket relay connected.")
	end

	function ws:onDisconnected()
		ax.util:PrintError("WebSocket relay disconnected.")
		timer.Simple(5, function() ax.discord.relay:ConnectWebSocket() end)
	end

	ws:open()

	ax.discord.relay.ws = ws
end

local function buildEmbed(title, description, color)
	return {
		title = title,
		description = description,
		color = color
	}
end

local function buildWebhookPayload(content, embed, username, avatar)
	local payload = {
		username = username or cfg.name,
		avatar_url = avatar or cfg.avatarURL
	}

	if ( embed ) then
		payload.embeds = {
			embed
		}
	end

	if ( content and content != "" ) then
		payload.content = content
	end

	return payload
end

function ax.discord.relay:SendWebhook(url, payload)
	if ( !url or url == "" ) then return end
	local json = util.TableToJSON(payload or {}, false)

	if ( ax.discord.relay.hasCHTTP ) then
		CHTTP({
			url = url,
			method = "POST",
			body = json,
			type = "application/json",
			success = function(code, body, headers)
				ax.util:PrintDebug("CHTTP succeeded: " .. tostring(code))
			end,
			failed = function(err)
				ax.util:PrintError("CHTTP failed: " .. tostring(err))
			end
		})
	else
		HTTP({
			url = url,
			method = "post",
			headers = { ["Content-Type"] = "application/json" },
			body = json,
			success = function(code, body, headers)
				ax.util:PrintDebug("HTTP succeeded: " .. tostring(code))
			end,
			failed = function(err)
				ax.util:PrintError("HTTP failed: " .. tostring(err))
			end
		})
	end
end

-- Send via websocket relay (simple JSON envelope)
function ax.discord.relay:SendWebSocket(event, data)
	if ( !cfg.useWebSocket and IsValid(ax.discord.relay.ws) ) then return end

	local envelope = util.TableToJSON({ event = event, data = data }, false)
	ax.discord.relay.ws:write(envelope)
end

function ax.discord.relay:Transmit(id, content, title, description, opts)
	if ( !cfg.enabled ) then return end
	id = tostring(id or "")

	local channel = (cfg.channels and cfg.channels[id]) or nil

	local color = (opts and opts.color)
		or (channel and channel.color)
		or cfg.ColorPublic

	local embed = buildEmbed(title, description or "", color)

	local payload = buildWebhookPayload(content or "", embed, opts and opts.username, opts and opts.avatar_url)

	local webhook = (opts and opts.webhook)
		or (channel and channel.webhook)
		or ""

	if ( webhook != "" ) then
		ax.discord.relay:SendWebhook(webhook, payload)
	end

	if ( cfg.useWebSocket and IsValid(ax.discord.relay.ws) ) then
		ax.discord.relay:SendWebSocket(id != "" and id or "generic", { content = content, title = title, description = description })
	end
end