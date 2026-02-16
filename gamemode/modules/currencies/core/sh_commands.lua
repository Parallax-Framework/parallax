--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local function normalizeAmount(value)
    local n = tonumber(value) or 0
    n = math.floor(math.abs(n))
    return n
end

local function validateAndDrop(client, amount, currencyID)
    currencyID = currencyID or "credits"
    amount = normalizeAmount(amount)

    if ( amount <= 0 ) then
        return "Please enter a positive amount."
    end

    if ( !ax.currencies:IsValid(currencyID) ) then
        return "That currency doesn't exist: " .. tostring(currencyID)
    end

    local character = client:GetCharacter()
    if ( !character ) then
        return "You don't have a character loaded right now."
    end

    if ( !character:HasCurrency(amount, currencyID) ) then
        return "You don't have enough " .. (ax.currencies:Get(currencyID).plural or "funds") .. "."
    end

    character:TakeCurrency(amount, currencyID)

    if ( SERVER ) then
        ax.currencies:Spawn(amount, currencyID, client)
    end

    return "You dropped " .. ax.currencies:Format(currencyID, amount) .. "."
end

ax.command:Add("DropCurrency", {
    description = "Drop an amount of a currency as a world item",
    arguments = {
        { name = "amount", type = ax.type.number },
        { name = "currencyID", type = ax.type.string, optional = true }
    },
    OnRun = function(def, client, amount, currencyID)
        return validateAndDrop(client, amount, currencyID)
    end
})

ax.command:Add("DropMoney", {
    description = "Drop credits (default currency) as a world item",
    arguments = {
        { name = "amount", type = ax.type.number }
    },
    OnRun = function(def, client, amount)
        return validateAndDrop(client, amount, "credits")
    end
})

local function validateCurrencyID(currencyID)
    currencyID = currencyID or "credits"
    if ( !ax.currencies:IsValid(currencyID) ) then
        return nil, "That currency doesn't exist: " .. tostring(currencyID)
    end
    return currencyID
end

local function requireCharacter(client)
    local character = ax.util:IsValidPlayer(client) and client:GetCharacter() or nil
    if ( !character ) then
        return nil, "That player doesn't have an active character."
    end
    return character
end

ax.command:Add("GiveMoney", {
    description = "Give money to the player you're looking at",
    arguments = {
        { name = "amount", type = ax.type.number, min = 1 }
    },
    OnRun = function(def, client, amount)
        if ( !ax.util:IsValidPlayer(client) ) then
            return "Couldn't identify you as a valid player."
        end

        amount = normalizeAmount(amount)
        if ( amount <= 0 ) then
            return "Please enter a positive amount."
        end

        local trace = client:GetEyeTrace()
        local target = trace and trace.Entity or nil
        if ( !ax.util:IsValidPlayer(target) ) then
            return "You need to be looking at a valid player."
        end

        local character, errMsg = requireCharacter(target)
        if ( !character ) then return errMsg end

        local delta = ax.currencies:Format(amount, "credits")
        character:AddCurrency(amount, "credits")

        return string.format("You gave %s to %s.", delta, target:Nick())
    end
})

ax.command:Add("CharSetCurrency", {
    description = "Set a player's currency to an exact amount",
    superAdminOnly = true,
    arguments = {
        { name = "player", type = ax.type.player },
        { name = "amount", type = ax.type.number, min = 0 },
        { name = "currencyID", type = ax.type.string, optional = true }
    },
    OnRun = function(def, client, target, amount, currencyID)
        local okID, err = validateCurrencyID(currencyID)
        if ( !okID ) then return err end

        amount = normalizeAmount(amount)

        local character, errMsg = requireCharacter(target)
        if ( !character ) then return errMsg end

        character:SetCurrency(amount, okID)

        local formatted = ax.currencies:Format(amount, okID)
        return string.format("Set %s's %s to %s.", target:Nick(), okID, formatted)
    end
})

ax.command:Add("CharAddCurrency", {
    description = "Add an amount of currency to a player",
    superAdminOnly = true,
    arguments = {
        { name = "player", type = ax.type.player },
        { name = "amount", type = ax.type.number, min = 1 },
        { name = "currencyID", type = ax.type.string, optional = true }
    },
    prefix = {"GiveCurrency"},
    OnRun = function(def, client, target, amount, currencyID)
        local okID, err = validateCurrencyID(currencyID)
        if ( !okID ) then return err end

        amount = normalizeAmount(amount)
        local character, errMsg = requireCharacter(target)
        if ( !character ) then return errMsg end

        local newTotal = character:AddCurrency(amount, okID)
        local delta = ax.currencies:Format(amount, okID)
        local total = ax.currencies:Format(newTotal, okID)
        return string.format("Added %s to %s (%s total).", delta, target:Nick(), total)
    end
})

