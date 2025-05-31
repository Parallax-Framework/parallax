--- Utility functions
-- @module ax.util

ax.util = ax.util or {}

--- Converts and sanitizes input data into the specified type.
-- This supports simple type coercion and fallback defaults.
-- @param typeID number A type constant from ax.types
-- @param value any The raw value to sanitize
-- @return any A validated and converted result
-- @usage ax.util:CoerceType(ax.types.number, "123") -- returns 123
function ax.util:CoerceType(typeID, value)
	if ( typeID == ax.types.string or typeID == ax.types.text ) then
		return tostring(value)
	elseif ( typeID == ax.types.number ) then
		return tonumber(value) or 0
	elseif ( typeID == ax.types.bool ) then
		return tobool(value)
	elseif ( typeID == ax.types.vector ) then
		return isvector(value) and value or vector_origin
	elseif ( typeID == ax.types.angle ) then
		return isangle(value) and value or angle_zero
	elseif ( typeID == ax.types.color ) then
		return IsColor(value) and value or color_white
	elseif ( typeID == ax.types.player ) then
		if ( isstring(value) ) then
			return ax.util:FindPlayer(value)
		elseif ( isnumber(value) ) then
			return Player(value)
		elseif ( IsValid(value) and value:IsPlayer() ) then
			return value
		end
	elseif ( typeID == ax.types.character ) then
		if ( istable(value) and getmetatable(value) == ax.character.meta ) then
			return value
		end
	elseif ( typeID == ax.types.steamid ) then
		if ( isstring(value) and #value == 17 and string.match(value, "^%d+$") ) then
			return value
		end
	elseif ( typeID == ax.types.steamid64 ) then
		if ( isstring(value) and #value == 17 and string.match(value, "^7656119%d+$") ) then
			return value
		end
	end

	return nil
end

local basicTypeMap = {
	string  = ax.types.string,
	number  = ax.types.number,
	boolean = ax.types.bool,
	Vector  = ax.types.vector,
	Angle   = ax.types.angle
}

local checkTypeMap = {
	[ax.types.color] = function(val) return IsColor(val) end,
	[ax.types.character] = function(val) return getmetatable(val) == ax.character.meta end,
	[ax.types.steamid] = function(val) return isstring(val) and #val == 17 and string.match(value, "^%d+$") end,
	[ax.types.steamid64] = function(val) return isstring(val) and #val == 17 and string.match(value, "^7656119%d+$") end
}

--- Attempts to identify the framework type of a given value.
-- @param value any The value to analyze
-- @return number|nil A type constant from ax.types or nil if unknown
-- @usage local t = ax.util:DetectType(Color(255,0,0)) -- returns ax.types.color
function ax.util:DetectType(value)
	local luaType = type(value)
	local mapped = basicTypeMap[luaType]

	if ( mapped ) then return mapped end

	for typeID, validator in pairs(checkTypeMap) do
		if ( validator(value) ) then
			return typeID
		end
	end

	if ( IsValid(value) and value:IsPlayer() ) then
		return ax.types.player
	end
end

--- Sends a chat message to the player.
-- @realm shared
-- @param client Player The player to send the message to.
-- @param ... any The message to send.
function ax.util:SendChatText(client, ...)
	if ( SERVER ) then
		ax.net:Start(client, "chat.text", {...})
	else
		chat.AddText(...)
	end
end

--- Prepares a package for printing to either the chat or console. This is useful for chat messages that need to be colored.
-- @realm shared
-- @param ... any The package to prepare.
-- @return any The prepared package.
function ax.util:PreparePackage(...)
	local arguments = {...}
	local package = {}

	for k, v in ipairs(arguments) do
		if ( type(v) == "Player" ) then
			table.insert(package, team.GetColor(v:Team()))
			table.insert(package, v:Name())
		else
			table.insert(package, v)
		end
	end

	table.insert(package, "\n")

	return package
end

local violetColor = Color(142, 68, 255)

local serverMsgColor = Color(156, 241, 255, 200)
local clientMsgColor = Color(255, 241, 122, 200)

--- Prints a message to the console.
-- @realm shared
-- @param ... any The message to print.
function ax.util:Print(...)
	local arguments = self:PreparePackage(...)

	local realmColor = SERVER and serverMsgColor or clientMsgColor
	MsgC(violetColor, "[Parallax] ", realmColor, unpack(arguments))

	if ( CLIENT and ax.config and ax.config.Get and ax.config:Get("debug.developer") ) then
		chat.AddText(violetColor, "[Parallax] ", realmColor, unpack(arguments))
	end

	return arguments
end

--- Prints an error message to the console.
-- @realm shared
-- @param ... any The message to print.
local f = "[%s Error] "
local colorError = Color(255, 120, 120)
local _printingError = false
function ax.util:PrintError(...)
	if ( _printingError ) then return end
	_printingError = true

	local arguments = self:PreparePackage(...)
	local info = {}

	for i = 1, 10 do
		local traceInfo = debug.getinfo(i, "Sl")
		if ( !traceInfo ) then break end
		table.insert(info, traceInfo)
	end

	local line = ""
	local quickInfo = info[3]
	if ( quickInfo and quickInfo.short_src and quickInfo.currentline > 0 ) then
		line = quickInfo.short_src .. ":" .. quickInfo.currentline
	end

	if ( line != "" ) then
		if ( #arguments > 0 and type(arguments[#arguments]) == "string" ) then
			arguments[#arguments] = string.Trim(arguments[#arguments])
		end

		line = string.gsub(line, "gamemodes/", "")
		table.insert(arguments, " (" .. line .. ")")
		table.insert(arguments, "\n")
	end

	MsgC(violetColor, "[Parallax] ", colorError, string.format(f, SERVER and "Server" or "Client"), unpack(arguments))

	if ( CLIENT and ax.config and ax.config.Get and ax.config:Get("debug.developer") ) then
		chat.AddText(violetColor, "[Parallax] ", colorError, "[Error] ", unpack(arguments))
	end

	if ( ax.config and ax.config.Get and ax.config:Get("debug.developer") ) then
		local log = {}
		for i = 1, 10 do
			local traceInfo = info[i]
			if ( !traceInfo ) then break end

			local file = traceInfo.short_src or "unknown"
			local lineNum = traceInfo.currentline or 0
			table.insert(log, string.format("%s:%d", file, lineNum) .. "\n")
		end
		log = table.concat(log, " -> ")
		MsgC(violetColor, "[Parallax] ", colorError, "[Error] [Traceback] ", log, "\n")
	end

	_printingError = false
	return arguments
end

--- Prints a warning message to the console.
-- @realm shared
-- @param ... any The message to print.
local colorWarning = Color(255, 200, 120)
function ax.util:PrintWarning(...)
	local arguments = self:PreparePackage(...)

	MsgC(violetColor, "[Parallax] ", colorWarning, "[Warning] ", unpack(arguments))

	if ( CLIENT and ax.config and ax.config.Get and ax.config:Get("debug.developer") ) then
		chat.AddText(violetColor, "[Parallax] ", colorWarning, "[Warning] ", unpack(arguments))
	end

	return arguments
end

--- Prints a success message to the console.
-- @realm shared
-- @param ... any The message to print.
local colorSuccess = Color(120, 255, 120)
function ax.util:PrintSuccess(...)
	local arguments = self:PreparePackage(...)

	MsgC(violetColor, "[Parallax] ", colorSuccess, "[Success] ", unpack(arguments))

	if ( CLIENT and ax.config:Get("debug.developer") ) then
		chat.AddText(violetColor, "[Parallax] ", colorSuccess, "[Success] ", unpack(arguments))
	end

	return arguments
end

--- Loads a file based on the realm.
-- @realm shared
-- @param path string The path to the file.
-- @param realm string The realm to load the file in.
function ax.util:LoadFile(path, realm)
	if ( !isstring(path) ) then
		self:PrintError("Failed to load file " .. path .. "!")
		return
	end

	if ( ( realm == "server" or string.find(path, "sv_") ) and SERVER ) then
		include(path)
	elseif ( realm == "shared" or string.find(path, "shared.lua") or string.find(path, "sh_") ) then
		if ( SERVER ) then
			AddCSLuaFile(path)
		end

		include(path)
	elseif ( realm == "client" or string.find(path, "cl_") ) then
		if ( SERVER ) then
			AddCSLuaFile(path)
		else
			include(path)
		end
	end
end

--- Loads all files in a folder based on the realm.
-- @realm shared
-- @param directory string The directory to load the files from.
-- @param bFromLua boolean Whether or not the files are being loaded from Lua.
function ax.util:LoadFolder(directory, bFromLua)
	local baseDir = debug.getinfo(2).source
	baseDir = string.sub(baseDir, 2, string.find(baseDir, "/[^/]*$"))
	baseDir = string.gsub(baseDir, "gamemodes/", "")

	if ( bFromLua ) then
		baseDir = ""
	end

	for k, v in ipairs(file.Find(baseDir .. directory .. "/*.lua", "LUA")) do
		if ( !file.Exists(baseDir .. directory .. "/" .. v, "LUA") ) then
			self:PrintError("Failed to load file " .. baseDir .. directory .. "/" .. v .. "!")
			continue
		end

		self:LoadFile(baseDir .. directory .. "/" .. v)
	end

	return true
end

--- Returns the type of a value.
-- @realm shared
-- @string str The value to get the type of.
-- @string find The type to search for.
-- @return string The type of the value.
function ax.util:FindString(str, find)
	if ( str == nil or find == nil ) then
		ax.util:PrintError("Attempted to find a string with no value to find for! (" .. tostring(str) .. ", " .. tostring(find) .. ")")
		return false
	end

	str = string.lower(str)
	find = string.lower(find)

	return string.find(str, find) != nil
end

--- Searches a given text for the specified value.
-- @realm shared
-- @string txt The text to search in.
-- @string find The value to search for.
-- @return boolean Whether or not the value was found.
function ax.util:FindText(txt, find)
	if ( txt == nil or find == nil ) then
		ax.util:PrintError("Attempted to find a string with no value to find for! (" .. txt .. ", " .. find .. ")")
		return false
	end

	local words = string.Explode(" ", txt)
	for k, v in ipairs(words) do
		if ( self:FindString(v, find) ) then
			return true
		end
	end

	return false
end

--- Searches for a string in a table.
-- @realm shared
-- @param tbl table The table to search in.
-- @param find string The string to search for.
function ax.util:FindInTable(tbl, find)
	if ( !istable(tbl) or !isstring(find) ) then
		ax.util:PrintError("Attempted to find a string in a table with no value to find for! (" .. tostring(tbl) .. ", " .. tostring(find) .. ")")
		return false
	end

	for k, v in pairs(tbl) do
		if ( self:FindString(v, find) ) then
			return true
		end
	end

	return false
end

--- Searches for a player based on the given identifier.
-- @realm shared
-- @param identifier any The identifier to search for.
-- @return Player The player that was found.
function ax.util:FindPlayer(identifier)
	if ( identifier == nil ) then return NULL end

	if ( type(identifier) == "Player" ) then
		return identifier
	end

	if ( isnumber(identifier) ) then
		return Player(identifier)
	end

	if ( isstring(identifier) ) then
		if (string.find(identifier, "STEAM_(%d+):(%d+):(%d+)")) then
			return player.GetBySteamID(identifier)
		elseif (string.find(identifier, "7656119%d+")) then
			return player.GetBySteamID64(identifier)
		end

		for _, v in player.Iterator() do
			if ( self:FindString(v:Name(), identifier) or self:FindString(v:SteamID(), identifier) or self:FindString(v:SteamID64(), identifier) ) then
				return v
			end
		end
	end

	if ( istable(identifier) ) then
		for k, v in ipairs(identifier) do
			local foundPlayer = self:FindPlayer(v)
			if ( IsValid(foundPlayer) ) then
				return foundPlayer
			end
		end
	end

	return NULL
end

--- Breaks a string into lines that fit within a maximum width in pixels.
-- Words are wrapped cleanly, and long words are split by character if needed.
-- @realm client
-- @param text string The text to wrap.
-- @param font string Font name to use.
-- @param maxWidth number Maximum allowed width in pixels.
-- @return table Table of wrapped lines.
-- @usage local lines = ax.util:GetWrappedText("Long example string", "DermaDefault", 250)
function ax.util:GetWrappedText(text, font, maxWidth)
	if ( !isstring(text) or !isstring(font) or !isnumber(maxWidth) ) then
		ax.util:PrintError("Attempted to wrap text with no value", text, font, maxWidth)
		return false
	end

	local lines = {}
	local line = ""

	if ( self:GetTextWidth(font, text) <= maxWidth ) then
		return {text}
	end

	local words = string.Explode(" ", text)

	for i = 1, #words do
		local word = words[i]
		local wordWidth = self:GetTextWidth(font, word)

		if ( wordWidth > maxWidth ) then
			for j = 1, string.len(word) do
				local char = string.sub(word, j, j)
				local next = line .. char

				if ( self:GetTextWidth(font, next) > maxWidth ) then
					table.insert(lines, line)
					line = ""
				end

				line = line .. char
			end

			continue
		end

		local space = (line == "") and "" or " "
		local next = line .. space .. word

		if ( self:GetTextWidth(font, next) > maxWidth ) then
			table.insert(lines, line)
			line = word
		else
			line = next
		end
	end

	if ( line != "" ) then
		table.insert(lines, line)
	end

	return lines
end

--- Gets the bounds of a box, providing the center, minimum, and maximum points.
-- @realm shared
-- @param startpos Vector The starting position of the box.
-- @param endpos Vector The ending position of the box.
-- @return Vector The center of the box.
function ax.util:GetBounds(startpos, endpos)
	local center = LerpVector(0.5, startpos, endpos)
	local min = WorldToLocal(startpos, angle_zero, center, angle_zero)
	local max = WorldToLocal(endpos, angle_zero, center, angle_zero)

	return center, min, max
end

do
	local i
	local value
	local character

	local function iterator(clientTable)
		repeat
			i = i + 1
			value = clientTable[i]
			character = value and value:GetCharacter()
		until character or value == nil

		return value, character
	end

	function ax.util:GetCharacters()
		i = 0
		return iterator, select(2, player.Iterator())
	end
end

function ax.util:IsPlayerReceiver(obj)
	return IsValid(obj) and obj:IsPlayer()
end

function ax.util:SafeParseTable(input)
	if ( istable(input) ) then
		return input
	elseif ( isstring(input) and input != "" and input != "[]" ) then
		return util.JSONToTable(input) or {}
	end

	return {}
end

local directions = {
	{ min = -180.0, max = -157.5, name = "S"  },
	{ min = -157.5, max = -112.5, name = "SE" },
	{ min = -112.5, max = -67.5,  name = "E"  },
	{ min = -67.5,  max = -22.5,  name = "NE" },
	{ min = -22.5,  max = 22.5,   name = "N"  },
	{ min = 22.5,   max = 67.5,   name = "NW" },
	{ min = 67.5,   max = 112.5,  name = "W"  },
	{ min = 112.5,  max = 157.5,  name = "SW" },
	{ min = 157.5,  max = 180.0,  name = "S"  }
}

--- Returns the compass direction from a yaw angle using a lookup table.
-- @param ang Angle The angle to interpret.
-- @return string Compass heading (e.g., "N", "SW")
-- @usage local heading = ax.util:GetHeadingFromAngle(client:EyeAngles())
function ax.util:GetHeadingFromAngle(ang)
	local yaw = ang.yaw or ang[2]

	for _, dir in ipairs(directions) do
		if ( yaw > dir.min and yaw <= dir.max ) then
			return dir.name
		end
	end

	return "N" -- Default to North if no match is found
end

ax.util.activeSoundQueues = ax.util.activeSoundQueues or {}

--- Queues and plays a sound sequence with controlled pacing.
-- Uses a polling step interval instead of chained timers.
-- @param ent Entity Entity to emit from.
-- @param queue table Table of sounds or {path, preDelay, postDelay}
-- @param volume number Volume to play at.
-- @param pitch number Pitch to play at.
function ax.util:QueueSounds(ent, queue, volume, pitch)
	if ( !IsValid(ent) or !istable(queue) or #queue == 0 ) then return end

	local data = {
		entity = ent,
		sounds = queue,
		volume = volume or 75,
		pitch = pitch or 100,
		current = 1,
		nextTime = CurTime()
	}

	local id = tostring(ent) .. "_" .. CurTime()
	ax.util.activeSoundQueues[id] = data

	timer.Create("ax.sound.queue." .. id, 0.1, 0, function()
		if ( !IsValid(data.entity) or !data.sounds[data.current] ) then
			timer.Remove("ax.sound.queue." .. id)
			ax.util.activeSoundQueues[id] = nil
			return
		end

		if ( CurTime() < data.nextTime ) then return end

		local soundEntry = data.sounds[data.current]
		local path, pre, post

		if ( isstring(soundEntry) ) then
			path, pre, post = soundEntry, 0, 0
		else
			path = soundEntry[1]
			pre  = soundEntry[2] or 0
			post = soundEntry[3] or 0
		end

		-- apply pre-delay only before playback
		data.nextTime = CurTime() + pre

		-- emit sound after pre-delay expires
		timer.Simple(pre, function()
			if ( IsValid(data.entity) ) then
				data.entity:EmitSound(path, data.volume, data.pitch)
			end
		end)

		local dur = SoundDuration(path) or 1.0
		data.nextTime = data.nextTime + dur + post
		data.current = data.current + 1
	end)
end

--- Includes Lua files for a defined entity folder path.
-- @param path string Path to the entity directory.
-- @param clientOnly boolean Whether inclusion should be client-only.
-- @return boolean True if any file was included successfully.
function ax.util:LoadEntityFile(path, clientOnly)
	if ( SERVER and file.Exists(path .. "init.lua", "LUA") ) or ( CLIENT and file.Exists(path .. "cl_init.lua", "LUA") ) then
		ax.util:LoadFile(path .. "init.lua", clientOnly and "client" or "server")

		if ( file.Exists(path .. "cl_init.lua", "LUA") ) then
			ax.util:LoadFile(path .. "cl_init.lua", "client")
		end

		return true
	elseif ( file.Exists(path .. "shared.lua", "LUA") ) then
		ax.util:LoadFile(path .. "shared.lua", "shared")
		return true
	end

	return false
end

--- Scans a folder and registers all contained entity files.
-- @param basePath string Base directory path.
-- @param folder string Subfolder to search (e.g., "entities").
-- @param globalKey string Global variable name to assign during load (e.g., "ENT").
-- @param registerFn function Function to register the entity.
-- @param default table? Default values for the global table.
-- @param clientOnly boolean? Whether registration should only happen on client.
function ax.util:LoadEntityFolder(basePath, folder, globalKey, registerFn, default, clientOnly)
	local fullPath = basePath .. "/" .. folder .. "/"
	local files, folders = file.Find(fullPath .. "*", "LUA")
	default = default or {}

	for _, dir in ipairs(folders) do
		local subPath = fullPath .. dir .. "/"

		_G[globalKey] = table.Copy(default)
		_G[globalKey].ClassName = dir

		if ( self:LoadEntityFile(subPath, clientOnly) ) then
			if ( !clientOnly or CLIENT ) then
				registerFn(_G[globalKey], dir)
			end
		end

		_G[globalKey] = nil
	end

	for _, fileName in ipairs(files) do
		local class = string.StripExtension(fileName)

		_G[globalKey] = table.Copy(default)
		_G[globalKey].ClassName = class

		self:LoadFile(fullPath .. fileName, clientOnly and "client" or "shared")

		if ( !clientOnly or CLIENT ) then
			registerFn(_G[globalKey], class)
		end

		_G[globalKey] = nil
	end
end

--- Loads and registers toolgun tools from a custom path.
-- Mimics GMod's native behavior for loading from stools/ folder.
-- @param path string Path to the folder containing tool files.
-- @realm shared
function ax.util:LoadTools(path)
	local files, folders = file.Find(path .. "/*.lua", "LUA")

	for _, fileName in ipairs(files) do
		local toolID = string.StripExtension(fileName)
		local toolPath = path .. "/" .. fileName

		TOOL = {
			Mode = toolID,
			Category = "Parallax",
			Name = "#" .. toolID,
			ClientConVar = {},
			ServerConVar = {}
		}

		self:LoadFile(toolPath, "shared")

		if ( !weapons.GetStored("gmod_tool") ) then
			ErrorNoHalt("gmod_tool base not found; skipping tool '" .. toolID .. "'\n")
			TOOL = nil
			continue
		end

		weapons.GetStored("gmod_tool").Tool = weapons.GetStored("gmod_tool").Tool or {}
		weapons.GetStored("gmod_tool").Tool[toolID] = TOOL

		TOOL = nil
	end

	for _, dir in ipairs(folders) do
		local toolPath = path .. "/" .. dir .. "/shared.lua"

		if ( file.Exists(toolPath, "LUA") ) then
			TOOL = {
				Mode = dir,
				Category = "Parallax",
				Name = "#" .. dir,
				ClientConVar = {},
				ServerConVar = {}
			}

			self:LoadFile(toolPath, "shared")

			if ( !weapons.GetStored("gmod_tool") ) then
				ErrorNoHalt("gmod_tool base not found; skipping tool '" .. dir .. "'\n")
				TOOL = nil
				continue
			end

			weapons.GetStored("gmod_tool").Tool = weapons.GetStored("gmod_tool").Tool or {}
			weapons.GetStored("gmod_tool").Tool[dir] = TOOL

			TOOL = nil
		end
	end
end

--- Loads all entities, weapons, and effects from a module or schema directory.
-- @param path string Path to module or schema folder.
-- @realm shared
function ax.util:LoadEntities(path)
	self:LoadEntityFolder(path, "entities", "ENT", scripted_ents.Register, {
		Type = "anim",
		Base = "base_gmodentity",
		Spawnable = true
	})

	self:LoadEntityFolder(path, "weapons", "SWEP", weapons.Register, {
		Primary = {},
		Secondary = {},
		Base = "weapon_base"
	})

	self:LoadEntityFolder(path, "effects", "EFFECT", effects and effects.Register, nil, true)

	self:LoadTools(path .. "/tools")
end

--- Returns the current difference between local time and UTC in seconds.
-- @realm shared
-- @return number Time difference to UTC in seconds
-- @usage local utcOffset = ax.util:GetUTCTime()
function ax.util:GetUTCTime()
	local utcTable = os.date("!*t")
	local localTable = os.date("*t")

	localTable.isdst = false

	return os.difftime(os.time(utcTable), os.time(localTable))
end

local time = {
	s = 1,                  -- Seconds
	m = 60,                 -- Minutes
	h = 3600,               -- Hours
	d = 86400,              -- Days
	w = 604800,             -- Weeks
	mo = 2592000,           -- Months (approximate)
	y = 31536000            -- Years (approximate)
}

--- Converts a formatted time string into total seconds.
-- @realm shared
-- @string input Text to interpret (e.g., "5y2d7w")
-- @return number Time in seconds
-- @return boolean True if format was valid, false otherwise
-- @usage local seconds = ax.util:GetStringTime("2h30m")
function ax.util:GetStringTime(input)
	local rawMinutes = tonumber(input)
	if ( rawMinutes ) then
		return math.abs(rawMinutes * 60), true
	end

	local totalSeconds = 0
	local hasValidUnit = false

	for numberStr, suffix in input:lower():gmatch("(%d+)(%a+)") do
		local count = tonumber(numberStr)
		local multiplier = time[suffix]

		if ( count and multiplier ) then
			totalSeconds = totalSeconds + math.abs(count * multiplier)
			hasValidUnit = true
		end
	end

	return totalSeconds, hasValidUnit
end

local stored = {}

--- Returns a material with the given path and parameters.
-- @realm shared
-- @param path string The path to the material.
-- @param parameters string The parameters to apply to the material.
-- @return Material The material that was created.
-- @usage local vignette = ax.util:GetMaterial("parallax/overlay_vignette.png")
-- surface.SetMaterial(vignette)
function ax.util:GetMaterial(path, parameters)
	if ( !tostring(path) ) then
		ax.util:PrintError("Attempted to get a material with no path", path, parameters)
		return false
	end

	parameters = tostring(parameters or "")
	local uniqueID = Format("material.%s.%s", path, parameters)

	if ( stored[uniqueID] ) then
		return stored[uniqueID]
	end

	local mat = Material(path, parameters)
	stored[uniqueID] = mat

	return mat
end

function ax.util:ZeroNumber(number, digits)
	local str = tostring(number)
	return string.rep("0", digits - #str) .. str
end

if ( CLIENT ) then
	--- Returns the given text's width.
	-- @realm client
	-- @param font string The font to use.
	-- @param text string The text to measure.
	-- @return number The width of the text.
	function ax.util:GetTextWidth(font, text)
		surface.SetFont(font)
		return select(1, surface.GetTextSize(text))
	end

	--- Returns the given text's height.
	-- @realm client
	-- @param font string The font to use.
	-- @return number The height of the text.
	function ax.util:GetTextHeight(font)
		surface.SetFont(font)
		return select(2, surface.GetTextSize("W"))
	end

	--- Returns the given text's size.
	-- @realm client
	-- @param font string The font to use.
	-- @param text string The text to measure.
	-- @return number The width of the text.
	-- @return number The height of the text.
	function ax.util:GetTextSize(font, text)
		surface.SetFont(font)
		return surface.GetTextSize(text)
	end

	local blurMaterial = ax.util:GetMaterial("pp/blurscreen")
	local scrW, scrH = ScrW(), ScrH()

	--- Draws a blur within a panel’s bounds. Falls back to a dim overlay if blur is disabled.
	-- @param panel Panel Panel to apply blur to.
	-- @param intensity number Blur strength (0–10 suggested).
	-- @param steps number Blur quality/steps. Defaults to 0.2.
	-- @param alpha number Overlay alpha (default 255).
	-- @usage ax.util:DrawBlur(panel, 6, 0.2, 200)
	function ax.util:DrawBlur(panel, intensity, steps, alpha)
		if ( !IsValid(panel) or alpha == 0 ) then return end

		if ( ax.option:Get("performance.blur") != true ) then
			surface.SetDrawColor(30, 30, 30, alpha or (intensity or 5) * 20)
			surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
			return
		end

		local x, y = panel:LocalToScreen(0, 0)
		local blurAmount = intensity or 5
		local passStep = steps or 0.2
		local overlayAlpha = alpha or 255

		surface.SetMaterial(blurMaterial)
		surface.SetDrawColor(255, 255, 255, overlayAlpha)

		for i = -passStep, 1, passStep do
			blurMaterial:SetFloat("$blur", i * blurAmount)
			blurMaterial:Recompute()

			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, scrW, scrH)
		end
	end

	--- Draws a blur within an arbitrary screen rectangle. Not intended for panels.
	-- @param x number X position.
	-- @param y number Y position.
	-- @param width number Width.
	-- @param height number Height.
	-- @param intensity number Blur strength (0–10 suggested).
	-- @param steps number Blur quality/steps. Defaults to 0.2.
	-- @param alpha number Overlay alpha (default 255).
	-- @usage ax.util:DrawBlurRect(0, 0, 512, 256, 8, 0.2, 180)
	function ax.util:DrawBlurRect(x, y, width, height, intensity, steps, alpha)
		if ( alpha == 0 ) then return end

		if ( ax.option:Get("performance.blur") != true ) then
			surface.SetDrawColor(30, 30, 30, alpha or (intensity or 5) * 20)
			surface.DrawRect(x, y, width, height)
			return
		end

		local blurAmount = intensity or 5
		local passStep = steps or 0.2
		local overlayAlpha = alpha or 255

		local u0, v0 = x / scrW, y / scrH
		local u1, v1 = (x + width) / scrW, (y + height) / scrH

		surface.SetMaterial(blurMaterial)
		surface.SetDrawColor(255, 255, 255, overlayAlpha)

		for i = -passStep, 1, passStep do
			blurMaterial:SetFloat("$blur", i * blurAmount)
			blurMaterial:Recompute()

			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRectUV(x, y, width, height, u0, v0, u1, v1)
		end
	end
end