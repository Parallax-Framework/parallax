--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.class = ax.class or {}
ax.class.instances  = ax.class.instances or {}
ax.class.stored = ax.class.stored or {}

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

function ax.class:Include(directory)
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

function ax.class:GetAll()
    return self.instances
end

function ax.class:IsValid(class)
    if ( self:Get(class) != nil ) then
        return true
    end

    return false
end
