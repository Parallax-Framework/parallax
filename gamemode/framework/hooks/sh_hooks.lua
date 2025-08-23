--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

function GM:Initialize()
    ax.module:Include("parallax/gamemode/modules")
    ax.schema:Initialize()
end

local reloaded = false
function GM:OnReloaded()
    if ( reloaded ) then return end
    reloaded = true

    ax.module:Include("parallax/gamemode/modules")
    ax.schema:Initialize()
end

function GM:CanBecomeFaction(factionTable, client)
    return true, nil
end

function GM:CanBecomeClass(classTable, client)
    return true, nil
end

function GM:CanLoadCharacter(client, character)
    return true
end