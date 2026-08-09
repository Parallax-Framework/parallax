--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Faction management system for creating, storing, and retrieving faction data.
-- Supports default player models, faction joining restrictions, and team setup.
-- @module ax.faction

ax.faction = ax.faction or {}
ax.faction.instances = ax.faction.instances or {}
ax.faction.stored = ax.faction.stored or {}

--- Initialize the faction system by loading all faction files.
-- Automatically includes factions from framework, modules, and schema directories.
-- Called during framework boot to set up all available factions.
-- @realm shared
-- @usage ax.faction:Initialize()
function ax.faction:Initialize()
    self:Include("parallax/gamemode/factions")

    local _, modules = file.Find("parallax/gamemode/modules/*", "LUA")
    for i = 1, #modules do
        self:Include("parallax/gamemode/modules/" .. modules[i] .. "/factions")
    end

    self:Include(engine.ActiveGamemode() .. "/gamemode/schema/factions")

    _, modules = file.Find(engine.ActiveGamemode() .. "/gamemode/modules/*", "LUA")
    for i = 1, #modules do
        self:Include(engine.ActiveGamemode() .. "/gamemode/modules/" .. modules[i] .. "/factions")
    end
end

--- Default models used if a faction does not specify its own.
FACTION_DEFAULT_MODELS = {
    "models/humans/group01/female_01.mdl",
    "models/humans/group01/female_02.mdl",
    "models/humans/group01/female_03.mdl",
    "models/humans/group01/female_04.mdl",
    "models/humans/group01/female_06.mdl",
    "models/humans/group01/female_07.mdl",
    "models/humans/group01/male_01.mdl",
    "models/humans/group01/male_02.mdl",
    "models/humans/group01/male_04.mdl",
    "models/humans/group01/male_05.mdl",
    "models/humans/group01/male_06.mdl",
    "models/humans/group01/male_07.mdl",
    "models/humans/group01/male_08.mdl",
    "models/humans/group01/male_09.mdl",
    "models/humans/group02/female_01.mdl",
    "models/humans/group02/female_03.mdl",
    "models/humans/group02/female_06.mdl",
    "models/humans/group02/male_01.mdl",
    "models/humans/group02/male_03.mdl",
    "models/humans/group02/male_05.mdl",
    "models/humans/group02/male_07.mdl",
    "models/humans/group02/male_09.mdl"
}

--- The genders a character may be created as, in the order they are offered.
AX_GENDERS = { "male", "female" }

--- Returns true when a faction declares its model pool split by gender, as `models = { male = {...}, female = {...} }` rather than as one flat array.
---@realm shared
---@param faction table|nil A registered faction table.
---@return boolean bGendered Whether the pool is split per gender.
function ax.faction:HasGenderedModels(faction)
    if ( !istable(faction) ) then return false end

    local models = isfunction(faction.GetModels) and faction:GetModels() or faction.models
    if ( !istable(models) ) then return false end

    return istable(models.male) or istable(models.female)
end

