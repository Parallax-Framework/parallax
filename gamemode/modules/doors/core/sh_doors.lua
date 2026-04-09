local MODULE = MODULE

function MODULE:GetAccessGroupPermissions(accessGroup, bReturnStringTable)
    if ( bReturnStringTable == true ) then
        local stringTable = {}
        local stringTableMissing = {}

        for group, perms in pairs(self.AccessGroup_Permissions) do
            if ( group != accessGroup ) then continue end

            for permName, permValue in pairs(self.Permissions) do
                if ( bit.band(perms, permValue) == permValue ) then
                    stringTable[permValue] = permName
                elseif ( bit.band(perms, permValue) != permValue ) then
                    stringTableMissing[permValue] = permName
                end
            end
        end

        return stringTable, stringTableMissing
    end

    local perms = self.AccessGroup_Permissions[accessGroup] or 0
    local permsMissing = 0

    for permName, permValue in pairs(self.Permissions) do
        if ( bit.band(perms, permValue) != permValue ) then
            permsMissing = bit.bor(permsMissing, permValue)
        end
    end


    return perms, permsMissing
end

function MODULE:CanAccessGroupPerformAction(accessGroup, actions)
    local permissions = self.AccessGroup_Permissions[accessGroup]
    if ( permissions and bit.band(permissions, actions) == actions ) then
        return true
    end

    return false
end
