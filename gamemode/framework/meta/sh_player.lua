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

--- Returns the player's in-character name when a character is active.
-- Overrides GMod's built-in `Nick()` method. When the player has an active character (via `GetCharacter()`), returns `character:GetName()`.
-- Falls back to the Steam name via the original `Nick` implementation (`GetNickInternal`) when no character is loaded (e.g. during character selection).
-- @realm shared
-- @return string The character name, or the Steam display name if no character is active.
ax.player.meta.GetNickInternal = ax.player.meta.GetNickInternal or ax.player.meta.Nick
function ax.player.meta:Nick()
    local character = self:GetCharacter()
    return character and character:GetName() or self:GetNickInternal()
end

--- Returns the player's actual Steam display name, bypassing the character name override.
-- Delegates directly to `GetNickInternal` (the original GMod `Nick` method saved before the Parallax override).
-- Use this when you specifically need the Steam name rather than the in-character name.
-- @realm shared
-- @return string The player's Steam display name.
function ax.player.meta:SteamName()
    return self:GetNickInternal()
end

--- Returns the character instance currently active for this player.
-- Reads `axCharacter` from the player's entity table, which is set when a character is loaded via `ax.character:Load()`.
-- Returns nil when the player is in the character selection screen or has no character loaded. Aliased as `GetChar`.
-- @realm shared
-- @return table|nil The active character instance, or nil if none is loaded.
function ax.player.meta:GetCharacter()
    return self:GetTable().axCharacter
end

ax.player.meta.GetChar = ax.player.meta.GetCharacter

--- Returns all character instances associated with this player.
-- Reads `axCharacters` from the player's entity table, which is populated when the player's characters are fetched from the database on connect.
-- Returns an empty table when no characters have been loaded yet.
-- @realm shared
-- @return table An ordered array of character instances, or `{}` if none are loaded.
function ax.player.meta:GetCharacters()
    return self:GetTable().axCharacters or {}
end

--- Returns the player's current faction index, or nil if not in a valid faction.
-- Reads the player's team index via `self:Team()` and validates it against the registered faction registry via `ax.faction:IsValid`.
-- Returns nil for spectators, players not yet assigned a faction, or indices that don't map to a registered faction.
-- @realm shared
-- @return number|nil The faction index, or nil if not in a valid faction.
function ax.player.meta:GetFaction()
    local teamIndex = self:Team()
    if ( ax.faction:IsValid(teamIndex) ) then
        return teamIndex
    end

    return nil
end

--- Returns the faction definition table for this player's current faction.
-- Delegates to `ax.faction:Get` using the result of `GetFaction()`. Returns nil when the player is not in a valid faction.
-- @realm shared
-- @return table|nil The faction definition table, or nil if not in a faction.
function ax.player.meta:GetFactionData()
    local factionData = ax.faction:Get(self:GetFaction())
    return factionData
end

--- Returns the class definition table for this player's active character's class.
-- Retrieves the character's class ID via `character:GetClass()` and looks it up in the class registry via `ax.class:Get`.
-- Returns nil when the player has no active character or the character has no class assigned.
-- @realm shared
-- @return table|nil The class definition table, or nil if no class is set.
function ax.player.meta:GetClassData()
    local char = self:GetCharacter()
    if ( !char ) then return nil end

    local classID = char:GetClass()
    if ( classID ) then
        return ax.class:Get(classID)
    end

    return nil
end

--- Returns the rank definition table for this player's active character's rank.
-- Retrieves the character's rank ID via `character:GetRank()` and looks it up in the rank registry via `ax.rank:Get`.
-- Returns nil when the player has no active character or the character has no rank assigned.
-- @realm shared
-- @return table|nil The rank definition table, or nil if no rank is set.
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

--- Plays a gesture animation in the given layer slot on this player.
-- On the server, broadcasts a PVS net message so nearby clients execute the gesture.
-- On the client, resolves a string sequence name to a numeric ID via `LookupSequence`, caching the result keyed by `"modelPath:sequenceName"` to avoid repeated lookups on the same model.
-- The numeric ID is then passed to `AddVCDSequenceToGestureSlot`.
-- Returns nil and prints an error when the slot is out of range (0–6) or the player has no active character.
-- @realm shared
-- @param slot number The gesture layer slot (0–6) to play the animation in.
-- @param sequence string|number The sequence name (string) or sequence ID (number) to play.
-- @return nil Always returns nil on the server (result via net message); nil on error.
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

