--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Hybrid SQL Wrapper for Parallax (MySQL/SQLite)
-- Uses MySQLOO if configured, otherwise falls back to SQLite.
-- Provides enhanced error handling, connection management, and feature parity between backends.
-- @module ax.database

ax.database = ax.database or {}
ax.database.backend = ax.database.backend or ax.sqlite -- Default to SQLite if MySQL is not available
ax.database.config = nil

--- Initializes the hybrid database system.
-- @tparam table[opt] config MySQL connection config
-- @usage ax.database:Initialize({ host = "localhost", username = "root", password = "", database = "gmod", port = 3306 })
function ax.database:Initialize(config)
    self.config = config

    if ( ax.util:HasMysqlooBinary() and ax.sqloo ) then
        if ( config ) then
            ax.util:Print("Initializing MySQL connection...")
            ax.sqloo:Initialize(config, function()
                ax.util:PrintSuccess("MySQL connection established.")
                self.backend = ax.sqloo
                self:LoadTables()
                hook.Run("DatabaseConnected")
            end, function(err)
                ax.util:PrintError("MySQL connection failed: " .. (err or "Unknown error"))
                self:Fallback(err)
                hook.Run("DatabaseConnectionFailed", err)
            end)
        else
            self:Fallback("MySQL config not provided")
        end
    else
        self:Fallback("MySQLOO not available")
    end
end

--- Fallback to SQLite if MySQL is unavailable.
-- @tparam string reason Reason for fallback
-- @usage ax.database:Fallback("MySQL connection failed")
function ax.database:Fallback(reason)
    self.backend = ax.sqlite
    ax.util:PrintWarning((reason or "MySQL unavailable") .. ". Falling back to SQLite.")

    -- Initialize SQLite
    ax.sqlite:Initialize()
    self:LoadTables()

    hook.Run("DatabaseFallback", reason)
end

--- Returns current backend object.
-- @treturn table Either ax.sqloo or ax.sqlite
function ax.database:GetBackend()
    return self.backend
end

--- Gets the database configuration.
-- @treturn table Database configuration or nil
function ax.database:GetConfig()
    return self.config
end

--- Checks if the database is connected.
-- @treturn boolean True if connected
function ax.database:IsConnected()
    return self.backend and self.backend:IsConnected()
end

--- Gets the current database status.
-- @treturn string Database status
function ax.database:GetStatus()
    return self.backend and self.backend:GetStatus() or "not_initialized"
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

-- Enhanced proxy calls with additional methods
local proxies = {
    "RegisterVar",
    "InitializeTable",
    "Insert",
    "Select",
    "Update",
    "Delete",
    "LoadRow",
    "SaveRow",
    "GetDefaultRow",
    "Query",
    "Count",
    "TableExists",
    "ColumnExists",
    "GetTableInfo",
    "BeginTransaction",
    "CommitTransaction",
    "RollbackTransaction",
    "ExecuteTransaction",
    "Escape"
}

for i = 1, #proxies do
    local fn = proxies[i]
    ax.database[fn] = function(self, ...)
        return dispatch(fn, ...)
    end
end

--- Loads database tables and sets up schema.
-- @usage ax.database:LoadTables()
function ax.database:LoadTables()
    hook.Run("PreDatabaseTablesLoaded")

    -- Initialize core tables
    self:InitializeTable("ax_players", {
        steamid = "VARCHAR(32) PRIMARY KEY",
        name = "TEXT",
        ip = "TEXT",
        play_time = "INT",
        last_played = "INT",
        data = "TEXT"
    })

    -- Register default player variables
    self:RegisterVar("ax_players", "name", "")
    self:RegisterVar("ax_players", "ip", "")
    self:RegisterVar("ax_players", "play_time", 0)
    self:RegisterVar("ax_players", "last_played", 0)
    self:RegisterVar("ax_players", "data", "{}")

    self:InitializeTable("ax_characters", {
        id = "INTEGER PRIMARY KEY " .. (self.backend == ax.sqloo and "AUTO_INCREMENT" or "AUTOINCREMENT"),
        steamid = "VARCHAR(32)",
        inventories = "TEXT",
        data = "TEXT"
    })

    self:InitializeTable("ax_inventories", {
        id = "INTEGER PRIMARY KEY " .. (self.backend == ax.sqloo and "AUTO_INCREMENT" or "AUTOINCREMENT"),
        character_id = "INT",
        name = "TEXT",
        max_weight = "INT",
        data = "TEXT"
    })

    self:InitializeTable("ax_items", {
        id = "INTEGER PRIMARY KEY " .. (self.backend == ax.sqloo and "AUTO_INCREMENT" or "AUTOINCREMENT"),
        inventory_id = "INT",
        character_id = "INT",
        unique_id = "TEXT",
        data = "TEXT"
    })

    hook.Run("PostDatabaseTablesLoaded")
end

--- Prints which database backend is currently in use.
-- @usage ax.database:PrintBackend()
function ax.database:PrintBackend()
    if ( self.backend == ax.sqloo ) then
        ax.util:Print("Using MySQL backend.")
        if ( self.config ) then
            ax.util:Print("Host: " .. self.config.host .. ":" .. (self.config.port or 3306))
            ax.util:Print("Database: " .. self.config.database)
        end
    elseif ( self.backend == ax.sqlite ) then
        ax.util:Print("Using SQLite backend.")
    else
        ax.util:PrintError("Unknown database backend in use!")
    end
end

--- Prints the current database status.
-- @usage ax.database:PrintStatus()
function ax.database:PrintStatus()
    if ( self.backend and self.backend.PrintStatus ) then
        self.backend:PrintStatus()
    else
        ax.util:PrintError("No database backend available")
    end
end

--- Safely shuts down the database connection.
-- @usage ax.database:Shutdown()
function ax.database:Shutdown()
    if ( self.backend and self.backend.Cleanup ) then
        self.backend:Cleanup()
    end

    self.backend = nil
    self.config = nil

    ax.util:Print("Database system shut down.")
end

--- Executes a query with automatic retry on connection failure.
-- @tparam string query SQL query string
-- @tparam function[opt] onSuccess Success callback
-- @tparam function[opt] onError Error callback
-- @usage ax.database:SafeQuery("SELECT * FROM players", function(result) print(result) end)
function ax.database:SafeQuery(query, onSuccess, onError)
    if ( !self.backend ) then
        ax.util:PrintError("No database backend available")
        if ( onError ) then onError("No backend available") end
        return
    end

    self.backend:Query(query, onSuccess, function(err)
        ax.util:PrintError("Database query failed: " .. (err or "Unknown error"))

        -- Try to reconnect if using MySQL
        if ( self.backend == ax.sqloo and !self.backend:IsConnected() ) then
            ax.util:PrintWarning("Attempting to reconnect to MySQL...")
            self.backend:Reconnect()
        end

        if ( onError ) then onError(err) end
    end)
end