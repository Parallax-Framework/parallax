--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

function ax.util:HasMysqlooBinary()
    return util.IsBinaryModuleInstalled("mysqloo")
end

if ( !ax.util:HasMysqlooBinary() ) then
    ax.util:PrintWarning("MySQLOO binary not found in lua/bin/. ax.sqloo disabled.")
    return
end

-- Now safe to require
require("mysqloo")

--- Parallax MySQLOO Database Wrapper
-- Provides a wrapper around the mysqloo module for async MySQL access
-- @module ax.sqloo

ax.sqloo = ax.sqloo or {}
ax.sqloo.config = nil
ax.sqloo.db = nil
ax.sqloo.tables = ax.sqloo.tables or {}

--- Initializes the SQL database connection or environment.
-- @realm server
-- @usage ax.sqloo:Initialize
function ax.sqloo:Initialize(config, callback, fallback)
    self.config = config

    local db = mysqloo.connect(
        config.host,
        config.username,
        config.password,
        config.database,
        config.port or 3306
    )

    db.onConnected = function()
        if ( callback ) then
            callback()
        end
    end

    db.onConnectionFailed = function(_, errString)
        if ( fallback ) then
            fallback(errString)
        end
    end

    db:connect()
    db:wait()

    self.db = db
end

--- Registers a variable/column for the specified table and sets its default value.
-- @realm server
-- @usage ax.sqloo:RegisterVar
function ax.sqloo:RegisterVar(tableName, key, default)
    self.tables[tableName] = self.tables[tableName] or {}
    self.tables[tableName][key] = default

    local columnType = isnumber(default) and "INT"
        or isstring(default) and "TEXT"
        or isbool(default) and "BOOLEAN"
        or "TEXT"

    self:AddColumn(tableName, key, columnType, default)
end

--- Creates a SQL table with the registered and extra schema fields.
-- @realm server
-- @usage ax.sqloo:InitializeTable
function ax.sqloo:InitializeTable(tableName, extraSchema)
    local schema = {}

    -- Check if any primary key is defined in user schema
    local hasPrimaryKey = false
    for k, v in pairs(extraSchema or {}) do
        if ( isstring(v) and string.find(v, "PRIMARY KEY") ) then
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
-- @realm server
-- @usage ax.sqloo:AddColumn
function ax.sqloo:AddColumn(tableName, columnName, columnType, defaultValue)
    local query = string.format("SHOW COLUMNS FROM `%s` LIKE %s;", tableName, sql.SQLStr(columnName))
    self:Query(query, function(result)
        if ( !result or !result[1] ) then
            local alter = string.format(
                "ALTER TABLE `%s` ADD COLUMN `%s` %s",
                tableName,
                columnName,
                columnType
            )

            if ( defaultValue != nil ) then
                alter = alter .. " DEFAULT " .. sql.SQLStr(defaultValue)
            end

            alter = alter .. ";"

            self:Query(alter)
        else
            ax.util:PrintWarning("Column '" .. columnName .. "' already exists in table '" .. tableName .. "'.")
        end
    end)
end

--- Returns a default row populated with the registered default values.
-- @realm server
-- @usage ax.sqloo:GetDefaultRow
function ax.sqloo:GetDefaultRow(tableName, override)
    local data = table.Copy(self.tables[tableName] or {})
    for k, v in pairs(override or {}) do
        data[k] = v
    end

    return data
end

