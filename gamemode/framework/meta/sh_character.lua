--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local character = ax.character.meta or {}
character.__index = character

--- Returns a human-readable string representation of the character.
-- Format: `"Character [id][name]"`. Useful for debug output and logging.
-- @realm shared
-- @return string A formatted string identifying this character.
function character:__tostring()
    return string.format("Character [%d][%s]", self.id, self.vars.name or "Unknown")
end

--- Returns the character's unique database ID.
-- This is the primary key from the `ax_characters` table. Temporary bot characters use the owner's SteamID64 as their ID instead.
-- @realm shared
-- @return number The character's numeric ID.
function character:GetID()
    return self.id
end

--- Returns the character's vars table containing all stored variable values.
-- The vars table holds every registered character variable (name, faction, model, description, etc.). Modifications to this table are live but not automatically persisted — call `Save()` to write changes to the database.
-- @realm shared
-- @return table The character's vars table.
function character:GetVars()
    return self.vars
end

--- Returns the inventory instance associated with this character.
-- Looks up `ax.inventory.instances` using the character's stored inventory ID.
-- Returns nil when the inventory has not been loaded or the ID is 0.
-- Aliased as `character.GetInv`.
-- @realm shared
-- @return table|nil The inventory instance, or nil if not loaded.
function character:GetInventory()
    return ax.inventory.instances[self.vars.inventory]
end

character.GetInv = character.GetInventory

--- Returns the numeric ID of the character's inventory.
-- This is the database ID of the associated inventory row. Returns 0 when no inventory has been assigned (e.g. freshly created characters before an inventory is allocated). Aliased as `character.GetInvID`.
-- @realm shared
-- @return number The inventory ID, or 0 if none is set.
function character:GetInventoryID()
    return tonumber(self.vars.inventory) or 0
end

character.GetInvID = character.GetInventoryID

--- Returns the player entity that owns this character.
-- Returns the player stored in `self.player` at load time. May be nil for offline or bot characters that have been unloaded. Aliased as `GetPlayer`, `GetPly`, `GetUser`, and `GetClient`.
-- @realm shared
-- @return Player|nil The owning player entity, or nil if unloaded.
function character:GetOwner()
    return self.player
end

character.GetPlayer = character.GetOwner
character.GetPly = character.GetOwner
character.GetUser = character.GetOwner
character.GetClient = character.GetOwner

--- Returns the faction definition table for this character's faction.
-- Delegates to `ax.faction:Get` using `self.vars.faction`. Returns nil when the faction index is unset or not registered.
-- @realm shared
-- @return table|nil The faction definition, or nil if not found.
function character:GetFactionData()
    return ax.faction:Get(self.vars.faction)
end

--- Returns the class definition table for this character's class.
-- Delegates to `ax.class:Get` using `self.vars.class`. Returns nil when no class is assigned or the class is not registered.
-- @realm shared
-- @return table|nil The class definition, or nil if not found.
function character:GetClassData()
    return ax.class:Get(self.vars.class)
end

--- Returns the rank definition table for this character's rank.
-- Delegates to `ax.rank:Get` using `self.vars.rank`. Returns nil when no rank is assigned or the rank is not registered.
-- @realm shared
-- @return table|nil The rank definition, or nil if not found.
function character:GetRankData()
    return ax.rank:Get(self.vars.rank)
end

--- Returns true if the character holds all of the specified flags.
-- Iterates each letter in `flags` and checks whether it appears in the character's stored flags string (via a case-sensitive `FindString` call).
-- Returns false as soon as any letter is missing. An empty `flags` string always returns true.
-- @realm shared
-- @param flags string A string of single-character flag letters to test for (e.g. `"acf"` checks for flags a, c, and f).
-- @return boolean True if every flag letter is present, false otherwise.
function character:HasFlags(flags)
    local data = self:GetData("flags", "")
    for i = 1, #flags do
        local letter = flags[i]
        if ( !ax.util:FindString(data, letter, true) ) then
            return false
        end
    end

    return true
end

