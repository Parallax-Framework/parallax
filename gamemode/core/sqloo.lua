-- Detect if mysqloo binary exists before requiring
local function hasMysqlooBinary()
    local osName = jit.os:lower()
    local arch = jit.arch == "x64" and "win64" or "win32"

    if ( osName == "osx" ) then arch = "osx" end
    if ( osName == "linux" ) then arch = "linux" end

    local binaryName = "gmsv_mysqloo_" .. arch .. ".dll"
    if ( osName == "linux" ) then binaryName = "gmsv_mysqloo_linux.dll" end
    if ( osName == "osx" ) then binaryName = "gmsv_mysqloo_osx.dll" end

    return file.Exists("lua/bin/" .. binaryName, "GAME")
end

if ( !hasMysqlooBinary() ) then
    ax.util:PrintWarning("MySQLOO binary not found in lua/bin/. ax.sqloo disabled.")
    return
end

-- Now safe to require
local success, err = pcall(require, "mysqloo")
if ( !success or !mysqloo ) then
    ax.util:PrintWarning("Failed to load MySQLOO module: " .. (err or "unknown"))
    return
end

--- Parallax MySQLOO Database Wrapper
-- Provides a wrapper around the mysqloo module for async MySQL access
-- @module ax.sqloo

ax.sqloo = ax.sqloo or {}
ax.sqloo.config = nil
ax.sqloo.db = nil
ax.sqloo.tables = ax.sqloo.tables or {}

--- Initializes the MySQL connection with the given config.
-- @tparam table config Connection config {host, username, password, database, port (optional)}
-- @usage ax.sqloo:Initialize({ host = "localhost", username = "root", password = "", database = "gmod", port = 3306 })
function ax.sqloo:Initialize(config)
    self.config = config

    local db = mysqloo.connect(
        config.host,
        config.username,
        config.password,
        config.database,
        config.port or 3306
    )

    db.onConnected = function()
        ax.util:PrintSuccess("Connected to MySQL server.")

        hook.Run("DatabaseConnected")
    end

    db.onConnectionFailed = function(_, err)
        ax.util:PrintError("MySQL connection failed: " .. err .. "\n")

        hook.Run("DatabaseConnectionFailed", err)
    end

    db:connect()

    self.db = db
end

--- Executes a raw SQL query.
-- @tparam string query SQL query string
-- @tparam function onSuccess Called with query data (table)
-- @tparam function onError Called with error message (string)
-- @usage ax.sqloo:Query("SELECT * FROM users", print, print)
function ax.sqloo:Query(query, onSuccess, onError)
    if ( !self.db or self.db:status() != mysqloo.DATABASE_CONNECTED ) then
        ax.util:PrintError("Database not connected.")
        return
    end

    local q = self.db:query(query)
    q.onSuccess = function(_, data)
        if ( onSuccess ) then
            onSuccess(data)
        end
    end

    q.onError = function(_, err)
        ax.util:PrintError("Query failed: " .. err)
        ax.util:PrintError("Query: " .. query)

        if ( onError ) then
            onError(err)
        end
    end

    q:start()

    return q
end

--- Escapes a string for safe usage in a query.
-- @tparam string str Raw input string
-- @treturn string Escaped string
-- @usage local safe = ax.sqloo:Escape("O'Reilly")
function ax.sqloo:Escape(str)
    return self.db and self.db:escape(str) or str
end

--- Returns the active database object.
-- @treturn Database mysqloo database object
function ax.sqloo:GetDB()
    return self.db
end

--- Returns the current connection status.
-- @treturn number mysqloo.DATABASE_* status enum
function ax.sqloo:Status()
    return self.db and self.db:status() or mysqloo.DATABASE_NOT_CONNECTED
end

--- Forces reconnection using stored config.
function ax.sqloo:Reconnect()
    if ( self.config ) then
        self:Initialize(self.config)
    end
end

--- Registers a variable for a table and adds the column if necessary.
-- @tparam string tableName The name of the table
-- @tparam string key Column name
-- @tparam any default Default value
function ax.sqloo:RegisterVar(tableName, key, default)
    self.tables[tableName] = self.tables[tableName] or {}
    self.tables[tableName][key] = default

    local columnType = isnumber(default) and "INT"
        or isstring(default) and "TEXT"
        or isbool(default) and "BOOLEAN"
        or "TEXT"

    self:AddColumn(tableName, key, columnType, default)
