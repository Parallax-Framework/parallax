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
    if ( !path or type(path) != "string" or path == "" ) then
        ax.util:PrintError("Include: Invalid path parameter provided")
        return false
    end

    -- Normalize path separators
    path = string.gsub(path, "\\", "/")
    path = string.gsub(path, "^/+", "") -- Remove leading slashes

    -- Determine the realm if not provided
    if ( !realm or type(realm) != "string" or realm == "" ) then
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
    if ( !directory or type(directory) != "string" or directory == "" ) then
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
    if ( !file.Exists(directory, "GAME") ) then
        ax.util:PrintError("IncludeDirectory: Directory '" .. directory .. "' does not exist")
        return false
    end

    -- Get all files in the directory
    local files, directories = file.Find(directory .. "/*", "GAME")

    -- Include all files found in the directory
    for _, file in ipairs(files) do
        local filePath = directory .. file
        ax.util:Include(filePath)
    end
    -- Recursively include all subdirectories
    for _, subdir in ipairs(directories) do
        local subdirPath = directory .. subdir
        ax.util:IncludeDirectory(subdirPath)
    end
    -- Print debug information if developer mode is enabled
    ax.util:PrintDebug("Included directory: " .. directory)
    return true
end

-- Print a regular message with framework styling
function ax.util:Print(...)
    local args = {...}
    local message = table.concat(args, " ")

    if ( SERVER ) then
        print("[PARALLAX] " .. message)
    else
        chat.AddText(Color(100, 150, 255), "[PARALLAX] ", Color(255, 255, 255), message)
    end
end

-- Print an error message
function ax.util:PrintError(...)
    local args = {...}
    local message = table.concat(args, " ")

    if ( SERVER ) then
        print("[PARALLAX] [ERROR] " .. message)
        ErrorNoHalt("[PARALLAX] [ERROR] " .. message .. "\n")
    else
        chat.AddText(Color(255, 100, 100), "[PARALLAX] [ERROR] ", Color(255, 255, 255), message)
    end
end

-- Print a warning message
function ax.util:PrintWarning(...)
    local args = {...}
    local message = table.concat(args, " ")

    if ( SERVER ) then
        print("[PARALLAX] [WARNING] " .. message)
    else
        chat.AddText(Color(255, 200, 100), "[PARALLAX] [WARNING] ", Color(255, 255, 255), message)
    end
end

-- Print a debug message (only when developer mode is enabled)
local developer = GetConVar("developer")
function ax.util:PrintDebug(...)
    if ( developer:GetInt() > 0 ) then
        local args = {...}
        local message = table.concat(args, " ")

        if ( SERVER ) then
            print("[PARALLAX] [DEBUG] " .. message)
        else
            chat.AddText(Color(150, 150, 150), "[PARALLAX] [DEBUG] ", Color(200, 200, 200), message)
        end
    end
end