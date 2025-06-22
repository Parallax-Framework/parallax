--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PLAYER = FindMetaTable("Player")

PLAYER.StripWeaponInternal = PLAYER.StripWeaponInternal or PLAYER.StripWeapon

--- Sets a database variable for the player.
-- @realm server
-- @tparam string key The key of the variable to set.
-- @param value The value to set for the key.
function PLAYER:SetDBVar(key, value)
    local clientTable = self:GetTable()
    if ( !istable(clientTable.axDatabase) ) then
        clientTable.axDatabase = {}
    end

    clientTable.axDatabase[key] = value
end

--- Gets a database variable for the player.
-- @realm server
-- @tparam string key The key of the variable to retrieve.
-- @param default The default value to return if the key does not exist.
-- @return The value associated with the key, or the default value.
function PLAYER:GetDBVar(key, default)
    local clientTable = self:GetTable()
    if ( istable(clientTable.axDatabase) ) then
        return clientTable.axDatabase[key] or default
    end

    return default
end

--- Saves the player's database to persistent storage.
-- @realm server
-- @tparam[opt] function callback A callback function to execute after saving.
function PLAYER:SaveDB(callback)
    local clientTable = self:GetTable()

    if ( istable(clientTable.axDatabase) ) then
        if ( istable(clientTable.axDatabase.data) ) then
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

--- Gets a specific data value associated with the player.
-- @realm server
-- @tparam string key The key of the data to retrieve.
-- @param default The default value to return if the key does not exist.
-- @return The value associated with the key, or the default value.
function PLAYER:GetData(key, default)
    local clientTable = self:GetTable()
    if ( !istable(clientTable.axDatabase) ) then
        clientTable.axDatabase = {}
    end

    local data = clientTable.axDatabase.data or {}

    if ( isstring(data) ) then
        data = util.JSONToTable(data) or {}
    else
        data = data or {}
    end

    return data[key] or default
end

--- Sets a specific data value for the player.
-- @realm server
-- @tparam string key The key of the data to set.
-- @param value The value to set for the key.
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

--- Sets the whitelist status for a specific faction.
-- @realm server
-- @tparam string factionID The ID of the faction.
-- @tparam[opt=true] boolean bWhitelisted Whether the player is whitelisted for the faction.
function PLAYER:SetWhitelisted(factionID, bWhitelisted)
    local key = "whitelists_" .. SCHEMA.Folder
    local whitelists = self:GetData(key, {}) or {}

    if ( bWhitelisted == nil ) then bWhitelisted = true end

    whitelists[factionID] = bWhitelisted
    self:SetData(key, whitelists)

    self:SaveDB()
end

--- Creates a server-side ragdoll for the player.
-- @realm server
-- @treturn Entity|nil The created ragdoll entity, or nil if creation failed.
function PLAYER:CreateServerRagdoll()
    if ( !self:GetCharacter() ) then return NULL end

    local ragdoll = ents.Create("prop_ragdoll")
    if ( !IsValid(ragdoll) ) then return NULL end

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

    local flameEntity = self:GetInternalVariable("m_hEffectEntity")
    if ( IsValid(flameEntity) and flameEntity:GetClass() == "entityflame" ) then
        ragdoll:Ignite(flameEntity:GetInternalVariable("m_flLifetime") - CurTime(), 0)
    end

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

