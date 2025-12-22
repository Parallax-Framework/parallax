local MODULE = MODULE

MODULE.name = "Admin"
MODULE.description = "Handles admin-related functionality."
MODULE.author = "Riggs"

ax.player:RegisterVar("usergroup", {
    field = "usergroup",
    fieldType = ax.type.string,
    default = "user"
})

concommand.Add("ax_player_set_usergroup", function(client, command, arguments, argumentsString)
    if ( !client:IsSuperAdmin() ) then return end
    if ( #arguments < 2 ) then return end

    local target = ax.util:FindPlayer(arguments[1])
    if ( !IsValid(target) ) then
        ax.util.NotifyError(client, "Player not found!")
        return
    end

    local usergroup = arguments[2]
    target:SetUserGroup(usergroup)
    target:SetUsergroup(usergroup) -- Update the player var as well
    target:Save()

    for _, v in player.Iterator() do
        v:Notify(client:Nick() .. " has set " .. target:Nick() .. "'s usergroup to " .. usergroup .. ".")
    end
end)
