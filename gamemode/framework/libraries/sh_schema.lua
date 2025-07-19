ax.schema = ax.schema or {}

function ax.schema:Initialize()
    SCHEMA = SCHEMA or {}

    local active = engine.ActiveGamemode()
    local boot = ax.util:Include(active .. "/gamemode/schema/boot.lua", "shared")
    if ( !boot ) then
        ax.util:PrintError("Failed to load schema boot file for gamemode '" .. active .. "'")
        return false
    end

    -- Initialize the schema
    ax.util:Print("Initializing schema for gamemode '" .. active .. "'")
end