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