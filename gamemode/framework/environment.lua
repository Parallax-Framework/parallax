ax.ENV = ax.ENV or {}

CreateConVar("ax_environment_name", "prod", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The current environment name")
ax.ENV.name = GetConVar("ax_environment_name"):GetString()

cvars.AddChangeCallback("ax_environment_name", function(convar, old, new)
    ax.ENV.name = new
end)

function ax.ENV:IsDev()
    return self.name != "prod"
end
