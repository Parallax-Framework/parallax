--- SQLite Utility Library for Parallax
-- Provides dynamic variable registration and row management per table.
-- Designed for frameworks with multiple data tables like `users`, `characters`, etc.
-- @module ax.sqlite

ax.sqlite = ax.sqlite or {}
ax.sqlite.tables = ax.sqlite.tables or {}

--- Registers a variable for a table to be included in table creation and loading.
-- It will also automatically add the column to the table in the database if it doesn't exist.
-- @realm shared
-- @tparam string tableName The name of the table (e.g. "users", "characters")
-- @tparam string key The name of the variable (e.g. "credits", "xp")
-- @tparam any default The default value for the variable
function ax.sqlite:RegisterVar(tableName, key, default)
    self.tables[tableName] = self.tables[tableName] or {}
    self.tables[tableName][key] = default

    self:AddColumn(tableName, key, type(default) == "number" and "INTEGER" or "TEXT", default)
end

--- Adds a column to an existing table if the column doesn't already exist.
-- @realm shared
-- @tparam string tableName The name of the table (e.g. "users", "characters")
-- @tparam string columnName The name of the column to add
-- @tparam string columnType The type of the column (e.g. "INTEGER", "TEXT")
-- @tparam any defaultValue The default value to set if the column is added
function ax.sqlite:AddColumn(tableName, columnName, columnType, defaultValue)
    local result = sql.Query(string.format("PRAGMA table_info(%s);", tableName))
    if ( result ) then
        local columnExists = false
        for _, column in ipairs(result) do
            if ( column.name == columnName ) then
                columnExists = true
                break
            end
        end

        if ( !columnExists ) then
            local insertQuery = string.format(
                "ALTER TABLE %s ADD COLUMN %s %s DEFAULT %s;",
                tableName,
                columnName,
                columnType,
                sql.SQLStr(defaultValue)
            )
            sql.Query(insertQuery)
        end
    end
end

--- Returns a default row based on registered variables for a table.
-- @realm shared
-- @tparam string query The table name
-- @tparam table[opt] override Optional overrides to apply to default row
-- @treturn table The default row with values
function ax.sqlite:GetDefaultRow(query, override)
    local data = table.Copy(self.tables[query] or {})
    for k, v in pairs(override or {}) do
        data[k] = v
    end

    return data
end

--- Initializes a table by creating it in SQLite with registered and extra schema fields.
-- @realm shared
-- @tparam string query The table name
-- @tparam table[opt] extraSchema Extra schema definitions (e.g. primary key)
function ax.sqlite:InitializeTable(query, extraSchema)
    local schema = {
        id = "INTEGER PRIMARY KEY AUTOINCREMENT"
    }

    for k, v in pairs(self.tables[query] or {}) do
        if ( isnumber(v) ) then
            schema[k] = "INTEGER"
        elseif ( isstring(v) ) then
            schema[k] = "TEXT"
        elseif ( isbool(v) ) then
            schema[k] = "BOOLEAN"
        else
            schema[k] = "TEXT"
        end
    end

    if ( extraSchema ) then
        for k, v in pairs(extraSchema) do
            schema[k] = v
        end
    end

    self:CreateTable(query, schema)
end

