function ax.util:DetectFileRealm(file)
    if ( !file or type(file) != "string" ) then
        return "shared"
    end

    local fileName = string.lower(file)

    -- Client-side patterns
    if ( string.match(fileName, "^cl_") or
        string.match(fileName, "/cl_") or
        string.match(fileName, "client") or
        string.match(fileName, "/ui/") or
        string.match(fileName, "/vgui/") or
        string.match(fileName, "/gui/") ) then
        return "client"
    end

    -- Server-side patterns
    if ( string.match(fileName, "^sv_") or
        string.match(fileName, "/sv_") or
        string.match(fileName, "server") or
        string.match(fileName, "/database") or
        string.match(fileName, "/sql/") ) then
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
    local args = unpack({...})

    if ( SERVER ) then
        MsgC("[PARALLAX] ", args)
    else
        chat.AddText(Color(100, 150, 255), "[PARALLAX] ", Color(255, 255, 255), args)
    end
end

-- Print an error message
function ax.util:PrintError(...)
    local args = unpack({...})

    if ( SERVER ) then
        MsgC("[PARALLAX] [ERROR] ", args)
        ErrorNoHalt("[PARALLAX] [ERROR] " .. args .. "\n")
    else
        chat.AddText(Color(255, 100, 100), "[PARALLAX] [ERROR] ", Color(255, 255, 255), args)
    end
end

-- Print a warning message
function ax.util:PrintWarning(...)
    local args = unpack({...})

    if ( SERVER ) then
        MsgC("[PARALLAX] [WARNING] " .. args)
    else
        chat.AddText(Color(255, 200, 100), "[PARALLAX] [WARNING] ", Color(255, 255, 255), args)
    end
end

-- Print a debug message (only when developer mode is enabled)
local developer = GetConVar("developer")
function ax.util:PrintDebug(...)
    if ( developer:GetInt() < 1 ) then return end

    local args = unpack({...})

    if ( SERVER ) then
        MsgC("[PARALLAX] [DEBUG] ", args)
    else
        chat.AddText(Color(150, 150, 150), "[PARALLAX] [DEBUG] ", Color(200, 200, 200), args)
    end
end