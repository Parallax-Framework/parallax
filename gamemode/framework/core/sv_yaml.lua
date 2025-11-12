local yaml = ax.yaml.Read("gamemodes/" .. engine.ActiveGamemode() .. "/database.yml")
if ( !yaml or !yaml.database ) then
    ax.util:PrintWarning("Database YAML configuration not found or invalid, proceeding with sqlite.")
    yaml = {}
else
    yaml = yaml.database
end

ax.database.server = yaml
