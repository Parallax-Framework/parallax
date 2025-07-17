--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

if ( !ax.util:HasMysqlooBinary() ) then
    ax.util:PrintWarning("MySQLOO binary not found in lua/bin/. ax.sqloo disabled.")
    return
end

-- Now safe to require
require("mysqloo")

--- Parallax MySQLOO Database Wrapper
-- Provides a comprehensive wrapper around the mysqloo module for async MySQL access
-- @module ax.sqloo

ax.sqloo = ax.sqloo or {}
ax.sqloo.config = nil
ax.sqloo.db = nil
ax.sqloo.tables = ax.sqloo.tables or {}
ax.sqloo.queryQueue = ax.sqloo.queryQueue or {}
ax.sqloo.isConnected = false
ax.sqloo.reconnectAttempts = 0
ax.sqloo.maxReconnectAttempts = 3
ax.sqloo.queryTimerStarted = false
ax.sqloo.connectionCallbacks = {}
ax.sqloo.lastPingTime = 0
ax.sqloo.pingInterval = 30 -- seconds

--- Initializes the MySQL database connection.
-- @realm server
-- @tparam table config Database configuration
-- @tparam function[opt] callback Success callback
-- @tparam function[opt] fallback Failure callback
-- @usage ax.sqloo:Initialize({host = "localhost", username = "root", password = "", database = "gmod"})
function ax.sqloo:Initialize(config, callback, fallback)
    if ( !config ) then
        ax.util:PrintError("MySQL initialization requires configuration")
        if ( fallback ) then fallback("No configuration provided") end
        return
    end

    -- Validate required config fields
    local required = {"host", "username", "password", "database"}
    for _, field in ipairs(required) do
        if ( !config[field] ) then
            ax.util:PrintError("MySQL config missing required field: " .. field)
            if ( fallback ) then fallback("Missing required field: " .. field) end
            return
        end
    end

    self.config = config
    self.connectionCallbacks = {
        success = callback,
        failure = fallback
    }

    ax.util:Print("Initializing MySQL connection to " .. config.host .. ":" .. (config.port or 3306) .. "...")

    -- Set up connection keepalive
    self:StartKeepalive()

    self:Connect()
end

--- Establishes the MySQL connection.
-- @realm server
function ax.sqloo:Connect()
    if ( self.db ) then
        self.db:disconnect()
    end

    local config = self.config
    self.db = mysqloo.connect(
        config.host,
        config.username,
        config.password,
        config.database,
        config.port or 3306
    )

    if ( !self.db ) then
        ax.util:PrintError("Failed to create MySQL connection object")
        self:HandleConnectionFailure("Failed to create connection object")
        return
    end

    self.db.onConnected = function()
        self.isConnected = true
        self.reconnectAttempts = 0
        self.lastPingTime = SysTime()

        ax.util:PrintSuccess("MySQL connection established successfully")

        -- Process queued queries
        self:ProcessQueuedQueries()

        -- Call success callback
        if ( self.connectionCallbacks.success ) then
            self.connectionCallbacks.success()
        end

        hook.Run("DatabaseConnected")
    end

    self.db.onConnectionFailed = function(_, errString)
        self:HandleConnectionFailure(errString)
    end

    self.db.onDisconnected = function()
        self.isConnected = false
        ax.util:PrintWarning("MySQL connection lost")

        -- Attempt to reconnect
        self:AttemptReconnect()
    end

    self.db:connect()
end

--- Handles connection failures with retry logic.
-- @realm server
-- @tparam string errString Error message
function ax.sqloo:HandleConnectionFailure(errString)
    self.isConnected = false
    self.reconnectAttempts = self.reconnectAttempts + 1

    ax.util:PrintError("MySQL connection failed: " .. (errString or "Unknown error"))

    if ( self.reconnectAttempts < self.maxReconnectAttempts ) then
        ax.util:PrintWarning("Retrying connection in 5 seconds... (Attempt " .. self.reconnectAttempts .. "/" .. self.maxReconnectAttempts .. ")")
        timer.Simple(5, function()
            self:Connect()
        end)
    else
        ax.util:PrintError("Max reconnection attempts reached. Giving up.")

        if ( self.connectionCallbacks.failure ) then
            self.connectionCallbacks.failure(errString)
        end

        hook.Run("DatabaseConnectionFailed", errString)
    end
