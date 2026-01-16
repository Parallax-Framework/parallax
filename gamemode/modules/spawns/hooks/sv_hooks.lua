--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:OnSchemaLoaded()
    ax.spawns:Load()
end

function MODULE:PostPlayerSpawn(client)
    local factionData = client:GetFactionData()
    local classData = client:GetClassData()

    local randomSpawn = ax.spawns:GetRandomSpawn(factionData and factionData.id or nil, classData and classData.id or nil)
    if ( randomSpawn ) then
        client:SetPos(randomSpawn.position)
        client:SetEyeAngles(randomSpawn.angles)
    end
end