if ( SERVER ) then
    --- Sets a bodygroup on the character's player model and persists it.
    -- Immediately applies the bodygroup to the owning player (if online) via `Player:SetBodygroup`, then stores the value in the character's data under `"bodygroups"` keyed by the numeric index (as a string) and saves via `SetData`. The stored value is reapplied when the character loads.
    -- @realm server
    -- @param index number The bodygroup index to set.
    -- @param value number The bodygroup value to apply.
    function character:SetBodygroup(index, value)
        local owner = self:GetOwner()
        if ( ax.util:IsValidPlayer(owner) ) then
            owner:SetBodygroup(index, value)
        end

        local bodygroups = self:GetData("bodygroups", {})
        bodygroups[tostring(index)] = value

        self:SetData("bodygroups", bodygroups)
    end

    --- Sets a bodygroup by name on the character's player model and persists it.
    -- Resolves the bodygroup name to an index via `Player:FindBodygroupByName` and applies it on the owning player if online. Stores the value in the character's data under `"bodygroups"` keyed by the name string, so it can be reapplied by name on model load. Prefer this over `SetBodygroup` when working with named bodygroups to avoid hardcoding indices.
    -- @realm server
    -- @param name string The bodygroup name as defined in the model.
    -- @param value number The bodygroup value to apply.
    function character:SetBodygroupName(name, value)
        local owner = self:GetOwner()
        if ( ax.util:IsValidPlayer(owner) ) then
            local id = owner:FindBodygroupByName(name)
            if ( id and id >= 0 ) then
                owner:SetBodygroup(id, value)
            end
        end

        local bodygroups = self:GetData("bodygroups", {})
        bodygroups[name] = value

        self:SetData("bodygroups", bodygroups)
    end

    --- Grants one or more flags to the character.
    -- Iterates each letter in `flags`. For each letter:
    -- - Skips letters whose flag data is not registered in `ax.flag`.
    -- - Skips letters the character already holds (idempotent).
    -- - Appends the letter to the character's stored flags string.
    -- - Calls `flagData:OnGiven(character)` if the flag defines it.
    -- - Fires the `"CharacterFlagGiven"` hook with the character and letter.
    -- After all letters are processed, calls `Save()` if any new flag was added. Returns immediately for empty or non-string input.
    -- @realm server
    -- @param flags string A string of single-character flag letters to grant.
    function character:GiveFlags(flags)
        if ( !isstring(flags) or #flags < 1 ) then return end

        local bOutdated = false
        local newFlags = self:GetData("flags", "")
        for i = 1, #flags do
            local letter = flags[i]
            local flagData = ax.flag:Get(letter)
            if ( !istable(flagData) ) then continue end
            if ( self:HasFlags(letter) ) then continue end

            newFlags = newFlags .. letter

            if ( isfunction(flagData.OnGiven) ) then
                flagData:OnGiven(self)
            end

            self:SetData("flags", newFlags)
            if ( !bOutdated ) then
                bOutdated = true
            end

            hook.Run("CharacterFlagGiven", self, letter)
        end

        if ( bOutdated ) then
            self:Save()
        end
    end

    --- Removes one or more flags from the character.
    -- Iterates each letter in `flags`. For each letter:
    -- - Skips letters whose flag data is not registered in `ax.flag`.
    -- - Skips letters the character does not currently hold (idempotent).
    -- - Removes the letter from the character's stored flags string via `string.Replace`.
    -- - Calls `flagData:OnTaken(character)` if the flag defines it.
    -- - Fires the `"CharacterFlagTaken"` hook with the character and letter.
    -- After all letters are processed, calls `Save()` if any flag was removed.
    -- Returns immediately for empty or non-string input.
    -- @realm server
    -- @param flags string A string of single-character flag letters to remove.
    function character:TakeFlags(flags)
        if ( !isstring(flags) or #flags < 1 ) then return end

        local bOutdated = false
        local newFlags = self:GetData("flags", "")
        for i = 1, #flags do
            local letter = flags[i]

            local flagData = ax.flag:Get(letter)
            if ( !istable(flagData) ) then continue end
            if ( !self:HasFlags(letter) ) then continue end

            newFlags = string.Replace(newFlags, letter, "")

            self:SetData("flags", newFlags)
            if ( !bOutdated ) then
                bOutdated = true
            end

            if ( isfunction(flagData.OnTaken) ) then
                flagData:OnTaken(self)
            end

            hook.Run("CharacterFlagTaken", self, letter)
        end

        if ( bOutdated ) then
            self:Save()
        end
    end

    --- Replaces the character's entire flag set with the given flags.
    -- Diffs the current flags against `flags`: letters present in the current set but absent from `flags` are removed via `TakeFlags` (triggering their `OnTaken` callbacks). The stored flags are then set to the new string and saved. Finally, `GiveFlags` is called for each letter in `flags` to trigger `OnGiven` callbacks for newly granted flags. Returns immediately for non-string input.
    -- @realm server
    -- @param flags string The complete new flag string to assign to the character. Letters not currently held will be granted; letters held but not present in this string will be revoked.
    function character:SetFlags(flags)
        if ( !isstring(flags) ) then return end

        local concatenated = table.concat(string.Explode("", flags))

        local current = self:GetData("flags", "")
        for i = 1, #current do
            local letter = current[i]
            if ( ax.util:FindString(concatenated, letter) ) then continue end

            self:TakeFlags(letter)
        end

        self:SetData("flags", concatenated)
        self:Save()

        for i = 1, #concatenated do
            local letter = concatenated[i]
            self:GiveFlags(letter)
        end
    end

    --- Persists all character variables and data to the database.
    -- Constructs a MySQL UPDATE query targeting the `ax_characters` table, filtering by the character's ID. All registered character vars that declare a `field` in their schema are included; table values are serialised to JSON. The `data` blob (arbitrary key/value store) is always written as JSON. Falls back to the registered default when a var has no value set. Call this after any direct modification to `self.vars` that bypasses the standard `SetVar` / `SetData` pathway.
    -- @realm server
    function character:Save()
        if ( !istable(self.vars.data) ) then self.vars.data = {} end

        -- Build an update query for the characters table using the registered schema
        local query = mysql:Update("ax_characters")
        query:Where("id", self:GetID())

        -- Ensure the data table exists and always save it as JSON
        query:Update("data", util.TableToJSON(self.vars.data or {}))

        -- Iterate registered vars and persist fields that declare a database column
        for name, meta in pairs(ax.character.vars or {}) do
            if ( istable(meta) and meta.field ) then
                local val = nil

                if ( istable(self.vars) ) then
                    val = self.vars[name]
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

                ax.util:PrintDebug("Saving character field '" .. meta.field .. "' with value: " .. tostring(val))
            end
        end

        query:Execute()
    end
end

ax.character.meta = character -- Keep, funcs don't define otherwise.
