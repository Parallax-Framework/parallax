--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.character = ax.character or {}
ax.character.instances = ax.character.instances or {}

function ax.character:InstanceObject()
    local character = setmetatable({}, ax.meta.character)
    -- bloodycop6385 @ TODO: Uh, move to character variables?
    character.data = {}

    -- TOOD: Change to DB
    character.id = #ax.character.instances + 1

    ax.character.instances[character.id] = character

    return character
end

function ax.character:Get(id)
    if ( !isnumber(id) ) then
        ax.util:PrintError("Invalid character ID provided to ax.character:Get()")
        return nil
    end

    return ax.character.instances[id]
end