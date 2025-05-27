--[[--
Physical representation of connected player.

`Player`s are a type of `Entity`. They are a physical representation of a `Character` - and can possess at most one `Character`
object at a time that you can interface with.

See the [Garry's Mod Wiki](https://wiki.garrysmod.com/page/Category:Player) for all other methods that the `Player` class has.
]]
-- @classmod Player

local PLAYER = FindMetaTable("Player")

function PLAYER:SetDBVar(key, value)
    local clientTable = self:GetTable()
    if ( !clientTable.axDatabase ) then
        clientTable.axDatabase = {}
    end

    clientTable.axDatabase[key] = value
end

function PLAYER:GetDBVar(key, default)
    local clientTable = self:GetTable()
    if ( clientTable.axDatabase ) then
        return clientTable.axDatabase[key] or default
    end

    return default
end

function PLAYER:SaveDB(callback)
    local clientTable = self:GetTable()

    if ( clientTable.axDatabase ) then
        if istable(clientTable.axDatabase.data) then
            clientTable.axDatabase.data = util.TableToJSON(clientTable.axDatabase.data)
        end

        ax.database:SaveRow("ax_players", clientTable.axDatabase, "steamid", function(data)
            if ( callback and isfunction(callback) ) then
                callback(data)
            end
        end)

        ax.net:Start(self, "database.save", clientTable.axDatabase or {})
    else
        ax.util:PrintError("Player database not initialized, cannot save")
    end
end

function PLAYER:GetData(key, default)
    local clientTable = self:GetTable()
    if ( !clientTable.axDatabase ) then
        clientTable.axDatabase = {}
    end

    local data = clientTable.axDatabase.data or {}

    if ( type(data) == "string" ) then
        data = util.JSONToTable(data) or {}
    else
        data = data or {}
    end

    return data[key] or default
end

function PLAYER:SetData(key, value)
    local clientTable = self:GetTable()
    local data = clientTable.axDatabase.data or {}

    if ( isstring(data) ) then
        data = util.JSONToTable(data) or {}
    else
        data = data or {}
    end

    data[key] = value
    clientTable.axDatabase.data = util.TableToJSON(data)
end

function PLAYER:SetWhitelisted(factionID, bWhitelisted)
    local key = "whitelists_" .. SCHEMA.Folder
    local whitelists = self:GetData(key, {}) or {}

    if ( bWhitelisted == nil ) then bWhitelisted = true end

    whitelists[factionID] = bWhitelisted
    self:SetData(key, whitelists)

    self:SaveDB()
end

function PLAYER:CreateServerRagdoll()
    if ( !self:GetCharacter() ) then return end

    local ragdoll = ents.Create("prop_ragdoll")
    if ( !IsValid(ragdoll) ) then return nil end

    ragdoll:SetModel(self:GetModel())
    ragdoll:SetSkin(self:GetSkin())
    ragdoll:InheritBodygroups(self)
    ragdoll:InheritMaterials(self)
    ragdoll:SetPos(self:GetPos())
    ragdoll:SetAngles(self:GetAngles())
    ragdoll:SetCreator(self)
    ragdoll:Spawn()

    ragdoll:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
    ragdoll:Activate()

    local velocity = self:GetVelocity()
    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local phys = ragdoll:GetPhysicsObjectNum(i)
        if ( IsValid(phys) ) then
            phys:SetVelocity(velocity)

            local index = ragdoll:TranslatePhysBoneToBone(i)
            local bone = self:TranslatePhysBoneToBone(index)
            if ( bone != -1 ) then
                local pos, ang = self:GetBonePosition(bone)

                phys:SetPos(pos)
                phys:SetAngles(ang)
            end
        end
    end

    return ragdoll
end

function PLAYER:SetRagdolled(bState)
    if ( bState == nil ) then bState = false end

    if ( !bState ) then
        SafeRemoveEntity(self:GetDataVariable("ragdoll", nil))
        self:SetDataVariable("ragdoll", nil)
        return
    end

    local ragdoll = self:CreateServerRagdoll()
    timer.Simple(0.1, function()
        if ( IsValid(ragdoll) ) then
            ragdoll:SetDataVariable("owner", self)
            self:SetDataVariable("ragdoll", ragdoll)
        end
    end)
end

function PLAYER:SetWeaponRaised(bRaised)
    if ( bRaised == nil ) then bRaised = true end

    self:SetRelay("bWeaponRaised", bRaised)
    self:SetRelay("bCanShoot", bRaised)

    local weapon = self:GetActiveWeapon()
    if ( IsValid(weapon) and weapon:IsWeapon() and isfunction(weapon.SetWeaponRaised) ) then
        weapon:SetWeaponRaised(bRaised)
    end

    hook.Run("PlayerWeaponRaised", self, bRaised)
end

function PLAYER:ToggleWeaponRaise()
    local bRaised = self:GetRelay("bWeaponRaised", false)
    self:SetWeaponRaised(!bRaised)
end

PLAYER.StripWeaponInternal = PLAYER.StripWeaponInternal or PLAYER.StripWeapon
function PLAYER:StripWeapon(weaponClass)
    local axWeapons = self:GetRelay("weapons", {})
    if ( axWeapons[weaponClass] ) then
        axWeapons[weaponClass] = nil
        self:SetRelay("weapons", axWeapons)
    end

    return self:StripWeaponInternal(weaponClass)
end