--- Collapses a faction's model pool into a single ordered array, accepting either the flat form or the gendered `{ male = {...}, female = {...} }` form. Use this for every "is this model in the pool at all" question -- validation, precaching, random picks -- so a gendered pool never reads as empty.
---@realm shared
---@param faction table|nil A registered faction table.
---@return table models Flat array of model entries; empty when the faction has no pool.
function ax.faction:FlattenModels(faction)
    if ( !istable(faction) ) then return {} end

    local models = isfunction(faction.GetModels) and faction:GetModels() or faction.models
    if ( !istable(models) ) then return {} end

    if ( !self:HasGenderedModels(faction) ) then
        local flat = {}
        for i = 1, #models do
            flat[i] = models[i]
        end

        return flat
    end

    local flat = {}
    for i = 1, #AX_GENDERS do
        local list = models[ AX_GENDERS[i] ]
        if ( !istable(list) ) then continue end

        for j = 1, #list do
            flat[#flat + 1] = list[j]
        end
    end

    return flat
end

--- Resolves a model entry, which may be a plain path or a `{ path, skin }` pair, to its path.
---@realm shared
---@param entry string|table A model pool entry.
---@return string|nil path The model path, or nil when the entry is malformed.
function ax.faction:GetModelPath(entry)
    if ( isstring(entry) ) then return entry end
    if ( istable(entry) and isstring(entry[1]) ) then return entry[1] end

    return nil
end

--- Returns true when a model belongs to the female half of a faction's pool. A faction that declares gendered lists is authoritative; a flat pool falls back to matching "female" in the path, which is how the stock Half-Life 2 citizen models encode it, so the common case needs no schema changes at all.
---@realm shared
---@param model string Model path to test.
---@param faction? table Faction whose declared lists take precedence.
---@return boolean bFemale Whether the model is female.
function ax.faction:IsFemaleModel(model, faction)
    if ( !isstring(model) or model == "" ) then return false end

    if ( self:HasGenderedModels(faction) ) then
        local models = isfunction(faction.GetModels) and faction:GetModels() or faction.models

        for i = 1, #AX_GENDERS do
            local gender = AX_GENDERS[i]
            local list = models[gender]
            if ( !istable(list) ) then continue end

            for j = 1, #list do
                if ( self:GetModelPath(list[j]) == model ) then
                    return gender == "female"
                end
            end
        end
    end

    -- Checked before "male" because "female" contains it as a substring.
    return string.find(string.lower(model), "female", 1, true) != nil
end

--- Returns the models a faction offers for one gender. A gendered pool returns that gender's list; a flat pool is filtered by `IsFemaleModel`. When the filter leaves nothing -- a masked or uniformed roster that ships one body for everyone -- the whole pool is returned, so gender stays a roleplay attribute rather than blocking creation.
---@realm shared
---@param faction table|nil A registered faction table.
---@param gender? string `"male"` or `"female"`. Defaults to `"male"`.
---@return table models Ordered array of model entries.
function ax.faction:GetModelsForGender(faction, gender)
    if ( !istable(faction) ) then return {} end

    gender = (gender == "female") and "female" or "male"

    if ( self:HasGenderedModels(faction) ) then
        local models = isfunction(faction.GetModels) and faction:GetModels() or faction.models
        local list = models[gender]

        if ( istable(list) and list[1] != nil ) then
            return list
        end

        return self:FlattenModels(faction)
    end

    local flat = self:FlattenModels(faction)
    local filtered = {}

    for i = 1, #flat do
        local path = self:GetModelPath(flat[i])
        if ( path and self:IsFemaleModel(path, faction) == (gender == "female") ) then
            filtered[#filtered + 1] = flat[i]
        end
    end

    if ( filtered[1] == nil ) then
        return flat
    end

    return filtered
end

--- Include and load faction files from a directory.
-- Recursively searches for faction .lua files and loads them into the faction system.
-- Automatically handles shared/client/server file prefixes and sets up team data.
-- @realm shared
-- @param directory string The directory path to search for faction files
-- @return boolean True if the operation completed successfully, false on error
-- @usage ax.faction:Include("parallax/gamemode/factions")
function ax.faction:Include(directory, timeFilter)
    if ( !isstring(directory) or directory == "" ) then
        ax.util:PrintError("Include: Invalid directory parameter provided")
        return false
    end

    -- Normalize path separators
    directory = string.gsub(directory, "\\", "/")
    directory = string.gsub(directory, "^/+", "") -- Remove leading slashes

    ax.util:PrintDebug(color_info, "Including faction files from directory: " .. directory)

    local files, directories = file.Find(directory .. "/*.lua", "LUA")
    if ( files[1] != nil ) then
        for i = 1, #files do
            local fileName = files[i]
            local filePath = directory .. "/" .. fileName

            -- Check file modification time if timeFilter is provided
            if ( isnumber(timeFilter) and timeFilter > 0 ) then
                local fileTime = file.Time(filePath, "LUA")
                local currentTime = os.time()

                if ( fileTime and (currentTime - fileTime) > timeFilter ) then
                    ax.util:PrintDebug("Skipping unchanged faction file (modified " .. (currentTime - fileTime) .. "s ago): " .. fileName)
                    continue
                end
            end

            local uniqueID = string.StripExtension(fileName)
            local prefix = string.sub(uniqueID, 1, 3)
            if ( prefix == "sh_" or prefix == "cl_" or prefix == "sv_" ) then
                uniqueID = string.sub(uniqueID, 4)
            end

            local existing = self.stored[uniqueID]
            local index = (istable(existing) and existing.index) or (#self.instances + 1)

            if ( existing ) then
                ax.util:PrintDebug(color_warning, "Faction \"" .. uniqueID .. "\" already exists, overwriting file: " .. fileName)
            end

            FACTION = { id = uniqueID, index = index }
                FACTION.GetModels = function(this)
                    return this.models or FACTION_DEFAULT_MODELS
                end

                ax.util:Include(directory .. "/" .. fileName, "shared")
                ax.util:PrintDebug(color_success, "Faction \"" .. (FACTION.name or FACTION.Name or FACTION.id) .. "\" initialised successfully.")

                team.SetUp(FACTION.index, FACTION.name or FACTION.Name or ("Faction " .. FACTION.id), FACTION.color or Color(255, 255, 255), FACTION.icon or "icon16/user.png")

                self.stored[FACTION.id] = FACTION
                self.instances[FACTION.index] = FACTION
            FACTION = nil
        end
    else
        ax.util:PrintDebug(color_warning, "No faction files found in directory: " .. directory)
    end

    if ( directories[1] != nil ) then
        for i = 1, #directories do
            local dirName = directories[i]
            self:Include(directory .. "/" .. dirName)
        end
    end

    return true
end

--- Get a faction by its identifier.
-- Supports lookup by unique ID string, index number, name, or partial name matching.
-- @realm shared
-- @param identifier string|number The faction ID, index, or name to search for
-- @return table|nil The faction table if found, nil otherwise
-- @usage local faction = ax.faction:Get("citizen")
-- @usage local faction = ax.faction:Get(1)
function ax.faction:Get(identifier)
    if ( isstring(identifier) and self.stored[identifier] ) then
        return self.stored[identifier]
    elseif ( isnumber(identifier) and self.instances[identifier] ) then
        return self.instances[identifier]
    end

    -- If all fails, run loops
    for i = 1, #self.instances do
        if ( isnumber(identifier) and self.instances[i].index == identifier ) then
            return self.instances[i]
        elseif ( isstring(identifier) and ( ax.util:FindString(self.instances[i].name or "", identifier) or ax.util:FindString(self.instances[i].id, identifier) ) ) then
            return self.instances[i]
        end
    end

    return nil
end

--- Check if a player can join a specific faction.
-- Runs through hook validation and faction-specific CanBecome functions.
-- @realm shared
-- @param identifier string|number The faction ID, index, or name
-- @param client Player The player entity to check permissions for
-- @return boolean, string|nil True if allowed, false if not. Error message if denied.
-- @usage local canJoin, reason = ax.faction:CanBecome("citizen", player)
function ax.faction:CanBecome(identifier, client)
    local factionTable = self:Get(identifier)
    if ( !factionTable ) then
        return false, "That faction does not exist."
    end

    local try, catch = hook.Run("CanPlayerBecomeFaction", factionTable, client)
    if ( try == false and isstring(catch) and #catch > 0 ) then
        return try, catch
    end

    if ( isfunction(factionTable.CanBecome) ) then
        try, catch = factionTable:CanBecome(client)
        if ( try == false and isstring(catch) and #catch > 0 ) then
            return try, catch
        end
    end

    return true, nil
end

--- Get all loaded faction instances.
-- Returns the complete list of factions indexed by their team index.
-- @realm shared
-- @return table Array of all faction instances indexed by team number
-- @usage local allFactions = ax.faction:GetAll()
function ax.faction:GetAll()
    return self.instances
end

--- Check if a faction exists and is valid.
-- Validates faction existence by attempting to retrieve it.
-- @realm shared
-- @param faction string|number The faction identifier to validate
-- @return boolean True if the faction exists, false otherwise
-- @usage if ax.faction:IsValid("citizen") then print("Faction exists") end
function ax.faction:IsValid(faction)
    if ( self:Get(faction) != nil ) then
        return true
    end

    return false
end
