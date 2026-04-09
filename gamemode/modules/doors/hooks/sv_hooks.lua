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
