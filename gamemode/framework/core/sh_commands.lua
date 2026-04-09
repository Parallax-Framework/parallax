--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

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
    OnRun = function(def, client, scale)
        RunConsoleCommand("sv_gravity", tostring(600 * scale))
        return "Gravity set to " .. scale .. "x"
    end
})

ax.command:Add("PM", {
    prefix = {"tell"},
    description = "Send a private message to another player.",
    arguments = {
        { name = "target", type = ax.type.player },
        { name = "message", type = ax.type.text }
    },
    OnRun = function(def, client, target, message)
        if ( !ax.util:IsValidPlayer(target) ) then
            return "Target player not found."
        end

        if ( target == client ) then
            return "You cannot PM yourself."
        end

        local check, reason = hook.Run("CanPlayerReceivePM", target, client)
        if ( check == false ) then
            return reason or "The target player cannot receive PMs from you."
        end

        target:ChatPrint(Color(125, 150, 75), "[PM from " .. client:Nick() .. "] " .. message)
        client:ChatPrint(Color(125, 150, 75), "[PM to " .. target:Nick() .. "] " .. message)

        target:SendLua([[ax.client:EmitSound("hl1/fvox/bell.wav", 75, 100, 0.25)]])
        client:SendLua([[ax.client:EmitSound("hl1/fvox/bell.wav", 75, 100, 0.25)]])

        target:SetRelay("pm.last", client:SteamID64())
        target:SetRelay("pm.last_since", os.time())
        client:SetRelay("pm.last", target:SteamID64())
        client:SetRelay("pm.last_since", os.time())

        return ""
    end
})

ax.command:Add("Reply", {
    description = "Reply to the last player who PMed you.",
    arguments = {
        { name = "message", type = ax.type.text }
    },
    OnRun = function(def, client, message)
        local lastPMerID = client:GetRelay("pm.last")
        local lastPMSince = client:GetRelay("pm.last_since")

        if ( !lastPMerID or !lastPMSince ) then
            return "You have not received any PMs to reply to."
        end

        if ( os.time() - lastPMSince > 300 ) then
            return "The last PM you received was too long ago to reply to."
        end

        local target = player.GetBySteamID64(lastPMerID)
        if ( !ax.util:IsValidPlayer(target) ) then
            return "The player you are trying to reply to is no longer online."
        end

        local check, reason = hook.Run("CanPlayerReceivePM", target, client)
        if ( check == false ) then
            return reason or "The target player cannot receive PMs from you."
        end

        target:ChatPrint(Color(125, 150, 75), "[PM from " .. client:Nick() .. "] " .. message)
        client:ChatPrint(Color(125, 150, 75), "[PM to " .. target:Nick() .. "] " .. message)

        target:SendLua([[ax.client:EmitSound("hl1/fvox/bell.wav", 75, 100, 0.25)]])
        client:SendLua([[ax.client:EmitSound("hl1/fvox/bell.wav", 75, 100, 0.25)]])

        target:SetRelay("pm.last", client:SteamID64())
        target:SetRelay("pm.last_since", os.time())
        client:SetRelay("pm.last", target:SteamID64())
        client:SetRelay("pm.last_since", os.time())

        return ""
    end
})

ax.command:Add("Roll", {
    description = "Rolls a dice with specified sides.",
    arguments = {
        { name = "sides", type = ax.type.number, min = 2, max = 100, optional = true }
    },
    OnRun = function(def, client, sides)
        sides = sides or 6
        ax.chat:Send(client, "roll", "", { sides = sides, result = math.random(sides) })

        return ""
    end
})

ax.command:Add("CharSetModel", {
    description = "Set the model of a character.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.character },
        { name = "model", type = ax.type.text }
    },
    OnRun = function(def, client, target, model)
        if ( !target) then return "Invalid character." end

        target:SetModel(model)
        target:Save()

        return "Model set to " .. model
    end
})

ax.command:Add("CharSetSkin", {
    description = "Set the skin of a character.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.character },
        { name = "skin", type = ax.type.number }
    },
    OnRun = function(def, client, target, skin)
        if ( !target ) then return "Invalid character." end

        target:SetSkin(skin)
        target:Save()

        return "Skin set to " .. skin
    end
})

ax.command:Add("CharSetName", {
    description = "Set the name of a character.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.character, optional = true },
        { name = "name", type = ax.type.string, optional = true }
    },
    OnRun = function(def, client, target, name)
        if ( !target ) then
            target = client:GetCharacter()
        end

        if ( !name or name == "" ) then
            ax.net:Start(client, "character.setnameprompt", target.id)

            return
        end

        target:SetName(name)
        target:Save()

        return "Name set to " .. name
    end
})

