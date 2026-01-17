--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Rank management system for creating, storing, and retrieving rank data.
-- Supports rank variables, faction associations, and validation checks.
-- @module ax.rank

ax.rank = ax.rank or {}
ax.rank.instances = ax.rank.instances or {}
ax.rank.stored = ax.rank.stored or {}

--- Initialize the rank system by loading all rank files.
-- Automatically includes ranks from framework, modules, and schema directories.
-- Called during framework boot to set up all available ranks.
-- @realm shared
-- @usage ax.rank:Initialize()
function ax.rank:Initialize()
    self:Include("parallax/gamemode/ranks")

    local _, modules = file.Find("parallax/gamemode/modules/*", "LUA")
    for i = 1, #modules do
        self:Include("parallax/gamemode/modules/" .. modules[i] .. "/ranks")
    end

    self:Include(engine.ActiveGamemode() .. "/gamemode/schema/ranks")

    _, modules = file.Find(engine.ActiveGamemode() .. "/gamemode/modules/*", "LUA")
    for i = 1, #modules do
        self:Include(engine.ActiveGamemode() .. "/gamemode/modules/" .. modules[i] .. "/ranks")
    end
end

--- Include and load rank files from a directory.
-- Recursively searches for rank .lua files and loads them into the rank system.
-- Automatically handles shared/client/server file prefixes.
-- @realm shared
-- @param directory string The directory path to search for rank files
-- @return boolean True if the operation completed successfully, false on error
-- @usage ax.rank:Include("parallax/gamemode/ranks")
function ax.rank:Include(directory, timeFilter)
    if ( !isstring(directory) or directory == "" ) then
        ax.util:PrintError("Include: Invalid directory parameter provided")
        return false
    end

    -- Normalize path separators
    directory = string.gsub(directory, "\\", "/")
    directory = string.gsub(directory, "^/+", "") -- Remove leading slashes

    ax.util:PrintDebug(color_info, "Including rank files from directory: " .. directory)

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
                    ax.util:PrintDebug("Skipping unchanged rank file (modified " .. (currentTime - fileTime) .. "s ago): " .. fileName)
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

            RANK = { id = uniqueID, index = index }
                ax.util:Include(directory .. "/" .. fileName, "shared")
                ax.util:PrintDebug(color_success, "RANK \"" .. (RANK.Name or RANK.name or RANK.id) .. "\" initialised successfully.")

                if ( !isnumber(RANK.faction) ) then
                    ax.util:PrintDebug(color_error, "Rank \"" .. RANK.id .. "\" does not have faction ID, skipping file: " .. fileName)
                    continue
                end

                local factionTable = ax.faction:Get(RANK.faction)
                if ( !istable(factionTable) ) then
                    ax.util:PrintDebug(color_error, "Rank \"" .. RANK.id .. "\" uses an invalid faction ID skipping file: " .. fileName)
                    continue
                end

                if ( !istable(factionTable.Ranks) ) then factionTable.Ranks = {} end
                factionTable.Ranks[RANK.id] = RANK

                self.stored[RANK.id] = RANK
                self.instances[RANK.index] = RANK
            RANK = nil
        end
    else
        ax.util:PrintDebug(color_warning, "No rank files found in directory: " .. directory)
    end

    if ( directories[1] != nil ) then
        for i = 1, #directories do
            local dirName = directories[i]
            self:Include(directory .. "/" .. dirName)
        end
    end

    return true
end

--- Get a rank by its identifier.
-- Supports lookup by unique ID string, index number, name, or partial name matching.
-- @realm shared
-- @param identifier string|number The rank ID, index, or name to search for
-- @return table|nil The rank table if found, nil otherwise
-- @usage local rank = ax.rank:Get("security")
-- @usage local rank = ax.rank:Get(1)
function ax.rank:Get(identifier)
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

--- Check if a player can become a specific rank.
-- Runs through hook validation and rank-specific CanBecome functions.
-- @realm shared
-- @param rank string|number The rank ID, index, or name
-- @param client Player The player entity to check permissions for
-- @return boolean, string|nil True if allowed, false if not. Error message if denied.
-- @usage local canBecome, reason = ax.rank:CanBecome("security", player)
function ax.rank:CanBecome(rank, client)
    local rankTable = self:Get(faction)
    local try, catch = hook.Run("CanBecomeRank", rankTable, client)
    if ( try == false and isstring(catch) and #catch > 0 ) then
        client:Notify(catch, "error")
        return false, catch
    end

    if ( isfunction(rankTable.CanBecome) ) then
        try, catch = rankTable:CanBecome(client)
        if ( try == false and isstring(catch) and #catch > 0 ) then
            client:Notify(catch, "error")
            return false, catch
        end
    end

    return true, nil
end

--- Get all loaded rank instances.
-- Returns the complete list of ranks indexed by their ID.
-- @realm shared
-- @return table Array of all rank instances
-- @usage local allRanks = ax.rank:GetAll()
function ax.rank:GetAll(filter)
    if ( filter and istable(filter) ) then
        local filtered = {}
        for _, rankTable in pairs(self.instances) do
            local match = false
            if ( isnumber(filter.faction) and rankTable.faction == filter.faction ) then
                match = true
            elseif ( isstring(filter.name) and ax.util:FindString(rankTable.name or "", filter.name) ) then
                match = true
            end

            if ( match ) then
                table.insert(filtered, rankTable)
            end
        end

        return filtered
    end

    return self.instances
end

--- Check if a rank exists and is valid.
-- Validates rank existence by attempting to retrieve it.
-- @realm shared
-- @param rank string|number The rank identifier to validate
-- @return boolean True if the rank exists, false otherwise
-- @usage if ax.rank:IsValid("security") then print("Rank exists") end
function ax.rank:IsValid(rank)
    if ( self:Get(rank) != nil ) then
        return true
    end

    return false
end
