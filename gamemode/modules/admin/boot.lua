local MODULE = MODULE

MODULE.name = "Admin"
MODULE.description = "Handles admin-related functionality."
MODULE.author = "Riggs"

concommand.Add("ax_player_set_usergroup", function(client, command, arguments, argumentsString)
    if ( IsValid(client) and !client:IsAdmin() ) then
        client:Notify("You do not have permission to use this command.")
        return
    end

    if ( #arguments < 2 ) then return end

    local target = ax.util:FindPlayer(arguments[1])
    if ( !IsValid(target) ) then
        if ( IsValid(client) ) then
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

    if ( IsValid(target) ) then
        target:Notify(Format("Your usergroup has been set to %s by %s.", usergroup, IsValid(client) and client:SteamName() or "Console"))
    end

    if ( IsValid(client) ) then
        client:Notify(Format("You have set %s's usergroup to %s.", target:SteamName(), usergroup))
    else
        ax.util:Print(Format("You have set %s's usergroup to %s.", target:SteamName(), usergroup))
    end
end)
