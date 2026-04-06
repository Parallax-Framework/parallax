local MODULE = MODULE

function MODULE:GetAccessGroupPermissions(accessGroup, bReturnStringTable)
    local perms = MODULE.AccessGroup_Permissions[accessGroup] or 0
    if ( bReturnStringTable == true ) then
        local stringTable = {}

        for group, perms in pairs(self.AccessGroup_Permissions) do
            if ( group == accessGroup ) then
                for permName, permValue in pairs(MODULE.Permissions) do
                    if ( bit.band(perms, permValue) == permValue ) then
                        stringTable[#stringTable + 1] = permName
                    end
                end
            end
        end

        return stringTable
    end

    return perms
end

function MODULE:CanAccessGroupPerformAction(accessGroup, actions)
    local permissions = self.AccessGroup_Permissions[accessGroup]
    if ( permissions and bit.band(permissions, actions) == actions ) then
        return true
    end

    return false
end
