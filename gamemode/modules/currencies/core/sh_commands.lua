--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

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
        return "Amount must be a positive number"
    end

    if ( !ax.currencies:IsValid(currencyID) ) then
        return "Unknown currency: " .. tostring(currencyID)
    end

    local character = client:GetCharacter()
    if ( !character ) then
        return "You don't have an active character"
    end

    if ( !character:HasCurrency(amount, currencyID) ) then
        return "You don't have enough " .. (ax.currencies:Get(currencyID).plural or "funds")
    end

    character:TakeCurrency(amount, currencyID)

    if ( SERVER ) then
        ax.currencies:Spawn(amount, currencyID, client)
    end

    return "Dropped " .. ax.currencies:Format(currencyID, amount)
end

ax.command:Add("DropCurrency", {
    description = "Drop an amount of a currency as a world item",
    arguments = {
        { name = "amount", type = ax.type.number },
        { name = "currencyID", type = ax.type.string, optional = true }
    },
    OnRun = function(client, amount, currencyID)
        return validateAndDrop(client, amount, currencyID)
    end
})

ax.command:Add("DropMoney", {
    description = "Drop credits (default currency) as a world item",
    arguments = {
        { name = "amount", type = ax.type.number }
    },
    OnRun = function(client, amount)
        return validateAndDrop(client, amount, "credits")
    end
})

local function validateCurrencyID(currencyID)
    currencyID = currencyID or "credits"
    if ( !ax.currencies:IsValid(currencyID) ) then
        return nil, "Unknown currency: " .. tostring(currencyID)
    end
    return currencyID
end

local function requireCharacter(client)
    local character = IsValid(client) and client:GetCharacter() or nil
    if ( !character ) then
        return nil, "Target has no active character"
    end
    return character
end

ax.command:Add("SetCurrency", {
    description = "Set a player's currency to an exact amount",
    superAdminOnly = true,
    arguments = {
        { name = "player", type = ax.type.player },
        { name = "amount", type = ax.type.number, min = 0 },
        { name = "currencyID", type = ax.type.string, optional = true }
    },
    alias = {"currency_set"},
    OnRun = function(client, target, amount, currencyID)
        local okID, err = validateCurrencyID(currencyID)
        if ( !okID ) then return err end

        amount = normalizeAmount(amount)

        local character, errMsg = requireCharacter(target)
        if ( !character ) then return errMsg end

        character:SetCurrency(amount, okID)

        local formatted = ax.currencies:Format(okID, amount)
        return string.format("Set %s's %s to %s", target:Name(), okID, formatted)
    end
})

ax.command:Add("AddCurrency", {
    description = "Add an amount of currency to a player",
    superAdminOnly = true,
    arguments = {
        { name = "player", type = ax.type.player },
        { name = "amount", type = ax.type.number, min = 1 },
        { name = "currencyID", type = ax.type.string, optional = true }
    },
    alias = {"currency_add", "GiveCurrency"},
    OnRun = function(client, target, amount, currencyID)
        local okID, err = validateCurrencyID(currencyID)
        if ( !okID ) then return err end

        amount = normalizeAmount(amount)

        local character, errMsg = requireCharacter(target)
        if ( !character ) then return errMsg end

        local newTotal = character:AddCurrency(amount, okID)
        local delta = ax.currencies:Format(okID, amount)
        local total = ax.currencies:Format(okID, newTotal)
        return string.format("Added %s to %s (%s total)", delta, target:Name(), total)
    end
})

ax.command:Add("TakeCurrency", {
    description = "Take an amount of currency from a player",
    superAdminOnly = true,
    arguments = {
        { name = "player", type = ax.type.player },
        { name = "amount", type = ax.type.number, min = 1 },
        { name = "currencyID", type = ax.type.string, optional = true }
    },
    alias = {"currency_take", "RemoveCurrency"},
    OnRun = function(client, target, amount, currencyID)
        local okID, err = validateCurrencyID(currencyID)
        if ( !okID ) then return err end

        amount = normalizeAmount(amount)

        local character, errMsg = requireCharacter(target)
        if ( !character ) then return errMsg end

        if ( !character:TakeCurrency(amount, okID) ) then
            return string.format("%s does not have enough %s", target:Name(), okID)
        end

        local delta = ax.currencies:Format(okID, amount)
        local remaining = ax.currencies:Format(okID, character:GetCurrency(okID))
        return string.format("Took %s from %s (%s remaining)", delta, target:Name(), remaining)
    end
})

