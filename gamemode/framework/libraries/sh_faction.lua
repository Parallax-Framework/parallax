--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

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
    Model("models/humans/group01/male_01.mdl"),
    Model("models/humans/group01/male_02.mdl"),
    Model("models/humans/group01/male_04.mdl"),
    Model("models/humans/group01/male_05.mdl"),
    Model("models/humans/group01/male_06.mdl"),
    Model("models/humans/group01/male_07.mdl"),
    Model("models/humans/group01/male_08.mdl"),
    Model("models/humans/group01/male_09.mdl"),
    Model("models/humans/group02/male_01.mdl"),
    Model("models/humans/group02/male_03.mdl"),
    Model("models/humans/group02/male_05.mdl"),
    Model("models/humans/group02/male_07.mdl"),
    Model("models/humans/group02/male_09.mdl"),
    Model("models/humans/group01/female_01.mdl"),
    Model("models/humans/group01/female_02.mdl"),
    Model("models/humans/group01/female_03.mdl"),
    Model("models/humans/group01/female_06.mdl"),
    Model("models/humans/group01/female_07.mdl"),
    Model("models/humans/group02/female_01.mdl"),
    Model("models/humans/group02/female_03.mdl"),
    Model("models/humans/group02/female_06.mdl"),
    Model("models/humans/group01/female_04.mdl")
}

function ax.faction:Include(directory)
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

-- Get a faction by ID, name, or table
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

-- Check if a faction can be joined
function ax.faction:CanBecome(identifier, client)
    local factionTable = self:Get(identifier)
    if ( !factionTable ) then
        return false, "That faction does not exist."
    end

    local try, catch = hook.Run("CanBecomeFaction", factionTable, client)
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

-- Return all faction instances
function ax.faction:GetAll()
    return self.instances
end

-- Check if a faction is valid
function ax.faction:IsValid(faction)
    if ( self:Get(faction) != nil ) then
        return true
    end

    return false
end
