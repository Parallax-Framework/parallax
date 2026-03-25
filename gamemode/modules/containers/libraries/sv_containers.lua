--[[
	Parallax Framework
	Copyright (c) 2026 Parallax Framework Contributors

	This file is part of the Parallax Framework and is licensed under the MIT License.
	You may use, copy, modify, merge, publish, distribute, and sublicense this file
	under the terms of the LICENSE file included with this project.

	Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

local function GetCharacterID(client)
	local character = ax.util:IsValidPlayer(client) and client:GetCharacter() or nil
	if ( !istable(character) ) then
		return nil
	end

	return character.id or (isfunction(character.GetID) and character:GetID()) or nil
end

function ax.container:ApplyInventoryData(inventory, definition)
	if ( !istable(inventory) ) then
		return
	end

	local defaultMaxWeight = math.max(tonumber(ax.config:Get("container.default.max_weight", 16)) or 16, 1)
	local maxWeight = self:GetMaxWeight(definition, inventory.maxWeight or defaultMaxWeight)

	inventory.maxWeight = math.max(maxWeight, 1)
	inventory.data = inventory.data or {}
	inventory.data.container = inventory.data.container or {}
	inventory.data.container.maxWeight = inventory.maxWeight
	inventory.data.maxWeight = inventory.maxWeight

	if ( !isnumber(inventory.id) or inventory.id < 1 ) then
		return
	end

	local query = mysql:Update("ax_inventories")
		query:Update("max_weight", inventory.maxWeight)
		query:Update("data", util.TableToJSON(inventory.data or {}))
		query:Where("id", inventory.id)
	query:Execute()
end

function ax.container:RestoreInventory(inventoryID, definition, callback)
	inventoryID = tonumber(inventoryID) or 0
	if ( inventoryID < 1 ) then
		if ( isfunction(callback) ) then
			callback(false)
		end

		return
	end

	local existing = ax.inventory.instances[inventoryID]
	if ( getmetatable(existing) == ax.inventory.meta ) then
		ax.container:ApplyInventoryData(existing, definition)

		if ( isfunction(callback) ) then
			callback(existing)
		end

		return
	end

	local inventoryQuery = mysql:Select("ax_inventories")
	inventoryQuery:Where("id", inventoryID)
	inventoryQuery:Callback(function(result, status)
		if ( result == nil or status == false or !istable(result) or !result[1] ) then
			if ( isfunction(callback) ) then
				callback(false)
			end

			return
		end

		local row = result[1]
		local inventory = setmetatable({}, ax.inventory.meta)
		inventory.id = tonumber(row.id) or inventoryID
		inventory.items = {}
		inventory.maxWeight = tonumber(row.maxWeight or row.max_weight) or 30.0
		inventory.receivers = {}

		local storedData = util.JSONToTable(row.data or "[]") or {}
		inventory.data = storedData
		ax.container:ApplyInventoryData(inventory, {
			maxWeight = ax.container:GetMaxWeight(definition, storedData.maxWeight or (storedData.container and storedData.container.maxWeight) or inventory.maxWeight),
		})

		local itemFetchQuery = mysql:Select("ax_items")
		itemFetchQuery:Where("inventory_id", inventory.id)
		itemFetchQuery:Callback(function(itemsResult, itemsStatus)
			if ( itemsResult == nil or itemsStatus == false ) then
				if ( isfunction(callback) ) then
					callback(false)
				end

				return
			end

			local items = {}
			for i = 1, #itemsResult do
				local itemData = itemsResult[i]
				local itemClass = itemData.class
				if ( !ax.item.stored[itemClass] ) then
					continue
				end

				local itemID = tonumber(itemData.id) or 0
				if ( itemID < 1 ) then
					continue
				end

				local itemObject = ax.item:Instance(itemID, itemClass)
				if ( !istable(itemObject) ) then
					continue
				end

				itemObject.invID = inventory.id
				itemObject.data = util.JSONToTable(itemData.data or "[]") or {}

				ax.item.instances[itemObject.id] = itemObject
				items[itemObject.id] = itemObject
			end

			inventory.items = items
			ax.inventory.instances[inventory.id] = inventory
			ax.item.inventories = ax.inventory.instances

			if ( isfunction(callback) ) then
				callback(inventory)
			end
		end)
		itemFetchQuery:Execute()
	end)
	inventoryQuery:Execute()
end

function MODULE:DeleteInventoryData(inventory, bRemoveMemory)
	if ( !istable(inventory) ) then
		return
	end

	local inventoryID = tonumber(inventory.id or (isfunction(inventory.GetID) and inventory:GetID())) or 0
	if ( inventoryID < 1 ) then
		return
	end

	local itemIDs = {}
	for itemID in pairs(inventory.items or {}) do
		itemIDs[#itemIDs + 1] = itemID
	end

	local deleteItemsQuery = mysql:Delete("ax_items")
		deleteItemsQuery:Where("inventory_id", inventoryID)
	deleteItemsQuery:Execute()

	local deleteInventoryQuery = mysql:Delete("ax_inventories")
		deleteInventoryQuery:Where("id", inventoryID)
	deleteInventoryQuery:Execute()

	if ( bRemoveMemory == true ) then
		if ( isfunction(inventory.RemoveReceivers) ) then
			inventory:RemoveReceivers()
		end

		for i = 1, #itemIDs do
			ax.item.instances[itemIDs[i]] = nil
		end

		ax.inventory.instances[inventoryID] = nil
		ax.item.inventories = ax.inventory.instances
	end
end

function MODULE:CloseContainerForClient(client, entity)
	if ( !ax.util:IsValidPlayer(client) ) then
		return
	end

	entity = IsValid(entity) and entity or client.axOpenContainer

	local inventoryID = tonumber(client.axOpenContainerInventory) or 0
	local inventory = inventoryID > 0 and ax.inventory.instances[inventoryID] or nil
	if ( !istable(inventory) and IsValid(entity) ) then
		inventory = entity:GetInventory()
	end

	if ( istable(inventory) and isfunction(inventory.IsReceiver) and inventory:IsReceiver(client) ) then
		inventory:RemoveReceiver(client)
	end

	if ( IsValid(entity) and client.axOpenContainer == entity ) then
		local definition = ax.container:Get(entity)
		if ( definition and isfunction(definition.OnClose) ) then
			definition.OnClose(entity, client)
		end

		ax.container:Log("containerClose", client, string.format(
			"%s (%s) closed %s.",
			client:SteamName(),
			client:SteamID64(),
			entity:GetDisplayName() != "" and entity:GetDisplayName() or (definition and definition.name or "container")
		))
	end

	client.axOpenContainer = nil
	client.axOpenContainerInventory = nil
end

function MODULE:TryLoadContainerData()
	if ( self.axContainersLoaded ) then
		return
	end

	if ( !self.axDatabaseReady or !self.axWorldReady ) then
		return
	end

	self.axContainersLoaded = true
	self:LoadData()
	ax.entityDataLoaded = true
end

function MODULE:SaveContainers()
	local data = {}

	for _, entity in ipairs(ents.FindByClass("ax_container")) do
		if ( !IsValid(entity) ) then
			continue
		end

		local inventory = entity:GetInventory()
		if ( !istable(inventory) ) then
			continue
		end

		if ( hook.Run("CanSaveContainer", entity, inventory) == false ) then
			self:DeleteInventoryData(inventory, false)
			continue
		end

		data[#data + 1] = {
			pos = entity:GetPos(),
			angles = entity:GetAngles(),
			inventoryID = inventory.id,
			model = string.lower(entity:GetModel() or ""),
			password = isstring(entity.password) and entity.password != "" and entity.password or nil,
			displayName = isstring(entity:GetDisplayName()) and entity:GetDisplayName() != "" and entity:GetDisplayName() or nil,
			money = entity:GetMoney() > 0 and entity:GetMoney() or nil,
			maxWeight = inventory:GetMaxWeight(),
		}
	end

	self:SetData(data)
end

properties.Add("container_setpassword", {
	MenuLabel = "Set Password",
	Order = 2000,
	MenuIcon = "icon16/lock_edit.png",

	Filter = function(self, entity, client)
		return hook.Run("CanProperty", client, "container_setpassword", entity) == true
	end,

	Receive = function(self, length, client)
		local entity = net.ReadEntity()
		local text = string.Trim(net.ReadString() or "")

		if ( hook.Run("CanProperty", client, "container_setpassword", entity) != true ) then
			return
		end

		entity.Sessions = {}
		entity.PasswordAttempts = {}

		if ( text != "" ) then
			entity.password = text
			entity:SetLocked(true)
			client:Notify(ax.localization:GetPhrase("container.password.updated"))
		else
			entity.password = nil
			entity:SetLocked(false)
			client:Notify(ax.localization:GetPhrase("container.password.cleared"))
		end

		MODULE:SaveContainers()
		ax.container:Log("containerPassword", client, string.format(
			"%s (%s) updated the password on %s.",
			client:SteamName(),
			client:SteamID64(),
			entity:GetDisplayName() != "" and entity:GetDisplayName() or "container"
		))
	end,
})

properties.Add("container_setname", {
	MenuLabel = "Set Name",
	Order = 2001,
	MenuIcon = "icon16/tag_blue_edit.png",

	Filter = function(self, entity, client)
		return hook.Run("CanProperty", client, "container_setname", entity) == true
	end,

	Receive = function(self, length, client)
		local entity = net.ReadEntity()
		local text = string.Trim(net.ReadString() or "")

		if ( hook.Run("CanProperty", client, "container_setname", entity) != true ) then
			return
		end

		local definition = ax.container:Get(entity)
		if ( !definition ) then
			return
		end

		if ( text != "" ) then
			entity:SetDisplayName(text)
			client:Notify(ax.localization:GetPhrase("container.name.updated"))
		else
			entity:SetDisplayName(definition.name)
			client:Notify(ax.localization:GetPhrase("container.name.reset"))
		end

		MODULE:SaveContainers()
		ax.container:Log("containerName", client, string.format(
			"%s (%s) renamed a container to %s.",
			client:SteamName(),
			client:SteamID64(),
			entity:GetDisplayName()
		))
	end,
})
