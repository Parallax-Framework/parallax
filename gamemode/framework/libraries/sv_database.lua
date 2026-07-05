--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

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
        [ax.type.data] = "TEXT",
    }
}

--- Connect to the database using specified parameters.
-- Establishes connection using mysqloo module with configurable database settings.
-- @realm server
-- @param module string Database module type (default: "sqlite")
-- @param hostname string Database hostname (default: "localhost")
-- @param user string Database username (default: "root")
-- @param password string Database password (default: "")
-- @param database string Database name (default: "parallax")
-- @param port number Database port (default: 3306)
-- @usage ax.database:Connect("mysql", "localhost", "user", "pass", "gamedb")
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

--- Add a field to the database schema.
-- Adds a new field to a specified table schema, handling queuing if database isn't ready.
-- @realm server
-- @param schemaType string The table name to add the field to
-- @param field string The field name to add
-- @param fieldType number The ax.type constant for the field type
-- @usage ax.database:AddToSchema("ax_characters", "description", ax.type.text)
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

--- Insert a field into the database schema (internal use).
-- Directly modifies database schema and table structure.
-- @realm server
-- @param schemaType string The table name
-- @param field string The field name
-- @param fieldType number The ax.type constant for the field type
-- @param callback function Optional callback to run when schema insert completes
-- @usage ax.database:InsertSchema("ax_characters", "description", ax.type.text)
function ax.database:InsertSchema(schemaType, field, fieldType, callback)
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
            query:Callback(function()
                if ( isfunction(callback) ) then
                    callback()
                end
            end)
        query:Execute()
    else
        -- Field already exists, call callback immediately
        if ( isfunction(callback) ) then
            callback()
        end
    end
end

