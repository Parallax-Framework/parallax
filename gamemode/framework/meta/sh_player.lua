--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Player meta functions
-- @module ax.player.meta

ax.player.meta.GetNickInternal = ax.player.meta.GetNickInternal or ax.player.meta.Nick
function ax.player.meta:Nick()
    local character = self:GetCharacter()
    return character and character:GetName() or self:GetNickInternal()
end

function ax.player.meta:SteamName()
    return self:GetNickInternal()
end

function ax.player.meta:GetCharacter()
    return self:GetTable().axCharacter
end

ax.player.meta.GetChar = ax.player.meta.GetCharacter

function ax.player.meta:GetCharacters()
    return self:GetTable().axCharacters or {}
end

function ax.player.meta:GetFaction()
    local teamIndex = self:Team()
    if ( ax.faction:IsValid(teamIndex) ) then
        return teamIndex
    end

    return nil
end

function ax.player.meta:GetFactionData()
    local factionData = ax.faction:Get(self:GetFaction())
    return factionData
end

function ax.player.meta:GetClassData()
    local char = self:GetCharacter()
    if ( !char ) then return nil end

    local classID = char:GetClass()
    if ( classID ) then
        return ax.class:Get(classID)
    end

    return nil
end

function ax.player.meta:GetRankData()
    local char = self:GetCharacter()
    if ( !char ) then return nil end

    local rankID = char:GetRank()
    if ( rankID ) then
        return ax.rank:Get(rankID)
    end

    return nil
end

-- Cache for gesture sequence lookups to avoid repeated LookupSequence calls
ax.player.gestureCache = ax.player.gestureCache or {}

function ax.player.meta:PlayGesture(slot, sequence)
    local character = self:GetCharacter()
    if ( !character ) then
        ax.util:PrintDebug("Player:PlayGesture() called but player has no character.")
        return nil
    end

    if ( !isnumber(slot) or slot < 0 or slot > 6 ) then
        ax.util:PrintError("Invalid gesture slot provided to Player:PlayGesture()")
        return nil
    end

    if ( SERVER ) then
        ax.net:StartPVS(self:GetPos(), "player.playGesture", self, slot, sequence)
        return
    end

    if ( isstring(sequence) and sequence != "" ) then
        sequence = utf8.lower(sequence)

        local modelPath = utf8.lower(self:GetModel())
        local cacheKey = modelPath .. ":" .. sequence

        -- Check cache first
        if ( ax.player.gestureCache[cacheKey] ) then
            sequence = ax.player.gestureCache[cacheKey]
            ax.util:PrintDebug("Player:PlayGesture() - Using cached sequence ID:", sequence)
        else
            -- Lookup and cache the result
            sequence = self:LookupSequence(sequence)
            ax.player.gestureCache[cacheKey] = sequence
            ax.util:PrintDebug("Player:PlayGesture() - Converted string sequence to ID and cached:", sequence)
        end
    end

    sequence = sequence or -1

    if ( !isnumber(sequence) or sequence < 0 ) then
        ax.util:PrintWarning("Invalid gesture sequence provided to Player:PlayGesture()")
        return nil
    end

    self:AddVCDSequenceToGestureSlot(slot, sequence, 0, true)
end

function ax.player.meta:HasFactionWhitelist(iFactionID)
    if ( !isnumber(iFactionID) ) then
        ax.util:PrintError("Invalid faction ID provided to Player:HasFactionWhitelist()")
        return false
    end

    if ( !istable(ax.faction:Get(iFactionID)) ) then
        ax.util:PrintWarning("Faction ID " .. tostring(iFactionID) .. " does not exist in the faction registry.")
        return false
    end

    local whitelists = self:GetData("whitelists", {})
    return whitelists[iFactionID] == true
end

function ax.player.meta:IsRagdolled()
    return self:GetRelay("ragdolled", false) == true
end

