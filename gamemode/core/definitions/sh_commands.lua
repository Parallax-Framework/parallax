ax.command:Register("PlyRespawn", {
    Description = "Respawn a player.",
    AdminOnly = true,
    Callback = function(info, client, arguments)
        local target = ax.util:FindPlayer(arguments[1])
        if ( !IsValid(target) ) then
            client:Notify("You must provide a valid player to respawn!")
            return
        end

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
    Callback = function(info, client, arguments)
        local target = ax.util:FindPlayer(arguments[1])
        if ( !IsValid(target) ) then
            client:Notify("You must provide a valid player to whitelist!")
            return
        end

        local identifier = arguments[2]
        if ( !isstring(identifier) or #identifier == 0 ) then
            client:Notify("You must provide a valid faction to whitelist the player to!")
            return
        end

        local faction = ax.faction:Get(identifier)
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
    Callback = function(info, client, arguments)
        local target = ax.util:FindPlayer(arguments[1])
        if ( !IsValid(target) ) then
            client:Notify("You must provide a valid player to unwhitelist!")
            return
        end

        local identifier = arguments[2]
        if ( !isstring(identifier) or #identifier == 0 ) then
            client:Notify("You must provide a valid faction to unwhitelist the player from!")
            return
        end

        local faction = ax.faction:Get(identifier)
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
    Callback = function(info, client, arguments)
        local target = ax.util:FindPlayer(arguments[1])
        if ( !IsValid(target) ) then
            client:Notify("You must provide a valid player to set the model of!")
            return
        end

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
    Callback = function(info, client, arguments)
        local target = ax.util:FindPlayer(arguments[1])
        if ( !IsValid(target) ) then
            client:Notify("You must provide a valid player to set the faction of!")
            return
        end

        local identifier = arguments[2]
        if ( !isstring(identifier) or #identifier == 0 ) then
            client:Notify("You must provide a valid faction to set!")
            return
        end

        local faction = ax.faction:Get(identifier)
        if ( !faction ) then
            client:Notify("You must provide a valid faction to set!")
            return
        end

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
    Callback = function(info, client, arguments)
        local target = ax.util:FindPlayer(arguments[1])
        if ( !IsValid(target) ) then
            client:Notify("You must provide a valid player to give a flag to!")
            return
        end

        local flags = arguments[2]
        if ( !isstring(flags) or #flags == 0 ) then
            client:Notify("You must provide either single flag or a set of flags!")
            return
        end

        local character = target:GetCharacter()
        if ( !character ) then
            client:Notify("The targeted player does not have a character!")
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
    Callback = function(info, client, arguments)
        local target = ax.util:FindPlayer(arguments[1])
        if ( !IsValid(target) ) then
            client:Notify("You must provide a valid player to take a flag from!")
            return
        end

        local character = target:GetCharacter()
        if ( !character ) then
            client:Notify("The targeted player does not have a character!")
            return
        end

        local flags = arguments[2]
        if ( !isstring(flags) or #flags == 0 ) then
            client:Notify("You must provide either single flag or a set of flags!")
            return
        end

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