--- Returns whether the player has been whitelisted for a given faction.
-- Reads the `"whitelists"` key from the player's data store. Returns true only when the entry for `iFactionID` is explicitly `true`.
-- Returns false when the faction ID is invalid, unregistered, or the player has no whitelist entry for it.
-- @realm shared
-- @param iFactionID number The numeric faction index to check.
-- @return boolean True if the player is whitelisted for the faction, false otherwise.
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

--- Returns whether the player is currently in a ragdolled state.
-- Reads the `"ragdolled"` relay key set by `SetRagdolled`. Returns false when the relay has not been set or has been cleared.
-- @realm shared
-- @return boolean True if the player is currently ragdolled, false otherwise.
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

    --- Clears the stored ragdoll weapon state from this player.
    -- Removes `axRagdollWeapons` and `axRagdollActiveWeapon` from the player's entity table.
    -- Called automatically by `RestoreRagdollWeapons` after weapons are given back, and can be called manually to discard weapon state without restoring.
    -- @realm server
    function ax.player.meta:ClearRagdollWeapons()
        self.axRagdollWeapons = nil
        self.axRagdollActiveWeapon = nil
    end

    --- Strips all weapons from the player and saves their state for later restoration.
    -- Records each weapon's class, clip counts, ammo counts, and linked inventory item (resolved via `GetWeaponInventoryItem`).
    -- For inventory-backed weapons that define an `Unequip` method, that method is called to mark the item as unequipped.
    -- The active weapon class is stored in `axRagdollActiveWeapon`.
    -- After recording, all weapons are removed via `StripWeapons`.
    -- Call `RestoreRagdollWeapons` to re-give them.
    -- Intended to be called as part of the ragdoll creation flow.
    -- @realm server
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

    --- Restores all weapons stripped by `StripWeaponsForRagdoll`.
    -- Iterates the stored weapon data in `axRagdollWeapons`.
    -- For inventory-backed items that define an `Equip` method, `Equip` is called to re-equip them; otherwise the weapon is re-given via `self:Give`.
    -- Clip sizes and ammo counts are restored after giving.
    -- After all weapons are restored, re-selects the previously active weapon (or `ax_hands` as a fallback).
    -- Calls `ClearRagdollWeapons` when done.
    -- @realm server
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

    --- Sets the player's ragdoll state, creating or destroying a ragdoll dummy.
    -- When `bRagdolled` is true, creates a `prop_ragdoll` entity at the player's position inheriting the player's model, skin, bodygroups, and materials.
    -- The player is hidden and made non-solid while a repeating timer keeps their position synced to the ragdoll.
    -- Weapons are stripped via `StripWeaponsForRagdoll` and stored for later restoration.
    -- When `bRagdolled` is false (or any non-true value), the ragdoll dummy is removed, the player is restored to `MOVETYPE_WALK`, and `RestoreRagdollWeapons` is called.
    -- Fires `"CanPlayerRagdoll"` before creating the ragdoll unless `bForced` is true;
    -- returning false from the hook prevents ragdolling. Fires `"OnPlayerRagdollCreated"` after the dummy is spawned.
    -- Returns the ragdoll entity on creation, false if blocked by the hook, or nil on error.
    -- @realm server
    -- @param bRagdolled boolean True to ragdoll the player, false (or any non-true value) to un-ragdoll.
    -- @param bForced boolean|nil When true, skips the `"CanPlayerRagdoll"` hook check.
    -- @return Entity|false|nil The ragdoll entity, false if blocked by hook, or nil on failure.
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

    --- Toggles the player's ragdoll state between ragdolled and un-ragdolled.
    -- Reads the current `"ragdolled"` relay value and calls `SetRagdolled` with the inverse.
    -- Passes `bForced` through to skip the `"CanPlayerRagdoll"` hook check.
    -- @realm server
    -- @param bForced boolean|nil When true, bypasses the `"CanPlayerRagdoll"` hook.
    function ax.player.meta:ToggleRagdoll(bForced)
        self:SetRagdolled(!self:GetRelay("ragdolled", false), bForced)
    end

    --- Sets or clears the player's whitelist status for a given faction.
    -- Updates the `"whitelists"` key in the player's data store.
    -- Setting `bStatus` to true grants whitelist access; false removes it (the entry is set to nil).
    -- Validates that `iFactionID` is a registered faction and that `bStatus` is a boolean before writing.
    -- Prints an error and returns early on invalid input.
    -- @realm server
    -- @param iFactionID number The numeric faction index to whitelist or un-whitelist.
    -- @param bStatus boolean True to grant whitelist access, false to revoke it.
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

    --- Persists all player variables and data to the database.
    -- Constructs a MySQL UPDATE query targeting the `ax_players` table, filtered by `steamid64`.
    -- All registered player vars that declare a `field` in their schema are included; table values are serialised to JSON.
    -- The `data` blob is always written as JSON.
    -- Falls back to the registered default when a var has no value set.
    -- Call this after any direct modification to `axVars` that bypasses the standard `SetVar` / `SetData` pathway.
    -- @realm server
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

    --- Ensures the player has a row in the `ax_players` database table, creating one if needed.
    -- On the server, issues a SELECT query for the player's SteamID64.
    -- If no row is found, an INSERT is issued with default values for all fields.
    -- In both cases `callback(true)` is invoked on success; `callback(false)` is invoked on database error.
    -- If no `callback` is provided, a debug message is printed instead.
    -- @realm server
    -- @param callback function|nil Called as `callback(ok)` where `ok` is true on success, false on error.
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

    --- Opens a Derma string input dialog on this player's client.
    -- Sends a `"player.dermaStringRequest"` net message to the player with the dialog parameters.
    -- The `confirm` and `cancel` callbacks are stored on the player's entity table and invoked when the client responds via the corresponding net handler.
    -- @realm server
    -- @param title string The dialog window title.
    -- @param subtitle string The instructional subtitle shown below the title.
    -- @param default string|nil Default text pre-filled in the input box.
    -- @param confirm function|nil Called with the entered text when the player confirms.
    -- @param cancel function|nil Called when the player cancels or closes the dialog.
    -- @param confirmText string|nil Label for the confirm button. Defaults to `"OK"`.
    -- @param cancelText string|nil Label for the cancel button. Defaults to `"Cancel"`.
    function ax.player.meta:DermaStringRequest(title, subtitle, default, confirm, cancel, confirmText, cancelText)
        confirmText = confirmText or "OK"
        cancelText = cancelText or "Cancel"

        ax.net:Start(self, "player.dermaStringRequest", title, subtitle, default or "", confirmText, cancelText)

        local clientTable = self:GetTable()
        clientTable.axStringRequest = clientTable.axStringRequest or {}
        clientTable.axStringRequest.confirm = confirm
        clientTable.axStringRequest.cancel = cancel
    end

    --- Opens a Derma message dialog on this player's client.
    -- Sends a `"player.dermaMessage"` net message with the dialog content.
    -- The optional `onClosed` callback is stored server-side and invoked when the client acknowledges the dialog.
    -- Useful for non-blocking informational prompts.
    -- @realm server
    -- @param text string The body text of the message dialog.
    -- @param title string The window title.
    -- @param buttonName string|nil Label for the dismiss button.
    -- @param onClosed function|nil Called when the player closes the dialog.
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
    --- Queues a callback to run once this player is ready on the client.
    -- On the client, "ready" means `axReady` has been set on the player's entity table by the framework initialisation sequence.
    -- If the player is already ready, `callback` is invoked immediately.
    -- Otherwise it is appended to `axEnsureCallbacks` and invoked once the ready state is reached.
    -- This is the client-side counterpart to the server's database-backed `EnsurePlayer`.
    -- @realm client
    -- @param callback function|nil Called as `callback(true)` when the player is ready.
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

