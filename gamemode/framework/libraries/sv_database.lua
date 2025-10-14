--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Database management system for handling connections, schema definitions, and table creation.
-- Utilizes the mysqloo module for MySQL connectivity and operations.
-- Originally adapted from the Helix framework with modifications for the Parallax framework.
-- @module ax.database

ax.database = ax.database or {
    schema = {},
    schemaQueue = {},
    type = {
        [ax.type.string] = "VARCHAR(255)",
        [ax.type.text] = "TEXT",
        [ax.type.number] = "INT(11)",
        [ax.type.steamid] = "VARCHAR(19)",
        [ax.type.steamid64] = "VARCHAR(17)",
        [ax.type.bool] = "TINYINT(1)",
    }
}

function ax.database:Connect(module, hostname, user, password, database, port)
    module = module or "sqlite"
    hostname = hostname or "localhost"
    user = user or "root"
    password = password or ""
    database = database or "parallax"
    port = port or 3306

    mysql:SetModule(module)
    mysql:Connect(hostname, user, password, database, port)
end

function ax.database:AddToSchema(schemaType, field, fieldType)
    if ( !self.type[fieldType] ) then
        error(string.format("attempted to add field in schema with invalid type '%s'", fieldType))
        return
    end

    if ( !mysql:IsConnected() or !self.schema[schemaType] ) then
        self.schemaQueue[#self.schemaQueue + 1] = {schemaType, field, fieldType}
        return
    end

    self:InsertSchema(schemaType, field, fieldType)
end

-- this is only ever used internally
function ax.database:InsertSchema(schemaType, field, fieldType)
    local schema = self.schema[schemaType]
    if ( !schema ) then
        error(string.format("attempted to insert into schema with invalid schema type '%s'", schemaType))
        return
    end

    if ( !schema[field] ) then
        schema[field] = true

        local query = mysql:Update("ax_schema")
            query:Update("columns", util.TableToJSON(schema))
            query:Where("table", schemaType)
        query:Execute()

        query = mysql:Alter(schemaType)
            query:Add(field, self.type[fieldType])
        query:Execute()
    end
end

function ax.database:CreateTables()
    local query

    query = mysql:Create("ax_schema")
        query:Create("table", "VARCHAR(64) NOT NULL")
        query:Create("columns", "TEXT NOT NULL")
        query:PrimaryKey("table")
    query:Execute()

    query = mysql:Create("ax_players")
        query:Create("steamid64", "VARCHAR(17) NOT NULL")
        query:PrimaryKey("steamid64")
    query:Execute()

    query = mysql:Create("ax_characters")
        query:Create("id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
        query:PrimaryKey("id")
    query:Execute()

    query = mysql:Create("ax_inventories")
        query:Create("id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
        query:Create("items", "LONGTEXT NOT NULL")
        query:Create("max_weight", "FLOAT NOT NULL DEFAULT 30.0")
        query:Create("data", "LONGTEXT NOT NULL")
        query:PrimaryKey("id")
    query:Execute()

    query = mysql:Create("ax_items")
        query:Create("id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
        query:Create("class", "VARCHAR(64) NOT NULL")
        query:Create("inventory_id", "INT(11) UNSIGNED NOT NULL")
        query:Create("data", "LONGTEXT NOT NULL")
        query:PrimaryKey("id")
    query:Execute()

    query = mysql:InsertIgnore("ax_schema")
        query:Insert("table", "ax_characters")
        query:Insert("columns", util.TableToJSON({}))
    query:Execute()

    query = mysql:InsertIgnore("ax_schema")
        query:Insert("table", "ax_players")
        query:Insert("columns", util.TableToJSON({}))
    query:Execute()

    -- load schema from database
    query = mysql:Select("ax_schema")
        query:Callback(function(result)
            if ( !istable(result) ) then return end

            for _, v in pairs(result) do
                self.schema[v.table] = util.JSONToTable(v.columns)
            end

            -- update schema if needed
            for i = 1, #self.schemaQueue do
                local entry = self.schemaQueue[i]
                self:InsertSchema(entry[1], entry[2], entry[3])
            end
        end)
    query:Execute()

    hook.Run("OnDatabaseTablesCreated")
end

concommand.Add("ax_database_create", function(client, command, args, argStr)
    if ( !IsValid(client) or !client:IsSuperAdmin() ) then
        ax.util:PrintError("You do not have permission to use this command.")
        return
    end

    ax.database:CreateTables()
    ax.util:Print(Color(0, 255, 0), "Database tables created successfully.")
end)

function ax.database:WipeTables(callback)
    local query

    query = mysql:Delete("ax_schema")
    query:Execute()

    query = mysql:Delete("ax_players")
    query:Execute()

    query = mysql:Delete("ax_characters")
    query:Execute()

    query = mysql:Delete("ax_inventories")
    query:Execute()

    query = mysql:Delete("ax_items")
        query:Callback(function()
            if ( isfunction(callback) ) then
                callback()
            end
        end)
    query:Execute()

    self.schema = {}
    self.schemaQueue = {}

    hook.Run("OnDatabaseTablesWiped")
end

concommand.Add("ax_database_wipe", function(client, command, args, argStr)
    if ( IsValid(client) or !client:IsSuperAdmin() ) then
        ax.util:PrintError("You do not have permission to use this command.")
        return
    end

    ax.database:WipeTables(function()
        ax.util:Print(Color(255, 255, 0), "Database tables wiped successfully.")
    end)
end)

function ax.database:DestroyTables(callback)
    local query

    query = mysql:Drop("ax_schema")
    query:Execute()

    query = mysql:Drop("ax_players")
    query:Execute()

    query = mysql:Drop("ax_characters")
    query:Execute()

    query = mysql:Drop("ax_inventories")
    query:Execute()

    query = mysql:Drop("ax_items")
        query:Callback(function()
            if ( isfunction(callback) ) then
                callback()
            end
        end)
    query:Execute()

    self.schema = {}
    self.schemaQueue = {}

    hook.Run("OnDatabaseTablesWiped")
end

concommand.Add("ax_database_destroy", function(client, command, args, argStr)
    if ( IsValid(client) and !client:IsSuperAdmin() ) then
        ax.util:PrintError("You do not have permission to use this command.")
        return
    end

    ax.database:DestroyTables(function()
        ax.util:Print(Color(255, 0, 0), "Database tables destroyed successfully.")
    end)
end)