end

--- Attempts to reconnect to the database.
-- @realm server
function ax.sqloo:AttemptReconnect()
    if ( self.reconnectAttempts >= self.maxReconnectAttempts ) then
        ax.util:PrintError("Max reconnection attempts reached")
        return
    end

    self.reconnectAttempts = self.reconnectAttempts + 1
    ax.util:PrintWarning("Attempting to reconnect to MySQL... (Attempt " .. self.reconnectAttempts .. "/" .. self.maxReconnectAttempts .. ")")

    timer.Simple(5, function()
        self:Connect()
    end)
end

--- Starts the database keepalive system.
-- @realm server
function ax.sqloo:StartKeepalive()
    timer.Create("ax.sqloo.keepalive", self.pingInterval, 0, function()
        if ( self.isConnected and self.db ) then
            local timeSinceLastPing = SysTime() - self.lastPingTime
            if ( timeSinceLastPing >= self.pingInterval ) then
                self:Ping()
            end
        end
    end)
end

--- Sends a ping to keep the connection alive.
-- @realm server
function ax.sqloo:Ping()
    if ( !self.isConnected or !self.db ) then return end

    self:Query("SELECT 1", function()
        self.lastPingTime = SysTime()
    end, function(error)
        ax.util:PrintWarning("Database ping failed: " .. (error or "Unknown error"))
        self.isConnected = false
    end)
end