if ( SERVER ) then
    local function GetWeaponInventoryItem(weapon, inventory)
        if ( !IsValid(weapon) ) then
            return nil
        end

        if ( istable(weapon.axItem) ) then
            return weapon.axItem
        end

        if ( !istable(inventory) ) then
            return nil
        end

        local class = weapon:GetClass()
        for _, item in pairs(inventory:GetItems()) do
            if ( !istable(item) ) then
                continue
            end

            if ( item.weaponClass == class and item:GetData("equipped") ) then
                return item
            end

            if ( item.class == class and item:GetData("equip") ) then
                return item
            end
        end

        return nil
    end

    function ax.player.meta:ClearRagdollWeapons()
        self.axRagdollWeapons = nil
        self.axRagdollActiveWeapon = nil
    end

    function ax.player.meta:StripWeaponsForRagdoll()
        local character = self:GetCharacter()
        local inventory = character and character:GetInventory() or nil
        local activeWeapon = self:GetActiveWeapon()
        local weapons = {}

        self.axRagdollActiveWeapon = IsValid(activeWeapon) and activeWeapon:GetClass() or nil

        for _, weapon in ipairs(self:GetWeapons()) do
            if ( !IsValid(weapon) ) then
                continue
            end

            local primaryAmmoType = weapon:GetPrimaryAmmoType()
            local secondaryAmmoType = weapon:GetSecondaryAmmoType()
            local item = GetWeaponInventoryItem(weapon, inventory)

            weapons[#weapons + 1] = {
                ammo = primaryAmmoType >= 0 and self:GetAmmoCount(primaryAmmoType) or nil,
                ammo2 = secondaryAmmoType >= 0 and self:GetAmmoCount(secondaryAmmoType) or nil,
                class = weapon:GetClass(),
                clip1 = weapon:Clip1(),
                clip2 = weapon:Clip2(),
                invID = istable(item) and item.invID or nil,
                item = item
            }

            if ( istable(item) ) then
                if ( isfunction(item.Unequip) ) then
                    item:Unequip(self, false, false)
                elseif ( item:GetData("equipped") ) then
                    item:SetData("equipped", false)
                elseif ( item:GetData("equip") ) then
                    item:SetData("equip", false)
                end
            end
        end

        self.axRagdollWeapons = weapons
        self:StripWeapons()
    end

    function ax.player.meta:RestoreRagdollWeapons()
        local weaponData = self.axRagdollWeapons
        if ( !istable(weaponData) ) then
            self:ClearRagdollWeapons()
            return
        end

        for _, data in ipairs(weaponData) do
            local weapon
            local item = data.item

            if ( istable(item) and item.invID == data.invID ) then
                if ( isfunction(item.Equip) ) then
                    item:Equip(self, true, true)

                    if ( istable(self.carryWeapons) and isstring(item.weaponCategory) ) then
                        weapon = self.carryWeapons[item.weaponCategory]
                    end

                    if ( !IsValid(weapon) and isstring(data.class) and data.class != "" ) then
                        weapon = self:GetWeapon(data.class)
                    end
                elseif ( isstring(item.weaponClass) and item.weaponClass == data.class ) then
                    weapon = self:Give(item.weaponClass)
                    item:SetData("equipped", true)
                end
            elseif ( isstring(data.class) and data.class != "" ) then
                weapon = self:Give(data.class)
            end

            if ( !IsValid(weapon) ) then
                continue
            end

            local primaryAmmoType = weapon:GetPrimaryAmmoType()
            local secondaryAmmoType = weapon:GetSecondaryAmmoType()

            if ( isnumber(data.ammo) and primaryAmmoType >= 0 ) then
                self:SetAmmo(data.ammo, primaryAmmoType)
            end

            if ( isnumber(data.ammo2) and secondaryAmmoType >= 0 ) then
                self:SetAmmo(data.ammo2, secondaryAmmoType)
            end

            if ( isnumber(data.clip1) and data.clip1 >= 0 ) then
                weapon:SetClip1(data.clip1)
            end

            if ( isnumber(data.clip2) and data.clip2 >= 0 ) then
                weapon:SetClip2(data.clip2)
            end
        end

        if ( isstring(self.axRagdollActiveWeapon) and self.axRagdollActiveWeapon != "" and self:HasWeapon(self.axRagdollActiveWeapon) ) then
            self:SelectWeapon(self.axRagdollActiveWeapon)
        elseif ( self:HasWeapon("ax_hands") ) then
            self:SelectWeapon("ax_hands")
        end

        self:ClearRagdollWeapons()
    end

    function ax.player.meta:SetRagdolled(bRagdolled, bForced)
        local ragdoll = Entity(self:GetRelay("ragdoll.index", -1))
        local bHasRagdollState = self:GetRelay("ragdolled", false) or IsValid(ragdoll) or istable(self.axRagdollWeapons)

        if ( bRagdolled != true ) then
            if ( !bHasRagdollState ) then
                self:SetRelay("ragdoll.index", -1)
                self:RemoveTimer("ragdoll.think")
                return
            end

            local restorePosition = IsValid(ragdoll) and ragdoll:WorldSpaceCenter() or self:GetPos()

            self:SetRelay("ragdolled", false)
            self:SetRelay("ragdoll.index", -1)
            self:RemoveTimer("ragdoll.think")

            SafeRemoveEntity(ragdoll)

            self:SetMoveType(MOVETYPE_WALK)
            self:SetNoDraw(false)
            self:SetNotSolid(false)
            self:DrawShadow(true)
            self:SetNoTarget(false)
            self:DrawWorldModel(true)
            self:SetPos(restorePosition + Vector(0, 0, 8)) -- Nudge the player up slightly to prevent getting stuck in the ground

            self:RestoreRagdollWeapons()

            return
        end

        if ( self:GetRelay("ragdolled", false) ) then
            return IsValid(ragdoll) and ragdoll or nil
        end

        if ( bForced != true and hook.Run("CanPlayerRagdoll", self, true) == false ) then
            return false
        end

        local ragdollDummy = ents.Create("prop_ragdoll")
        if ( !IsValid(ragdollDummy) ) then return nil end

        self:Timer("ragdoll.think", 0.1, 0, function()
            if ( !IsValid(self) ) then return end
            if ( !self:GetRelay("ragdolled", false) ) then return end
            if ( !IsValid(ragdollDummy) ) then
                self:SetRagdolled(false, true)
                return
            end

            self:SetPos(ragdollDummy:WorldSpaceCenter())
            self:SetAngles(ragdollDummy:GetAngles())

            debugoverlay.Axis(ragdollDummy:WorldSpaceCenter(), ragdollDummy:GetAngles(), 16, 0.1, true)
        end)

        self:StripWeaponsForRagdoll()
        self:SetRelay("ragdoll.index", -1)
        self:SetRelay("ragdolled", bRagdolled)

        self:SetMoveType(MOVETYPE_NONE)
        self:SetNoDraw(true)
        self:SetNotSolid(true)
        self:DrawShadow(false)
        self:DrawWorldModel(false)

        ragdollDummy:SetModel(self:GetModel())
        ragdollDummy:SetSkin(self:GetSkin())
        ragdollDummy:SetPos(self:GetPos())

        for i = 0, self:GetNumBodyGroups() - 1 do
            ragdollDummy:SetBodygroup(i, self:GetBodygroup(i))
        end

        ragdollDummy:Spawn()
        ragdollDummy:Activate()

        ragdollDummy:SetAngles(self:EyeAngles())
        ragdollDummy:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        local velocity = self:GetVelocity()
        for i = 0, ragdollDummy:GetPhysicsObjectCount() - 1 do
            local physObj = ragdollDummy:GetPhysicsObjectNum(i)
            if ( !IsValid(physObj) ) then return end

            physObj:SetVelocity(velocity)

            local boneID = ragdollDummy:TranslatePhysBoneToBone(i)
            if ( !boneID ) then continue end

            local matrix = self:GetBoneMatrix(boneID)
            local bonePos, boneAng = matrix:GetTranslation(), matrix:GetAngles()

            physObj:SetPos(bonePos)
            physObj:SetAngles(boneAng)
        end

        local materials = self:GetMaterials()
        for i = 1, #materials do
            ragdollDummy:SetSubMaterial(i - 1, materials[i])
        end

        self:SetRelay("ragdoll.index", ragdollDummy:EntIndex())

        hook.Run("OnPlayerRagdollCreated", self, ragdollDummy)

        return ragdollDummy
    end

    function ax.player.meta:ToggleRagdoll(bForced)
        self:SetRagdolled(!self:GetRelay("ragdolled", false), bForced)
    end

    function ax.player.meta:SetFactionWhitelisted(iFactionID, bStatus)
        if ( !isnumber(iFactionID) ) then
            ax.util:PrintError("Invalid faction ID provided to Player:SetFactionWhitelisted()")
            return
        end

        if ( !istable(ax.faction:Get(iFactionID)) ) then
            ax.util:PrintError("Faction ID " .. tostring(iFactionID) .. " does not exist in the faction registry.")
            return
        end
        if ( !isbool(bStatus) ) then
            ax.util:PrintError("Invalid status provided to Player:SetFactionWhitelisted(), expected boolean.")
            return
        end

        local whitelists = self:GetData("whitelists", {})
        whitelists[iFactionID] = bStatus == false and nil or true
        self:SetData("whitelists", whitelists)
    end

    function ax.player.meta:Save()
        local clientTable = self:GetTable()
        if ( !istable(clientTable.axVars) ) then clientTable.axVars = {} end
        if ( !istable(clientTable.axVars.data) ) then clientTable.axVars.data = {} end

        -- Build an update query for the players table using the registered schema
        local query = mysql:Update("ax_players")
        query:Where("steamid64", self:SteamID64())

        -- Ensure the data table exists and always save it as JSON
        query:Update("data", util.TableToJSON(clientTable.axVars.data or {}))

        -- Iterate registered vars and persist fields that declare a database column
        for name, meta in pairs(ax.player.vars or {}) do
            if ( istable(meta) and meta.field ) then
                local val = nil

                if ( istable(clientTable.axVars) ) then
                    val = clientTable.axVars[name]
                end

                -- Fall back to default if not present
                if ( val == nil and meta.default != nil ) then
                    val = meta.default
                end

                -- Serialize tables to JSON for storage
                if ( istable(val) ) then
                    val = util.TableToJSON(val)
                end

                query:Update(meta.field, val)

                ax.util:PrintDebug("Saving player field '" .. meta.field .. "' with value: " .. tostring(val))
            end
        end

        query:Execute()
    end

    function ax.player.meta:EnsurePlayer(callback)
        local steamID64 = self:SteamID64()

        local function finish(ok)
            if ( isfunction(callback) ) then
                callback(ok)
            else
                ax.util:PrintDebug("No callback provided to Player:EnsurePlayer() for " .. steamID64)
            end
        end

        local query = mysql:Select("ax_players")
            query:Where("steamid64", steamID64)
            query:Callback(function(result, status)
                if ( result == false ) then
                    ax.util:PrintError("Failed to query players for " .. steamID64)
                    finish(false)
                    return
                end

                if ( result[1] == nil ) then
                    ax.util:PrintDebug("No player row found for " .. steamID64 .. ", creating one.")

                    local insert = mysql:Insert("ax_players")
                        insert:Insert("steamid64", steamID64)
                        insert:Insert("name", self:SteamName())
                        insert:Insert("last_join", os.time())
                        insert:Insert("last_leave", 0)
                        insert:Insert("play_time", 0)
                        insert:Insert("data", "[]")
                    insert:Callback(function(res, st, lastID)
                        if ( res == false ) then
                            ax.util:PrintError("Failed to create player row for " .. steamID64)
                            finish(false)
                            return
                        end

                        ax.util:PrintDebug("Created player row for " .. steamID64 .. " with id " .. tostring(lastID))
                        finish(true)
                    end)
                    insert:Execute()
                else
                    ax.util:PrintDebug("Player row found for " .. steamID64 .. ", ensuring data is valid.")
                    finish(true)
                end
            end)
        query:Execute()
    end

    function ax.player.meta:DermaStringRequest(title, subtitle, default, confirm, cancel, confirmText, cancelText)
        confirmText = confirmText or "OK"
        cancelText = cancelText or "Cancel"

        ax.net:Start(self, "player.dermaStringRequest", title, subtitle, default or "", confirmText, cancelText)

        local clientTable = self:GetTable()
        clientTable.axStringRequest = clientTable.axStringRequest or {}
        clientTable.axStringRequest.confirm = confirm
        clientTable.axStringRequest.cancel = cancel
    end

    function ax.player.meta:DermaMessage(text, title, buttonName, onClosed)
        ax.net:Start(self, "player.dermaMessage", text, title, buttonName)

        local clientTable = self:GetTable()
        clientTable.axDermaMessage = clientTable.axDermaMessage or {}
        clientTable.axDermaMessage.onClosed = onClosed
        clientTable.axDermaMessage.buttonName = buttonName
        clientTable.axDermaMessage.title = title
        clientTable.axDermaMessage.text = text
    end
