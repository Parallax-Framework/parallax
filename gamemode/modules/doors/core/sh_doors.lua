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
        if ( !gamemode.Call( "CanProperty", client, "door.toggleownable", ent ) ) then return false end

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
