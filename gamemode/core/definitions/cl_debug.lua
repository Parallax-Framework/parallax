--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local posFormat = "Vector(%f, %f, %f)"
concommand.Add("ax_debug_pos", function(client, cmd, args)
    if ( !isstring(args[1]) ) then
        args[1] = "local"
    end

    if ( args[1] == "hitpos" ) then
        local hitPos = client:GetEyeTrace().HitPos
        Parallax.Util:Print(string.format(posFormat, hitPos.x, hitPos.y, hitPoss.z))
    elseif ( args[1] == "local" ) then
        local localPos = client:GetPos()
        Parallax.Util:Print(string.format(posFormat, localPos.x, localPos.y, localPos.z))
    elseif ( args[1] == "entity" ) then
        local ent = client:GetEyeTrace().Entity
        if ( IsValid(ent) ) then
            local entPos = ent:GetPos()
            Parallax.Util:Print(string.format(posFormat, entPos.x, entPos.y, entPos.z))
        else
            Parallax.Util:Print("No valid entity under cursor.")
        end
    end
end)

local angFormat = "Angle(%f, %f, %f)"
concommand.Add("ax_debug_ang", function(client, cmd, args)
    if ( !isstring(args[1]) ) then
        args[1] = "local"
    end

    if ( args[1] == "hitang" ) then
        local hitNormal = client:GetEyeTrace().HitNormal
        Parallax.Util:Print(string.format(angFormat, hitNormal.p, hitNormal.y, hitNormal.r))
    elseif ( args[1] == "local" ) then
        local eyeAngles = client:EyeAngles()
        Parallax.Util:Print(string.format(angFormat, eyeAngles.p, eyeAngles.y, eyeAngles.r))
    elseif ( args[1] == "entity" ) then
        local ent = client:GetEyeTrace().Entity
        if ( IsValid(ent) ) then
            local entAngs = ent:GetAngles()
            Parallax.Util:Print(string.format(angFormat, entAngs.p, entAngs.y, entAngs.r))
        else
            Parallax.Util:Print("No valid entity under cursor.")
        end
    end
end)