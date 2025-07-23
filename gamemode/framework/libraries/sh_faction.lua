ax.faction = ax.faction or {}
ax.faction.instances  = ax.faction.instances or {}
ax.faction.stored = ax.faction.stored or {}

function ax.faction:Initialize()
    self:Include("parallax/gamemode/factions")
    self:Include(engine.ActiveGamemode() .. "/gamemode/schema/factions")
end

function ax.faction:Include(directory)
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

            local facUniqueID = string.StripExtension(fileName)
            local prefix = string.sub(facUniqueID, 1, 3)
            if ( prefix == "sh_" or prefix == "cl_" or prefix == "sv_" ) then
                facUniqueID = string.sub(facUniqueID, 4)
            end

            if ( self.stored[facUniqueID] ) then
                ax.util:PrintDebug(Color(255, 79, 43), "Faction \"" .. facUniqueID .. "\" already exists, skipping file: " .. fileName)
                continue
            end

            FACTION = { id = facUniqueID, index = #self.instances + 1 }
                ax.util:Include(directory .. "/" .. fileName, "shared")
                ax.util:PrintDebug(Color(85, 255, 120), "Faction \"" .. FACTION.Name .. "\" initialised successfully.")

                self.stored[FACTION.id] = FACTION
                self.instances[FACTION.index] = FACTION
            FACTION = nil
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

function ax.faction:Get(id)
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
        end
    end

    return nil
end

function ax.faction:CanBecome(faction, client)
    local factionTable = self:Get(faction)
    local try, err = hook.Run("CanBecomeFaction", factionTable, client)
    if ( try == false ) then
        client:ChatPrint("You cannot become part of this faction: " .. (err or ""))
    end

    if ( isfunction(factionTable.CanBecome) ) then
        try, err = factionTable:CanBecome(client)
        if ( try == false ) then
            client:ChatPrint("You cannot become part of this faction: " .. (err or ""))
        end
    end

    return true, nil
end