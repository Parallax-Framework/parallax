ax.ENV = ax.ENV or {}

CreateConVar("ax_environment_name", "prod", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The current environment name")
ax.ENV.name = GetConVar("ax_environment_name"):GetString()

cvars.AddChangeCallback("ax_environment_name", function(convar, old, new)
    ax.ENV.name = new
    SetRelay("env_name", new)
end, "ax_env_update")

function ax.ENV:IsDev()
    return SERVER and self.name != "prod" or GetRelay("env_name") != "prod"
end
