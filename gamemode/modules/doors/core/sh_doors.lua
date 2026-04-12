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

properties.Add("door.toggleownable", {
    MenuLabel = "Toggle Ownable",
    Order = 9999,
    MenuIcon = "icon16/fire.png",

    Filter = function(self, ent, client)
        if ( !IsValid(ent) or !ent:IsDoor() or !client:IsAdmin() ) then return false end
        if ( !hook.Run( "CanProperty", client, "door.toggleownable", ent ) ) then return false end

        return true
    end,
    Action = function(self, ent)
        self:MsgStart()
            net.WriteEntity( ent )
        self:MsgEnd()
    end,
    Receive = function( self, length, client )
        local ent = net.ReadEntity()

        if ( !properties.CanBeTargeted(ent, client) ) then return end
        if ( !self:Filter(ent, client) ) then return end

        local currentUnownable = ax.data:Get("doors_unownable", {}, {
            scope = "map",
        })

        local ownable = !ent:GetRelay("ownable", true)

        currentUnownable[ent:MapCreationID()] = ownable == false and true or nil
        ent:SetRelay("ownable", ownable)

        client:Notify("You have made this door " .. (!ownable and "unownable" or "ownable"))

        ax.data:Set("doors_unownable", currentUnownable, {
            scope = "map",
        })
    end
})

properties.Add("door.manageusers", {
    MenuLabel = "Manage Users",
    Order = 9999,
    MenuIcon = "icon16/user.png",

    Filter = function(self, ent, client)
        if ( !IsValid(ent) or !ent:IsDoor() ) then return false end
        if ( !hook.Run( "CanProperty", client, "door.manageusers", ent ) ) then return false end

        return client:HasDoorAccess(ent, MODULE.Permissions.EDIT_ACCESS)
    end,
    MenuOpen = function(self, menu, entity, trace)
        local subMenu = menu:AddSubMenu("Manage Users")

        local giveAccessMenu = subMenu:AddSubMenu("Give Access")
        local takeAccessMenu = subMenu:AddSubMenu("Take Access")

        local function SendMsg(target, accessGroup)
            self:MsgStart()
                net.WriteEntity(entity)
                net.WritePlayer(target)
                net.WriteUInt(accessGroup, 8)
            self:MsgEnd()
        end

        for k, v in player.Iterator() do
            if ( v == ax.client ) then continue end

            local bHasAccess = v:HasDoorAccess(entity)

            if ( bHasAccess ) then
                local userSubOption = takeAccessMenu:AddOption(v:GetName(), SendMsg(v, MODULE.AccessGroups.NONE))
                continue
            end

            local userSubOption = giveAccessMenu:AddSubMenu(v:GetName())

            for enumName, enumIndex in pairs(MODULE.AccessGroups) do
                if ( enumIndex != MODULE.AccessGroups.NONE and enumIndex != MODULE.AccessGroups.OWNER ) then
                    userSubOption:AddOption(enumName, SendMsg(v, enumIndex))
                end
            end

        end
    end,
    Receive = function( self, length, client )
        local entity = net.ReadEntity()

        if ( !properties.CanBeTargeted(entity, client) ) then return end
        if ( !self:Filter(entity, client) ) then return end

        local target = net.ReadPlayer()
        local accessGroup = net.ReadUInt(8)

        if ( !ax.util:IsValidPlayer(target) ) then return end
        if ( !table.HasValue(MODULE.AccessGroups, accessGroup) ) then return end

        if ( target == client ) then return end

        if ( accessGroup == MODULE.AccessGroups.NONE ) then
            entity:TakeDoorAccess(target)
        else
            entity:GiveDoorAccess(target, accessGroup)
        end
    end

})
