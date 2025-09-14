--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

GM.Name = "Parallax"
GM.Author = "Parallax Framework Contributors"
GM.Website = "https://project-ordinance.com/parallax/"
GM.Email = "<email@example.com>"

LocalPlayerInternal = LocalPlayerInternal or LocalPlayer
function LocalPlayer()
    if ( IsValid( ax.client ) ) then
        LocalPlayer = function() return ax.client end
    end

    return LocalPlayerInternal()
end

ax.util:IncludeDirectory("libraries")
ax.util:IncludeDirectory("meta")
ax.util:IncludeDirectory("core")
ax.util:IncludeDirectory("hooks")
ax.util:IncludeDirectory("networking")
ax.util:IncludeDirectory("interface")
