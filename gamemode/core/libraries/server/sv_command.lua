--- Command library
-- @module ax.command

--- Runs a command.
-- @realm server
-- @player client The player running the command.
-- @string command The command to run.
-- @tab arguments The arguments of the command.
function ax.command:Run(client, command, arguments)
    if ( !IsValid(client) ) then
        ax.util:PrintError("Attempted to run a command with no player!")
        return false
    end

    if ( !isstring(command) ) then
        client:Notify("You must provide a command to run!")
        return false
    end

    local info = self:Get(command)
    if ( !istable(info) ) then
        client:Notify("This command does not exist!")
        return false
    end

    if ( !tobool(CAMI) ) then
        if ( info.AdminOnly and !client:IsAdmin() ) then
            client:Notify("You must be an admin to run this command!")
            return false
        end

        if ( info.SuperAdminOnly and !client:IsSuperAdmin() ) then
            client:Notify("You must be a superadmin to run this command!")
            return false
        end
    else
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Commands - " .. info.UniqueID, nil) ) then
            return false
        end
    end

    local canRun, err = hook.Run("PrePlayerCommandRun", client, command, arguments)
    if ( canRun == false ) then
        if ( err ) then
            client:Notify(err)
        end

        return false
    end

    info:Callback(client, arguments)

    hook.Run("PostPlayerCommandRun", client, command, arguments)

    return true, arguments
end

concommand.Add("ax_command_run", function(client, cmd, arguments)
    if ( !IsValid(client) ) then
        ax.util:PrintError("Attempted to run a command with no player!")
        return
    end

    local command = arguments[1]
    table.remove(arguments, 1)

    ax.command:Run(client, command, arguments)

    client.axNextCommand = CurTime() + 1
end)

concommand.Add("ax_command", function(client, cmd, arguments)
    if ( !IsValid(client) ) then
        ax.util:PrintError("Attempted to list commands with no player!")
        return
    end

    local clientTable = client:GetTable()
    if ( clientTable.axNextCommand and clientTable.axNextCommand > CurTime() ) then
        return
    end

    ax.util:Print("Commands:")

    for k, v in pairs(ax.command.stored) do
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Commands - " .. k) ) then
            continue
        end

        ax.util:Print("/" .. v.Name .. (v.Description and " - " .. v.Description or ""))
    end

    clientTable.axNextCommand = CurTime() + 1
end--[[, function(cmd, argStr, arguments)
    local commands = {}

    for k, v in pairs(ax.command.stored) do
        table.insert(commands, cmd .. " " .. v.Name)
    end

    return commands
end, "Lists all available commands."]])
-- TODO: Add auto-complete for commands