ax.command:Add("GetCurrency", {
    description = "Show a player's balance for a currency",
    superAdminOnly = true,
    arguments = {
        { name = "player", type = ax.type.player },
        { name = "currencyID", type = ax.type.string, optional = true }
    },
    alias = {"currency_get", "Balance"},
    OnRun = function(client, target, currencyID)
        local okID, err = validateCurrencyID(currencyID)
        if ( !okID ) then return err end

        local character, errMsg = requireCharacter(target)
        if ( !character ) then return errMsg end

        local amount = character:GetCurrency(okID)
        local formatted = ax.currencies:Format(okID, amount)
        return string.format("%s has %s", target:Name(), formatted)
    end
})

ax.command:Add("AddCurrencyAll", {
    description = "Add currency to all players with characters",
    superAdminOnly = true,
    arguments = {
        { name = "amount", type = ax.type.number, min = 1 },
        { name = "currencyID", type = ax.type.string, optional = true }
    },
    alias = {"currency_addall"},
    OnRun = function(client, amount, currencyID)
        local okID, err = validateCurrencyID(currencyID)
        if ( !okID ) then return err end

        amount = normalizeAmount(amount)

        local count = 0
        for _, ply in ipairs(player.GetAll()) do
            local char = ply:GetCharacter()
            if ( char ) then
                char:AddCurrency(amount, okID)
                count = count + 1
            end
        end

        local delta = ax.currencies:Format(okID, amount)
        return string.format("Added %s to %d player(s)", delta, count)
    end
})

ax.command:Add("SetCurrencyAll", {
    description = "Set currency amount for all players with characters",
    superAdminOnly = true,
    arguments = {
        { name = "amount", type = ax.type.number, min = 0 },
        { name = "currencyID", type = ax.type.string, optional = true }
    },
    alias = {"currency_setall"},
    OnRun = function(client, amount, currencyID)
        local okID, err = validateCurrencyID(currencyID)
        if ( !okID ) then return err end

        amount = normalizeAmount(amount)

        local count = 0
        for _, ply in ipairs(player.GetAll()) do
            local char = ply:GetCharacter()
            if ( char ) then
                char:SetCurrency(amount, okID)
                count = count + 1
            end
        end

        local formatted = ax.currencies:Format(okID, amount)
        return string.format("Set %s for %d player(s)", formatted, count)
    end
})

ax.command:Add("SetMoney", {
    description = "Set a player's money (default currency)",
    superAdminOnly = true,
    arguments = {
        { name = "player", type = ax.type.player },
        { name = "amount", type = ax.type.number, min = 0 }
    },
    alias = {"money_set"},
    OnRun = function(client, target, amount)
        return ax.command.registry[ax.util:NameToUniqueID("SetCurrency")].OnRun(client, target, amount, "credits")
    end
})

ax.command:Add("AddMoney", {
    description = "Add money to a player (default currency)",
    superAdminOnly = true,
    arguments = {
        { name = "player", type = ax.type.player },
        { name = "amount", type = ax.type.number, min = 1 }
    },
    alias = {"money_add", "GiveMoney"},
    OnRun = function(client, target, amount)
        return ax.command.registry[ax.util:NameToUniqueID("AddCurrency")].OnRun(client, target, amount, "credits")
    end
})

ax.command:Add("TakeMoney", {
    description = "Take money from a player (default currency)",
    superAdminOnly = true,
    arguments = {
        { name = "player", type = ax.type.player },
        { name = "amount", type = ax.type.number, min = 1 }
    },
    alias = {"money_take", "RemoveMoney"},
    OnRun = function(client, target, amount)
        return ax.command.registry[ax.util:NameToUniqueID("TakeCurrency")].OnRun(client, target, amount, "credits")
    end
})

ax.command:Add("GetMoney", {
    description = "Show a player's money (default currency)",
    superAdminOnly = true,
    arguments = {
        { name = "player", type = ax.type.player }
    },
    alias = {"money_get", "BalanceMoney"},
    OnRun = function(client, target)
        return ax.command.registry[ax.util:NameToUniqueID("GetCurrency")].OnRun(client, target, "credits")
    end
})
