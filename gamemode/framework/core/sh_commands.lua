--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.command:Add("SetGravity", {
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

ax.command:Add("PM", {
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

ax.command:Add("SetModel", {
    description = "Set the model of a character.",
    arguments = {
        { name = "target", type = ax.type.character },
        { name = "model", type = ax.type.text }
    },
    OnRun = function(client, target, model)
        if ( !target) then return "Invalid character." end

        target:SetModel(model)
        target:Save()

        return "Model set to " .. model
    end
})

ax.command:Add("SetSkin", {
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