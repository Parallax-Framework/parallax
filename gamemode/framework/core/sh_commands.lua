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

ax.command:Add("CharSetModel", {
    description = "Set the model of a character.",
    arguments = {
        { name = "target", type = ax.type.character },
        { name = "model", type = ax.type.text }
    },
    OnRun = function(client, target, model)
        if ( !target) then return "Invalid character." end

        target:SetModel(model, true)
        target:Save()

        return "Model set to " .. model
    end
})

ax.command:Add("CharSetSkin", {
    description = "Set the skin of a character.",
    arguments = {
        { name = "target", type = ax.type.character },
        { name = "skin", type = ax.type.number }
    },
    OnRun = function(client, target, skin)
        if ( !target ) then return "Invalid character." end

        target:SetData("skin", skin)
        target:Save()

        local targetPlayer = target:GetOwner()
        if ( IsValid(targetPlayer) ) then
            targetPlayer:SetSkin(skin)
        end

        return "Skin set to " .. skin
    end
})

ax.command:Add("CharSetName", {
    description = "Set the name of a character.",
    arguments = {
        { name = "target", type = ax.type.character, optional = true },
        { name = "name", type = ax.type.string, optional = true }
    },
    OnRun = function(client, target, name)
        if ( !target ) then
            target = client:GetCharacter()
        end

        if ( !name or name == "" ) then
            net.Start("ax.character.setnameprompt")
                net.WriteUInt(target.id, 32)
                net.WriteString(target:GetName())
            net.Send(client)

            return
        end

        target:SetName(name, true)
        target:Save()

        return "Name set to " .. name
    end
})

ax.command:Add("CharGiveFlags", {
    description = "Give flags to a character.",
    arguments = {
        { name = "target", type = ax.type.character },
        { name = "flags", type = ax.type.string }
    },
    OnRun = function(client, target, flags)
        if ( !target ) then target = client:GetCharacter() end

        target:GiveFlags(flags)
        target:Save()

        return "Flags given to " .. target:GetName() .. ": " .. flags
    end
})

ax.command:Add("CharTakeFlags", {
    description = "Take flags from a character.",
    arguments = {
        { name = "target", type = ax.type.character },
        { name = "flags", type = ax.type.string }
    },
    OnRun = function(client, target, flags)
        if ( !target ) then target = client:GetCharacter() end

        target:TakeFlags(flags)
        target:Save()

        return "Flags taken from " .. target:GetName() .. ": " .. flags
    end
})

ax.command:Add("CharSetFlags", {
    description = "Set flags for a character.",
    arguments = {
        { name = "target", type = ax.type.character, optional = true },
        { name = "flags", type = ax.type.string }
    },
    OnRun = function(client, target, flags)
        if ( !target ) then target = client:GetCharacter() end

        target:SetFlags(flags)
        target:Save()

        return "Flags set for " .. target:GetName() .. ": " .. flags
    end
})

ax.command:Add("CharSetFaction", {
    description = "Set the faction of a character.",
    arguments = {
        { name = "target", type = ax.type.character, optional = true },
        { name = "faction", type = ax.type.string }
    },
    OnRun = function(client, target, faction)
        if ( !target ) then
            target = client:GetCharacter()
        end

        if ( !target ) then
            return "Invalid character."
        end

        local factionTable = ax.faction:Get(faction)
        if ( !factionTable ) then
            return "Invalid faction."
        end

        target:SetFaction(factionTable.index, true)
        target:Save()

        return "Faction set to " .. factionTable.name
    end
})

ax.command:Add("PlyWhitelist", {
    description = "Whitelist a player for a faction.",
    arguments = {
        { name = "target", type = ax.type.player },
        { name = "faction", type = ax.type.string }
    },
    OnRun = function(client, target, faction)
        if ( !IsValid(target) ) then return "Invalid player." end

        local factionTable = ax.faction:Get(faction)
        if ( !factionTable ) then return "Invalid faction." end
        if ( factionTable.isDefault ) then return "This faction does not require whitelisting." end

        local whitelists = target:GetData("whitelists", {})
        whitelists[factionTable.index] = true
        target:SetData("whitelists", whitelists)
        target:Save()

        return target:Nick() .. "( " .. target:SteamName() .. " ) has been whitelisted for " .. factionTable.name .. "."
    end
})

ax.command:Add("PlyUnWhitelist", {
    description = "Remove a player's whitelist for a faction.",
    arguments = {
        { name = "target", type = ax.type.player },
        { name = "faction", type = ax.type.string }
    },
    OnRun = function(client, target, faction)
        if ( !IsValid(target) ) then return "Invalid player." end

        local factionTable = ax.faction:Get(faction)
        if ( !factionTable ) then return "Invalid faction." end
        if ( factionTable.isDefault ) then return "This faction does not require whitelisting." end

        local whitelists = target:GetData("whitelists", {})
        whitelists[factionTable.index] = nil
        target:SetData("whitelists", whitelists)
        target:Save()

        return target:Nick() .. "( " .. target:SteamName() .. " ) has been unwhitelisted for " .. factionTable.name .. "."
    end
})

ax.command:Add("PlyRespawn", {
    description = "Respawn a player.",
    arguments = {
        { name = "target", type = ax.type.player }
    },
    OnRun = function(client, target)
        if ( !IsValid(target) ) then return "Invalid player." end

        target:Spawn()

        return "Player " .. target:Nick() .. " has been respawned."
    end
})
