--- Parallax Sqlite Database Wrapper
-- Provides a wrapper around the Garry's Mod SQLite system.
-- @module ax.sqlite

ax.sqlite = ax.sqlite or {}
ax.sqlite.tables = ax.sqlite.tables or {}

--- Executes a raw SQL query and optionally handles success/failure callbacks.
-- @realm shared
-- @tparam string query SQL query string
-- @tparam function[opt] onSuccess Callback with query result (table)
-- @tparam function[opt] onError Callback with error message (string)
function ax.sqlite:Query(query, onSuccess, onError)
    local result = sql.Query(query)
    if ( result == false ) then
        local err = sql.LastError()
        ax.util:PrintError("SQLite query failed: " .. query .. " :: " .. (err or "unknown"))
        if ( onError ) then onError(err) end
    else
        if ( onSuccess ) then onSuccess(result) end
    end

    return result
end

--- Registers a variable/column for the specified table and sets its default value.
-- @realm shared
-- @usage ax.sqlite:RegisterVar
function ax.sqlite:RegisterVar(tableName, key, default)
    self.tables[tableName] = self.tables[tableName] or {}
    self.tables[tableName][key] = default

    self:AddColumn(tableName, key, type(default) == "number" and "INTEGER" or "TEXT", default)
end

--- Creates a SQL table with the registered and extra schema fields.
-- @realm shared
-- @usage ax.sqlite:InitializeTable
function ax.sqlite:InitializeTable(tableName, extraSchema)
    local schema = {}

    -- Check if any primary key is defined in user schema
    local hasPrimaryKey = false
    for k, v in pairs(extraSchema or {}) do
        if ( isstring(v) and v:find("PRIMARY KEY") ) then
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
        if ( isnumber(v) ) then
            schema[k] = "INT"
        elseif ( isstring(v) ) then
            schema[k] = "TEXT"
        elseif ( isbool(v) ) then
            schema[k] = "BOOLEAN"
        else
            schema[k] = "TEXT"
        end
    end

    -- Merge user-provided schema
    for k, v in pairs(extraSchema or {}) do
        schema[k] = v
    end

    local parts = {}
    for k, v in pairs(schema) do
        parts[#parts + 1] = string.format("`%s` %s", k, v)
    end

    local query = string.format("CREATE TABLE IF NOT EXISTS `%s` (%s);", tableName, table.concat(parts, ", "))
    self:Query(query)
end

--- Adds a column to a table if it doesn't exist already.
-- @realm shared
-- @usage ax.sqlite:AddColumn
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
            self:Query(insertQuery)
        end
    end
end

--- Returns a default row populated with the registered default values.
-- @realm shared
-- @usage ax.sqlite:GetDefaultRow
function ax.sqlite:GetDefaultRow(query, override)
    local data = table.Copy(self.tables[query] or {})
    for k, v in pairs(override or {}) do
        data[k] = v
    end

    return data
end

--- Loads a row based on a key/value match or inserts a default if not found.
-- @realm shared
-- @usage ax.sqlite:LoadRow
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

--- Saves a row of data into the table using the given key.
-- @realm shared
-- @usage ax.sqlite:SaveRow
function ax.sqlite:SaveRow(query, data, key, callback)
    local condition = string.format("%s = %s", key, sql.SQLStr(data[key]))
    self:Update(query, data, condition)

    if ( callback and isfunction(callback) ) then
        callback(data)
    end
end

--- Inserts a new row of data into the table.
-- @realm shared
-- @usage ax.sqlite:Insert
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
    self:Query(insertQuery)

    if ( callback ) then
        local result = sql.QueryRow("SELECT last_insert_rowid();")
        if ( result ) then
            local id = tonumber(result["last_insert_rowid()"])
            callback(id)
        end
    end
end

--- Updates existing data in the table matching a given condition.
-- @realm shared
-- @usage ax.sqlite:Update
function ax.sqlite:Update(query, data, condition, callback)
    local updates = {}
    for k, v in pairs(data) do
        updates[#updates + 1] = string.format("%s = %s", k, sql.SQLStr(v))
    end

    local insertQuery = string.format("UPDATE %s SET %s WHERE %s;", query, table.concat(updates, ", "), condition)
    local result = self:Query(insertQuery)
    if ( result == false ) then
        ax.util:PrintError("Database Failed to update row: ", insertQuery, sql.LastError())
        return false
    end

    if ( callback and isfunction(callback) ) then
        callback(result)
    end

    return true
end

--- Deletes rows from the table based on a condition.
-- @realm shared
-- @usage ax.sqlite:Delete
function ax.sqlite:Delete(query, condition, callback)
    local insertQuery = string.format("DELETE FROM %s WHERE %s;", query, condition)
    local result = self:Query(insertQuery)
    if ( result == false ) then
        ax.util:PrintError("Database Failed to delete row: ", insertQuery, sql.LastError())
        return false
    end

    if ( callback and isfunction(callback) ) then
        callback(result)
    end

    return true
end

--- Selects rows from the table matching the optional condition.
-- @realm shared
-- @usage ax.sqlite:Select
function ax.sqlite:Select(query, columns, condition, callback)
    local cols = columns and table.concat(columns, ", ") or "*"
    local insertQuery = string.format("SELECT %s FROM %s", cols, query)

    if ( condition ) then
        insertQuery = insertQuery .. " WHERE " .. condition
    end

    local result = self:Query(insertQuery)
    if ( result == false ) then
        ax.util:PrintError("Database Failed to select rows: ", insertQuery, " ", sql.LastError())
        return nil
    end

    if ( callback and isfunction(callback) ) then
        callback(result)
    end

    return result
end

--- Counts the number of rows in a table matching an optional condition.
-- @realm shared
-- @usage ax.sqlite:Count
function ax.sqlite:Count(query, condition)
    local insertQuery = string.format("SELECT COUNT(*) FROM %s", query)

    if ( condition ) then
        insertQuery = insertQuery .. " WHERE " .. condition
    end

    local result = self:Query(insertQuery)
    return result and result[1]["COUNT(*)"] or 0
end