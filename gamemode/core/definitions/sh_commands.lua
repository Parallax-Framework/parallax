--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

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

        if ( target:HasWhitelist(faction:GetUniqueID()) ) then
            client:Notify("The targeted player is already whitelisted to that faction!")
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

        if ( !target:HasWhitelist(faction:GetUniqueID()) ) then
            client:Notify("The targeted player is not whitelisted to that faction!")
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

            net.Start("ax.flag.list")
                net.WritePlayer(target)
                net.WriteTable(hasFlags)
                net.WriteBool(true)
            net.Send(client)

            return
        end

        local given = {}
        for i = 1, #flags do
            local flag = flags[i]
            given[#given + 1] = flag
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
        for i = 1, #given do
            if ( !character:HasFlag(given[i]) ) then
                hasAllFlags = false
            end
        end

        if ( hasAllFlags ) then
            client:Notify("They already have all the flags you are trying to give!")
            return
        end

        -- Give the flags to the character
        for i = 1, #given do
            character:GiveFlag(given[i])
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

            net.Start("ax.flag.list")
                net.WritePlayer(target)
                net.WriteTable(hasFlags)
                net.WriteBool(false)
            net.Send(client)

            return
        end

        local taken = {}
        for i = 1, #flags do
            local flag = flags[i]
            taken[#taken + 1] = flag
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
        for i = 1, #taken do
            if ( character:HasFlag(taken[i]) ) then
                hasNoFlags = false
            end
        end

        if ( hasNoFlags ) then
            client:Notify("They already don't have the flags you are trying to take!")
            return
        end

        -- Take the flags from the character
        for i = 1, #taken do
            character:TakeFlag(taken[i])
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

ax.command:Register("FallOver", {
    Description = "Make your character fall over.",
    Arguments = {
        {
            Type = ax.types.number,
            ErrorMsg = "You must provide a valid duration in seconds!",
            Optional = true
        }
    },
    Callback = function(info, client, arguments)
        local character = client:GetCharacter()
        if ( !character ) then return end

        client:SetRagdolled(true, arguments[1] or 5)
    end
})

ax.command:Register("RefreshDefaultFlags", {
    Description = "Refresh default flags for all characters or a specific player",
    AdminOnly = true,
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player!",
            Optional = true
        }
    },
    Callback = function(info, client, arguments)
        local target = arguments[1]
        if ( target ) then
            -- Apply to specific player's character
            local character = target:GetCharacter()
            if ( !character ) then
                client:Notify("The targeted player does not have a character!")
                return
            end

            ax.character:ApplyDefaultFlags(character)
            client:Notify("Applied default flags to " .. target:Nick() .. "'s character.", NOTIFY_HINT)
        else
            local count = 0
            for _, v in player.Iterator() do
                local character = v:GetCharacter()
                if ( character ) then
                    ax.character:ApplyDefaultFlags(character)
                    count = count + 1
                end
            end

            client:Notify("Applied default flags to " .. count .. " online characters.", NOTIFY_HINT)
        end
    end
})

ax.command:Register("CharGiveMoney", {
    Description = "Give money to a character",
    AdminOnly = true,
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to give money to!"
        },
        {
            Type = ax.types.number,
            ErrorMsg = "You must provide a valid amount of money to give!"
        }
    },
    Callback = function(info, client, arguments)
        local target = arguments[1]
        local amount = arguments[2]

        if ( amount <= 0 ) then
            client:Notify("You must provide a positive amount of money!")
            return
        end

        local character = target:GetCharacter()
        if ( !character ) then
            client:Notify("The targeted player does not have a character!")
            return
        end

        character:GiveMoney(amount)

        client:Notify("You have given " .. ax.currency:Format(amount) .. " to " .. target:Nick() .. ".", NOTIFY_HINT)
        target:Notify("You have been given " .. ax.currency:Format(amount) .. " by " .. client:Nick() .. "!", NOTIFY_HINT)
    end
})

