--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Module management system for loading and retrieving modules.
-- Supports automatic inclusion of module files and directories.
-- @module ax.module

ax.module = ax.module or {}
ax.module.stored = ax.module.stored or {}

--- Include and load modules from a directory path.
-- Automatically loads both single-file modules and directory-based modules with boot.lua.
-- For directory modules, includes all standard framework directories in proper order.
-- @realm shared
-- @param path string The directory path to search for modules
-- @usage ax.module:Include("parallax/gamemode/modules")
function ax.module:Include(path, timeFilter)
    local files, directories = file.Find(path .. "/*", "LUA")

    if ( files[1] != nil ) then
        for i = 1, #files do
            local fileName = files[i]
            local filePath = path .. "/" .. fileName

            -- Check file modification time if timeFilter is provided
            if ( isnumber(timeFilter) and timeFilter > 0 ) then
                local fileTime = file.Time(filePath, "LUA")
                local currentTime = os.time()

                if ( fileTime and (currentTime - fileTime) > timeFilter ) then
                    ax.util:PrintDebug("Skipping unchanged module file (modified " .. (currentTime - fileTime) .. "s ago): " .. fileName)
                    continue
                end
            end

            local moduleName = string.StripExtension(fileName)
            local prefix = string.sub(moduleName, 1, 3)
            if ( prefix == "sh_" or prefix == "cl_" or prefix == "sv_" ) then
                moduleName = string.sub(moduleName, 4)
            end

            local scope = "schema"
            if ( string.StartWith(path, "parallax/") ) then
                scope = "framework"
            end

            MODULE = { uniqueID = moduleName, scope = scope }
                ax.util:Include(filePath)
                ax.util:PrintSuccess("Module \"" .. tostring(MODULE.name) .. "\" initialized successfully.")
                ax.module.stored[moduleName] = MODULE
            MODULE = nil
        end
    end

    if ( directories[1] != nil ) then
        for i = 1, #directories do
            local dirName = directories[i]
            local bootFile = path .. "/" .. dirName .. "/boot.lua"
            if ( file.Exists(bootFile, "LUA") ) then
                -- Check boot file modification time if timeFilter is provided
                local shouldSkip = false
                if ( isnumber(timeFilter) and timeFilter > 0 ) then
                    local fileTime = file.Time(bootFile, "LUA")
                    local currentTime = os.time()

                    if ( fileTime and (currentTime - fileTime) > timeFilter ) then
                        ax.util:PrintDebug("Skipping unchanged module boot file (modified " .. (currentTime - fileTime) .. "s ago): " .. bootFile)
                        shouldSkip = true
                    end
                end

                local scope = "schema"
                if ( string.StartWith(path, "parallax/") ) then
                    scope = "framework"
                end

                if ( !shouldSkip ) then
                    MODULE = { uniqueID = dirName, scope = scope }

                    ax.util:Include(bootFile, "shared")

                    ax.util:IncludeDirectory(path .. "/" .. dirName .. "/libraries", true, nil, timeFilter)
                    ax.util:IncludeDirectory(path .. "/" .. dirName .. "/meta", true, nil, timeFilter)
                    ax.util:IncludeDirectory(path .. "/" .. dirName .. "/core", true, nil, timeFilter)
                    ax.util:IncludeDirectory(path .. "/" .. dirName .. "/hooks", true, nil, timeFilter)
                    ax.util:IncludeDirectory(path .. "/" .. dirName .. "/networking", true, nil, timeFilter)
                    ax.util:IncludeDirectory(path .. "/" .. dirName .. "/interface", true, nil, timeFilter)

                    ax.util:IncludeDirectory(path .. "/" .. dirName, true, {
                        ["libraries"] = true,
                        ["meta"] = true,
                        ["core"] = true,
                        ["hooks"] = true,
                        ["networking"] = true,
                        ["interface"] = true,
                        ["factions"] = true,
                        ["classes"] = true,
                        ["items"] = true,
                        ["entities"] = true,
                        ["boot.lua"] = true
                    }, timeFilter)

                    ax.faction:Include(path .. "/" .. dirName .. "/factions", timeFilter)
                    ax.class:Include(path .. "/" .. dirName .. "/classes", timeFilter)
                    ax.item:Include(path .. "/" .. dirName .. "/items", timeFilter)
                    ax.util:LoadEntities(path .. "/" .. dirName .. "/entities", timeFilter)

                    ax.util:PrintSuccess("Module \"" .. tostring(MODULE.name) .. "\" initialized successfully.")
                    ax.module.stored[MODULE.uniqueID] = MODULE

                    MODULE = nil
                end
            end
        end
    end

    if ( files[1] == nil and directories[1] == nil ) then
        ax.util:PrintDebug(color_error, "No modules found in path: " .. path)
    end
end

--- Get a loaded module by its unique identifier.
-- Retrieves a module that has been previously loaded.
-- @realm shared
-- @param name string The module's unique identifier
-- @return table|nil The module table if found, nil otherwise
-- @usage local myModule = ax.module:Get("example_module")
function ax.module:Get(name)
    if ( !name or name == "" ) then return nil end

    local module = self.stored[name]
    if ( !module ) then
        ax.util:PrintError("Module \"" .. tostring(name) .. "\" not found.")
        return nil
    end

    return module
end

--- Check if a module is loaded.
-- Tests whether a module with the given name has been successfully loaded.
-- @realm shared
-- @param name string The module's unique identifier
-- @return boolean True if the module is loaded, false otherwise
-- @usage if ax.module:IsLoaded("example_module") then print("Module available") end
function ax.module:IsLoaded(name)
    if ( !name or name == "" ) then return false end

    return self.stored[name] != nil
end
