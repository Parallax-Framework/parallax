ax.ENV = ax.ENV or {}
ax.ENV.name = "dev"

function ax:IsDevEnvironment()
    return ax.ENV.name != "prod"
end