ax.command:Add("CharGiveItem", {
    description = "Give an item to a character.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.character },
        { name = "item", type = ax.type.string },
        { name = "amount", type = ax.type.number, min = 1, optional = true }
    },
    OnRun = function(def, client, target, identifier, amount)
        if ( !target ) then
            return "Invalid character."
        end

        local inventory = target:GetInventory()
        if ( !istable(inventory) ) then
            return "Target character inventory is not available."
        end

        local itemClass, itemDataOrErr = ax.item:FindByIdentifier(identifier)
        if ( !itemClass ) then
            return itemDataOrErr or "Invalid item identifier."
        end

        local itemData = itemDataOrErr
        local requestedAmount = math.max(1, math.floor(amount or 1))
        local addedAmount = 0
        local targetName = target:GetName() or ("Character #" .. tostring(target:GetID()))
        local itemName = itemData.name or itemClass

        local function notifyResult(message)
            if ( ax.util:IsValidPlayer(client) and isstring(message) and message != "" ) then
                client:Notify(message)
            end
        end

        local function giveNext()
            if ( addedAmount >= requestedAmount ) then
                notifyResult(string.format("Gave %d x %s (%s) to %s.", addedAmount, itemName, itemClass, targetName))
                return
            end

            local ok, reason = inventory:AddItem(itemClass, nil, function()
                addedAmount = addedAmount + 1
                giveNext()
            end)

            if ( ok == false ) then
                if ( addedAmount > 0 ) then
                    notifyResult(string.format(
                        "Gave %d/%d x %s (%s) to %s. Stopped: %s",
                        addedAmount,
                        requestedAmount,
                        itemName,
                        itemClass,
                        targetName,
                        reason or "unknown error"
                    ))
                else
                    notifyResult("Failed to give item: " .. (reason or "unknown error"))
                end
            end
        end

        giveNext()

        return ""
    end
})

ax.command:Add("CharGiveFlags", {
    description = "Give flags to a character.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.character },
        { name = "flags", type = ax.type.string, optional = true }
    },
    OnRun = function(def, client, target, flags)
        if ( !target ) then target = client:GetCharacter() end

        if ( !flags or flags == "" ) then
            local flagsToGive = ""
            for flag, _ in pairs(ax.flag.stored) do
                if ( !target:HasFlags(flag) ) then
                    flagsToGive = flagsToGive .. flag
                end
            end

            client:DermaStringRequest("Enter flags", "Enter the flags to give to the character.", flagsToGive, function(text)
                if ( text == "" ) then return end

                target:GiveFlags(text)
            end)

            return
        else
            target:GiveFlags(flags)

            return "Flags given to " .. target:GetName() .. ": " .. flags
        end
    end
})

ax.command:Add("CharTakeFlags", {
    description = "Take flags from a character.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.character },
        { name = "flags", type = ax.type.string, optional = true }
    },
    OnRun = function(def, client, target, flags)
        if ( !target ) then target = client:GetCharacter() end

        if ( !flags or flags == "" ) then
            local flagsToTake = ""
            for flag, _ in pairs(ax.flag.stored) do
                if ( target:HasFlags(flag) ) then
                    flagsToTake = flagsToTake .. flag
                end
            end

            client:DermaStringRequest("Enter flags", "Enter the flags to take from the character.", flagsToTake, function(text)
                if ( text == "" ) then return end

                target:TakeFlags(text)
            end)

            return
        else
            target:TakeFlags(flags)

            return "Flags taken from " .. target:GetName() .. ": " .. flags
        end
    end
})

ax.command:Add("CharSetFlags", {
    description = "Set flags for a character.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.character, optional = true },
        { name = "flags", type = ax.type.string }
    },
    OnRun = function(def, client, target, flags)
        if ( !target ) then target = client:GetCharacter() end

        target:SetFlags(flags)
        target:Save()

        return "Flags set for " .. target:GetName() .. ": " .. flags
    end
})

ax.command:Add("CharSetFaction", {
    description = "Set the faction of a character.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.character, optional = true },
        { name = "faction", type = ax.type.string }
    },
    OnRun = function(def, client, target, faction)
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

        target:SetFaction(factionTable.index)
        target:Save()

        return "Faction set to " .. factionTable.name
    end
})

ax.command:Add("CharSetClass", {
    description = "Set the class of a character.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.character, optional = true },
        { name = "class", type = ax.type.string }
    },
    OnRun = function(def, client, target, class)
        if ( !target ) then
            target = client:GetCharacter()
        end

        if ( !target ) then
            print("No target character found for CharSetClass command.")
            return "Invalid character."
        end

        local classes = {}
        for _, classTable in ipairs(ax.class:GetAll({faction = target:GetFaction()})) do
            classes[#classes + 1] = classTable
        end

        local classTable = nil
        for _, classIter in ipairs(classes) do
            if ( ax.util:FindString(classIter.name, class) ) then
                classTable = classIter
                break
            end
        end

        if ( !classTable ) then
            local classNames = {}
            for _, classIter in ipairs(classes) do
                classNames[#classNames + 1] = classIter.name
            end

            return "You must specify a valid class for the character's faction, possible classes are: " .. " " .. table.concat(classNames, ", ")
        end

        target:SetClass(classTable.index)
        target:Save()

        return "Class set to " .. classTable.name
    end
})

ax.command:Add("CharSetRank", {
    description = "Set the rank of a character.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.character, optional = true },
        { name = "rank", type = ax.type.string }
    },
    OnRun = function(def, client, target, rank)
        if ( !target ) then
            target = client:GetCharacter()
        end

        if ( !target ) then
            print("No target character found for CharSetRank command.")
            return "Invalid character."
        end

        local rankTable = nil
        for _, rankIter in ipairs(ax.rank:GetAll({faction = target:GetFaction()})) do
            if ( ax.util:FindString(rankIter.name, rank) ) then
                rankTable = rankIter
                break
            end
        end

        if ( !rankTable ) then
            return "You must specify a valid rank for the character's faction."
        end

        target:SetRank(rankTable.index)
        target:Save()

        return "Rank set to " .. rankTable.name
    end
})