ax.command:Register("CharTakeMoney", {
    Description = "Take money from a character",
    AdminOnly = true,
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to take money from!"
        },
        {
            Type = ax.types.number,
            ErrorMsg = "You must provide a valid amount of money to take!"
        }
    },
    Callback = function(info, client, arguments)
        local target = arguments[1]
        local amount = arguments[2]

        if ( amount <= 0 ) then
            client:Notify("You must provide a positive amount of money!")
            return
        end

        local character = target:GetCharacter()
        if ( !character ) then
            client:Notify("The targeted player does not have a character!")
            return
        end

        if ( !character:CanAfford(amount) ) then
            client:Notify("The targeted player cannot afford to lose " .. ax.currency:Format(amount) .. "! They only have " .. ax.currency:Format(character:GetMoney()) .. ".")
            return
        end

        character:TakeMoney(amount)

        client:Notify("You have taken " .. ax.currency:Format(amount) .. " from " .. target:Nick() .. ".", NOTIFY_HINT)
        target:Notify("You have had " .. ax.currency:Format(amount) .. " taken from you by " .. client:Nick() .. "!", NOTIFY_HINT)
    end
})

ax.command:Register("CharSetMoney", {
    Description = "Set a character's money to a specific amount",
    AdminOnly = true,
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to set money for!"
        },
        {
            Type = ax.types.number,
            ErrorMsg = "You must provide a valid amount of money to set!"
        }
    },
    Callback = function(info, client, arguments)
        local target = arguments[1]
        local amount = arguments[2]

        if ( amount < 0 ) then
            client:Notify("You cannot set money to a negative amount!")
            return
        end

        local character = target:GetCharacter()
        if ( !character ) then
            client:Notify("The targeted player does not have a character!")
            return
        end

        local oldAmount = character:GetMoney()
        character:SetMoney(amount)

        client:Notify("You have set " .. target:Nick() .. "'s money from " .. ax.currency:Format(oldAmount) .. " to " .. ax.currency:Format(amount) .. ".", NOTIFY_HINT)
        target:Notify("Your money has been set to " .. ax.currency:Format(amount) .. " by " .. client:Nick() .. "!", NOTIFY_HINT)
    end
})

ax.command:Register("CharCheckMoney", {
    Description = "Check how much money a character has",
    AdminOnly = true,
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to check money for!"
        }
    },
    Callback = function(info, client, arguments)
        local target = arguments[1]

        local character = target:GetCharacter()
        if ( !character ) then
            client:Notify("The targeted player does not have a character!")
            return
        end

        local amount = character:GetMoney()
        client:Notify(target:Nick() .. " has " .. ax.currency:Format(amount) .. ".", NOTIFY_HINT)
    end
})

ax.command:Register("CharResetName", {
    Description = "Ask a user to reset their character's name",
    AdminOnly = true,
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to reset the name for!"
        }
    },
    Callback = function(info, client, arguments)
        local target = arguments[1]

        local character = target:GetCharacter()
        if ( !character ) then
            client:Notify("The targeted player does not have a character!")
            return
        end

        target:GetTable().axResetRequestBy = client

        net.Start("ax.character.namereset")
        net.Send(target)

        target:Notify("An admin has requested you to reset your character's name.", NOTIFY_HINT)
        client:Notify("You have requested " .. target:Nick() .. " to reset their character's name.", NOTIFY_HINT)
    end
})

ax.command:Register("CharResetDescription", {
    Description = "Ask a user to reset their character's description",
    AdminOnly = true,
    Arguments = {
        {
            Type = ax.types.player,
            ErrorMsg = "You must provide a valid player to reset the name for!"
        }
    },
    Callback = function(info, client, arguments)
        local target = arguments[1]

        local character = target:GetCharacter()
        if ( !character ) then
            client:Notify("The targeted player does not have a character!")
            return
        end

        target:GetTable().axResetRequestBy = client

        net.Start("ax.character.descreset")
        net.Send(target)

        target:Notify("An admin has requested you to reset your character's description.", NOTIFY_HINT)
        client:Notify("You have requested " .. target:Nick() .. " to reset their character's description.", NOTIFY_HINT)
    end
})