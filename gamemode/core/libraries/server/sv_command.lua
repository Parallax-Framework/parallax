--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Command library
-- @module Parallax.Command

--- Runs a command.
-- @realm server
-- @player client The player running the command.
-- @string command The command to run.
-- @tab arguments The arguments of the command.
function Parallax.Command:Run(client, command, arguments)
    if ( !IsValid(client) ) then
        Parallax.Util:PrintError("Attempted to run a command with no player!")
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
        local permission = info.Permission or "Parallax - Commands - " .. info.UniqueID
        if ( !CAMI.PlayerHasAccess(client, permission) ) then
            client:Notify("You do not have permission to run this command!")
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

    if ( info.Arguments ) then
        for i = 1, #info.Arguments do
            local v = info.Arguments[i]
            local value = Parallax.Util:CoerceType(v.Type, arguments[i])
            if ( Parallax.Util:DetectType(value) != v.Type and !v.Optional ) then
                client:Notify(v.ErrorMsg or "Invalid argument type provided!", NOTIFY_ERROR)

                return false
            end

            arguments[i] = value
        end
    end

    info:Callback(client, arguments)

    hook.Run("PostPlayerCommandRun", client, command, arguments)

    return true, arguments
end

concommand.Add("ax_command_run", function(client, cmd, arguments)
    if ( !IsValid(client) ) then
        Parallax.Util:PrintError("Attempted to run a command with no player!")
        return
    end

    if ( client:OnCooldown("command") ) then return end

    local command = arguments[1]
    table.remove(arguments, 1)

    Parallax.Command:Run(client, command, arguments)

    client:SetCooldown("command", 1)
end)

concommand.Add("ax_command", function(client, cmd, arguments)
    if ( !IsValid(client) ) then
        Parallax.Util:PrintError("Attempted to list commands with no player!")
        return
    end

    if ( client:OnCooldown("command") ) then return end

    Parallax.Util:Print("Commands:")

    for k, v in pairs(Parallax.Command.Stored) do
        if ( !CAMI.PlayerHasAccess(client, "Parallax - Commands - " .. k) ) then
            continue
        end

        Parallax.Util:Print("/" .. v.Name .. (v.Description and " - " .. v.Description or ""))
    end

    client:SetCooldown("command", 1)
end--[[, function(cmd, argStr, arguments)
    local commands = {}

    for k, v in pairs(Parallax.Command.Stored) do
        table.insert(commands, cmd .. " " .. v.Name)
    end

    return commands
end, "Lists all available commands."]])
-- TODO: Add auto-complete for commands