--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.module = ax.module or {}
ax.module.stored = ax.module.stored or {}

function ax.module:Include(path)
    local files, directories = file.Find(path .. "/*", "LUA")

    if ( files[1] != nil ) then
        for i = 1, #files do
            local fileName = files[i]

            local moduleName = string.StripExtension(fileName)
            local prefix = string.sub(moduleName, 1, 3)
            if ( prefix == "sh_" or prefix == "cl_" or prefix == "sv_" ) then
                moduleName = string.sub(moduleName, 4)
            end

            MODULE = { UniqueID = moduleName }
                ax.util:Include(path .. "/" .. fileName)
                ax.util:PrintSuccess("Module \"" .. tostring(MODULE.Name) .. "\" initialized successfully.")
                ax.module.stored[moduleName] = MODULE
            MODULE = nil
        end
    end

    if ( directories[1] != nil ) then
        for i = 1, #directories do
            local dirName = directories[i]
            local bootFile = path .. "/" .. dirName .. "/boot.lua"
            if ( file.Exists(bootFile, "LUA") ) then
                MODULE = { UniqueID = dirName }

                ax.util:Include(bootFile, "shared")

                ax.util:IncludeDirectory(path .. "/" .. dirName .. "/libraries", true)
                ax.util:IncludeDirectory(path .. "/" .. dirName .. "/meta", true)
                ax.util:IncludeDirectory(path .. "/" .. dirName .. "/core", true)
                ax.util:IncludeDirectory(path .. "/" .. dirName .. "/hooks", true)
                ax.util:IncludeDirectory(path .. "/" .. dirName .. "/networking", true)
                ax.util:IncludeDirectory(path .. "/" .. dirName .. "/interface", true)

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
                    ["boot.lua"] = true
                })

                ax.faction:Include(path .. "/" .. dirName .. "/factions")
                ax.class:Include(path .. "/" .. dirName .. "/classes")
                ax.item:Include(path .. "/" .. dirName .. "/items")

                ax.util:PrintSuccess("Module \"" .. tostring(MODULE.Name) .. "\" initialized successfully.")
                ax.module.stored[MODULE.UniqueID] = MODULE

                MODULE = nil
            end
        end
    end

    if ( files[1] == nil and directories[1] == nil ) then
        ax.util:PrintDebug(color_error, "No modules found in path: " .. path)
    end
end

function ax.module:Get(name)
    if ( !name or name == "" ) then return nil end

    local module = self.stored[name]
    if ( !module ) then
        ax.util:PrintError("Module \"" .. tostring(name) .. "\" not found.")
        return nil
    end

    return module
end

function ax.module:IsLoaded(name)
    if ( !name or name == "" ) then return false end

    return self.stored[name] != nil
end