end

--- Adds a column to an existing MySQL table if it doesn't already exist.
-- @tparam string tableName The name of the table
-- @tparam string columnName The name of the column to add
-- @tparam string columnType SQL type of the column (e.g. "INT", "TEXT")
-- @tparam any defaultValue Optional default value
-- @usage ax.sqloo:AddColumn("ax_players", "play_time", "INT", 0)
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

--- Create table if it doesn't exist with registered + extra schema
-- @tparam string tableName Table name
-- @tparam table extraSchema Extra schema to add
-- @usage ax.sqloo:InitializeTable("users", { last_login = "DATETIME" })
function ax.sqloo:InitializeTable(tableName, extraSchema)
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
        schema.id = "VARCHAR(32) PRIMARY KEY"
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

--- Insert row into table
-- @tparam string tableName Table name
-- @tparam table data Data to insert
-- @tparam function callback Optional callback after insert
-- @usage ax.sqloo:Insert("users", { steamid = "STEAM_0:1:123456", age = 25 })
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

--- Select rows with optional columns and condition
-- @tparam string tableName Table name
-- @tparam table columns Optional columns to select
-- @tparam string condition Optional condition for WHERE clause
-- @tparam function callback Optional callback with result
-- @usage ax.sqloo:Select("users", {"steamid", "age"}, "age > 18", function(result) print(result) end)
function ax.sqloo:Select(tableName, columns, condition, callback)
    local cols = columns and table.concat(columns, ", ") or "*"
    local query = string.format("SELECT %s FROM `%s`", cols, tableName)

    if ( condition ) then
        query = query .. " WHERE " .. condition
    end

    self:Query(query, callback)
end

--- Update rows in a table
-- @tparam string tableName Table name
-- @tparam table data Data to update
-- @tparam string condition WHERE clause
-- @tparam function callback Optional callback after update
-- @usage ax.sqloo:Update("users", { data = { something = true } }, "steamid = 'STEAM_X'", ...)
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

--- Delete rows from a table
-- @tparam string tableName Table name
-- @tparam string condition Condition for WHERE clause
-- @tparam function callback Optional callback after delete
-- @usage ax.sqloo:Delete("users", "steamid = 'STEAM_0:1:123456'", function() print("Deleted!") end)
function ax.sqloo:Delete(tableName, condition, callback)
    local query = string.format("DELETE FROM `%s` WHERE %s;", tableName, condition)
    self:Query(query, function()
        if ( callback ) then
            callback()
        end
    end)
end

--- Get default row from schema
-- @tparam string tableName Table name
-- @tparam table override Optional override values
-- @treturn table Default row with schema values
-- @usage local defaultRow = ax.sqloo:GetDefaultRow("users", { age = 30 })
function ax.sqloo:GetDefaultRow(tableName, override)
    local data = table.Copy(self.tables[tableName] or {})
    for k, v in pairs(override or {}) do
        data[k] = v
    end

    return data
end

--- Load or insert default row if not found
-- @tparam string tableName Table name
-- @tparam string key Key to match (e.g. "steamid")
-- @tparam any value Value to match
-- @tparam function callback Optional callback with row data
-- @usage ax.sqloo:LoadRow("users", "steamid", "STEAM_0:1:123456", function(row) print(row) end)
-- @usage ax.sqloo:LoadRow("users", "steamid", "STEAM_0:1:123456", function(row) print(row.age) end)
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

--- Save entire row by key
-- @tparam string tableName Table name
-- @tparam table data Data to save
-- @tparam string key Key to match (e.g. "steamid")
-- @tparam function callback Optional callback after save
-- @usage ax.sqloo:SaveRow("users", { steamid = "STEAM_0:1:123456", age = 26 }, "steamid", function() print("Saved!") end)
function ax.sqloo:SaveRow(tableName, data, key, callback)
    local condition = string.format("`%s` = %s", key, self:Escape(data[key]))
    self:Update(tableName, data, condition, callback)
end