--- Loads a row from a table, or inserts a default if not found.
-- @realm shared
-- @tparam string query Table name
-- @tparam string key Column to match (e.g. "steamid")
-- @tparam any value Value to match (e.g. player's SteamID)
-- @tparam function callback Function to run with resulting data row
function ax.sqlite:LoadRow(query, key, value, callback)
    local condition = string.format("%s = %s", key, sql.SQLStr(value))
    local result = self:Select(query, nil, condition)

    local row = result and result[1]
    if ( !row ) then
        row = self:GetDefaultRow(query)
        row[key] = value

        self:Insert(query, row)

        if ( callback ) then
            if ( isfunction(callback) ) then
                ax.util:PrintWarning("Database Row not found, inserting default row")
                callback(row)
            else
                ax.util:PrintError("Database LoadRow Callback must be a function")
            end
        end

        return
    else
        for k, v in pairs(row) do
            if ( v == nil ) then
                row[k] = self.tables[query][k]
            end
        end
    end

    if ( callback ) then
        if ( isfunction(callback) ) then
            callback(row)
        else
            error("Callback must be a function")
        end
    end
end

--- Saves a full data row back into the table using a key match.
-- @realm shared
-- @tparam string query Table name
-- @tparam table data The row data to save
-- @tparam string key Column name to use for matching
-- @tparam function[opt] callback Optional callback to run after saving
function ax.sqlite:SaveRow(query, data, key, callback)
    local condition = string.format("%s = %s", key, sql.SQLStr(data[key]))
    self:Update(query, data, condition)

    if ( callback and isfunction(callback) ) then
        callback(data)
    end
end

--- Creates a table with a given schema if it doesn't already exist.
-- @realm shared
-- @tparam string query Table name
-- @tparam table schema Column definitions
function ax.sqlite:CreateTable(query, schema)
    local parts = {}
    for column, columnType in pairs(schema) do
        parts[#parts + 1] = string.format("%s %s", column, columnType)
    end

    local insertQuery = string.format("CREATE TABLE IF NOT EXISTS %s (%s);", query, table.concat(parts, ", "))
    sql.Query(insertQuery)
end

--- Inserts a row into a table and optionally returns the inserted row ID.
-- @realm shared
-- @tparam string query Table name
-- @tparam table data Row data
-- @tparam function[opt] callback Optional callback to receive last inserted ID
function ax.sqlite:Insert(query, data, callback)
    local keys, values = {}, {}

    for k, v in pairs(data) do
        keys[#keys + 1] = k
        values[#values + 1] = sql.SQLStr(v)
    end

    local insertQuery = string.format(
        "INSERT INTO %s (%s) VALUES (%s);",
        query,
        table.concat(keys, ", "),
        table.concat(values, ", ")
    )
    sql.Query(insertQuery)

    if ( callback ) then
        local result = sql.QueryRow("SELECT last_insert_rowid();")
        if ( result ) then
            local id = tonumber(result["last_insert_rowid()"])
            callback(id)
        end
    end
end

--- Deletes a row from a table
-- @realm shared
-- @tparam string query Table name
-- @tparam string condition WHERE clause condition
-- @tparam function[opt] callback Optional callback to run after deletion
-- @treturn boolean Success status
function ax.sqlite:Delete(query, condition, callback)
    local insertQuery = string.format("DELETE FROM %s WHERE %s;", query, condition)
    local result = sql.Query(insertQuery)
    if ( result == false ) then
        ax.util:PrintError("Database Failed to delete row: ", insertQuery, sql.LastError())
        return false
    end

    if ( callback and isfunction(callback) ) then
        callback(result)
    end

    return true
end

--- Updates a row in a table based on a condition.
-- @realm shared
-- @tparam string query Table name
-- @tparam table data Row data to update
-- @tparam string condition WHERE clause condition
-- @tparam function[opt] callback Optional callback to run after update
-- @treturn boolean Success status
function ax.sqlite:Update(query, data, condition, callback)
    local updates = {}
    for k, v in pairs(data) do
        updates[#updates + 1] = string.format("%s = %s", k, sql.SQLStr(v))
    end

    local insertQuery = string.format("UPDATE %s SET %s WHERE %s;", query, table.concat(updates, ", "), condition)
    local result = sql.Query(insertQuery)
    if ( result == false ) then
        ax.util:PrintError("Database Failed to update row: ", insertQuery, sql.LastError())
        return false
    end

    if ( callback and isfunction(callback) ) then
        callback(result)
    end

    return true
end

--- Selects rows from a table matching a condition.
-- @realm shared
-- @tparam string query Table name
-- @tparam table[opt] columns Array of column names or nil for all
-- @tparam string[opt] condition WHERE clause
-- @tparam function[opt] callback Optional callback to process results
-- @treturn table|nil Resulting rows or nil
function ax.sqlite:Select(query, columns, condition, callback)
    local cols = columns and table.concat(columns, ", ") or "*"
    local insertQuery = string.format("SELECT %s FROM %s", cols, query)

    if ( condition ) then
        insertQuery = insertQuery .. " WHERE " .. condition
    end

    local result = sql.Query(insertQuery)
    if ( result == false ) then
        ax.util:PrintError("Database Failed to select rows: ", insertQuery, " ", sql.LastError())
        return nil
    end

    if ( callback and isfunction(callback) ) then
        callback(result)
    end

    return result
end

--- Returns the number of rows in a table.
-- @realm shared
-- @tparam string query Table name
-- @tparam string[opt] condition WHERE clause
-- @treturn number Number of rows
function ax.sqlite:Count(query, condition)
    local insertQuery = string.format("SELECT COUNT(*) FROM %s", query)

    if ( condition ) then
        insertQuery = insertQuery .. " WHERE " .. condition
    end

    local result = sql.Query(insertQuery)
    return result and result[1]["COUNT(*)"] or 0
end