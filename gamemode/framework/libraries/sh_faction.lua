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