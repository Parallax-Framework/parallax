--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:SaveData()
	if ( ax.shuttingDown ) then
		return
	end

	self:SaveContainers()
end

function MODULE:LoadData()
	local data = self:GetData() or {}

	for i = 1, #data do
		local saved = data[i]
		local definition = ax.container:Get(saved.model)
		if ( !definition ) then
			continue
		end

		local entity = ents.Create("ax_container")
		if ( !IsValid(entity) ) then
			continue
		end

		entity:SetModel(saved.model)
		entity:SetPos(saved.pos)
		entity:SetAngles(saved.angles)
		entity:SetDisplayName(isstring(saved.displayName) and saved.displayName != "" and saved.displayName or definition.name)
		entity:Spawn()
		entity:Activate()
		entity:SetSolid(SOLID_VPHYSICS)
		entity:PhysicsInit(SOLID_VPHYSICS)

		local physicsObject = entity:GetPhysicsObject()
		if ( IsValid(physicsObject) ) then
			physicsObject:EnableMotion(true)
			physicsObject:Wake()
		end

		if ( saved.money != nil ) then
			entity:SetMoney(saved.money)
		end

		if ( isstring(saved.password) and saved.password != "" ) then
			entity.password = saved.password
			entity.Sessions = {}
			entity.PasswordAttempts = {}
			entity:SetLocked(true)
		end

		ax.container:RestoreInventory(saved.inventoryID, {
			maxWeight = saved.maxWeight or definition.maxWeight,
		}, function(inventory)
			if ( !IsValid(entity) or inventory == false or !istable(inventory) ) then
				return
			end

			entity:SetInventory(inventory)
		end)
	end
end

function MODULE:ContainerRemoved(entity, inventory)
	self:SaveContainers()
end

function MODULE:CanSaveContainer(entity, inventory)
	return ax.config:Get("container.save", true)
end

function MODULE:OnDatabaseTablesCreated()
	self.axDatabaseReady = true
	self:TryLoadContainerData()
end

function MODULE:InitPostEntity()
	self.axWorldReady = true
	self:TryLoadContainerData()
end

function MODULE:PlayerSpawnedProp(client, model, entity)
	if ( !IsValid(entity) ) then
		return
	end

	model = string.lower(tostring(model or entity:GetModel() or ""))

	local definition = ax.container:Get(model)
	if ( !definition ) then
		return
	end

	if ( hook.Run("CanPlayerSpawnContainer", client, model, entity) == false ) then
		return
	end

	local containerEntity = ents.Create("ax_container")
	if ( !IsValid(containerEntity) ) then
		return
	end

	containerEntity:SetPos(entity:GetPos())
	containerEntity:SetAngles(entity:GetAngles())
	containerEntity:SetModel(entity:GetModel())
	containerEntity:SetDisplayName(definition.name)
	containerEntity:Spawn()
	containerEntity:Activate()
	containerEntity:SetMoney(ax.container:GetStartingMoney(definition))

	ax.inventory:Create({
		maxWeight = ax.container:GetMaxWeight(definition, ax.config:Get("container.default.max_weight", 16)),
	}, function(inventory)
		if ( inventory == false or !istable(inventory) ) then
			if ( IsValid(containerEntity) ) then
				containerEntity.axIsSafe = true
				containerEntity:Remove()
			end

			return
		end

		ax.container:ApplyInventoryData(inventory, definition)

		if ( !IsValid(containerEntity) ) then
			self:DeleteInventoryData(inventory, true)
			return
		end

		containerEntity:SetInventory(inventory)
		self:SaveContainers()

		if ( IsValid(entity) ) then
			entity:Remove()
		end
	end)
end

function MODULE:PlayerDisconnected(client)
	self:CloseContainerForClient(client)
end

function MODULE:ShutDown()
	if ( self.axShutdownHandled ) then
		return
	end

	self.axShutdownHandled = true
	self:SaveData()
	ax.shuttingDown = true
end
