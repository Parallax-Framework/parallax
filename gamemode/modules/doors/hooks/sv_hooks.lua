local MODULE = MODULE

function MODULE:PlayerUse(client, entity)
	if ( !entity:IsDoor() ) then return end

	if ( client:KeyDown(IN_WALK) ) then
		local isLocked = entity:IsLocked()
		local permsNeeded = isLocked and MODULE.Permissions.UNLOCK or MODULE.Permissions.LOCK

		if ( client:HasDoorAccess(entity, permsNeeded) ) then
			client:PerformEntityAction(entity, isLocked and "Unlock" or "Lock", 0.5, function()
				entity:ToggleLock()
			end, nil)
		end

		return false
	end
end

function MODULE:PlayerReady(client)
	ax.net:Start(client, "ax.doors.permissions_sync", MODULE.AccessGroup_Permissions)
end

function MODULE:InitPostEntity()
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