ax.command:Add("CharTakeCurrency", {
    description = "Take an amount of currency from a player",
    superAdminOnly = true,
    arguments = {
        { name = "player", type = ax.type.player },
        { name = "amount", type = ax.type.number, min = 1 },
        { name = "currencyID", type = ax.type.string, optional = true }
    },
    prefix = {"RemoveCurrency"},
    OnRun = function(def, client, target, amount, currencyID)
        local okID, err = validateCurrencyID(currencyID)
        if ( !okID ) then return err end

        amount = normalizeAmount(amount)

        local character, errMsg = requireCharacter(target)
        if ( !character ) then return errMsg end

        if ( !character:TakeCurrency(amount, okID) ) then
            return string.format("%s doesn't have enough %s.", target:Nick(), okID)
        end

        local delta = ax.currencies:Format(amount, okID)
        local remaining = ax.currencies:Format(character:GetCurrency(okID), okID)
        return string.format("Took %s from %s (%s remaining).", delta, target:Nick(), remaining)
    end
})

ax.command:Add("CharGetCurrency", {
    description = "Show a player's balance for a currency",
    superAdminOnly = true,
    arguments = {
        { name = "player", type = ax.type.player },
        { name = "currencyID", type = ax.type.string, optional = true }
    },
    OnRun = function(def, client, target, currencyID)
        local okID, err = validateCurrencyID(currencyID)
        if ( !okID ) then return err end

        local character, errMsg = requireCharacter(target)
        if ( !character ) then return errMsg end

        local amount = character:GetCurrency(okID)
        local formatted = ax.currencies:Format(amount, okID)
        return string.format("%s has %s.", target:Nick(), formatted)
    end
})

ax.command:Add("CharAddCurrencyAll", {
    description = "Add currency to all players with characters",
    superAdminOnly = true,
    arguments = {
        { name = "amount", type = ax.type.number, min = 1 },
        { name = "currencyID", type = ax.type.string, optional = true }
    },
    OnRun = function(def, client, amount, currencyID)
        local okID, err = validateCurrencyID(currencyID)
        if ( !okID ) then return err end

        amount = normalizeAmount(amount)

        local count = 0
        for _, target in ipairs(player.GetAll()) do
            local character = target:GetCharacter()
            if ( character ) then
                character:AddCurrency(amount, okID)
                count = count + 1
            end
        end

        local delta = ax.currencies:Format(amount, okID)
        return string.format("Added %s to %d player(s).", delta, count)
    end
})

ax.command:Add("CharSetCurrencyAll", {
    description = "Set currency amount for all players with characters",
    superAdminOnly = true,
    arguments = {
        { name = "amount", type = ax.type.number, min = 0 },
        { name = "currencyID", type = ax.type.string, optional = true }
    },
    OnRun = function(def, client, amount, currencyID)
        local okID, err = validateCurrencyID(currencyID)
        if ( !okID ) then return err end

        amount = normalizeAmount(amount)

        local count = 0
        for _, target in ipairs(player.GetAll()) do
            local character = target:GetCharacter()
            if ( character ) then
                character:SetCurrency(amount, okID)
                count = count + 1
            end
        end

        local formatted = ax.currencies:Format(amount, okID)
        return string.format("Set %s for %d player(s).", formatted, count)
    end
})

ax.command:Add("CharSetMoney", {
    description = "Set a player's money (default currency)",
    superAdminOnly = true,
    arguments = {
        { name = "player", type = ax.type.player },
        { name = "amount", type = ax.type.number, min = 0 }
    },
    OnRun = function(def, client, target, amount)
        return ax.command.registry["CharSetCurrency"]:OnRun(client, target, amount, "credits")
    end
})

ax.command:Add("CharAddMoney", {
    description = "Add money to a player (default currency)",
    superAdminOnly = true,
    arguments = {
        { name = "player", type = ax.type.player },
        { name = "amount", type = ax.type.number, min = 1 }
    },
    prefix = {"MoneyAdd"},
    OnRun = function(def, client, target, amount)
        return ax.command.registry["CharAddCurrency"]:OnRun(client, target, amount, "credits")
    end
})

ax.command:Add("CharTakeMoney", {
    description = "Take money from a player (default currency)",
    superAdminOnly = true,
    arguments = {
        { name = "player", type = ax.type.player },
        { name = "amount", type = ax.type.number, min = 1 }
    },
    alias = {"RemoveMoney"},
    OnRun = function(def, client, target, amount)
        return ax.command.registry["CharTakeCurrency"]:OnRun(client, target, amount, "credits")
    end
})

ax.command:Add("CharGetMoney", {
    description = "Show a player's money (default currency)",
    superAdminOnly = true,
    arguments = {
        { name = "player", type = ax.type.player }
    },
    alias = {"MoneyGet", "BalanceMoney"},
    OnRun = function(def, client, target)
        return ax.command.registry["CharGetCurrency"]:OnRun(client, target, "credits")
    end
})
