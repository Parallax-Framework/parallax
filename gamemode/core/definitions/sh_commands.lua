----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 --- Made by a transgender queen
 -- Slay queen Riggs
 -- Stay Powerfull against the Patiarchy by a man (Alex Grist) stealing code
 -- #OverwatchFramework #CodeStealingMatters

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.command:Register("PlyRespawn", {
    Description = "Respawn a player.",
    AdminOnly = true,
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to respawn!"
        }
    },
    Callback = function(info, client, arguments)
        local target = arguments[1]

        if ( target:GetCharacter() == nil ) then
            client:Notify("The targeted player does not have a character!")
            return
        end

        target:KillSilent()
        target:Spawn()

        client:Notify("You have respawned " .. target:Nick() .. ".", NOTIFY_HINT)
    end
})

ax.command:Register("PlyWhitelist", {
    Description = "Whitelist a player to a faction.",
    AdminOnly = true,
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to whitelist!"
        },
        {
            Type = ax.types.string,
            ErrorMsg = "You must provide a valid faction to whitelist the player to!"
        }
    },
    Callback = function(info, client, arguments)
        local target = arguments[1]

        local faction = ax.faction:Get(arguments[2])
        if ( !faction ) then
            client:Notify("You must provide a valid faction to whitelist the player to!")
            return
        end

        target:SetWhitelisted(faction:GetUniqueID(), true)

        client:Notify("You have whitelisted " .. target:Nick() .. " to the faction " .. faction:GetName() .. ".", NOTIFY_HINT)
    end
})

ax.command:Register("PlyUnWhitelist", {
    Description = "Unwhitelist a player from a faction.",
    AdminOnly = true,
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to unwhitelist!"
        },
        {
            Type = ax.types.string,
            ErrorMsg = "You must provide a valid faction to unwhitelist the player from!"
        }
    },
    Callback = function(info, client, arguments)
        local target = arguments[1]

        local faction = ax.faction:Get(arguments[2])
        if ( !faction ) then
            client:Notify("You must provide a valid faction to unwhitelist the player from!")
            return
        end

        target:SetWhitelisted(faction:GetUniqueID(), false)

        client:Notify("You have unwhitelisted " .. target:Nick() .. " from the faction " .. faction:GetName() .. ".", NOTIFY_HINT)
    end
})

ax.command:Register("CharSetModel", {
    Description = "Set the model of a character.",
    AdminOnly = true,
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to set the model of!"
        },
        {
            Type = ax.types.string,
            ErrorMsg = "You must provide a valid model!"
        }
    },
    Callback = function(info, client, arguments)
        local target = arguments[1]

        local character = target:GetCharacter()
        if ( !character ) then
            client:Notify("The targeted player does not have a character!")
            return
        end

        local model = arguments[2]
        if ( string.lower(model) == string.lower(target:GetModel()) ) then
            client:Notify("The targeted player already has that model!")
            return
        end

        character:SetModel(model)

        client:Notify("You have set the model of " .. target:Nick() .. " to " .. model .. ".", NOTIFY_HINT)
    end
})

ax.command:Register("CharSetFaction", {
    Description = "Set the faction of a character.",
    AdminOnly = true,
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to set the faction of!"
        },
        {
            Type = ax.types.string,
            ErrorMsg = "You must provide a valid faction to set!"
        }
    },
    Callback = function(info, client, arguments)
        local faction = ax.faction:Get(arguments[2])
        if ( !faction ) then
            client:Notify("You must provide a valid faction to set!")
            return
        end

        local target = arguments[1]

        local character = target:GetCharacter()
        if ( !character ) then
            client:Notify("The targeted player does not have a character!")
            return
        end

        character:SetFaction(faction:GetID())
        ax.faction:Join(target, faction:GetID(), true)

        client:Notify("You have set the faction of " .. target:Nick() .. " to " .. faction.Name .. ".", NOTIFY_HINT)
    end
})

ax.command:Register("CharGiveFlags", {
    Description = "Give a character a flag.",
    AdminOnly = true,
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to give a flag to!"
        },
        {
            Type = ax.types.string,
            Optional = true
        }
    },
    Callback = function(info, client, arguments)
        local target = arguments[1]

        local character = target:GetCharacter()
        if ( !character ) then
            client:Notify("The targeted player does not have a character!")
            return
        end

        local flags = arguments[2]
        if ( flags == nil or flags == "" ) then
            local hasFlags = {}
            for k, v in pairs(ax.flag:GetAll()) do
                if ( character:HasFlag(k) ) then
                    hasFlags[k] = true
                end
            end

            ax.net:Start(client, "flag.list", target, hasFlags)

            return
        end

        local given = {}
        for i = 1, #flags do
            local flag = flags[i]
            table.insert(given, flag)
        end

        -- Check if the flags are valid
        local validFlags = true
        for i = 1, #given do
            local flag = given[i]
            if ( !ax.flag:Get(flag) ) then
                validFlags = false
                break
            end
        end

        if ( !validFlags ) then
            client:Notify("You must provide valid flags to give!")
            return
        end

        -- Check if we already have all the flags
        local hasAllFlags = true
        for k, v in ipairs(given) do
            if ( !character:HasFlag(v) ) then
                hasAllFlags = false
            end
        end

        if ( hasAllFlags ) then
            client:Notify("They already have all the flags you are trying to give!")
            return
        end

        -- Give the flags to the character
        for k, v in ipairs(given) do
            character:GiveFlag(v)
        end

        local flagString = table.concat(given, ", ")
        client:Notify("You have given " .. target:Nick() .. " the flag(s) \"" .. flagString .. "\".", NOTIFY_HINT)
        target:Notify("You have been given the flag(s) \"" .. flagString .. "\" for your character!", NOTIFY_HINT)
    end
})

ax.command:Register("CharTakeFlags", {
    Description = "Take a flag from a character.",
    AdminOnly = true,
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to take a flag from!"
        },
        {
            Type = ax.types.string,
            ErrorMsg = "You must provide either single flag or a set of flags!"
        }
    },
    Callback = function(info, client, arguments)
        local target = arguments[1]

        local character = target:GetCharacter()
        if ( !character ) then
            client:Notify("The targeted player does not have a character!")
            return
        end

        local flags = arguments[2]

        local taken = {}
        for i = 1, #flags do
            local flag = flags[i]
            table.insert(taken, flag)
        end

        -- Check if the flags are valid
        local validFlags = true
        for i = 1, #taken do
            local flag = taken[i]
            if ( !ax.flag:Get(flag) ) then
                validFlags = false
                break
            end
        end

        if ( !validFlags ) then
            client:Notify("You must provide valid flags to take!")
            return
        end

        -- Check if we already dont have the flags we are trying to take
        local hasNoFlags = true
        for k, v in ipairs(taken) do
            if ( character:HasFlag(v) ) then
                hasNoFlags = false
            end
        end

        if ( hasNoFlags ) then
            client:Notify("They already don't have the flags you are trying to take!")
            return
        end

        -- Take the flags from the character
        for k, v in ipairs(taken) do
            character:TakeFlag(v)
        end

        local flagString = table.concat(taken, ", ")
        client:Notify("You have taken the flag(s) \"" .. flagString .. "\" from " .. target:Nick() .. ".", NOTIFY_HINT)
        target:Notify("You have had the flag(s) \"" .. flagString .. "\" taken from your character!", NOTIFY_HINT)
    end
})

ax.command:Register("ToggleRaise", {
    Callback = function(info, client, arguments)
        client:ToggleWeaponRaise()
    end
})