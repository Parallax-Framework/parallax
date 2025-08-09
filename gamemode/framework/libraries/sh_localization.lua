ax.localization = ax.localization or {}
ax.localization.langs = ax.localization.langs or {}

function ax.localization:Register(name, translation)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintWarning("Invalid localization name provided")
        return
    end

    if ( !istable(translation) ) then
        ax.util:PrintWarning("Invalid localization translation provided for \"" .. name .. "\"")
        return
    end

    if ( istable(ax.localization.langs[name]) ) then
        ax.localization.langs[name] = table.Merge(ax.localization.langs[name], translation)
    end

    self.langs[name] = translation
    ax.util:PrintDebug("Localization \"" .. name .. "\" registered successfully.")
end

function ax.localization:GetPhrase(phrase, ...)
    if ( !isstring(phrase) or phrase == "" ) then
        ax.util:PrintWarning("Invalid phrase provided to ax.localization:GetPhrase()")
        return ""
    end

    local langCode = CLIENT and GetConVar("gmod_language"):GetString() or "en"
    local lang = ax.localization.langs[langCode]
    if ( !istable(lang) or !lang[phrase] ) then
        ax.util:PrintWarning("Phrase \"" .. phrase .. "\" not found in language \"" .. langCode .. "\"")
        return phrase
    end

    local translation = lang[phrase]
    if ( !isstring(translation) or translation == "" ) then
        ax.util:PrintWarning("Translation for phrase \"" .. phrase .. "\" is not a valid string")
        return phrase
    end

    if ( ... ) then
        translation = string.format(translation, ...)
    end

    return translation
end

function ax.localization:Initialize()
    self:Include("parallax/gamemode/localization")

    local _, modules = file.Find("parallax/gamemode/modules/*", "LUA")
    for i = 1, #modules do
        self:Include("parallax/gamemode/modules/" .. modules[i] .. "/localization")
    end

    self:Include(engine.ActiveGamemode() .. "/gamemode/schema/localization")

    _, modules = file.Find(engine.ActiveGamemode() .. "/gamemode/modules/*", "LUA")
    for i = 1, #modules do
        self:Include(engine.ActiveGamemode() .. "/gamemode/modules/" .. modules[i] .. "/localization")
    end
end

function ax.localization:Include(directory)
    if ( !isstring(directory) or directory == "" ) then
        ax.util:PrintWarning("Include: Invalid directory parameter provided")
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

ax.localization = ax.localization