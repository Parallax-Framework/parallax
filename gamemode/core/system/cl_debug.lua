local posFormat = "Vector(%f, %f, %f)"
concommand.Add("ax_debug_pos", function(client, cmd, args)
    if ( !isstring(args[1]) ) then
        args[1] = "local"
    end

    if ( isstring(args[1]) ) then
        if ( args[1] == "hitpos" ) then
            local hitPos = client:GetEyeTrace().HitPos
            ax.util:Print(string.format(posFormat, hitPos.x, hitPos.y, hitPoss.z))
        elseif ( args[1] == "local" ) then
            local localPos = client:GetPos()
            ax.util:Print(string.format(posFormat, localPos.x, localPos.y, localPos.z))
        elseif ( args[1] == "entity" ) then
            local ent = client:GetEyeTrace().Entity
            if ( IsValid(ent) ) then
                local entPos = ent:GetPos()
                ax.util:Print(string.format(posFormat, entPos.x, entPos.y, entPos.z))
            else
                ax.util:Print("No valid entity under cursor.")
            end
        end
    end
end)

local angFormat = "Angle(%f, %f, %f)"
concommand.Add("ax_debug_ang", function(client, cmd, args)
    if ( isstring(args[1]) ) then
        if ( args[1] == "hitang" ) then
            local hitNormal = client:GetEyeTrace().HitNormal
            ax.util:Print(string.format(angFormat, hitNormal.p, hitNormal.y, hitNormal.r))
        elseif ( args[1] == "local" ) then
            local eyeAngles = client:EyeAngles()
            ax.util:Print(string.format(angFormat, eyeAngles.p, eyeAngles.y, eyeAngles.r))
        elseif ( args[1] == "entity" ) then
            local ent = client:GetEyeTrace().Entity
            if ( IsValid(ent) ) then
                local entAngs = ent:GetAngles()
                ax.util:Print(string.format(angFormat, entAngs.p, entAngs.y, entAngs.r))
            else
                ax.util:Print("No valid entity under cursor.")
            end
        end
    end
end)