else
    function ax.player.meta:EnsurePlayer(callback)
        local clientTable = self:GetTable()
        if ( clientTable.axReady ) then
            if ( isfunction(callback) ) then callback(true) end
            return
        end

        clientTable.axEnsureCallbacks = clientTable.axEnsureCallbacks or {}
        clientTable.axEnsureCallbacks[#clientTable.axEnsureCallbacks + 1] = callback
    end
end

function ax.player.meta:GetSessionPlayTime()
    local joinTime = self:GetTable().axJoinTime
    if ( !joinTime ) then return 0 end

    return os.difftime(os.time(), joinTime)
end

if ( CLIENT ) then
    ax.net:Hook("player.chatPrint", function(messages)
        chat.AddText(unpack(messages))
    end)

    ax.net:Hook("player.playGesture", function(sender, slot, sequence)
        if ( !ax.util:IsValidPlayer(sender) ) then return end

        sender:PlayGesture(slot, sequence)
    end)
end

ax.player.meta.ChatPrintInternal = ax.player.meta.ChatPrintInternal or ax.player.meta.ChatPrint
function ax.player.meta:ChatPrint(...)
    if ( SERVER ) then
        ax.net:Start(self, "player.chatPrint", {...})
    else
        chat.AddText(...)
    end
end

--- Player:Notify - Convenience for sending a toast to this player.
-- @realm server
function ax.player.meta:Notify(text, type, length)
    if ( SERVER ) then
        ax.notification:Send(self, text, type, length)
    else
        ax.notification:Add(text, type, length)
    end
end

function ax.player.meta:SyncRelay()
    for k, v in pairs( ax.relay.data["global"] or {} ) do
        self:SetRelay( k, v, false, self )
    end

    for entityIndex, data in pairs( ax.relay.data ) do
        if ( entityIndex == "global" ) then continue end

        local ent = Entity( tonumber( entityIndex ) or 0 )
        if ( !IsValid( ent ) or ( ax.util:IsValidPlayer(ent) and ent:SteamID64() != entityIndex ) ) then continue end

        for k, v in pairs( data ) do
            ent:SetRelay( k, v, false, self )
        end
    end
end

function ax.player.meta:PerformAction(label, duration, onComplete, onCancel)
    if ( SERVER ) then
        if ( label == nil ) then
            local selfTable = self:GetTable()
            if ( istable(selfTable.axActionBar) ) then
                if ( isfunction(selfTable.axActionBar.onCancel) ) then
                    selfTable.axActionBar.onCancel()
                    selfTable.axActionBar.onCancel = nil
                end

                selfTable.axActionBar.onComplete = nil
                selfTable.axActionBar = nil
            end

            timer.Remove("ax.player." .. self:SteamID64() .. ".entityAction")
            ax.net:Start(self, "player.actionbar.stop", true)
            return
        end

        ax.net:Start(self, "player.actionbar.start", label or "Processing...", duration or 5)

        local selfTable = self:GetTable()
        selfTable.axActionBar = {}
        selfTable.axActionBar.onComplete = onComplete
        selfTable.axActionBar.onCancel = onCancel
    else
        if ( label == nil ) then
            ax.actionBar:Stop(true)
            return
        end

        ax.actionBar:Start(label, duration, onComplete, onCancel)
    end
end

function ax.player.meta:CanMaintainEntityAction(entity, allowEyeTrace, maxDistance)
    if ( !ax.util:IsValidPlayer(self) or !IsValid(entity) ) then
        return false
    end

    local entityTrace = self:GetUseEntity()
    if ( IsValid(entityTrace) and entityTrace == entity ) then
        return true
    end

    if ( allowEyeTrace != true ) then
        return false
    end

    local trace = self:GetEyeTrace()
    local traceEntity = trace and trace.Entity or nil
    if ( !IsValid(traceEntity) or traceEntity != entity ) then
        return false
    end

    if ( isnumber(maxDistance) and maxDistance > 0 ) then
        local hitPosition = isvector(trace.HitPos) and trace.HitPos or entity:WorldSpaceCenter()
        if ( self:GetShootPos():DistToSqr(hitPosition) > (maxDistance * maxDistance) ) then
            return false
        end
    end

    return true
end

function ax.player.meta:PerformEntityAction(entity, label, duration, onComplete, onCancel, allowEyeTrace, maxDistance)
    local timerName = "ax.player." .. self:SteamID64() .. ".entityAction"
    timer.Create(timerName, 0.1, 0, function()
        if ( !IsValid(entity) or !ax.util:IsValidPlayer(self) ) then
            timer.Remove(timerName)
            self:PerformAction()

            return
        end

        if ( !self:CanMaintainEntityAction(entity, allowEyeTrace, maxDistance) ) then
            timer.Remove(timerName)
            self:PerformAction()

            return
        end
    end)

    self:PerformAction(label, duration, onComplete, onCancel)
end
