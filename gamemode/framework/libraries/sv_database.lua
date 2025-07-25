ax.database = ax.database or {
    schema = {},
    schemaQueue = {},
    type = {
        [ax.type.string] = "VARCHAR(255)",
        [ax.type.text] = "TEXT",
        [ax.type.number] = "INT(11)",
        [ax.type.steamid] = "VARCHAR(20)",
        [ax.type.bool] = "TINYINT(1)",
    }
}

function ax.database:Connect(module, hostname, user, password, database, port)
    mysql:SetModule(module)
    mysql:Connect(hostname, user, password, database, port)
end

function ax.database:AddToSchema(schemaType, field, fieldType)
    if ( !self.type[fieldType] ) then
        error(string.format("attempted to add field in schema with invalid type '%s'", fieldType))
        return
    end

    if (!mysql:IsConnected() or !self.schema[schemaType]) then
        self.schemaQueue[#self.schemaQueue + 1] = {schemaType, field, fieldType}
        return
    end

    self:InsertSchema(schemaType, field, fieldType)
end

-- this is only ever used internally
function ax.database:InsertSchema(schemaType, field, fieldType)
    local schema = self.schema[schemaType]

    if (!schema) then
        error(string.format("attempted to insert into schema with invalid schema type '%s'", schemaType))
        return
    end

    if (!schema[field]) then
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

    query = mysql:Create("ax_characters")
        query:Create("id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
        query:Create("schema", "VARCHAR(64) NOT NULL")
        query:PrimaryKey("id")
    query:Execute()

    query = mysql:InsertIgnore("ax_schema")
        query:Insert("table", "ax_characters")
        query:Insert("columns", util.TableToJSON({}))
    query:Execute()

    -- load schema from database
    query = mysql:Select("ax_schema")
        query:Callback(function(result)
            if (!istable(result)) then
                return
            end

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
end

hook.Add("InitPostEntity", "ax.database.Connect", function()
    ax.database:Connect("sqlite")
end)