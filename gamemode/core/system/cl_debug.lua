concommand.Add("ax_debug_pos", function(client, cmd, args)
    if ( isstring(args[1]) ) then
        if ( args[1] == "hitpos" ) then
            ax.util:Print(client:GetEyeTrace().HitPos)
        elseif ( args[1] == "local" ) then
            ax.util:Print(client:GetPos())
        elseif ( args[1] == "entity" ) then
            local ent = client:GetEyeTrace().Entity
            if ( IsValid(ent) ) then
                ax.util:Print(ent:GetPos())
            else
                ax.util:Print("No valid entity under cursor.")
            end
        end
    end
end)