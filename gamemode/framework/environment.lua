ax.ENV = ax.ENV or {}
ax.ENV.name = "prod"

function ax:IsDevEnvironment()
    return ax.ENV.name != "prod"
end
