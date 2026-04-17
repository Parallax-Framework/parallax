ax.ENV = ax.ENV or {}

local ax_environment_name = CreateConVar("ax_environment_name", "prod", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The environment the server is running in")
ax.ENV.name = ax_environment_name:GetString()

cvars.RemoveChangeCallback("ax_environment_name", "ax_env_update")
cvars.AddChangeCallback("ax_environment_name", function(convar, old, new)
    ax.ENV.name = new
    BroadcastLua("ax.ENV.name = \"" .. new .. "\"")
end, "ax_env_update")
function ax.ENV:IsDev()
    return self.name != "prod" or GetConVar("developer"):GetInt() > 0
end
