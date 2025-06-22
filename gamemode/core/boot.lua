--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

GM.Name = "Parallax"
GM.Author = "Riggs and bloodycop6385"
GM.Description = "Parallax is a modular roleplay framework for Garry's Mod, built for performance, structure, and developer clarity."
GM.State = "Beta"

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