--- Loads a row based on a key/value match or inserts a default if not found.
-- @realm server
-- @usage ax.sqloo:LoadRow
function ax.sqloo:LoadRow(tableName, key, value, callback)
    local condition = string.format("`%s` = %s", key, self:Escape(value))

    self:Select(tableName, nil, condition, function(result)
        if ( !result or !result[1] ) then
            local row = self:GetDefaultRow(tableName)
            row[key] = value

            self:Insert(tableName, row, function()
                if ( callback ) then
                    callback(row)
                end
            end)
        else
            local row = result[1]
            local vars = self.tables[tableName]
            if ( !vars ) then
                ax.util:PrintError("No registered variables for table '" .. tableName .. "'")
                return
            end

            for k, v in pairs(vars) do
                if ( row[k] == nil ) then
                    row[k] = v
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
-- @usage ax.sqloo:SaveRow
function ax.sqloo:SaveRow(tableName, data, key, callback)
    local condition = string.format("`%s` = %s", key, self:Escape(data[key]))
    self:Update(tableName, data, condition, callback)
end

--- Inserts a new row of data into the table.
-- @realm server
-- @usage ax.sqloo:Insert
function ax.sqloo:Insert(tableName, data, callback)
    local keys, values = {}, {}

    for k, v in pairs(data) do
        keys[#keys + 1] = "`" .. k .. "`"
        values[#values + 1] = sql.SQLStr(v)
    end

    local query = string.format("INSERT INTO `%s` (%s) VALUES (%s);", tableName, table.concat(keys, ", "), table.concat(values, ", "))
    self:Query(query, function()
        -- fetch last inserted ID
        self:Query("SELECT LAST_INSERT_ID() AS id;", function(result)
            if ( callback ) then
                callback(result and result[1] and tonumber(result[1].id))
            end
        end)
    end)
end

--- Updates existing data in the table matching a given condition.
-- @realm server
-- @usage ax.sqloo:Update
function ax.sqloo:Update(tableName, data, condition, callback)
    local updates = {}

    for k, v in pairs(data) do
        -- Auto-convert tables to JSON
        if ( istable(v) ) then
            v = util.TableToJSON(v)
        end

        updates[#updates + 1] = string.format("`%s` = %s", k, sql.SQLStr(v))
    end

    local query = string.format("UPDATE `%s` SET %s WHERE %s;", tableName, table.concat(updates, ", "), condition)
    self:Query(query, function()
        if ( callback ) then
            callback()
        end
    end)
end

--- Deletes rows from the table based on a condition.
-- @realm server
-- @usage ax.sqloo:Delete
function ax.sqloo:Delete(tableName, condition, callback)
    local query = string.format("DELETE FROM `%s` WHERE %s;", tableName, condition)
    self:Query(query, function()
        if ( callback ) then
            callback()
        end
    end)
end

--- Selects rows from the table matching the optional condition.
-- @realm server
-- @usage ax.sqloo:Select
function ax.sqloo:Select(tableName, columns, condition, callback)
    local cols = columns and table.concat(columns, ", ") or "*"
    local query = string.format("SELECT %s FROM `%s`", cols, tableName)

    if ( condition ) then
        query = query .. " WHERE " .. condition
    end

    self:Query(query, callback)
end

--- Executes a SQL query asynchronously, queuing it if the database is not connected.
-- This method allows you to run any SQL query and handle success or error callbacks.
-- @realm server
-- @usage ax.sqloo:Query
function ax.sqloo:Query(query, onSuccess, onError)
    if ( !self.db or self.db:status() != mysqloo.DATABASE_CONNECTED ) then
        local uniqueID = util.CRC(query .. tostring(onSuccess) .. tostring(onError))
        ax.util:PrintWarning("Database not connected, queuing query. (" .. uniqueID .. ")")

        self.queryQueue = self.queryQueue or {}
        table.insert(self.queryQueue, {query = query, onSuccess = onSuccess, onError = onError})

        if ( !self.queryTimerStarted ) then
            self.queryTimerStarted = true

            local startTime = SysTime()
            timer.Create("ax.sqloo.wait", 0.1, 0, function()
                if ( self.db and self.db:status() == mysqloo.DATABASE_CONNECTED ) then
                    timer.Remove("ax.sqloo.wait")
                    self.queryTimerStarted = false

                    for i = 1, #self.queryQueue do
                        local queuedQuery = self.queryQueue[i]
                        self:Query(queuedQuery.query, queuedQuery.onSuccess, queuedQuery.onError)

                        uniqueID = util.CRC(queuedQuery.query .. tostring(queuedQuery.onSuccess) .. tostring(queuedQuery.onError))
                        ax.util:PrintSuccess("Executing queued query: " .. uniqueID)
                    end

                    self.queryQueue = {}
                elseif ( SysTime() - startTime > 5 ) then
                    timer.Remove("ax.sqloo.wait")
                    self.queryTimerStarted = false

                    ax.util:PrintError("Database connection failed after 5 seconds. Aborting queued queries.")
                    self.queryQueue = {}
                else
                    ax.util:PrintWarning("Waiting for database connection...")
                end
            end)
        end

        return
    end

    local q = self.db:query(query)
    if ( !q ) then
        ax.util:PrintError("Failed to create query for: " .. query)

        if ( onError ) then
            onError("Failed to create query")
        end

        return
    end

    q.onSuccess = function(_, data)
        if ( onSuccess ) then
            onSuccess(data)
        end
    end

    q.onError = function(_, errString)
        ax.util:PrintError("Query failed: " .. errString)
        ax.util:PrintError("Query: " .. query)

        if ( onError ) then
            onError(errString)
        end
    end

    q:start()
    q:wait()

    return q
end

--- Escape
-- @realm server
-- @usage ax.sqloo:Escape
function ax.sqloo:Escape(str)
    return self.db and self.db:escape(str) or str
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

--- Counts the number of rows in a table.
-- @realm server
-- @usage ax.sqloo:Count
-- @tparam string tableName Table name
-- @tparam string condition Optional WHERE clause
-- @tparam function callback Optional callback with row count
function ax.sqloo:Count(tableName, condition, callback)
    local query = string.format("SELECT COUNT(*) AS count FROM `%s`", tableName)
    if ( condition ) then
        query = query .. " WHERE " .. condition
    end

    self:Query(query, function(result)
        local count = result and result[1] and tonumber(result[1].count) or 0
        if ( callback ) then
            callback(count)
        end
    end)
end

--- Prints the current database status in a human-readable format.
-- @realm server
-- @usage ax.sqloo:PrintStatus
function ax.sqloo:PrintStatus()
    local status = self:Status()
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
end

--- Cheks if the database is connected.
-- @realm server
-- @usage ax.sqloo:IsConnected
function ax.sqloo:IsConnected()
    return self.db and self.db:status() == mysqloo.DATABASE_CONNECTED
end