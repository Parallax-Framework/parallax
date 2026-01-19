--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Map scene networking (server).
-- @module ax.mapscene

ax.net:Hook("mapscene.pvs", function(client, origin)
    if ( !IsValid(client) ) then return end

    if ( ax.mapscene:IsValidVector(origin) ) then
        client.axMapSceneOrigin = origin

        local character = client.GetCharacter and client:GetCharacter() or nil
        if ( !character ) then
            local last = client.axMapSceneTeleport
            if ( !isvector(last) or last:DistToSqr(origin) > 4 ) then
                client:SetPos(origin)
                debugoverlay.Sphere(origin, 512, 1, Color(0, 255, 0, 10), true)
                client.axMapSceneTeleport = origin
            end
        else
            client.axMapSceneTeleport = nil
        end
    else
        client.axMapSceneOrigin = nil
        client.axMapSceneTeleport = nil
    end
end)
