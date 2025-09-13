--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Example commands for testing and demonstration

--[[
    Example: Set gravity command (admin only)
]]
ax.command:Add("setgravity", {
    description = "Set world gravity scale.",
    adminOnly = true,
    arguments = {
        { name = "scale", type = ax.type.number, min = 0.1, max = 3, decimals = 2 }
    },
    OnRun = function(client, scale)
        RunConsoleCommand("sv_gravity", tostring(600 * scale))
        return "Gravity set to " .. scale .. "x"
    end
})

--[[
    Example: Private message command with aliases
]]
ax.command:Add("pm", {
    alias = {"tell", "whisper"},
    description = "Send a private message to another player.",
    arguments = {
        { name = "target", type = ax.type.player },
        { name = "message", type = ax.type.text }
    },
    OnRun = function(client, target, message)
        if ( !IsValid(target) ) then
            return "Target player not found."
        end

        target:ChatPrint("[PM from " .. client:Nick() .. "] " .. message)
        client:ChatPrint("[PM to " .. target:Nick() .. "] " .. message)
        return ""
    end
})

--[[
    Example: Toggle god mode with optional parameter
]]
ax.command:Add("god", {
    description = "Toggle god mode for yourself or another player.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.player, optional = true }
    },
    OnRun = function(client, target)
        target = target or client

        if ( !IsValid(target) ) then
            return "Invalid target player."
        end

        local isGod = target:HasGodMode()
        target:GodEnable(!isGod)

        local status = !isGod and "enabled" or "disabled"
        local targetName = target == client and "yourself" or target:Nick()

        return "God mode " .. status .. " for " .. targetName
    end
})

--[[
    Example: Help command to list available commands
]]
ax.command:Add("help", {
    alias = {"commands", "cmds"},
    description = "List available commands or get help for a specific command.",
    arguments = {
        { name = "command", type = ax.type.string, optional = true }
    },
    OnRun = function(client, commandName)
        if ( commandName ) then
            -- Show help for specific command
            local def = ax.command.registry[string.lower(commandName)]
            if ( !def ) then
                return "Command '" .. commandName .. "' not found."
            end

            local hasAccess = ax.command:HasAccess(client, def)
            if ( !hasAccess ) then
                return "Command '" .. commandName .. "' not found." -- Don't reveal existence
            end

            return ax.command:Help(def.name)
        else
            -- List all available commands
            local available = {}
            local processed = {} -- Track original command names to avoid duplicates from aliases

            for name, def in pairs(ax.command.registry) do
                if ( name == def.name and !processed[def.name] ) then -- Only process original command names
                    local hasAccess = ax.command:HasAccess(client, def)
                    if ( hasAccess ) then
                        available[ #available + 1 ] = def.name
                        processed[def.name] = true
                    end
                end
            end

            table.sort(available)

            if ( available[1] == nil ) then
                return "No commands available."
            else
                return "Available commands (" .. #available .. "): " .. table.concat(available, ", ")
            end
        end
    end
})

ax.command:Add("setmodel", {
    description = "Set the model of a character.",
    arguments = {
        { name = "target", type = ax.type.character },
        { name = "model", type = ax.type.text }
    },
    OnRun = function(client, target, model)
        if ( !target) then return "Invalid character." end

        target:SetModel(model)
        return "Model set to " .. model
    end
})

ax.command:Add("setskin", {
    description = "Set the skin of a player.",
    arguments = {
        { name = "target", type = ax.type.player },
        { name = "skin", type = ax.type.number }
    },
    OnRun = function(client, target, skin)
        if ( !IsValid(target) ) then return "Invalid player." end

        target:SetSkin(skin)
        target:GetCharacter():SetData("skin", skin)
        target:GetCharacter():Save()
        return "Skin set to " .. skin
    end
})
