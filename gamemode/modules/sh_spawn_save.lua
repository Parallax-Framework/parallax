--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "Spawn Save"
MODULE.description = "Saves characters' spawn locations to their previous positions."
MODULE.author = "Riggs"

function MODULE:OnCharacterDisconnected(character)
    local client = character:GetOwner()
    if ( !ax.util:IsValidPlayer(client) ) then return end

    local position = client:GetPos()
    local angles = client:EyeAngles()

    local data = ax.data:Get("spawn_save", {}, {
        scope = "map"
    })

    data[character:GetID()] = {
        position,
        angles
    }

    ax.data:Set("spawn_save", data, {
        scope = "map",
        human = true
    })
end

function MODULE:PlayerLoadedCharacter(client, character, previous)
    if ( CLIENT or !character ) then return end

    local data = ax.data:Get("spawn_save", {}, {
        scope = "map"
    })

    local spawn_save = data[character:GetID()]
    if ( spawn_save ) then
        client:SetPos(spawn_save[1])
        client:SetEyeAngles(spawn_save[2])

        data[character:GetID()] = nil

        ax.data:Set("spawn_save", data, {
            scope = "map",
            human = true
        })
    end
end
