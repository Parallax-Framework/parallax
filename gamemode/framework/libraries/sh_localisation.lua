ax.localisation = ax.localisation or {}
ax.localisation.langs = ax.localisation.langs or {}

function ax.localisation:Register(name, translation)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("Invalid localisation name provided")
        return
    end

    if ( !istable(translation) ) then
        ax.util:PrintError("Invalid localisation translation provided for \"" .. name .. "\"")
        return
    end

    if ( istable(ax.localisation.langs[name]) ) then
        ax.localisation.langs[name] = table.Merge(ax.localisation.langs[name], translation)
    end

    self.langs[name] = translation
    ax.util:PrintDebug("Localisation \"" .. name .. "\" registered successfully.")
end

function ax.localisation:GetPhrase(phrase, ...)
    if ( !isstring(phrase) or phrase == "" ) then
        ax.util:PrintError("Invalid phrase provided to ax.localisation:GetPhrase()")
        return ""
    end

    local langCode = CLIENT and GetConVar("gmod_language"):GetString() or "en"
    local lang = ax.localisation.langs[langCode]
    if ( !istable(lang) or !lang[phrase] ) then
        ax.util:PrintError("Phrase \"" .. phrase .. "\" not found in language \"" .. langCode .. "\"")
        return phrase
    end

    local formatted = lang[phrase]
    if ( ... ) then
        formatted = string.format(formatted, ...)
    end

    return formatted
end

function ax.localisation:Initialize()
    self:Include("parallax/gamemode/localization")
    self:Include(engine.ActiveGamemode() .. "/gamemode/schema/localization")

    local _, modules = file.Find("parallax/gamemode/modules/*", "LUA")
    for i = 1, #modules do
        self:Include("parallax/gamemode/modules/" .. modules[i] .. "/localization")
    end

    _, modules = file.Find(engine.ActiveGamemode() .. "/gamemode/modules/*", "LUA")
    for i = 1, #modules do
        self:Include(engine.ActiveGamemode() .. "/gamemode/modules/" .. modules[i] .. "/localization")
    end
end

function ax.localisation:Include(directory)
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
            ax.util:Include(directory .. "/" .. fileName, "shared")
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

ax.localization = ax.localisation