ax.module = ax.module or {}
ax.module.stored = ax.module.stored or {}

-- bloodycop6385 :: Wanted to use the below code, but I started to re-consider due to schema support.
--[[
function ax.module:Initialise()
    local files, directories = file.Find("gamemodes/" .. engine.ActiveGamemode() .. "/gamemode/modules/*.lua", "LUA")
    if ( files[1] != nil ) then
        for i = 1, #files do
            local fileName = files[i]
            local moduleName = string.StripExtension(fileName)

            local prefix = string.sub(moduleName, 1, 3)
            if ( prefix == "sh_" or prefix == "cl_" or prefix == "sv_" ) then
                moduleName = string.sub(moduleName, 4)
            end

            MODULE = { uniqueID = moduleName }
                ax.util:Include("gamemodes/" .. engine.ActiveGamemode() .. "/gamemode/modules/" .. fileName, "shared")
            MODULE = nil
        end
    end

    if ( directories[1] != nil ) then
        for i = 1, #directories do
            local directoryName = directories[i]
            local moduleName = string.StripExtension(directoryName)

            local prefix = string.sub(moduleName, 1, 3)
            if ( prefix == "sh_" or prefix == "cl_" or prefix == "sv_" ) then
                moduleName = string.sub(moduleName, 4)
            end

            MODULE = { uniqueID = moduleName }
                ax.util:IncludeDirectory("gamemodes/" .. engine.ActiveGamemode() .. "/gamemode/modules/" .. directoryName)
            MODULE = nil
        end
    end
end
]]