--- Processes queued queries when connection is restored.
-- @realm server
function ax.sqloo:ProcessQueuedQueries()
    if ( #self.queryQueue == 0 ) then return end

    ax.util:Print("Processing " .. #self.queryQueue .. " queued queries...")

    timer.Create("ax.sqloo.processqueue", 0.1, 0, function()
        if ( !self.isConnected or #self.queryQueue == 0 ) then
            timer.Remove("ax.sqloo.processqueue")
            return
        end

        local queuedQuery = table.remove(self.queryQueue, 1)
        if ( queuedQuery ) then
            self:Query(queuedQuery.query, queuedQuery.onSuccess, queuedQuery.onError)
        end
    end)
end

--- Registers a variable/column for the specified table and sets its default value.
-- @realm server
-- @tparam string tableName Name of the table
-- @tparam string key Column name
-- @tparam any default Default value for the column
-- @usage ax.sqloo:RegisterVar("players", "name", "")
function ax.sqloo:RegisterVar(tableName, key, default)
    if ( !tableName or !key ) then
        ax.util:PrintError("RegisterVar requires tableName and key parameters")
        return
    end

    self.tables[tableName] = self.tables[tableName] or {}
    self.tables[tableName][key] = default

    local columnType = self:GetColumnType(default)
    self:AddColumn(tableName, key, columnType, default)
end

--- Determines the appropriate MySQL column type based on the default value.
-- @realm server
-- @tparam any default Default value
-- @treturn string MySQL column type
function ax.sqloo:GetColumnType(default)
    if ( isnumber(default) ) then
        return math.floor(default) == default and "INT" or "DECIMAL(10,2)"
    elseif ( isstring(default) ) then
        return "TEXT"
    elseif ( isbool(default) ) then
        return "BOOLEAN"
    else
        return "TEXT"
    end
end

--- Escapes a value for safe use in MySQL queries.
-- @realm server
-- @tparam any value Value to escape
-- @treturn string Escaped value
function ax.sqloo:Escape(value)
    if ( value == nil ) then
        return "NULL"
    end

    -- Handle different data types
    if ( isnumber(value) ) then
        return tostring(value)
    elseif ( isbool(value) ) then
        return value and "1" or "0"
    elseif ( isstring(value) ) then
        if ( self.db and self.isConnected ) then
            return "'" .. self.db:escape(value) .. "'"
        else
            -- Fallback to SQLite escaping with quotes
            return sql.SQLStr(value)
        end
    else
        -- Convert other types to string and escape
        local str = tostring(value)
        if ( self.db and self.isConnected ) then
            return "'" .. self.db:escape(str) .. "'"
        else
            return sql.SQLStr(str)
        end
    end
end

--- Checks if a table exists in the database.
-- @realm server
-- @tparam string tableName Name of the table to check
-- @tparam function callback Callback with boolean result
-- @usage ax.sqloo:TableExists("players", function(exists) print(exists) end)
function ax.sqloo:TableExists(tableName, callback)
    if ( !tableName ) then
        ax.util:PrintError("TableExists requires tableName parameter")
        if ( callback ) then callback(false) end
        return
    end

    local query = "SELECT COUNT(*) as count FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = " .. self:Escape(tableName)
    self:Query(query, function(result)
        local exists = result and result[1] and tonumber(result[1].count) > 0
        if ( callback ) then callback(exists) end
    end, function()
        if ( callback ) then callback(false) end
    end)
end

--- Gets information about table columns.
-- @realm server
-- @tparam string tableName Name of the table
-- @tparam function callback Callback with column information
-- @usage ax.sqloo:GetTableInfo("players", function(info) print(info) end)
function ax.sqloo:GetTableInfo(tableName, callback)
    if ( !tableName ) then
        ax.util:PrintError("GetTableInfo requires tableName parameter")
        if ( callback ) then callback({}) end
        return
    end

    local query = "SHOW COLUMNS FROM `" .. tableName .. "`"
    self:Query(query, function(result)
        if ( callback ) then callback(result or {}) end
    end, function()
        if ( callback ) then callback({}) end
    end)
end

--- Checks if a column exists in a table.
-- @realm server
-- @tparam string tableName Name of the table
-- @tparam string columnName Name of the column
-- @tparam function callback Callback with boolean result
-- @usage ax.sqloo:ColumnExists("players", "score", function(exists) print(exists) end)
function ax.sqloo:ColumnExists(tableName, columnName, callback)
    if ( !tableName or !columnName ) then
        ax.util:PrintError("ColumnExists requires tableName and columnName parameters")
        if ( callback ) then callback(false) end
        return
    end

    -- First check if the table exists
    self:TableExists(tableName, function(tableExists)
        if ( !tableExists ) then
            -- Table doesn't exist, so column doesn't exist
            if ( callback ) then callback(false) end
            return
        end

        -- Table exists, now check for column
        local query = "SHOW COLUMNS FROM `" .. tableName .. "` LIKE '" .. columnName .. "'"
        self:Query(query, function(result)
            local exists = result and #result > 0
            if ( callback ) then callback(exists) end
        end, function(error)
            -- Don't show errors for table doesn't exist since we already checked
            if ( error and string.find(error, "doesn't exist") ) then
                if ( callback ) then callback(false) end
            else
                ax.util:PrintError("Failed to check column existence: " .. (error or "Unknown error"))
                if ( callback ) then callback(false) end
            end
        end)
    end)
end

--- Creates a SQL table with the registered and extra schema fields.
-- @realm server
-- @tparam string tableName Name of the table to create
-- @tparam table[opt] extraSchema Additional schema fields
-- @usage ax.sqloo:InitializeTable("players", {steamid = "VARCHAR(32) PRIMARY KEY"})
function ax.sqloo:InitializeTable(tableName, extraSchema)
    if ( !tableName ) then
        ax.util:PrintError("InitializeTable requires tableName parameter")
        return
    end

    local schema = {}
    extraSchema = extraSchema or {}

    -- Check if any primary key is defined in user schema
    local hasPrimaryKey = false
    for k, v in pairs(extraSchema) do
        if ( isstring(v) and string.find(string.upper(v), "PRIMARY KEY") ) then
            hasPrimaryKey = true
            break
        end
    end

    -- Only default to id primary key if not explicitly defined
    if ( !hasPrimaryKey ) then
        schema.id = "INTEGER PRIMARY KEY AUTO_INCREMENT"
    end

    -- Merge registered vars
    for k, v in pairs(self.tables[tableName] or {}) do
        schema[k] = self:GetColumnType(v)
    end

    -- Merge user-provided schema (takes precedence)
    for k, v in pairs(extraSchema) do
        schema[k] = v
    end

    local parts = {}
    for k, v in pairs(schema) do
        parts[#parts + 1] = string.format("`%s` %s", k, v)
    end

    local query = string.format("CREATE TABLE IF NOT EXISTS `%s` (%s) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;", tableName, table.concat(parts, ", "))

    self:Query(query, function()
        ax.util:PrintSuccess("Table '" .. tableName .. "' initialized successfully.")
    end, function(error)
        -- Don't show errors for table already exists
        if ( error and string.find(error, "already exists") ) then
            ax.util:Print("Table '" .. tableName .. "' already exists.")
        else
            ax.util:PrintError("Failed to initialize table '" .. tableName .. "': " .. (error or "Unknown error"))
        end
    end)
end

--- Adds a column to a table if it doesn't exist already.
-- @realm server
-- @tparam string tableName Name of the table
-- @tparam string columnName Name of the column to add
-- @tparam string columnType MySQL column type
-- @tparam any defaultValue Default value for the column
-- @usage ax.sqloo:AddColumn("players", "score", "INT", 0)
function ax.sqloo:AddColumn(tableName, columnName, columnType, defaultValue)
    if ( !tableName or !columnName or !columnType ) then
        ax.util:PrintError("AddColumn requires tableName, columnName, and columnType parameters")
        return
    end

    self:ColumnExists(tableName, columnName, function(exists)
        if ( exists ) then
            ax.util:PrintWarning("Column '" .. columnName .. "' already exists in table '" .. tableName .. "'.")
            return
        end

        local query = string.format("ALTER TABLE `%s` ADD COLUMN `%s` %s", tableName, columnName, columnType)

        if ( defaultValue != nil ) then
            local escapedDefault = self:Escape(defaultValue)
            if ( escapedDefault != "NULL" and escapedDefault != "" ) then
                query = query .. " DEFAULT " .. escapedDefault
            end
        end

        query = query .. ";"

        -- Validate the query before executing
        if ( !query or query == "" or string.find(query, "``") or string.find(query, "DEFAULT ;") ) then
            ax.util:PrintError("Generated invalid ALTER TABLE query: " .. (query or "nil"))
            return
        end

        self:Query(query, function()
            ax.util:PrintSuccess("Column '" .. columnName .. "' added to table '" .. tableName .. "'.")
        end, function(error)
            -- Don't show errors for column already exists
            if ( error and (string.find(error, "already exists") or string.find(error, "Duplicate column")) ) then
                ax.util:Print("Column '" .. columnName .. "' already exists in table '" .. tableName .. "'.")
            else
                ax.util:PrintError("Failed to add column '" .. columnName .. "' to table '" .. tableName .. "': " .. (error or "Unknown error"))
            end
        end)
    end)
end

--- Returns a default row populated with the registered default values.
-- @realm server
-- @tparam string tableName Name of the table
-- @tparam table[opt] override Values to override defaults
-- @treturn table Default row data
-- @usage local defaultRow = ax.sqloo:GetDefaultRow("players", {name = "NewPlayer"})
function ax.sqloo:GetDefaultRow(tableName, override)
    if ( !tableName ) then
        ax.util:PrintError("GetDefaultRow requires tableName parameter")
        return {}
    end

    local data = table.Copy(self.tables[tableName] or {})

    for k, v in pairs(override or {}) do
        data[k] = v
    end

    return data
end

--- Loads a row based on a key/value match or inserts a default if not found.
-- @realm server
-- @tparam string tableName Name of the table
-- @tparam string key Column name to match
-- @tparam any value Value to match
-- @tparam function[opt] callback Callback function with row data
-- @usage ax.sqloo:LoadRow("players", "steamid", "STEAM_0:0:123456", function(row) print(row.name) end)
function ax.sqloo:LoadRow(tableName, key, value, callback)
    if ( !tableName or !key or value == nil ) then
        ax.util:PrintError("LoadRow requires tableName, key, and value parameters")
        return
    end

    local condition = string.format("`%s` = %s", key, self:Escape(value))

    self:Select(tableName, nil, condition, function(result)
        if ( !result or !result[1] ) then
            -- Create default row
            local row = self:GetDefaultRow(tableName)
            row[key] = value

            -- Insert the default row
            self:Insert(tableName, row, function()
                if ( callback ) then
                    ax.util:PrintWarning("Database row not found for " .. tableName .. ", inserting default row")
                    callback(row)
                end
            end)
        else
            local row = result[1]
            local vars = self.tables[tableName]

            if ( vars ) then
                -- Fill in any missing values with defaults
                for k, v in pairs(vars) do
                    if ( row[k] == nil ) then
                        row[k] = v
                    end
                end
            end

            if ( callback ) then
                callback(row)
            end
        end
    end)
end

--- Saves a row of data into the table using the given key.
-- @realm server
-- @tparam string tableName Name of the table
-- @tparam table data Data to save
-- @tparam string key Column name to use for matching
-- @tparam function[opt] callback Callback function
-- @usage ax.sqloo:SaveRow("players", {name = "John", score = 100}, "steamid")
function ax.sqloo:SaveRow(tableName, data, key, callback)
    if ( !tableName or !data or !key ) then
        ax.util:PrintError("SaveRow requires tableName, data, and key parameters")
        return
    end

    if ( !data[key] ) then
        ax.util:PrintError("SaveRow: data must contain the key field '" .. key .. "'")
        return
    end

    local condition = string.format("`%s` = %s", key, self:Escape(data[key]))
    self:Update(tableName, data, condition, callback)
end

--- Inserts a new row of data into the table.
-- @realm server
-- @tparam string tableName Name of the table
-- @tparam table data Data to insert
-- @tparam function[opt] callback Callback function with inserted row ID
-- @usage ax.sqloo:Insert("players", {name = "John", steamid = "STEAM_0:0:123456"})
function ax.sqloo:Insert(tableName, data, callback)
    if ( !tableName or !data ) then
        ax.util:PrintError("Insert requires tableName and data parameters")
        return
    end

    if ( !istable(data) or table.IsEmpty(data) ) then
        ax.util:PrintError("Insert data must be a non-empty table")
        return
    end

    local keys, values = {}, {}

    for k, v in pairs(data) do
        keys[#keys + 1] = "`" .. k .. "`"

        -- Convert tables to JSON
        if ( istable(v) ) then
            v = util.TableToJSON(v)
        end

        -- Handle nil values
        if ( v == nil ) then
            values[#values + 1] = "NULL"
        else
            values[#values + 1] = self:Escape(v)
        end
    end

    local query = string.format("INSERT INTO `%s` (%s) VALUES (%s);", tableName, table.concat(keys, ", "), table.concat(values, ", "))

    self:Query(query, function()
        -- Fetch last inserted ID
        self:Query("SELECT LAST_INSERT_ID() AS id;", function(result)
            if ( callback ) then
                callback(result and result[1] and tonumber(result[1].id))
            end
        end)
    end, function(error)
        ax.util:PrintError("Failed to insert into table '" .. tableName .. "': " .. (error or "Unknown error"))
        if ( callback ) then callback(nil) end
    end)
end

--- Updates existing data in the table matching a given condition.
-- @realm server
-- @tparam string tableName Name of the table
-- @tparam table data Data to update
-- @tparam string condition WHERE clause condition
-- @tparam function[opt] callback Callback function
-- @usage ax.sqloo:Update("players", {score = 100}, "steamid = 'STEAM_0:0:123456'")
function ax.sqloo:Update(tableName, data, condition, callback)
    if ( !tableName or !data or !condition ) then
        ax.util:PrintError("Update requires tableName, data, and condition parameters")
        return
    end

    if ( !istable(data) or table.IsEmpty(data) ) then
        ax.util:PrintError("Update data must be a non-empty table")
        return
    end

    local updates = {}

    for k, v in pairs(data) do
        -- Convert tables to JSON
        if ( istable(v) ) then
            v = util.TableToJSON(v)
        end

        -- Handle nil values
        if ( v == nil ) then
            updates[#updates + 1] = string.format("`%s` = NULL", k)
        else
            updates[#updates + 1] = string.format("`%s` = %s", k, self:Escape(v))
        end
    end

    local query = string.format("UPDATE `%s` SET %s WHERE %s;", tableName, table.concat(updates, ", "), condition)

    self:Query(query, function()
        if ( callback ) then callback() end
    end, function(error)
        -- Don't show errors for table doesn't exist
        if ( error and string.find(error, "doesn't exist") ) then
            ax.util:PrintWarning("Table '" .. tableName .. "' doesn't exist. Consider initializing it first.")
        else
            ax.util:PrintError("Failed to update table '" .. tableName .. "': " .. (error or "Unknown error"))
        end
        if ( callback ) then callback() end
    end)
end

--- Deletes rows from the table based on a condition.
-- @realm server
-- @tparam string tableName Name of the table
-- @tparam string condition WHERE clause condition
-- @tparam function[opt] callback Callback function
-- @usage ax.sqloo:Delete("players", "last_played < " .. (os.time() - 86400))
function ax.sqloo:Delete(tableName, condition, callback)
    if ( !tableName or !condition ) then
        ax.util:PrintError("Delete requires tableName and condition parameters")
        return
    end

    local query = string.format("DELETE FROM `%s` WHERE %s;", tableName, condition)

    self:Query(query, function()
        if ( callback ) then callback() end
    end, function(error)
        ax.util:PrintError("Failed to delete from table '" .. tableName .. "': " .. (error or "Unknown error"))
        if ( callback ) then callback() end
    end)
end

--- Selects rows from the table matching the optional condition.
-- @realm server
-- @tparam string tableName Name of the table
-- @tparam table[opt] columns Array of column names to select
-- @tparam string[opt] condition WHERE clause condition
-- @tparam function[opt] callback Callback function with results
-- @usage ax.sqloo:Select("players", {"name", "score"}, "score > 50")
function ax.sqloo:Select(tableName, columns, condition, callback)
    if ( !tableName ) then
        ax.util:PrintError("Select requires tableName parameter")
        return
    end

    local cols = "*"
    if ( columns and istable(columns) and !table.IsEmpty(columns) ) then
        -- Wrap column names in backticks
        local wrappedCols = {}
        for i = 1, #columns do
            wrappedCols[i] = "`" .. columns[i] .. "`"
        end
        cols = table.concat(wrappedCols, ", ")
    end

    local query = string.format("SELECT %s FROM `%s`", cols, tableName)

    if ( condition and condition != "" ) then
        query = query .. " WHERE " .. condition
    end

    self:Query(query, function(result)
        -- Convert JSON strings back to tables if needed
        if ( result and istable(result) ) then
            for i = 1, #result do
                for k, v in pairs(result[i]) do
                    if ( isstring(v) and string.StartWith(v, "{") and string.EndsWith(v, "}") ) then
                        local success, decoded = pcall(util.JSONToTable, v)
                        if ( success and decoded ) then
                            result[i][k] = decoded
                        end
                    end
                end
            end
        end

        if ( callback ) then callback(result) end
    end, function(error)
        -- Don't show errors for table doesn't exist
        if ( error and string.find(error, "doesn't exist") ) then
            ax.util:PrintWarning("Table '" .. tableName .. "' doesn't exist. Consider initializing it first.")
            if ( callback ) then callback(nil) end
        else
            ax.util:PrintError("Failed to select from table '" .. tableName .. "': " .. (error or "Unknown error"))
            if ( callback ) then callback(nil) end
        end
    end)
end

--- Executes a SQL query asynchronously, queuing it if the database is not connected.
-- @realm server
-- @tparam string query SQL query string
-- @tparam function[opt] onSuccess Success callback with result data
-- @tparam function[opt] onError Error callback with error message
-- @usage ax.sqloo:Query("SELECT * FROM players", function(result) print(result) end)
function ax.sqloo:Query(query, onSuccess, onError)
    if ( !query or query == "" or !isstring(query) ) then
        local err = "Empty or invalid query provided"
        ax.util:PrintError("MySQL error: " .. err)
        if ( onError ) then onError(err) end
        return
    end

    -- Trim whitespace and check for empty query
    query = string.Trim(query)
    if ( query == "" ) then
        local err = "Empty query after trimming whitespace"
        ax.util:PrintError("MySQL error: " .. err)
        if ( onError ) then onError(err) end
        return
    end

    -- Basic SQL injection protection - check for suspicious patterns
    -- Look for semicolons followed by non-whitespace (indicating multiple statements)
    local trimmedQuery = string.Trim(query)
    if ( string.find(trimmedQuery, ";.+") ) then
        local err = "Multiple statements detected in query"
        ax.util:PrintError("MySQL error: " .. err)
        ax.util:PrintError("Blocked query: " .. query)
        if ( onError ) then onError(err) end
        return
    end

    -- Queue queries if not connected
    if ( !self.isConnected or !self.db or self.db:status() != mysqloo.DATABASE_CONNECTED ) then
        local uniqueID = util.CRC(query .. tostring(onSuccess) .. tostring(onError))
        ax.util:PrintWarning("Database not connected, queuing query. (" .. uniqueID .. ")")

        self.queryQueue[#self.queryQueue + 1] = {query = query, onSuccess = onSuccess, onError = onError}
        return
    end

    local q = self.db:query(query)
    if ( !q ) then
        local err = "Failed to create query object"
        ax.util:PrintError("MySQL error: " .. err)
        ax.util:PrintError("Query that failed: " .. query)
        if ( onError ) then onError(err) end
        return
    end

    q.onSuccess = function(_, data)
        if ( onSuccess ) then
            onSuccess(data)
        end
    end

    q.onError = function(_, errString)
        local err = errString or "Unknown MySQL error"
        ax.util:PrintError("MySQL query failed: " .. err)
        ax.util:PrintError("Failed query: " .. query)

        if ( onError ) then
            onError(err)
        end
    end

    q:start()

    return q
end

--- GetDB
-- @realm server
-- @usage ax.sqloo:GetDB
function ax.sqloo:GetDB()
    return self.db
end

--- Status
-- @realm server
-- @usage ax.sqloo:Status
function ax.sqloo:Status()
    return self.db and self.db:status() or mysqloo.DATABASE_NOT_CONNECTED
end

--- Reconnect
-- @realm server
-- @usage ax.sqloo:Reconnect
function ax.sqloo:Reconnect()
    if ( self.db and self.db:status() == mysqloo.DATABASE_NOT_CONNECTED ) then
        self.db:connect()
    else
        ax.util:PrintWarning("Database is already connected or not initialized.")
    end
end

--- Counts the number of rows in a table matching an optional condition.
-- @realm server
-- @tparam string tableName Name of the table
-- @tparam string[opt] condition WHERE clause condition
-- @tparam function[opt] callback Callback function with row count
-- @usage ax.sqloo:Count("players", "score > 50", function(count) print(count) end)
function ax.sqloo:Count(tableName, condition, callback)
    if ( !tableName ) then
        ax.util:PrintError("Count requires tableName parameter")
        if ( callback ) then callback(0) end
        return
    end

    local query = string.format("SELECT COUNT(*) AS count FROM `%s`", tableName)

    if ( condition and condition != "" ) then
        query = query .. " WHERE " .. condition
    end

    self:Query(query, function(result)
        local count = result and result[1] and tonumber(result[1].count) or 0
        if ( callback ) then callback(count) end
    end, function(error)
        -- Don't show errors for table doesn't exist
        if ( error and string.find(error, "doesn't exist") ) then
            ax.util:PrintWarning("Table '" .. tableName .. "' doesn't exist. Consider initializing it first.")
            if ( callback ) then callback(0) end
        else
            ax.util:PrintError("Failed to count rows in table '" .. tableName .. "': " .. (error or "Unknown error"))
            if ( callback ) then callback(0) end
        end
    end)
end

--- Gets the database connection object.
-- @realm server
-- @treturn table Database connection object
-- @usage local db = ax.sqloo:GetDB()
function ax.sqloo:GetDB()
    return self.db
end

--- Gets the current database connection status.
-- @realm server
-- @treturn number MySQL status constant
-- @usage local status = ax.sqloo:GetStatus()
function ax.sqloo:GetStatus()
    return self.db and self.db:status() or mysqloo.DATABASE_NOT_CONNECTED
end

--- Checks if the database is connected.
-- @realm server
-- @treturn boolean True if connected, false otherwise
-- @usage if ax.sqloo:IsConnected() then print("Connected") end
function ax.sqloo:IsConnected()
    return self.isConnected and self.db and self.db:status() == mysqloo.DATABASE_CONNECTED
end

--- Manually triggers a reconnection attempt.
-- @realm server
-- @usage ax.sqloo:Reconnect()
function ax.sqloo:Reconnect()
    if ( self.db and self.db:status() == mysqloo.DATABASE_NOT_CONNECTED ) then
        ax.util:Print("Attempting manual reconnection...")
        self:Connect()
    else
        ax.util:PrintWarning("Database is already connected or not initialized.")
    end
end

--- Prints the current database connection status.
-- @realm server
-- @usage ax.sqloo:PrintStatus()
function ax.sqloo:PrintStatus()
    local status = self:GetStatus()
    local statusText = "Unknown"

    if ( status == mysqloo.DATABASE_NOT_CONNECTED ) then
        statusText = "Not connected"
    elseif ( status == mysqloo.DATABASE_CONNECTED ) then
        statusText = "Connected"
    elseif ( status == mysqloo.DATABASE_CONNECTING ) then
        statusText = "Connecting"
    elseif ( status == mysqloo.DATABASE_FAILED ) then
        statusText = "Connection failed"
    end

    ax.util:Print("MySQL Status: " .. statusText)

    if ( self.config ) then
        ax.util:Print("Host: " .. self.config.host .. ":" .. (self.config.port or 3306))
        ax.util:Print("Database: " .. self.config.database)
    end
end

--- Begins a database transaction.
-- @realm server
-- @tparam function[opt] callback Callback function
-- @usage ax.sqloo:BeginTransaction()
function ax.sqloo:BeginTransaction(callback)
    self:Query("START TRANSACTION;", function()
        ax.util:Print("MySQL transaction started.")
        if ( callback ) then callback(true) end
    end, function(error)
        ax.util:PrintError("Failed to start transaction: " .. (error or "Unknown error"))
        if ( callback ) then callback(false) end
    end)
end

--- Commits the current transaction.
-- @realm server
-- @tparam function[opt] callback Callback function
-- @usage ax.sqloo:CommitTransaction()
function ax.sqloo:CommitTransaction(callback)
    self:Query("COMMIT;", function()
        ax.util:Print("MySQL transaction committed.")
        if ( callback ) then callback(true) end
    end, function(error)
        ax.util:PrintError("Failed to commit transaction: " .. (error or "Unknown error"))
        if ( callback ) then callback(false) end
    end)
end

--- Rolls back the current transaction.
-- @realm server
-- @tparam function[opt] callback Callback function
-- @usage ax.sqloo:RollbackTransaction()
function ax.sqloo:RollbackTransaction(callback)
    self:Query("ROLLBACK;", function()
        ax.util:Print("MySQL transaction rolled back.")
        if ( callback ) then callback(true) end
    end, function(error)
        ax.util:PrintError("Failed to rollback transaction: " .. (error or "Unknown error"))
        if ( callback ) then callback(false) end
    end)
end

--- Executes multiple queries in a single transaction.
-- @realm server
-- @tparam table queries Array of query strings
-- @tparam function[opt] callback Callback function with success status
-- @usage ax.sqloo:ExecuteTransaction({"INSERT INTO players...", "UPDATE players..."})
function ax.sqloo:ExecuteTransaction(queries, callback)
    if ( !queries or !istable(queries) or table.IsEmpty(queries) ) then
        ax.util:PrintError("ExecuteTransaction requires a non-empty array of queries")
        if ( callback ) then callback(false) end
        return
    end

    self:BeginTransaction(function(success)
        if ( !success ) then
            if ( callback ) then callback(false) end
            return
        end

        local queryIndex = 1
        local function executeNext()
            if ( queryIndex > #queries ) then
                -- All queries executed successfully
                self:CommitTransaction(callback)
                return
            end

            self:Query(queries[queryIndex], function()
                queryIndex = queryIndex + 1
                executeNext()
            end, function(error)
                ax.util:PrintError("Transaction failed at query " .. queryIndex .. ": " .. (error or "Unknown error"))
                self:RollbackTransaction(function()
                    if ( callback ) then callback(false) end
                end)
            end)
        end

        executeNext()
    end)
end

--- Cleans up resources and closes the database connection.
-- @realm server
-- @usage ax.sqloo:Cleanup()
function ax.sqloo:Cleanup()
    if ( timer.Exists("ax.sqloo.keepalive") ) then
        timer.Remove("ax.sqloo.keepalive")
    end

    if ( timer.Exists("ax.sqloo.processqueue") ) then
        timer.Remove("ax.sqloo.processqueue")
    end

    if ( self.db ) then
        self.db:disconnect()
        self.db = nil
    end

    self.isConnected = false
    self.queryQueue = {}

    ax.util:Print("MySQL connection cleaned up.")
end