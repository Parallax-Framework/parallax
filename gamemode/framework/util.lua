function ax.util:DetectFileRealm(file)
    if ( !file or type(file) != "string" ) then
        return "shared"
    end

    local fileName = string.lower(file)

    -- Client-side patterns
    if ( string.match(fileName, "^cl_") or
        string.match(fileName, "/cl_") ) then

        return "client"
    end

    -- Server-side patterns
    if ( string.match(fileName, "^sv_") or
        string.match(fileName, "/sv_") ) then
        return "server"
    end

    -- Shared patterns (default for sh_ prefix or no clear indication)
    return "shared"
end

function ax.util:Include(path, realm)
    if ( !isstring(path) or path == "" ) then
        ax.util:PrintError("Include: Invalid path parameter provided")
        return false
    end

    -- Normalize path separators
    path = string.gsub(path, "\\", "/")
    path = string.gsub(path, "^/+", "") -- Remove leading slashes

    -- Determine the realm if not provided
    if ( !isstring(realm) or realm == "" ) then
        realm = ax.util:DetectFileRealm(path)
    end

    -- Include the file based on the realm
    if ( realm == "client" ) then
        if ( SERVER ) then
            AddCSLuaFile(path)
        else
            include(path)
        end
    elseif ( realm == "server" ) then
        if ( CLIENT ) then
            ax.util:PrintError("Include: Attempted to include server file '" .. path .. "' on client")
            return false
        end

        include(path)
    else
        if ( SERVER ) then
            AddCSLuaFile(path)
        end

        include(path)
    end

    -- Print debug information if developer mode is enabled
    ax.util:PrintDebug("Included file: " .. path .. " with realm: " .. realm)
    return true
end

-- Recursively include all files in a directory
function ax.util:IncludeDirectory(directory)
    if ( !isstring(directory) or directory == "" ) then
        ax.util:PrintError("IncludeDirectory: Invalid directory parameter provided")
        return false
    end

    -- Normalize path separators
    directory = string.gsub(directory, "\\", "/")
    directory = string.gsub(directory, "^/+", "") -- Remove leading slashes

    -- Get the active path
    local path = debug.getinfo(2).source
    path = string.sub(path, 2, string.find(path, "/[^/]*$"))
    path = string.gsub(path, "gamemodes/", "")

    -- Combine the path with the directory
    if ( !string.match(directory, "^/") ) then
        directory = path .. directory
    end

    -- Check if the directory exists
    if ( !file.IsDir("gamemodes/" .. directory, "GAME") ) then
        ax.util:PrintError("IncludeDirectory: Directory '" .. directory .. "' does not exist")
        return false
    end

    -- Get all files in the directory
    local files, directories = file.Find("gamemodes/" .. directory .. "/*.lua", "GAME")

    -- Include all files found in the directory
    for i = 1, #files do
        ax.util:Include(directory .. "/" .. files[i])
    end

    -- Recursively include all subdirectories
    for i = 1, #directories do
        ax.util:IncludeDirectory(directory .. directories[i] .. "/")
    end

    -- Print debug information if developer mode is enabled
    ax.util:PrintDebug("Included directory: " .. directory)
    return true
end

-- Print a regular message with framework styling
function ax.util:Print(...)
    local args = {...}
    args[#args + 1] = "\n"

    local varArgs = unpack(args)

    if ( SERVER ) then
        MsgC("[PARALLAX] ", varArgs)
    else
        chat.AddText(Color(100, 150, 255), "[PARALLAX] ", color_white, varArgs)
    end
end

-- Print an error message
function ax.util:PrintError(...)
    local args = {...}
    args[#args + 1] = "\n"

    local varArgs = unpack(args)

    if ( SERVER ) then
        MsgC("[PARALLAX] [ERROR] ", varArgs)
        ErrorNoHalt("[PARALLAX] [ERROR] " .. varArgs .. "\n")
    else
        chat.AddText(Color(255, 100, 100), "[PARALLAX] [ERROR] ", color_white, varArgs)
    end
end

-- Print a warning message
function ax.util:PrintWarning(...)
    local args = {...}
    args[#args + 1] = "\n"

    local varArgs = unpack(args)

    if ( SERVER ) then
        MsgC("[PARALLAX] [WARNING] " .. varArgs)
    else
        chat.AddText(Color(255, 200, 100), "[PARALLAX] [WARNING] ", color_white, varArgs)
    end
end

-- Print a debug message (only when developer mode is enabled)
local developer = GetConVar("developer")
function ax.util:PrintDebug(...)
    if ( developer:GetInt() < 1 ) then return end
    local args = {...}
    args[#args + 1] = "\n"

    local varArgs = unpack(args)

    if ( SERVER ) then
        MsgC("[PARALLAX] [DEBUG] ", varArgs)
    else
        chat.AddText(Color(150, 150, 150), "[PARALLAX] [DEBUG] ", color_white, varArgs)
    end
end

function ax.util:FindString(str, find)
    if ( str == nil or find == nil ) then
        ax.util:PrintError("Attempted to find a string with no value to find for! (" .. tostring(str) .. ", " .. tostring(find) .. ")")
        return false
    end

    str = string.lower(str)
    find = string.lower(find)

    return string.find(str, find) != nil
end

function ax.util:FindText(txt, find)
    if ( txt == nil or find == nil ) then return false end

    local words = string.Explode(" ", txt)
    for i = 1, #words do
        if ( self:FindString(words[i], find) ) then
            return true
        end
    end

    return false
end

function ax.util:FindPlayer(identifier)
    if ( identifier == nil ) then return NULL end

    if ( IsValid(identifier) and identifier:IsPlayer() ) then
        return identifier
    end

    if ( isnumber(identifier) ) then
        return Player(identifier)
    end

    if ( isstring(identifier) ) then
        if ( ax.util:CoerceType(ax.types.steamid, identifier) ) then
            return player.GetBySteamID(identifier)
        elseif ( ax.util:CoerceType(ax.types.steamid64, identifier) ) then
            return player.GetBySteamID64(identifier)
        end

        for _, v in player.Iterator() do
            if ( self:FindString(v:Name(), identifier) or self:FindString(v:SteamName(), identifier) or self:FindString(v:SteamID(), identifier) or self:FindString(v:SteamID64(), identifier) ) then
                return v
            end
        end
    end

    if ( istable(identifier) ) then
        for i = 1, #identifier do
            local foundPlayer = self:FindPlayer(identifier[i])

            if ( IsValid(foundPlayer) ) then
                return foundPlayer
            end
        end
    end

    return NULL
end