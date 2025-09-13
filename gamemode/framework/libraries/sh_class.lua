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

    local files, directories = file.Find(directory .. "/*.lua", "LUA")

    if ( files[1] != nil ) then
        for i = 1, #files do
            local fileName = files[i]

            local clsUniqueID = string.StripExtension(fileName)
            local prefix = string.sub(clsUniqueID, 1, 3)
            if ( prefix == "sh_" or prefix == "cl_" or prefix == "sv_" ) then
                clsUniqueID = string.sub(clsUniqueID, 4)
            end

            local existing = self.stored[clsUniqueID]
            local index = (istable(existing) and existing.index) or (#self.instances + 1)

            if ( existing ) then
                ax.util:PrintDebug(Color(255, 200, 50), "Class \"" .. clsUniqueID .. "\" already exists, overwriting file: " .. fileName)
            end

            CLASS = { id = clsUniqueID, index = index }
                if ( !isnumber(CLASS.Faction) ) then
                    ax.util:PrintDebug(Color(255, 73, 24), "Class \"" .. CLASS.id .. "\" does not have faction ID, skipping file: " .. fileName)
                    continue
                end

                local factionTable = ax.faction:Get(CLASS.Faction)
                if ( !istable(factionTable) ) then
                    ax.util:PrintDebug(Color(255, 73, 24), "Class \"" .. CLASS.id .. "\" uses an invalid faction ID skipping file: " .. fileName)
                    continue
                end

                ax.util:Include(directory .. "/" .. fileName, "shared")
                ax.util:PrintDebug(Color(85, 255, 120), "CLASS \"" .. (CLASS.Name or CLASS.name or CLASS.id) .. "\" initialised successfully.")

                if ( !istable(factionTable.Classes) ) then factionTable.Classes = {} end
                factionTable.Classes[CLASS.id] = CLASS

                self.stored[CLASS.id] = CLASS
                self.instances[CLASS.index] = CLASS
            CLASS = nil
        end
    end

    if ( directories[1] != nil ) then
        for i = 1, #directories do
            local dirName = directories[i]
            self:Include(directory .. "/" .. dirName)
        end
    end

    return true
end

function ax.class:Get(id)
    if ( isstring(id) and self.stored[id] ) then
        return self.stored[id]
    elseif ( isnumber(id) and self.instances[id] ) then
        return self.instances[id]
    end

    for i = 1, #self.instances do
        if ( isnumber(id) and self.instances[i].index == id ) then
            return self.instances[i]
        elseif ( isstring(id) and ( ax.util:FindString(self.instances[i].Name, id) or ax.util:FindString(self.instances[i].id, id) ) ) then
            return self.instances[i]
        elseif ( istable(id) and isnumber(id.id) and self.instances[i].id == id.id ) then
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