--- Sets the player's ragdoll state.
-- @realm server
-- @tparam[opt=false] boolean bState Whether the player should be ragdolled.
-- @tparam[opt] number duration The duration of the ragdoll state in seconds.
function PLAYER:SetRagdolled(bState, duration)
    if ( bState == nil ) then bState = false end

    if ( !bState ) then
        SafeRemoveEntity(self:GetRelay("ragdoll", nil))
        self:SetRelay("ragdoll", nil)
        return
    end

    self:SetNoDraw(true)
    self:SetNotSolid(true)
    self:SetNoTarget(true)
    self:SetRelay("ragdolled", true)
    self:SetRelay("canShoot", false)
    self:SetRelay("bWeaponRaised", false)

    local arsenalTable = {}
    local weaponsTable = self:GetWeapons()
    for i = 1, #weaponsTable do
        local weapon = weaponsTable[i]
        if ( IsValid(weapon) ) then
            arsenalTable[i] = weapon:GetClass()
        end
    end

    self:SetRelay("ragdollArsenal", arsenalTable)
    self:SetRelay("ragdollAmmo", self:GetAmmo())

    self:RemoveAllItems()

    local ragdoll = self:CreateServerRagdoll()
    timer.Simple(0.1, function()
        if ( IsValid(ragdoll) ) then
            ragdoll:SetRelay("owner", self)
            self:SetRelay("ragdoll", ragdoll)

            local timerID = "ax.client." .. self:SteamID64() .. ".ragdollRestore"
            timer.Create(timerID, 0.1, 0, function()
                if ( !IsValid(self) or !IsValid(ragdoll) ) then timer.Remove(timerID) return end

                self:SetPos(ragdoll:GetPos())
                self:SetVelocity(ragdoll:GetVelocity())
            end)

            ragdoll:CallOnRemove("ax.client.restore" .. self:SteamID64(), function(this)
                timer.Remove(timerID)

                if ( !IsValid(self) ) then return end

                self:SetNoDraw(false)
                self:SetNotSolid(false)
                self:SetNoTarget(false)
                self:SetRelay("ragdolled", false)
                self:SetRelay("canShoot", true)
                self:SetRelay("bWeaponRaised", true)

                local ragdollArsenal = self:GetRelay("ragdollArsenal", {})
                for i = 1, #ragdollArsenal do
                    self:Give(ragdollArsenal[i])
                end

                local ragdollAmmo = self:GetRelay("ragdollAmmo", {})
                for ammoType in pairs(ragdollAmmo) do
                    local ammoCount = ragdollAmmo[ammoType]
                    if ( isnumber(ammoType) and isstring(game.GetAmmoName(ammoType)) and isnumber(ammoCount) ) then
                        self:SetAmmo(ammoCount, ammoType)
                    end
                end


                self:SelectWeapon("ax_hands")
                self:SetRelay("ragdoll", nil)
            end)

            if ( isnumber(duration) and duration > 0 ) then
                timer.Simple(duration, function()
                    if ( IsValid(self) and IsValid(ragdoll) ) then
                        self:SetRagdolled(false)
                    end
                end)
            end

            hook.Run("OnPlayerRagdolled", self, ragdoll, duration)
        end
    end)
end

--- Sets whether the player's weapon is raised.
-- @realm server
-- @tparam[opt=true] boolean bRaised Whether the weapon should be raised.
function PLAYER:SetWeaponRaised(bRaised)
    if ( bRaised == nil ) then bRaised = true end

    self:SetRelay("bWeaponRaised", bRaised)

    local weapon = self:GetActiveWeapon()
    if ( IsValid(weapon) and weapon:IsWeapon() and isfunction(weapon.SetWeaponRaised) ) then
        weapon:SetWeaponRaised(bRaised)
    end

    hook.Run("PlayerWeaponRaised", self, bRaised)
end

--- Toggles the player's weapon raise state.
-- @realm server
function PLAYER:ToggleWeaponRaise()
    local bRaised = self:GetRelay("bWeaponRaised", false)
    self:SetWeaponRaised(!bRaised)
end

--- Strips a specific weapon from the player.
-- @realm server
-- @tparam string weaponClass The class of the weapon to strip.
-- @return The result of the internal weapon strip function.
function PLAYER:StripWeapon(weaponClass)
    local axWeapons = self:GetRelay("weapons", {})
    if ( axWeapons[weaponClass] ) then
        axWeapons[weaponClass] = nil
        self:SetRelay("weapons", axWeapons)
    end

    return self:StripWeaponInternal(weaponClass)
end