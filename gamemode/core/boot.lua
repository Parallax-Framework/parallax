GM.Name = "Parallax"
GM.Author = "Riggs and bloodycop6385"
GM.Description = "Parallax is a modular roleplay framework for Garry's Mod, built for performance, structure, and developer clarity."
GM.State = "Alpha"

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