--- Returns the number of seconds the player has been connected in this session.
-- Computes `os.time() - axJoinTime` where `axJoinTime` is set when the player joins the server.
-- Returns 0 when `axJoinTime` has not been set (e.g. before the player has fully initialised).
-- @realm shared
-- @return number The number of seconds in the current session, or 0 if unavailable.
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

--- Prints colored messages to this player's chat box.
-- On the server, sends a `"player.chatPrint"` net message containing the arguments; the client-side hook unpacks and passes them to `chat.AddText`.
-- On the client, calls `chat.AddText` directly.
-- Accepts the same argument format as `chat.AddText`: alternating `Color` and `string` values.
-- @realm shared
-- @param ... Color|string Alternating color and text arguments forwarded to `chat.AddText`.
ax.player.meta.ChatPrintInternal = ax.player.meta.ChatPrintInternal or ax.player.meta.ChatPrint
function ax.player.meta:ChatPrint(...)
    if ( SERVER ) then
        ax.net:Start(self, "player.chatPrint", {...})
    else
        chat.AddText(...)
    end
end

--- Sends a toast notification to this player.
-- On the server, delegates to `ax.notification:Send`.
-- On the client, delegates to `ax.notification:Add`.
-- The `type` parameter controls the notification style (e.g. `"error"`, `"success"`, `"info"`).
-- `length` controls display duration in seconds; the notification system applies a default when omitted.
-- @realm shared
-- @param text string The notification message to display.
-- @param type string|nil The notification type (e.g. `"error"`, `"success"`, `"info"`).
-- @param length number|nil Display duration in seconds.
function ax.player.meta:Notify(text, type, length)
    if ( SERVER ) then
        ax.notification:Send(self, text, type, length)
    else
        ax.notification:Add(text, type, length)
    end
