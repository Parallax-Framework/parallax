GM.Name = "Parallax"
GM.Author = "Riggs"
GM.Description = "Parallax is a modular roleplay framework for Garry's Mod, built for performance, structure, and developer clarity."
GM.Version = "1.4.5"
GM.ProductionState = "Alpha"

local colorSuccess = Color(120, 255, 120)
local colorWarning = Color(255, 200, 120)

local versionFetchHttp = "https://raw.githubusercontent.com/bloodycop6385/parallax/refs/heads/main/version.txt"
http.Fetch(versionFetchHttp, function(body)
    if ( GAMEMODE.Version != body ) then
        ax.util:PrintWarning("You are running an outdated version of Parallax! Please update to the latest version: " .. body)

        for k, v in player.Iterator() do
            v:ChatText(colorWarning, "You are running an outdated version of Parallax! Please update to the latest version: ", body)
        end
    else
        ax.util:PrintSuccess("Parallax is up to date.")

        for k, v in player.Iterator() do
            v:ChatText(colorSuccess, "Parallax is up to date. Version: ", body)
        end
    end
end)

ax.util:Print("Framework Initializing...")
ax.util:LoadFolder("libraries/external")
ax.util:LoadFolder("libraries/client")
ax.util:LoadFolder("libraries/shared")
ax.util:LoadFolder("libraries/server")
ax.util:LoadFolder("definitions")
ax.util:LoadFolder("meta")
ax.util:LoadFolder("ui")
ax.util:LoadFolder("hooks")
ax.util:LoadFolder("net")
ax.util:LoadFolder("languages")
ax.util:Print("Framework Initialized.")

function widgets.PlayerTick()
end

hook.Remove("PlayerTick", "TickWidgets")