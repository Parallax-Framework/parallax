--[[
	Parallax Framework
	Copyright (c) 2026 Parallax Framework Contributors

	This file is part of the Parallax Framework and is licensed under the MIT License.
	You may use, copy, modify, merge, publish, distribute, and sublicense this file
	under the terms of the LICENSE file included with this project.

	Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

ax.container = ax.container or {}
ax.container.stored = ax.container.stored or {}
ax.container.module = MODULE

ax.item.inventories = ax.item.inventories or ax.inventory.instances

local DATA_OPTIONS = {
	scope = "map",
	human = true,
}

local PROPERTY_PRIVILEGES = {
	container_setpassword = "Parallax - Container Set Password",
	container_setname = "Parallax - Container Set Name",
}

local function GetModuleDataKey(moduleTable)
	return "module_" .. tostring(moduleTable.uniqueID or "containers")
end

local function NormalizeModel(model)
	if ( !isstring(model) ) then
		return nil
	end

	model = string.Trim(string.lower(model))

	if ( model == "" ) then
		return nil
	end

	return model
end

local function NormalizeColorValue(value)
	if ( IsColor(value) ) then
		return Color(value.r, value.g, value.b, value.a or 255)
	end

	if ( !istable(value) ) then
		return nil
	end

	local red = tonumber(value.r)
	local green = tonumber(value.g)
	local blue = tonumber(value.b)
	if ( !red or !green or !blue ) then
		return nil
	end

	return Color(red, green, blue, tonumber(value.a) or 255)
end

local function NormalizeDefinitionData(data)
	local normalized = table.Copy(data)
	local inventoryData = istable(data.inventory) and data.inventory or {}
	local interactionData = istable(data.interaction) and data.interaction or {}
	local lockingData = istable(data.locking) and data.locking or {}

	normalized.name = string.Trim(data.name)
	normalized.description = data.description
	normalized.maxWeight = math.max(tonumber(
		data.maxWeight
		or data.weight
		or inventoryData.maxWeight
		or inventoryData.weight
	) or 0, 0)
	normalized.searchTime = math.max(tonumber(
		data.searchTime
		or data.openTime
		or interactionData.searchTime
		or interactionData.openTime
	) or 0, 0)
	normalized.money = math.max(math.floor(tonumber(
		data.money
		or data.defaultMoney
		or interactionData.money
	) or 0), 0)
	normalized.color = NormalizeColorValue(data.color)
	normalized.locksound = isstring(
		data.locksound
		or lockingData.sound
	) and string.Trim(data.locksound or lockingData.sound or "") or ""
	normalized.OnOpen = data.OnOpen
	normalized.OnClose = data.OnClose
	normalized.inventory = {
		maxWeight = normalized.maxWeight,
	}
	normalized.interaction = {
		searchTime = normalized.searchTime,
		money = normalized.money,
	}
	normalized.locking = {
		sound = normalized.locksound,
	}

	if ( normalized.locksound == "" ) then
		normalized.locksound = "doors/default_locked.wav"
		normalized.locking.sound = normalized.locksound
	end

	return normalized
end

function ax.container:Register(model, data)
	model = NormalizeModel(model)
	if ( !model ) then
		ErrorNoHalt("[Parallax] ax.container:Register called with an invalid model.\n")
		return false
	end

	if ( !istable(data) ) then
		ErrorNoHalt("[Parallax] ax.container:Register called with invalid data for model '" .. model .. "'.\n")
		return false
	end

	if ( !isstring(data.name) or data.name == "" ) then
		ErrorNoHalt("[Parallax] ax.container:Register missing name for model '" .. model .. "'.\n")
		return false
	end

	if ( !isstring(data.description) ) then
		ErrorNoHalt("[Parallax] ax.container:Register missing description for model '" .. model .. "'.\n")
		return false
	end

	local stored = NormalizeDefinitionData(data)

	if ( stored.maxWeight <= 0 ) then
		ErrorNoHalt("[Parallax] ax.container:Register missing valid maxWeight for model '" .. model .. "'.\n")
		return false
	end

	ax.container.stored[model] = stored

	return stored
end

function ax.container:GetMaxWeight(definition, fallback)
	if ( !istable(definition) ) then
		return math.max(tonumber(fallback) or 0, 0)
	end

	return math.max(tonumber(definition.maxWeight or definition.weight) or tonumber(fallback) or 0, 0)
end

function ax.container:GetSearchTime(definition, fallback)
	if ( !istable(definition) ) then
		return math.max(tonumber(fallback) or 0, 0)
	end

	return math.max(tonumber(definition.searchTime or definition.openTime) or tonumber(fallback) or 0, 0)
end

function ax.container:GetStartingMoney(definition)
	if ( !istable(definition) ) then
		return 0
	end

	return math.max(math.floor(tonumber(definition.money) or 0), 0)
end

function ax.container:Get(modelOrEntity)
	if ( IsValid(modelOrEntity) ) then
		modelOrEntity = modelOrEntity:GetModel()
	end

	local model = NormalizeModel(modelOrEntity)
	if ( !model ) then
		return nil
	end

	return self.stored[model]
end

function ax.container:GetPropertyPrivilege(propertyName)
	return PROPERTY_PRIVILEGES[propertyName]
end

function ax.container:CanEditProperty(client, propertyName, entity)
	if ( !ax.util:IsValidPlayer(client) ) then
		return false
	end

	if ( !IsValid(entity) or entity:GetClass() != "ax_container" ) then
		return false
	end

	local privilege = self:GetPropertyPrivilege(propertyName)
	if ( !privilege ) then
		return false
	end

	if ( istable(CAMI) and isfunction(CAMI.PlayerHasAccess) ) then
		local hasAccess = CAMI.PlayerHasAccess(client, privilege, nil)
		if ( hasAccess != nil ) then
			return hasAccess == true
		end
	end

	return client:IsAdmin() or client:IsSuperAdmin()
end

function ax.container:Log(logType, client, message)
	logType = tostring(logType or "container")
	message = tostring(message or "")

	if ( ax.log ) then
		if ( isfunction(ax.log.Add) ) then
			ax.log:Add(logType, client, message)
			return
		end

		if ( isfunction(ax.log.AddRaw) ) then
			ax.log:AddRaw("[" .. logType .. "] " .. message)
			return
		end
	end

	ax.util:Print("[Containers][" .. logType .. "] " .. message)
end

function MODULE:GetData()
	local data = ax.data:Get(GetModuleDataKey(self), {}, DATA_OPTIONS)

	if ( !istable(data) ) then
		return {}
	end

	return data
end

if ( SERVER ) then
	function MODULE:SetData(data)
		return ax.data:Set(GetModuleDataKey(self), istable(data) and data or {}, DATA_OPTIONS)
	end
end

if ( istable(CAMI) and isfunction(CAMI.RegisterPrivilege) ) then
	CAMI.RegisterPrivilege({
		Name = PROPERTY_PRIVILEGES.container_setpassword,
		MinAccess = "admin",
	})

	CAMI.RegisterPrivilege({
		Name = PROPERTY_PRIVILEGES.container_setname,
		MinAccess = "admin",
	})
end

function MODULE:OnLoaded()
	ax.container.module = self
	ax.item.inventories = ax.inventory.instances
end

function MODULE:InitializedModules()
	ax.container.module = self
	ax.item.inventories = ax.inventory.instances
end

function MODULE:CanProperty(client, prop, entity)
	if ( prop != "container_setpassword" and prop != "container_setname" ) then
		return
	end

	return ax.container:CanEditProperty(client, prop, entity)
end