end

--- Syncs all relay data to this player.
-- Iterates `ax.relay.data` and calls `SetRelay` for every key/value pair in the `"global"` scope, then for every per-entity scope whose entity is still valid.
-- The `false` third argument to `SetRelay` suppresses the normal broadcast so each value is sent only to this player rather than all receivers.
-- Called when the player becomes ready to ensure they receive the full relay state.
-- @realm shared
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

--- Starts or stops a progress action bar for this player.
-- When `label` is nil, cancels any running action bar: invokes `onCancel` if stored, clears the action bar timer, and sends `"player.actionbar.stop"` to the client.
-- When `label` is provided, starts a new action bar by sending `"player.actionbar.start"` to the client with the label and duration, and stores `onComplete`/`onCancel` on the player's entity table.
-- On the client, delegates to `ax.actionBar:Start` or `ax.actionBar:Stop`.
-- If the player is ragdolled and `bAllowRagdolled` is not true, a localised error notification is sent and false is returned.
-- @realm shared
-- @param label string|nil The action bar label. Pass nil to cancel the active bar.
-- @param duration number|nil The bar duration in seconds. Defaults to 5.
-- @param onComplete function|nil Called when the bar completes without cancellation.
-- @param onCancel function|nil Called when the bar is cancelled before completion.
-- @param bAllowRagdolled boolean|nil When true, allows the action bar while ragdolled.
-- @return false|nil Returns false if blocked due to ragdoll state; nil otherwise.
function ax.player.meta:PerformAction(label, duration, onComplete, onCancel, bAllowRagdolled)
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

        if ( bAllowRagdolled != true and self:IsRagdolled() ) then
            self:Notify(ax.localization:GetPhrase("error.ragdolled.action"), "error")
            return false
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

--- Returns whether the player is still in a position to maintain an entity interaction.
-- First checks `self:GetUseEntity()` — if it equals `entity` the player is actively looking at it and true is returned immediately.
-- If `allowEyeTrace` is true, also checks `self:GetEyeTrace()` and optionally enforces a maximum distance between the player's shoot position and the trace hit position.
-- Returns false when the player or entity is invalid, the entity is not being looked at, or the distance limit is exceeded.
-- @realm shared
-- @param entity Entity The entity the action is being performed on.
-- @param allowEyeTrace boolean|nil When true, also accepts the eye trace as a valid look target.
-- @param maxDistance number|nil Maximum allowed distance to the entity (in world units). Ignored when 0 or nil.
-- @return boolean True if the player can maintain the action, false otherwise.
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

--- Starts an action bar that automatically cancels if the player stops looking at an entity.
-- Creates a repeating 0.1-second timer that calls `CanMaintainEntityAction` each tick.
-- If the entity becomes invalid or the player stops meeting the look/distance requirements, the timer is removed and `PerformAction(nil)` is called to cancel the bar.
-- The action bar itself is started via `PerformAction` with the provided parameters.
-- @realm shared
-- @param entity Entity The entity the player must keep looking at.
-- @param label string The action bar label displayed to the player.
-- @param duration number The bar duration in seconds.
-- @param onComplete function|nil Called when the bar completes without cancellation.
-- @param onCancel function|nil Called when the bar is cancelled.
-- @param allowEyeTrace boolean|nil When true, the eye trace is also accepted (see `CanMaintainEntityAction`).
-- @param maxDistance number|nil Maximum allowed distance to the entity. Ignored when nil.
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
