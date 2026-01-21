local MODULE = MODULE

MODULE.name = "Admin"
MODULE.description = "Handles admin-related functionality."
MODULE.author = "Riggs"

ax.admin = MODULE

concommand.Add("ax_player_set_usergroup", function(client, command, arguments, argumentsString)
    if ( ax.util:IsValidPlayer(client) and !client:IsAdmin() ) then
        client:Notify("You do not have permission to use this command.")
        return
    end

    if ( #arguments < 2 ) then
        if ( ax.util:IsValidPlayer(client) ) then
            client:Notify("Usage: ax_player_set_usergroup <player> <usergroup>")
        else
            ax.util:Print("Usage: ax_player_set_usergroup <player> <usergroup>")
        end

        return
    end

    local target = ax.util:FindPlayer(arguments[1])
    if ( !ax.util:IsValidPlayer(target) ) then
        if ( ax.util:IsValidPlayer(client) ) then
            client:Notify("You must specify a valid player to set the usergroup for.")
        else
            ax.util:PrintWarning("You must specify a valid player to set the usergroup for.")
        end

        return
    end

    local usergroup = arguments[2]
    target:SetUserGroup(usergroup)
    target:SetUsergroup(usergroup) -- Update the player var as well
    target:Save()

    if ( ax.util:IsValidPlayer(target) ) then
        target:Notify(Format("Your usergroup has been set to %s by %s.", usergroup, ax.util:IsValidPlayer(client) and client:SteamName() or "Console"))
    end

    if ( ax.util:IsValidPlayer(client) ) then
        client:Notify(Format("You have set %s's usergroup to %s.", target:SteamName(), usergroup))
    else
        ax.util:Print(Format("You have set %s's usergroup to %s.", target:SteamName(), usergroup))
    end
end)
