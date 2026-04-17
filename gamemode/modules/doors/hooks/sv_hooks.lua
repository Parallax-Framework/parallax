local MODULE = MODULE

function MODULE:PlayerUse(client, entity)
	if ( !entity:IsDoor() ) then return end

	if ( client:KeyDown(IN_WALK) ) then
		local isLocked = entity:IsLocked()
		local permsNeeded = isLocked and MODULE.Permissions.UNLOCK or MODULE.Permissions.LOCK

		if ( client:HasDoorAccess(entity, permsNeeded) ) then
			client:PerformEntityAction(entity, isLocked and "Unlock" or "Lock", 0.5, function()
				entity:ToggleDoorLock()
			end, nil)
		end

		return false
	end
end

function MODULE:PlayerReady(client)
	ax.net:Start(client, "ax.doors.permissions_sync", MODULE.AccessGroup_Permissions)
end

function MODULE:InitPostEntity()
	local bInitialized = ax.data:Get("doors_initialized", false, {
		scope = "map",
		force = true,
	})

	if ( !bInitialized ) then
		local unownableData = {}

		for _, ent in ipairs(ents.GetAll()) do
			if ( ent:IsDoor() ) then
				ent:SetRelay("ownable", false)
				unownableData[ent:MapCreationID()] = true
			end
		end

		ax.data:Set("doors_unownable", unownableData, { scope = "map" })
		ax.data:Set("doors_initialized", true, { scope = "map" })
	else
		local unownableDoors = ax.data:Get("doors_unownable", {}, {
			scope = "map",
			force = true,
		})

		for doorID, isUnownable in pairs(unownableDoors) do
			local door = ents.GetMapCreatedEntity(doorID)
			if ( IsValid(door) and door:IsDoor() ) then
				door:SetRelay("ownable", !isUnownable)
			end
		end
	end

	for _, ent in ipairs(ents.GetAll()) do
		if ( ent:IsDoor() ) then
			ent:SetRelay("locked", ent:IsLocked())
		end
	end
end