ax.command:Add("PlyWhitelist", {
    description = "Whitelist a player for a faction.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.player },
        { name = "faction", type = ax.type.string }
    },
    OnRun = function(def, client, target, faction)
        if ( !ax.util:IsValidPlayer(target) ) then return "Invalid player." end

        local factionTable = ax.faction:Get(faction)
        if ( !factionTable ) then return "Invalid faction." end
        if ( factionTable.isDefault ) then return "This faction does not require whitelisting." end

        local whitelists = target:GetData("whitelists", {})
        whitelists[factionTable.id] = true

        target:SetFactionWhitelisted(factionTable.id, true)
        target:Save()

        return target:Nick() .. "( " .. target:SteamName() .. " ) has been whitelisted for " .. factionTable.name .. "."
    end
})

ax.command:Add("PlyWhitelistAll", {
    description = "Whitelist a player for all factions.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.player }
    },
    OnRun = function(def, client, target)
        if ( !ax.util:IsValidPlayer(target) ) then return "Invalid player." end

        local whitelists = {}
        local factions = ax.faction:GetAll()
        for i = 1, #factions do
            local factionTable = factions[i]
            if ( !factionTable.isDefault ) then
                whitelists[factionTable.id] = true
            end
        end

        target:SetData("whitelists", whitelists)
        target:Save()

        return target:Nick() .. "( " .. target:SteamName() .. " ) has been whitelisted for all factions."
    end
})

ax.command:Add("PlyUnWhitelist", {
    description = "Remove a player's whitelist for a faction.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.player },
        { name = "faction", type = ax.type.string }
    },
    OnRun = function(def, client, target, faction)
        if ( !ax.util:IsValidPlayer(target) ) then return "Invalid player." end

        local factionTable = ax.faction:Get(faction)
        if ( !factionTable ) then return "Invalid faction." end
        if ( factionTable.isDefault ) then return "This faction does not require whitelisting." end

        target:SetFactionWhitelisted(factionTable.id, false)
        target:Save()

        return target:Nick() .. "( " .. target:SteamName() .. " ) has been unwhitelisted for " .. factionTable.name .. "."
    end
})

ax.command:Add("PlyUnWhitelistAll", {
    description = "Remove a player's whitelist for all factions.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.player }
    },
    OnRun = function(def, client, target)
        if ( !ax.util:IsValidPlayer(target) ) then return "Invalid player." end

        target:SetData("whitelists", {})
        target:Save()

        return target:Nick() .. "( " .. target:SteamName() .. " ) has been unwhitelisted from all factions."
    end
})

ax.command:Add("PlyRespawn", {
    description = "Respawn a player.",
    adminOnly = true,
    arguments = {
        { name = "target", type = ax.type.player }
    },
    OnRun = function(def, client, target)
        if ( !ax.util:IsValidPlayer(target) ) then return "Invalid player." end

        target:Spawn()

        return "Player " .. target:Nick() .. " has been respawned."
    end
})

ax.command:Add("BecomeClass", {
    description = "Become a specific class.",
    adminOnly = false,
    arguments = {
        { name = "class", type = ax.type.string }
    },
    OnRun = function(def, client, class)
        local character = client:GetCharacter()
        if ( !character ) then return end

        local classTable = ax.class:Get(class)
        if ( !classTable ) then return "Invalid class." end

        local classes = ax.class:GetAll({faction = character:GetFaction()})
        if ( classes[1] == nil ) then return "You do not have any classes available to become." end

        local selectedClass = nil
        for i = 1, #classes do
            local classTable = classes[i]
            if ( ax.util:FindString(classTable.name, class) or ax.util:FindString(classTable.id, class) ) then
                selectedClass = classTable
                break
            end
        end

        if ( !selectedClass ) then return "Invalid class." end

        if ( !ax.class:CanBecome(selectedClass.id, client) ) then
            return "You cannot become this class."
        end

        character:SetClass(selectedClass.index)

        return "You have become the \"" .. selectedClass.name .. "\" class."
    end
})

ax.command:Add("MapRestart", {
    description = "Restart the current map.",
    superAdminOnly = true,
    arguments = {
        { name = "delay", type = ax.type.number }
    },
    OnRun = function(def, client, delay)
        delay = delay or 0
        timer.Simple(delay, function()
            RunConsoleCommand("changelevel", game.GetMap())
        end)

        return "Map restarting in " .. delay .. " seconds."
    end
})
