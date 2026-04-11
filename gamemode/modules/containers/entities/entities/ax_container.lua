--[[
	Parallax Framework
	Copyright (c) 2026 Parallax Framework Contributors

	This file is part of the Parallax Framework and is licensed under the MIT License.
	You may use, copy, modify, merge, publish, distribute, and sublicense this file
	under the terms of the LICENSE file included with this project.

	Attribution is required. If you use or modify this file, you must retain this notice.
]]

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Container"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

local function GetCharacterID(client)
	local character = ax.util:IsValidPlayer(client) and client:GetCharacter() or nil
	if ( !istable(character) ) then
		return nil
	end

	return character.id or (isfunction(character.GetID) and character:GetID()) or nil
end

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "ID")
	self:NetworkVar("Bool", 0, "Locked")
	self:NetworkVar("String", 0, "DisplayName")
end

function ENT:GetDefinition()
	return ax.container and ax.container:Get(self) or nil
end

function ENT:SetInventory(inventory)
	self.inventory = inventory

	if ( istable(inventory) ) then
		self:SetID(inventory.id)
	end
end

function ENT:GetInventory()
	local inventories = ax.item and ax.item.inventories or nil
	if ( istable(inventories) ) then
		return inventories[self:GetID()]
	end

	return ax.inventory and ax.inventory.instances and ax.inventory.instances[self:GetID()] or nil
end

function ENT:SetMoney(amount)
	self.axMoney = math.max(math.floor(tonumber(amount) or 0), 0)
end

function ENT:GetMoney()
	return math.max(math.floor(tonumber(self.axMoney) or 0), 0)
end

if ( SERVER ) then
	function ENT:Initialize()
		local definition = self:GetDefinition()

		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		if ( definition and self:GetDisplayName() == "" ) then
			self:SetDisplayName(definition.name)
		end

		self.Sessions = self.Sessions or {}
		self.PasswordAttempts = self.PasswordAttempts or {}

		local physicsObject = self:GetPhysicsObject()
		if ( IsValid(physicsObject) ) then
			physicsObject:EnableMotion(true)
			physicsObject:Wake()
		end
	end

	function ENT:OnRemove()
		local inventory = self:GetInventory()
		local moduleTable = ax.container and ax.container.module or nil

		if ( istable(inventory) ) then
			local receivers = table.Copy(inventory:GetReceivers() or {})

			for _ = 1, #receivers do
				local receiver = receivers[_]
				if ( istable(moduleTable) and isfunction(moduleTable.CloseContainerForClient) ) then
					moduleTable:CloseContainerForClient(receiver, self)
				end
			end
		end

		if ( ax.shuttingDown or !ax.entityDataLoaded or self.axIsSafe ) then
			return
		end

		if ( istable(moduleTable) and isfunction(moduleTable.DeleteInventoryData) ) then
			moduleTable:DeleteInventoryData(inventory, true)
		end

		hook.Run("ContainerRemoved", self, inventory)
	end

	function ENT:Use(activator)
		if ( !ax.util:IsValidPlayer(activator) ) then
			return
		end

		if ( activator.axNextOpen and activator.axNextOpen > CurTime() ) then
			return
		end

		activator.axNextOpen = CurTime() + 1

		if ( self:GetLocked() ) then
			local charID = GetCharacterID and GetCharacterID(activator) or nil
			self.Sessions = self.Sessions or {}

			if ( !charID or !self.Sessions[charID] ) then
				local definition = self:GetDefinition()
				self:EmitSound(definition and definition.locksound or "doors/default_locked.wav")

				if ( !self.keypad ) then
					ax.net:Start(activator, "container.password.prompt", self)
				end

				return
			end
		end

		self:OpenInventory(activator)
	end

	function ENT:OpenInventory(activator)
		if ( !ax.util:IsValidPlayer(activator) ) then
			return
		end

		if ( activator.axOpenContainer == self ) then
			return
		end

		local inventory = self:GetInventory()
		if ( !istable(inventory) ) then
			activator:Notify(ax.localization:GetPhrase("container.not_ready"), "error")
			return
		end

		local moduleTable = ax.container and ax.container.module or nil
		local definition = self:GetDefinition()
		local displayName = self:GetDisplayName() != "" and self:GetDisplayName() or (definition and definition.name or "Container")
		local searchTime = ax.container:GetSearchTime(definition, ax.config:Get("container.default.open_time", 0.7))
		local charID = GetCharacterID and GetCharacterID(activator) or nil

		local function FinishOpen()
			if ( !IsValid(self) or !ax.util:IsValidPlayer(activator) ) then
				return
			end

			if ( istable(moduleTable) and isfunction(moduleTable.CloseContainerForClient) ) then
				moduleTable:CloseContainerForClient(activator)
			end

			inventory:AddReceiver(activator)
			ax.inventory:Sync(inventory)

			activator.axOpenContainer = self
			activator.axOpenContainerInventory = inventory.id

			if ( self:GetLocked() and charID ) then
				self.Sessions = self.Sessions or {}
				self.Sessions[charID] = true
			end

			ax.net:Start(activator, "container.open", self, inventory.id, displayName, searchTime, self:GetMoney(), inventory:GetMaxWeight())

			if ( definition and isfunction(definition.OnOpen) ) then
				definition.OnOpen(self, activator)
			end

			ax.container:Log("containerOpen", activator, string.format(
				"%s (%s) opened %s.",
				activator:SteamName(),
				activator:SteamID64(),
				displayName
			))
		end

		if ( searchTime > 0 ) then
			activator:PerformEntityAction(self, ax.localization:GetPhrase("container.opening", displayName), searchTime, FinishOpen, nil, true, 128)
			return
		end

		FinishOpen()
	end
end

function ENT:GetDisplayDescription()
	local definition = self:GetDefinition()
	return definition and definition.description or ""
end