--- Create the default database tables for the framework.
-- Sets up schema tracking, players, characters, and inventories tables.
-- @realm server
-- @usage ax.database:CreateTables()
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

    -- type_id/owner_kind/owner_id (ax_inventories) and placement (ax_items) are purely
    -- additive columns, defined ONLY here through the schema tracker (never in the
    -- CREATE TABLE above). Queued as ALTER ... ADD COLUMN (never DROP/MODIFY) so both
    -- fresh and pre-existing tables converge on the same schema through a single code
    -- path - a fresh table gets the base columns from CREATE and these via the ALTER,
    -- exactly like an existing table that predates them. Every insert supplies these
    -- columns explicitly (see sh_inventory.lua / sv_item.lua), so the SQL-level DEFAULTs
    -- they used to carry are not load-bearing. Existing rows and data are untouched;
    -- every legacy inventory row implicitly resolves to the "weight" type via
    -- ax.inventory:GetType()'s default, so this is pure back-compat, not a migration.
    -- `placement` is a single type-owned JSON blob (keys like `gridX`/`gridY`/`slotID`
    -- - whatever the inventory's type puts in GetSyncFields, see sh_inventory_types.lua)
    -- rather than one dedicated column per addressing scheme, so a new inventory type
    -- never needs its own schema migration to store its placement data. Kept separate
    -- from the item's own `data` column (item-class-owned, arbitrary keys) so the two
    -- namespaces can never collide.
    self:AddToSchema("ax_inventories", "type_id", ax.type.string)
    self:AddToSchema("ax_inventories", "owner_kind", ax.type.string)
    self:AddToSchema("ax_inventories", "owner_id", ax.type.number)
    self:AddToSchema("ax_items", "placement", ax.type.text)

    query = mysql:InsertIgnore("ax_schema")
        query:Insert("table", "ax_characters")
        query:Insert("columns", util.TableToJSON({}))
    query:Execute()

    query = mysql:InsertIgnore("ax_schema")
        query:Insert("table", "ax_players")
        query:Insert("columns", util.TableToJSON({}))
    query:Execute()

    -- ax_inventories/ax_items need schema-tracker rows too, otherwise the
    -- AddToSchema() calls above have nothing to register their queued columns
    -- against once the SELECT below populates self.schema (InsertSchema errors on
    -- an untracked table). Seeded EMPTY (`{}`) - the additive columns must NOT be
    -- pre-listed here, or InsertSchema sees them as already-present and skips the
    -- ALTER, leaving the physical table without the column. On a fresh install the
    -- tracker starts empty and every AddToSchema entry ALTERs its column in; on a
    -- pre-existing install (which never had a tracker row before) this INSERT seeds
    -- the empty row and the same ALTERs add whatever columns are genuinely missing.
    query = mysql:InsertIgnore("ax_schema")
        query:Insert("table", "ax_inventories")
        query:Insert("columns", util.TableToJSON({}))
    query:Execute()

    query = mysql:InsertIgnore("ax_schema")
        query:Insert("table", "ax_items")
        query:Insert("columns", util.TableToJSON({}))
    query:Execute()

    -- load schema from database
    query = mysql:Select("ax_schema")
        query:Callback(function(result)
            if ( !istable(result) ) then return end

            for _, v in pairs(result) do
                self.schema[v.table] = ax.util:SafeParseTable(v.columns)
            end

            -- Runs after the additive columns are guaranteed to exist (freshly ALTERed in
            -- this same callback, or already present) - the owner backfill reads/writes
            -- owner_kind/owner_id, so it can't run until they're there. OnDatabaseTablesCreated
            -- fires only after it so consumers see a fully-migrated schema.
            local function finalize()
                self:MigrateLegacyInventoryOwners(function()
                    hook.Run("OnDatabaseTablesCreated")
                end)
            end

            -- update schema if needed
            local queueCount = #self.schemaQueue
            if ( queueCount == 0 ) then
                -- No schema updates needed, run the migration and fire the hook.
                finalize()
                return
            end

            local completedCount = 0
            for i = 1, queueCount do
                local entry = self.schemaQueue[i]
                self:InsertSchema(entry[1], entry[2], entry[3], function()
                    completedCount = completedCount + 1

                    -- Only migrate + fire the hook once every schema insertion is complete
                    if ( completedCount >= queueCount ) then
                        finalize()
                    end
                end)
            end
        end)
    query:Execute()
end

--- Back-compat migration: populate owner_kind/owner_id on inventory rows that predate the
-- ownership model. Older installs linked a character to its inventory only through the legacy
-- `ax_characters.inventory` column; the type/ownership rewrite loads inventories by
-- owner_kind/owner_id instead (see ax.inventory:Restore/RestoreOwner), so those pre-existing
-- rows - owner columns NULL after the additive ALTER - would never load and every character
-- would report no valid inventory. This copies each character's legacy link into the owner
-- columns.
-- @realm server
-- @param callback function Optional callback run once when the migration has finished dispatching.
-- @usage ax.database:MigrateLegacyInventoryOwners()
function ax.database:MigrateLegacyInventoryOwners(callback)
    local query = mysql:Select("ax_characters")
        query:Select("id")
        query:Select("inventory")
        query:Callback(function(result, status)
            if ( !istable(result) or status == false or result[1] == nil ) then
                if ( isfunction(callback) ) then callback() end
                return
            end

            for i = 1, #result do
                local characterID = tonumber(result[i].id)
                local inventoryID = tonumber(result[i].inventory)
                if ( characterID == nil or inventoryID == nil or inventoryID < 1 ) then continue end

                -- The `owner_kind IS NULL` guard (a Where with a nil value, see sv_mysql)
                -- makes this a one-time backfill - an already-owned or reassigned inventory
                -- is left untouched no matter how many times this runs, so it is safe on
                -- every boot and no-ops on already-migrated and freshly-created installs.
                local update = mysql:Update("ax_inventories")
                    update:Update("owner_kind", "character")
                    update:Update("owner_id", characterID)
                    update:Where("id", inventoryID)
                    update:Where("owner_kind", nil)
                update:Execute()
            end

            if ( isfunction(callback) ) then callback() end
        end)
    query:Execute()
end

concommand.Add("ax_database_create", function(client, command, args, argStr)
    if ( !ax.util:IsValidPlayer(client) or !client:IsSuperAdmin() ) then
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
    if ( ax.util:IsValidPlayer(client) or !client:IsSuperAdmin() ) then
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
    if ( ax.util:IsValidPlayer(client) and !client:IsSuperAdmin() ) then
        ax.util:PrintError("You do not have permission to use this command.")
        return
    end

    ax.database:DestroyTables(function()
        ax.util:Print(Color(255, 0, 0), "Database tables destroyed successfully.")
    end)
end)
