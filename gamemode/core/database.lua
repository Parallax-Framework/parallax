--- Hybrid SQL Wrapper for Parallax (MySQL/SQLite)
-- Uses MySQLOO if configured, otherwise falls back to SQLite.
-- @module ax.database

ax.database = ax.database or {}
ax.database.backend = ax.sqlite -- Default to SQLite if MySQL is not available

--- Initializes the hybrid database system.
-- @tparam table[opt] config MySQL connection config
-- @usage ax.database:Initialize({ host = "localhost", username = "root", password = "", database = "gmod", port = 3306 })
function ax.database:Initialize(config)
    if ( ax.sqloo ) then
        if ( config ) then
            self.backend = ax.sqloo
            ax.sqloo:Initialize(config)

            timer.Simple(1, function()
                if ( ax.sqloo:Status() == mysqloo.DATABASE_CONNECTED ) then
                    ax.util:PrintSuccess("MySQL connection established")
                    self:LoadTables()
                else
                    self:Fallback("MySQL connection failed")
                end
            end)
        else
            self:Fallback("MySQL config not provided")
        end
    else
        self:Fallback("MySQLOO not found")
    end
end

--- Fallback to SQLite if MySQL is unavailable.
-- @tparam string reason Reason for fallback
-- @usage ax.database:Fallback("MySQL connection failed")
function ax.database:Fallback(reason)
    self.backend = ax.sqlite
    ax.util:PrintWarning((reason or "MySQL unavailable") .. ". Falling back to SQLite.")

    hook.Run("DatabaseFallback", reason)
end

--- Returns current backend object.
-- @treturn table Either ax.sqloo or ax.sqlite
function ax.database:GetBackend()
    return self.backend
end

--- Wraps backend call if available.
-- @tparam string fn Function name
-- @tparam ... Arguments
-- @return Returns backend function result
local function dispatch(fn, ...)
    if ( ax.database.backend and ax.database.backend[fn] ) then
        return ax.database.backend[fn](ax.database.backend, ...)
    else
        if ( ax.database.backend == nil ) then
            ax.util:PrintError("Database backend not initialized, cannot call: " .. fn .. " from " .. debug.getinfo(2, "S").source)
        else
            ax.util:PrintError("Database backend missing method: " .. fn)
        end

        return false
    end
end

-- Proxy calls
for _, fn in ipairs({
    "RegisterVar",
    "InitializeTable",
    "Insert",
    "Select",
    "Update",
    "Delete",
    "LoadRow",
    "SaveRow",
    "GetDefaultRow"
}) do
    ax.database[fn] = function(self, ...)
        return dispatch(fn, ...)
    end
end

function ax.database:LoadTables()
    ax.util:Print("Loading database tables...")

    hook.Run("PreDatabaseTablesLoaded")

    self:RegisterVar("ax_players", "name", "")
    self:RegisterVar("ax_players", "ip", "")
    self:RegisterVar("ax_players", "play_time", 0)
    self:RegisterVar("ax_players", "last_played", 0)
    self:RegisterVar("ax_players", "data", "{}")

    self:InitializeTable("ax_players", {
        steamid = "VARCHAR(32) PRIMARY KEY",
        name = "TEXT",
        ip = "TEXT",
        play_time = "INT",
        last_played = "INT",
        data = "TEXT"
    })

    self:InitializeTable("ax_characters", {
        id = "INTEGER PRIMARY KEY AUTOINCREMENT",
        steamid = "VARCHAR(32)",
        inventories = "TEXT",
        data = "TEXT"
    })

    self:InitializeTable("ax_inventories", {
        id = "INTEGER PRIMARY KEY AUTOINCREMENT",
        character_id = "INT",
        name = "TEXT",
        max_weight = "INT",
        data = "TEXT"
    })

    self:InitializeTable("ax_items", {
        id = "INTEGER PRIMARY KEY AUTOINCREMENT",
        inventory_id = "INT",
        character_id = "INT",
        unique_id = "TEXT",
        data = "TEXT"
    })

    hook.Run("PostDatabaseTablesLoaded")

    ax.util:PrintSuccess("Database tables loaded.")
end

local folder = engine.ActiveGamemode()
local database = folder .. "/schema/database.lua"
if ( file.Exists(database, "LUA") ) then
    ax.util:Print("Loading database config...")
    ax.util:LoadFile(folder .. "/schema/database.lua", "server")
    ax.util:Print("Loaded database config.")
else
    ax.util:PrintWarning("Failed to find database config, using SQLite.")
end