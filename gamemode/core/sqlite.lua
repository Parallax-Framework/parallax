--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Parallax SQLite Database Wrapper
-- Provides a comprehensive wrapper around the Garry's Mod SQLite system with enhanced features.
-- @module ax.sqlite

ax.sqlite = ax.sqlite or {}
ax.sqlite.tables = ax.sqlite.tables or {}
ax.sqlite.queryQueue = ax.sqlite.queryQueue or {}
ax.sqlite.isProcessingQueue = false
ax.sqlite.transactionActive = false

--- Initializes the SQLite database system.
-- @realm shared
-- @usage ax.sqlite:Initialize()
function ax.sqlite:Initialize()
    -- SQLite doesn't require connection setup, but we can use this for initialization
    self:ProcessQueuedQueries()
    hook.Run("DatabaseConnected")
    ax.util:PrintSuccess("SQLite database initialized successfully.")
end

--- Processes any queued queries (mainly for consistency with MySQL wrapper).
-- @realm shared
function ax.sqlite:ProcessQueuedQueries()
    if ( self.isProcessingQueue ) then return end
    self.isProcessingQueue = true

    while ( #self.queryQueue > 0 ) do
        local queuedQuery = table.remove(self.queryQueue, 1)
        self:Query(queuedQuery.query, queuedQuery.onSuccess, queuedQuery.onError)
    end

    self.isProcessingQueue = false
end

--- Starts a database transaction.
-- @realm shared
-- @usage ax.sqlite:BeginTransaction()
function ax.sqlite:BeginTransaction()
    if ( self.transactionActive ) then
        ax.util:PrintWarning("Transaction already active, ignoring BeginTransaction call.")
        return false
    end

    local result = self:Query("BEGIN TRANSACTION;")
    if ( result != false ) then
        self.transactionActive = true
        ax.util:Print("SQLite transaction started.")
        return true
    end

    return false
end

--- Commits the current transaction.
-- @realm shared
-- @usage ax.sqlite:CommitTransaction()
function ax.sqlite:CommitTransaction()
    if ( !self.transactionActive ) then
        ax.util:PrintWarning("No active transaction to commit.")
        return false
    end

    local result = self:Query("COMMIT;")
    if ( result != false ) then
        self.transactionActive = false
        ax.util:Print("SQLite transaction committed.")
        return true
    end

    return false
end

--- Rolls back the current transaction.
-- @realm shared
-- @usage ax.sqlite:RollbackTransaction()
function ax.sqlite:RollbackTransaction()
    if ( !self.transactionActive ) then
        ax.util:PrintWarning("No active transaction to rollback.")
        return false
    end

    local result = self:Query("ROLLBACK;")
    if ( result != false ) then
        self.transactionActive = false
        ax.util:Print("SQLite transaction rolled back.")
        return true
    end

    return false
end

--- Executes a raw SQL query and optionally handles success/failure callbacks.
-- @realm shared
-- @tparam string query SQL query string
-- @tparam function[opt] onSuccess Callback with query result (table)
-- @tparam function[opt] onError Callback with error message (string)
-- @treturn table|false Query result or false on failure
function ax.sqlite:Query(query, onSuccess, onError)
    if ( !query or query == "" ) then
        local err = "Empty or invalid query provided"
        ax.util:PrintError("SQLite error: " .. err)
        if ( onError ) then onError(err) end
        return false
    end

    local result = sql.Query(query)
    if ( result == false ) then
        local err = sql.LastError() or "Unknown SQLite error"
        ax.util:PrintError("SQLite query failed: " .. query .. " :: " .. err)
        if ( onError ) then onError(err) end
        return false
    end

    if ( onSuccess ) then onSuccess(result) end
    return result
end

--- Escapes a string for safe use in SQL queries.
-- @realm shared
-- @tparam string str String to escape
-- @treturn string Escaped string
function ax.sqlite:Escape(str)
    return sql.SQLStr(str)
end

--- Checks if a table exists in the database.
-- @realm shared
-- @tparam string tableName Name of the table to check
-- @treturn boolean True if table exists, false otherwise
function ax.sqlite:TableExists(tableName)
    local result = self:Query("SELECT name FROM sqlite_master WHERE type='table' AND name=" .. self:Escape(tableName) .. ";")
    return result and #result > 0
end

--- Gets information about table columns.
-- @realm shared
-- @tparam string tableName Name of the table
-- @treturn table|false Table column information or false on failure
function ax.sqlite:GetTableInfo(tableName)
    return self:Query("PRAGMA table_info(" .. tableName .. ");")
end

--- Checks if a column exists in a table.
-- @realm shared
-- @tparam string tableName Name of the table
-- @tparam string columnName Name of the column
-- @treturn boolean True if column exists, false otherwise
function ax.sqlite:ColumnExists(tableName, columnName)
    local result = self:GetTableInfo(tableName)
    if ( !result ) then return false end

    for i = 1, #result do
        if ( result[i].name == columnName ) then
            return true
        end
    end

    return false
end

--- Registers a variable/column for the specified table and sets its default value.
-- @realm shared
-- @tparam string tableName Name of the table
-- @tparam string key Column name
-- @tparam any default Default value for the column
-- @usage ax.sqlite:RegisterVar("players", "name", "")
function ax.sqlite:RegisterVar(tableName, key, default)
    if ( !tableName or !key ) then
        ax.util:PrintError("RegisterVar requires tableName and key parameters")
        return
    end

    self.tables[tableName] = self.tables[tableName] or {}
    self.tables[tableName][key] = default

    local columnType = self:GetColumnType(default)
    self:AddColumn(tableName, key, columnType, default)
end

--- Determines the appropriate SQL column type based on the default value.
-- @realm shared
-- @tparam any default Default value
-- @treturn string SQL column type
function ax.sqlite:GetColumnType(default)
    if ( isnumber(default) ) then
        return math.floor(default) == default and "INTEGER" or "REAL"
    elseif ( isstring(default) ) then
        return "TEXT"
    elseif ( isbool(default) ) then
        return "INTEGER" -- SQLite stores booleans as integers
    else
        return "TEXT"
    end
end

--- Creates a SQL table with the registered and extra schema fields.
-- @realm shared
-- @tparam string tableName Name of the table to create
-- @tparam table[opt] extraSchema Additional schema fields
-- @usage ax.sqlite:InitializeTable("players", {steamid = "VARCHAR(32) PRIMARY KEY"})
function ax.sqlite:InitializeTable(tableName, extraSchema)
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
        schema.id = "INTEGER PRIMARY KEY AUTOINCREMENT"
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

    local query = string.format("CREATE TABLE IF NOT EXISTS `%s` (%s);", tableName, table.concat(parts, ", "))
    local result = self:Query(query)

    if ( result != false ) then
        ax.util:PrintSuccess("Table '" .. tableName .. "' initialized successfully.")
    else
        -- Don't show errors for table already exists
        local error = sql.LastError()
        if ( error and string.find(error, "already exists") ) then
            ax.util:Print("Table '" .. tableName .. "' already exists.")
        else
            ax.util:PrintError("Failed to initialize table '" .. tableName .. "': " .. (error or "Unknown error"))
        end
    end
end

--- Adds a column to a table if it doesn't exist already.
-- @realm shared
-- @tparam string tableName Name of the table
-- @tparam string columnName Name of the column to add
-- @tparam string columnType SQL column type
-- @tparam any defaultValue Default value for the column
-- @usage ax.sqlite:AddColumn("players", "score", "INTEGER", 0)
function ax.sqlite:AddColumn(tableName, columnName, columnType, defaultValue)
    if ( !tableName or !columnName or !columnType ) then
        ax.util:PrintError("AddColumn requires tableName, columnName, and columnType parameters")
        return
    end

    -- Check if table exists first
    if ( !self:TableExists(tableName) ) then
        ax.util:PrintWarning("Table '" .. tableName .. "' does not exist, cannot add column.")
        return
    end

    -- Check if column already exists
    if ( self:ColumnExists(tableName, columnName) ) then
        ax.util:PrintWarning("Column '" .. columnName .. "' already exists in table '" .. tableName .. "'.")
        return
    end

    local query = string.format("ALTER TABLE `%s` ADD COLUMN `%s` %s", tableName, columnName, columnType)

    if ( defaultValue != nil ) then
        query = query .. " DEFAULT " .. self:Escape(defaultValue)
    end

    query = query .. ";"

    local result = self:Query(query)
    if ( result != false ) then
        ax.util:PrintSuccess("Column '" .. columnName .. "' added to table '" .. tableName .. "'.")
    else
        -- Don't show errors for column already exists
        local error = sql.LastError()
        if ( error and (string.find(error, "already exists") or string.find(error, "duplicate column")) ) then
            ax.util:Print("Column '" .. columnName .. "' already exists in table '" .. tableName .. "'.")
        else
            ax.util:PrintError("Failed to add column '" .. columnName .. "' to table '" .. tableName .. "': " .. (error or "Unknown error"))
        end
    end
end

--- Returns a default row populated with the registered default values.
-- @realm shared
-- @tparam string tableName Name of the table
-- @tparam table[opt] override Values to override defaults
-- @treturn table Default row data
-- @usage local defaultRow = ax.sqlite:GetDefaultRow("players", {name = "NewPlayer"})
function ax.sqlite:GetDefaultRow(tableName, override)
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
-- @realm shared
-- @tparam string tableName Name of the table
-- @tparam string key Column name to match
-- @tparam any value Value to match
-- @tparam function[opt] callback Callback function with row data
-- @usage ax.sqlite:LoadRow("players", "steamid", "STEAM_0:0:123456", function(row) print(row.name) end)
function ax.sqlite:LoadRow(tableName, key, value, callback)
    if ( !tableName or !key or value == nil ) then
        ax.util:PrintError("LoadRow requires tableName, key, and value parameters")
        return
    end

    local condition = string.format("`%s` = %s", key, self:Escape(value))
    local result = self:Select(tableName, nil, condition)

    local row = result and result[1]
    if ( !row ) then
        -- Create default row
        row = self:GetDefaultRow(tableName)
        row[key] = value

        -- Insert the default row
        self:Insert(tableName, row)

        if ( callback ) then
            if ( isfunction(callback) ) then
                ax.util:PrintWarning("Database row not found for " .. tableName .. ", inserting default row")
                callback(row)
            else
                ax.util:PrintError("LoadRow callback must be a function")
            end
        end
    else
        -- Fill in any missing values with defaults
        local defaults = self.tables[tableName] or {}
        for k, v in pairs(defaults) do
            if ( row[k] == nil ) then
                row[k] = v
            end
        end

        if ( callback ) then
            if ( isfunction(callback) ) then
                callback(row)
            else
                ax.util:PrintError("LoadRow callback must be a function")
            end
        end
    end

    return row
end

--- Saves a row of data into the table using the given key.
-- @realm shared
-- @tparam string tableName Name of the table
-- @tparam table data Data to save
-- @tparam string key Column name to use for matching
-- @tparam function[opt] callback Callback function
-- @usage ax.sqlite:SaveRow("players", {name = "John", score = 100}, "steamid")
function ax.sqlite:SaveRow(tableName, data, key, callback)
    if ( !tableName or !data or !key ) then
        ax.util:PrintError("SaveRow requires tableName, data, and key parameters")
        return
    end

    if ( !data[key] ) then
        ax.util:PrintError("SaveRow: data must contain the key field '" .. key .. "'")
        return
    end

    local condition = string.format("`%s` = %s", key, self:Escape(data[key]))
    local result = self:Update(tableName, data, condition)

    if ( callback and isfunction(callback) ) then
        callback(result)
    end

    return result
end

--- Inserts a new row of data into the table.
-- @realm shared
-- @tparam string tableName Name of the table
-- @tparam table data Data to insert
-- @tparam function[opt] callback Callback function with inserted row ID
-- @usage ax.sqlite:Insert("players", {name = "John", steamid = "STEAM_0:0:123456"})
function ax.sqlite:Insert(tableName, data, callback)
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

        values[#values + 1] = self:Escape(v)
    end

    local query = string.format(
        "INSERT INTO `%s` (%s) VALUES (%s);",
        tableName,
        table.concat(keys, ", "),
        table.concat(values, ", ")
    )

    local result = self:Query(query)
    if ( result != false ) then
        if ( callback ) then
            local idResult = sql.QueryRow("SELECT last_insert_rowid() as id;")
            if ( idResult ) then
                local id = tonumber(idResult.id)
                callback(id)
            else
                callback(nil)
            end
        end
        return true
    end

    return false
end

--- Updates existing data in the table matching a given condition.
-- @realm shared
-- @tparam string tableName Name of the table
-- @tparam table data Data to update
-- @tparam string condition WHERE clause condition
-- @tparam function[opt] callback Callback function
-- @usage ax.sqlite:Update("players", {score = 100}, "steamid = 'STEAM_0:0:123456'")
function ax.sqlite:Update(tableName, data, condition, callback)
    if ( !tableName or !data or !condition ) then
        ax.util:PrintError("Update requires tableName, data, and condition parameters")
        return false
    end

    if ( !istable(data) or table.IsEmpty(data) ) then
        ax.util:PrintError("Update data must be a non-empty table")
        return false
    end

    local updates = {}
    for k, v in pairs(data) do
        -- Convert tables to JSON
        if ( istable(v) ) then
            v = util.TableToJSON(v)
        end

        updates[#updates + 1] = string.format("`%s` = %s", k, self:Escape(v))
    end

    local query = string.format("UPDATE `%s` SET %s WHERE %s;", tableName, table.concat(updates, ", "), condition)
    local result = self:Query(query)

    if ( result == false ) then
        ax.util:PrintError("Failed to update table '" .. tableName .. "': " .. (sql.LastError() or "Unknown error"))
        return false
    end

    if ( callback and isfunction(callback) ) then
        callback(result)
    end

    return true
end

--- Deletes rows from the table based on a condition.
-- @realm shared
-- @tparam string tableName Name of the table
-- @tparam string condition WHERE clause condition
-- @tparam function[opt] callback Callback function
-- @usage ax.sqlite:Delete("players", "last_played < " .. (os.time() - 86400))
function ax.sqlite:Delete(tableName, condition, callback)
    if ( !tableName or !condition ) then
        ax.util:PrintError("Delete requires tableName and condition parameters")
        return false
    end

    local query = string.format("DELETE FROM `%s` WHERE %s;", tableName, condition)
    local result = self:Query(query)

    if ( result == false ) then
        ax.util:PrintError("Failed to delete from table '" .. tableName .. "': " .. (sql.LastError() or "Unknown error"))
        return false
    end

    if ( callback and isfunction(callback) ) then
        callback(result)
    end

    return true
end

--- Selects rows from the table matching the optional condition.
-- @realm shared
-- @tparam string tableName Name of the table
-- @tparam table[opt] columns Array of column names to select
-- @tparam string[opt] condition WHERE clause condition
-- @tparam function[opt] callback Callback function with results
-- @treturn table|nil Query results or nil on failure
-- @usage ax.sqlite:Select("players", {"name", "score"}, "score > 50")
function ax.sqlite:Select(tableName, columns, condition, callback)
    if ( !tableName ) then
        ax.util:PrintError("Select requires tableName parameter")
        return nil
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

    local result = self:Query(query)

    if ( result == false ) then
        ax.util:PrintError("Failed to select from table '" .. tableName .. "': " .. (sql.LastError() or "Unknown error"))
        return nil
    end

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

    if ( callback and isfunction(callback) ) then
        callback(result)
    end

    return result
end

--- Counts the number of rows in a table matching an optional condition.
-- @realm shared
-- @tparam string tableName Name of the table
-- @tparam string[opt] condition WHERE clause condition
-- @treturn number Number of rows
-- @usage local playerCount = ax.sqlite:Count("players", "score > 50")
function ax.sqlite:Count(tableName, condition)
    if ( !tableName ) then
        ax.util:PrintError("Count requires tableName parameter")
        return 0
    end

    local query = string.format("SELECT COUNT(*) as count FROM `%s`", tableName)

    if ( condition and condition != "" ) then
        query = query .. " WHERE " .. condition
    end

    local result = self:Query(query)
    return result and result[1] and tonumber(result[1].count) or 0
end

--- Checks if the database is connected and ready (always true for SQLite).
-- @realm shared
-- @treturn boolean Always returns true for SQLite
function ax.sqlite:IsConnected()
    return true
end

--- Gets the current database status (always connected for SQLite).
-- @realm shared
-- @treturn string Always returns "connected" for SQLite
function ax.sqlite:GetStatus()
    return "connected"
end

--- Prints the current database status.
-- @realm shared
-- @usage ax.sqlite:PrintStatus()
function ax.sqlite:PrintStatus()
    ax.util:Print("SQLite Status: Connected (always available)")
end

--- Performs a database vacuum to optimize storage.
-- @realm shared
-- @usage ax.sqlite:Vacuum()
function ax.sqlite:Vacuum()
    local result = self:Query("VACUUM;")
    if ( result != false ) then
        ax.util:PrintSuccess("SQLite database vacuumed successfully.")
    else
        ax.util:PrintError("Failed to vacuum SQLite database.")
    end
end

--- Gets database file size information.
-- @realm shared
-- @treturn table Database size information
function ax.sqlite:GetDatabaseInfo()
    local result = self:Query("PRAGMA database_list;")
    if ( result ) then
        return result
    end
    return {}
end

--- Executes multiple queries in a single transaction.
-- @realm shared
-- @tparam table queries Array of query strings
-- @tparam function[opt] callback Callback function
-- @usage ax.sqlite:ExecuteTransaction({"INSERT INTO players...", "UPDATE players..."})
function ax.sqlite:ExecuteTransaction(queries, callback)
    if ( !queries or !istable(queries) or table.IsEmpty(queries) ) then
        ax.util:PrintError("ExecuteTransaction requires a non-empty array of queries")
        return false
    end

    if ( !self:BeginTransaction() ) then
        return false
    end

    local success = true
    for i = 1, #queries do
        local result = self:Query(queries[i])
        if ( result == false ) then
            success = false
            break
        end
    end

    if ( success ) then
        self:CommitTransaction()
        if ( callback ) then callback(true) end
    else
        self:RollbackTransaction()
        if ( callback ) then callback(false) end
    end

    return success
end