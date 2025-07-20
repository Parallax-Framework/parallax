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

function ax.module:Initialize()
    self:Include("parallax/gamemode/modules")
    self:Include(engine.ActiveGamemode() .. "/gamemode/modules")
end

function ax.module:Include(path)
    local files, directories = file.Find(path .. "/*", "LUA")

    if ( files[1] != nil ) then
        for i = 1, #files do
            local fileName = files[i]
            if ( !string.EndsWith(fileName, ".lua") ) then continue end

            local moduleName = string.StripExtension(fileName)
            local prefix = string.sub(moduleName, 1, 3)
            if ( prefix == "sh_" or prefix == "cl_" or prefix == "sv_" ) then
                moduleName = string.sub(moduleName, 4)
            end

            MODULE = { uniqueID = moduleName }
                ax.util:Include(path .. "/" .. fileName, "shared")
                ax.util:PrintSuccess("Module \"" .. MODULE.uniqueID .. "\" initialized successfully.")
            MODULE = nil
        end
    end

    if ( directories[1] != nil ) then
        for i = 1, #directories do
            local dirName = directories[i]
            local bootFile = path .. "/" .. dirName .. "/boot.lua"
            if ( file.Exists(bootFile, "LUA") ) then
                MODULE = { uniqueID = dirName }

                ax.util:Include(bootFile, "shared")
                ax.util:IncludeDirectory(path .. "/" .. dirName, true)
                ax.util:PrintSuccess("Module \"" .. MODULE.uniqueID .. "\" initialized successfully.")

                MODULE = nil
            end
        end
    end

    if ( #files == 0 and #directories == 0 ) then
        ax.util:PrintWarning("No modules found in path: " .. path)
    end
end