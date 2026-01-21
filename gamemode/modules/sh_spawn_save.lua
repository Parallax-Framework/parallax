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
MODULE.description = "Saves character's spawn locations to their previous position."
MODULE.author = "Riggs"

function MODULE:OnCharacterDisconnected(character)
    local client = character:GetOwner()
    if ( !IsValid(client) ) then return end

    local position = client:GetPos()
    local angles = client:EyeAngles()
    character:SetData("spawn_save", {position, angles})
end

function MODULE:PlayerLoadedCharacter(client, character, previous)
    if ( CLIENT or !character ) then return end

    local spawnSave = character:GetData("spawn_save")
    if ( spawnSave ) then
        client:SetPos(spawnSave[1])
        client:SetEyeAngles(spawnSave[2])

        character:SetData("spawn_save", nil)
        character:Save()
    end
end
