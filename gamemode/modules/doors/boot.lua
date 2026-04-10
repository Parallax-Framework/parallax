local MODULE = MODULE

MODULE.name = "Doors"
MODULE.description = "Provides functionality for managing doors in the game."
MODULE.author = "bloodycop6385"

MODULE.AccessGroups = {
    NONE    = 1, -- keep none with the lowest index, thanks
    TENANT  = 2,
    OWNER   = 3 -- keep owner with the highest index, thanks
}

MODULE.Permissions = {
    UNLOCK      = (1) "<<" (0),
    LOCK        = (1) "<<" (1),
    EDIT_ACCESS = (1) "<<" (2)
}

MODULE.AccessGroup_Permissions = {
    [MODULE.AccessGroups.OWNER]     = bit.bor(MODULE.Permissions.UNLOCK, MODULE.Permissions.LOCK, MODULE.Permissions.EDIT_ACCESS),
    [MODULE.AccessGroups.TENANT]    = bit.bor(MODULE.Permissions.UNLOCK, MODULE.Permissions.LOCK),
    [MODULE.AccessGroups.NONE]      = 0
}

if ( ax.data:Get("door.groupPermissions", nil, {
    scope = "schema",
    force = true,
}) ) then
    MODULE.AccessGroup_Permissions = ax.data:Get("door.groupPermissions")
end


CAMI.RegisterPrivilege({
    Name = "Parallax - Doors - Manage Access Groups",
    MinAccess = "superadmin"
})

if ( SERVER ) then
    -- some developer commands, remove before merging to prod environment (main)
    concommand.Add("ax_door_player_setaccessgroup", function(client, command, args)
        if ( !client:IsAdmin() ) then return end

        local entity = client:GetEyeTrace().Entity
        if ( !IsValid(entity) or !entity:IsDoor() ) then return end

        local accessGroup = args[1]
        local accessGroupName = ""
        if ( isstring(accessGroup) ) then
            for k, v in pairs( MODULE.AccessGroups ) do
                if ( ax.util:FindString(k, accessGroup) ) then
                    accessGroup = v
                    accessGroupName = k
                    break
                end
            end
        end

        if ( isnumber(accessGroup) ) then
            local entityTable = entity:GetTable()
            entityTable.axPlayerAccess = entityTable.axPlayerAccess or {}

            entityTable.axPlayerAccess[client] = accessGroup
            print("Player " .. client:GetName() .. " set to access group " .. accessGroupName)
            print("This door access group has the following permissions:")
            local stringTable = MODULE:GetAccessGroupPermissions(accessGroup, true)
            for _ = 1, #stringTable do
                local permName = stringTable[_]
                print("  - " .. permName)
            end

        end
    end)

    concommand.Add("ax_door_player_checkaccess", function(client, command, args)
        if ( !client:IsAdmin() ) then return end

        local entity = client:GetEyeTrace().Entity
        if ( !IsValid(entity) or !entity:IsDoor() ) then return end

        local checkingAccess = 0

        local accessString = args[1]
        if ( !isstring(accessString) or accessString == "" ) then return end

        local splitTable = string.Split(accessString, " ")
        for _ = 1, #splitTable do
            local v = splitTable[_]
            if ( isstring(v) ) then
                for permName, permValue in pairs( MODULE.Permissions ) do
                    if ( ax.util:FindString(permName, v) ) then
                        checkingAccess = bit.bor(checkingAccess, permValue)
                    end
                end
            end
        end

        local bHasAccess = client:HasDoorAccess(entity, checkingAccess)
        local missingPermissions = {}

        if ( !bHasAccess ) then
            print("Missing permissions:")
            for k, v in pairs(MODULE.Permissions) do
                if ( bit.band(checkingAccess, v) == v and !client:HasDoorAccess(entity, v) ) then
                    print("  - " .. k)
                end
            end
        end
    end)
end
