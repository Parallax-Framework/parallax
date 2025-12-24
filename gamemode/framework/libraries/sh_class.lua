--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Class management system for creating, storing, and retrieving class data.
-- Supports class variables, faction associations, and validation checks.
-- @module ax.class

ax.class = ax.class or {}
ax.class.instances = ax.class.instances or {}
ax.class.stored = ax.class.stored or {}

--- Initialize the class system by loading all class files.
-- Automatically includes classes from framework, modules, and schema directories.
-- Called during framework boot to set up all available classes.
-- @realm shared
-- @usage ax.class:Initialize()
function ax.class:Initialize()
    self:Include("parallax/gamemode/classes")

    local _, modules = file.Find("parallax/gamemode/modules/*", "LUA")
    for i = 1, #modules do
        self:Include("parallax/gamemode/modules/" .. modules[i] .. "/classes")
    end

    self:Include(engine.ActiveGamemode() .. "/gamemode/schema/classes")

    _, modules = file.Find(engine.ActiveGamemode() .. "/gamemode/modules/*", "LUA")
    for i = 1, #modules do
        self:Include(engine.ActiveGamemode() .. "/gamemode/modules/" .. modules[i] .. "/classes")
    end
end

--- Include and load class files from a directory.
-- Recursively searches for class .lua files and loads them into the class system.
-- Automatically handles shared/client/server file prefixes.
-- @realm shared
-- @param directory string The directory path to search for class files
-- @return boolean True if the operation completed successfully, false on error
-- @usage ax.class:Include("parallax/gamemode/classes")
function ax.class:Include(directory, timeFilter)
    if ( !isstring(directory) or directory == "" ) then
        ax.util:PrintError("Include: Invalid directory parameter provided")
        return false
    end

    -- Normalize path separators
    directory = string.gsub(directory, "\\", "/")
    directory = string.gsub(directory, "^/+", "") -- Remove leading slashes

    ax.util:PrintDebug(color_info, "Including class files from directory: " .. directory)

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
                    ax.util:PrintDebug("Skipping unchanged class file (modified " .. (currentTime - fileTime) .. "s ago): " .. fileName)
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

            CLASS = { id = uniqueID, index = index }
                ax.util:Include(directory .. "/" .. fileName, "shared")
                ax.util:PrintDebug(color_success, "CLASS \"" .. (CLASS.Name or CLASS.name or CLASS.id) .. "\" initialised successfully.")

                if ( !isnumber(CLASS.faction) ) then
                    ax.util:PrintDebug(color_error, "Class \"" .. CLASS.id .. "\" does not have faction ID, skipping file: " .. fileName)
                    continue
                end

                local factionTable = ax.faction:Get(CLASS.faction)
                if ( !istable(factionTable) ) then
                    ax.util:PrintDebug(color_error, "Class \"" .. CLASS.id .. "\" uses an invalid faction ID skipping file: " .. fileName)
                    continue
                end

                if ( !istable(factionTable.Classes) ) then factionTable.Classes = {} end
                factionTable.Classes[CLASS.id] = CLASS

                self.stored[CLASS.id] = CLASS
                self.instances[CLASS.index] = CLASS
            CLASS = nil
        end
    else
        ax.util:PrintDebug(color_warning, "No class files found in directory: " .. directory)
    end

    if ( directories[1] != nil ) then
        for i = 1, #directories do
            local dirName = directories[i]
            self:Include(directory .. "/" .. dirName)
        end
    end

    return true
end

--- Get a class by its identifier.
-- Supports lookup by unique ID string, index number, name, or partial name matching.
-- @realm shared
-- @param identifier string|number The class ID, index, or name to search for
-- @return table|nil The class table if found, nil otherwise
-- @usage local class = ax.class:Get("security")
-- @usage local class = ax.class:Get(1)
function ax.class:Get(identifier)
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

--- Check if a player can become a specific class.
-- Runs through hook validation and class-specific CanBecome functions.
-- @realm shared
-- @param class string|number The class ID, index, or name
-- @param client Player The player entity to check permissions for
-- @return boolean, string|nil True if allowed, false if not. Error message if denied.
-- @usage local canBecome, reason = ax.class:CanBecome("security", player)
function ax.class:CanBecome(class, client)
    local classTable = self:Get(faction)
    local try, catch = hook.Run("CanBecomeClass", classTable, client)
    if ( try == false and isstring(catch) and #catch > 0 ) then
        client:Notify(catch, "error")
        return false, catch
    end

    if ( isfunction(classTable.CanBecome) ) then
        try, catch = classTable:CanBecome(client)
        if ( try == false and isstring(catch) and #catch > 0 ) then
            client:Notify(catch, "error")
            return false, catch
        end
    end

    return true, nil
end

--- Get all loaded class instances.
-- Returns the complete list of classes indexed by their ID.
-- @realm shared
-- @return table Array of all class instances
-- @usage local allClasses = ax.class:GetAll()
function ax.class:GetAll(filter)
    if ( filter and istable(filter) ) then
        local filtered = {}
        for _, classTable in pairs(self.instances) do
            local match = false
            if ( isnumber(filter.faction) and classTable.faction == filter.faction ) then
                match = true
            elseif ( isstring(filter.name) and ax.util:FindString(classTable.name or "", filter.name) ) then
                match = true
            end

            if ( match ) then
                table.insert(filtered, classTable)
            end
        end

        return filtered
    end

    return self.instances
end

--- Check if a class exists and is valid.
-- Validates class existence by attempting to retrieve it.
-- @realm shared
-- @param class string|number The class identifier to validate
-- @return boolean True if the class exists, false otherwise
-- @usage if ax.class:IsValid("security") then print("Class exists") end
function ax.class:IsValid(class)
    if ( self:Get(class) != nil ) then
        return true
    end

    return false
end
