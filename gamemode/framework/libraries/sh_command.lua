--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.command = ax.command or {}
ax.command.stored = ax.command.stored or {}

function ax.command:Add(name, data)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("Invalid command name provided")
        return
    end

    if ( !istable(data) ) then
        ax.util:PrintError("Invalid command data provided for command \"" .. name .. "\"")
        return
    end

    if ( istable(data.Alias) and isstring(data.Alias[1]) ) then
        for i = 1, #data.Alias do
            self.stored[data.Alias[i]] = data
            ax.util:PrintDebug("Command alias \"" .. data.Alias[i] .. "\" added successfully.")
        end
    end

    self.stored[name] = data
    ax.util:PrintDebug("Command \"" .. name .. "\" added successfully.")
end

function ax.command:Get(name)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("Invalid command name provided")
        return nil
    end

    local cmd = self.stored[name]
    if ( !istable(cmd) ) then return nil end

    if ( istable(cmd.Alias) and isstring(cmd.Alias[1]) ) then
        for i = 1, #cmd.Alias do
            if ( cmd.Alias[i] == name ) then
                return cmd
            end
        end
    end

    return cmd
end

function ax.command:ParseArguments(args)
    if ( !isstring(args) ) then
        ax.util:PrintError("Invalid command arguments provided")
        return {}
    end

    local arguments = {}
    local exploded = string.Explode(" ", args)
    for i = 1, #exploded do
        local arg = string.Trim(exploded[i])
        if ( arg != "" ) then
            arguments[#arguments + 1] = arg
        end
    end

    return arguments
end

function ax.command:CanRun(name, client)
    if ( !isstring(name) or name == "" ) then
        ax.util:PrintError("Invalid command name provided")
        return false
    end

    local cmd = self:Get(name)
    if ( !istable(cmd) ) then
        ax.util:PrintError("Command \"" .. name .. "\" not found")
        return false
    end

    if ( hook.Run("CanRunCommand", name, client) == false ) then
        ax.util:PrintError("Command \"" .. name .. "\" cannot be run by client " .. tostring(client))
        return false
    end

    if ( isfunction(cmd.CanRun) ) then
        return cmd:CanRun(client)
    end

    return true
end

ax.command:Add("test", {
    Description = "This is a test command.",
    CanRun = function(self, client)
        return true
    end,
    Alias = { "testalias" },
})