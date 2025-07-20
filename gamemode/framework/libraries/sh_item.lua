ax.item = ax.item or {}
ax.item.stored = ax.item.stored or {}
ax.item.instances = ax.item.instances or {}

function ax.item:Initialize()
    self:Include("parallax/gamemode/items")
    self:Include(engine.ActiveGamemode() .. "/gamemode/items")

    -- Look through modules for items
    local modules = file.Find("parallax/gamemode/modules/*", "LUA")
    for _, module in ipairs(modules) do
        self:Include("parallax/gamemode/modules/" .. module)
    end
end

function ax.item:Include(path)
    local files, _ = file.Find(path .. "/*", "LUA")

    for i = 1, #files do
        local fileName = files[i]
        if ( !string.EndsWith(fileName, ".lua") ) then continue end

        local itemName = string.StripExtension(fileName)
        local prefix = string.sub(itemName, 1, 3)
        if ( prefix == "sh_" or prefix == "cl_" or prefix == "sv_" ) then
            itemName = string.sub(itemName, 4)
        end

        ITEM = setmetatable({ uniqueID = itemName }, ax.meta.item)
            ax.util:Include(path .. "/" .. fileName, "shared")
            ax.util:PrintSuccess("Item \"" .. tostring(ITEM.Name) .. "\" initialized successfully.")
            ax.item.stored[itemName] = ITEM
        ITEM = nil
    end
end