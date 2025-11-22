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
    alias = {"tell"},
    description = "Send a private message to another player.",
    arguments = {
        { name = "target", type = ax.type.player },
        { name = "message", type = ax.type.text }
    },
    OnRun = function(client, target, message)
        if ( !IsValid(target) ) then
            return "Target player not found."
        end

        if ( target == client ) then
            return "You cannot PM yourself."
        end

        target:ChatPrint(Color(125, 150, 75), "[PM from " .. client:Nick() .. "] " .. message)
        client:ChatPrint(Color(125, 150, 75), "[PM to " .. target:Nick() .. "] " .. message)

        target:SendLua([[ax.client:EmitSound("hl1/fvox/bell.wav", 75, 100, 0.25)]])
        client:SendLua([[ax.client:EmitSound("hl1/fvox/bell.wav", 75, 100, 0.25)]])

        return ""
    end
})

ax.command:Add("Roll", {
    description = "Rolls a dice with specified sides.",
    arguments = {
        { name = "sides", type = ax.type.number, min = 2, max = 100, optional = true }
    },
    OnRun = function(client, sides)
        sides = sides or 6
        ax.chat:Send(client, "roll", math.random(1, sides), sides)

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

        target:SetModel(model)
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

        target:SetSkin(skin)
        target:Save()

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

        target:SetName(name)
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

        -- Get the old faction before changing
        local oldFaction = target:GetFaction()

        -- Set the new faction
        target:SetFaction(factionTable.index)
        target:Save()

        -- Call OnTransferred callback if it exists on the new faction
        if ( isfunction(factionTable.OnTransferred) ) then
            local player = target:GetOwner()
            if ( IsValid(player) ) then
                local success, err = pcall(factionTable.OnTransferred, factionTable, player, oldFaction)
                if ( !success ) then
                    ax.util:PrintError("Error in faction OnTransferred callback: " .. tostring(err))
                end
            end
        end

        return "Faction set to " .. factionTable.name
    end
})

ax.command:Add("CharSetClass", {
    description = "Set the class of a character.",
    arguments = {
        { name = "target", type = ax.type.character, optional = true },
        { name = "class", type = ax.type.string }
    },
    OnRun = function(client, target, class)
        if ( !target ) then
            target = client:GetCharacter()
        end

        if ( !target ) then
            return "Invalid character."
        end

        local classTable = ax.class:Get(class)
        if ( !classTable ) then
            return "Invalid class."
        end

        target:SetClass(classTable.index)
        target:Save()

        -- Call OnTransferred callback if it exists on the new class
        if ( isfunction(classTable.OnTransferred) ) then
            local player = target:GetOwner()
            if ( IsValid(player) ) then
                local success, err = pcall(classTable.OnTransferred, classTable, player)
                if ( !success ) then
                    ax.util:PrintError("Error in class OnTransferred callback: " .. tostring(err))
                end
            end
        end

        return "Class set to " .. classTable.name
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
        whitelists[factionTable.id] = true

        target:SetData("whitelists", whitelists)
        target:Save()

        return target:Nick() .. "( " .. target:SteamName() .. " ) has been whitelisted for " .. factionTable.name .. "."
    end
})

ax.command:Add("PlyWhitelistAll", {
    description = "Whitelist a player for all factions.",
    arguments = {
        { name = "target", type = ax.type.player }
    },
    OnRun = function(client, target)
        if ( !IsValid(target) ) then return "Invalid player." end

        local whitelists = {}
        for _, faction in pairs(ax.faction:GetAll()) do
            if ( !faction.isDefault ) then
                whitelists[faction.id] = true
            end
        end

        target:SetData("whitelists", whitelists)
        target:Save()

        return target:Nick() .. "( " .. target:SteamName() .. " ) has been whitelisted for all factions."
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
        whitelists[factionTable.id] = nil

        target:SetData("whitelists", whitelists)
        target:Save()

        return target:Nick() .. "( " .. target:SteamName() .. " ) has been unwhitelisted for " .. factionTable.name .. "."
    end
})

ax.command:Add("PlyUnWhitelistAll", {
    description = "Remove a player's whitelist for all factions.",
    arguments = {
        { name = "target", type = ax.type.player }
    },
    OnRun = function(client, target)
        if ( !IsValid(target) ) then return "Invalid player." end

        target:SetData("whitelists", {})
        target:Save()

        return target:Nick() .. "( " .. target:SteamName() .. " ) has been unwhitelisted from all factions."
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

ax.command:Add("BotAdd", {
    description = "Add a bot to the server for testing purposes.",
    adminOnly = true,
    arguments = {
        { name = "name", type = ax.type.string, optional = true }
    },
    OnRun = function(client, name)
        if ( SERVER ) then
            local botName = name or "TestBot"
            RunConsoleCommand("bot")

            return "Adding bot: " .. botName
        else
            return "This command can only be run on the server."
        end
    end
})

ax.command:Add("BotKick", {
    description = "Remove all bots from the server.",
    adminOnly = true,
    OnRun = function(client)
        if ( SERVER ) then
            local count = 0
            for _, target in player.Iterator() do
                if ( target:IsBot() ) then
                    target:Kick("Removed by admin")
                    count = count + 1
                end
            end

            return "Removed " .. count .. " bot(s) from the server."
        else
            return "This command can only be run on the server."
        end
    end
})

ax.command:Add("BotSupport", {
    description = "Enable or disable automatic bot character creation.",
    adminOnly = true,
    arguments = {
        { name = "enabled", type = ax.type.bool }
    },
    OnRun = function(client, enabled)
        if ( SERVER ) then
            ax.config:Set("bot.support", enabled)
            ax.config:Save()

            return "Bot support " .. (enabled and "enabled" or "disabled") .. "."
        else
            return "This command can only be run on the server."
        end
    end
})

ax.command:Add("BotList", {
    description = "List all bots currently on the server.",
    adminOnly = true,
    OnRun = function(client)
        if ( SERVER ) then
            local bots = {}
            for _, target in player.Iterator() do
                if ( target:IsBot() ) then
                    local character = target:GetCharacter()
                    local charName = character and character:GetName() or "No Character"
                    local faction = character and ax.faction:Get(character:GetFaction())
                    local factionName = faction and faction.name or "No Faction"

                    table.insert(bots, {
                        name = target:SteamName(),
                        character = charName,
                        faction = factionName
                    })
                end
            end

            if ( #bots == 0 ) then
                return "No bots currently on the server."
            end

            local result = "Bots on server (" .. #bots .. "):\n"
            for i, bot in ipairs(bots) do
                result = result .. "  " .. bot.name .. " (" .. bot.character .. " - " .. bot.faction .. ")\n"
            end

            return result
        else
            return "This command can only be run on the server."
        end
    end
})
