--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local character = ax.character.meta

--- Get the amount of a specific currency this character has.
-- @realm shared
-- @param uniqueID string|nil The unique identifier of the currency (defaults to "credits")
-- @return number The amount of currency, or 0 if invalid currency or character
-- @usage local money = character:GetCurrency("credits")
function character:GetCurrency(uniqueID)
    uniqueID = uniqueID or "credits"

    if ( !ax.currencies:IsValid(uniqueID) ) then
        ax.util:PrintError("Attempted to get invalid currency: " .. tostring(uniqueID))
        return 0
    end

    return ax.character:GetVar(self, "currency_" .. uniqueID, 0)
end

--- Set the amount of a specific currency for this character.
-- Clamps the value to be non-negative. Use AddCurrency or TakeCurrency for modifications.
-- @realm shared
-- @param amount number The amount to set
-- @param uniqueID string The unique identifier of the currency (defaults to "credits")
-- @param bNoNetworking bool Optional flag to disable networking (server only)
-- @param recipients table Optional specific recipients for networking (server only)
-- @usage character:SetCurrency(1000, "credits")
function character:SetCurrency(amount, uniqueID, bNoNetworking, recipients)
    amount = tonumber(amount) or 0
    uniqueID = uniqueID or "credits"

    if ( !ax.currencies:IsValid(uniqueID) ) then
        ax.util:PrintError("Attempted to set invalid currency: " .. tostring(uniqueID))
        return
    end

    -- Clamp to non-negative values
    amount = math.max(0, amount)

    ax.character:SetVar(self, "currency_" .. uniqueID, amount, {
        bNoNetworking = bNoNetworking == true,
        recipients = recipients
    })
end

--- Add an amount of currency to this character.
-- Clamps the result to be non-negative.
-- @realm shared
-- @param amount number The amount to add (can be negative to subtract)
-- @param uniqueID string The unique identifier of the currency (defaults to "credits")
-- @param bNoNetworking bool Optional flag to disable networking (server only)
-- @param recipients table Optional specific recipients for networking (server only)
-- @return number The new total amount of currency
-- @usage character:AddCurrency(500, "credits")
function character:AddCurrency(amount, uniqueID, bNoNetworking, recipients)
    amount = tonumber(amount) or 0
    uniqueID = uniqueID or "credits"

    if ( !ax.currencies:IsValid(uniqueID) ) then
        ax.util:PrintError("Attempted to add invalid currency: " .. tostring(uniqueID))
        return 0
    end

    local currentAmount = self:GetCurrency(uniqueID)
    local newAmount = math.max(0, currentAmount + amount)

    self:SetCurrency(newAmount, uniqueID, bNoNetworking, recipients)

    return newAmount
end

--- Remove an amount of currency from this character.
-- Will not go below zero. Returns false if the character doesn't have enough.
-- @realm shared
-- @param amount number The amount to remove (must be positive)
-- @param uniqueID string The unique identifier of the currency (defaults to "credits")
-- @return bool True if the full amount was taken, false if insufficient funds
-- @usage if (character:TakeCurrency(100, "credits")) then
--     print("Purchased item")
-- else
--     print("Not enough credits")
-- end
function character:TakeCurrency(amount, uniqueID)
    amount = math.abs(tonumber(amount) or 0)
    uniqueID = uniqueID or "credits"

    if ( !ax.currencies:IsValid(uniqueID) ) then
        ax.util:PrintError("Attempted to take invalid currency: " .. tostring(uniqueID))
        return false
    end

    local currentAmount = self:GetCurrency(uniqueID)

    if ( currentAmount < amount ) then return false end

    self:SetCurrency(currentAmount - amount, uniqueID)

    return true
end

--- Check if this character has at least the specified amount of currency.
-- @realm shared
-- @param amount number The amount to check
-- @param uniqueID string The unique identifier of the currency (defaults to "credits")
-- @return bool True if the character has at least this amount, false otherwise
-- @usage if (character:HasCurrency(1000, "credits")) then
--     print("Character is wealthy")
-- end
function character:HasCurrency(amount, uniqueID)
    amount = tonumber(amount) or 0
    uniqueID = uniqueID or "credits"

    if ( !ax.currencies:IsValid(uniqueID) ) then
        ax.util:PrintError("Attempted to check invalid currency: " .. tostring(uniqueID))
        return false
    end

    return self:GetCurrency(uniqueID) >= amount
end

--- Convenience aliases for the default "credits" currency
-- These methods use "credits" as the default currency ID

--- Get credits amount (alias for GetCurrency with "credits").
-- @realm shared
-- @return number The amount of credits
-- @usage local credits = character:GetMoney()
function character:GetMoney(uniqueID)
    return self:GetCurrency(uniqueID or "credits")
end

--- Set credits amount (alias for SetCurrency with "credits").
-- @realm shared
-- @param amount number The amount to set
-- @param bNoNetworking bool Optional flag to disable networking (server only)
-- @param recipients table Optional specific recipients for networking (server only)
-- @usage character:SetMoney(1000)
function character:SetMoney(amount, uniqueID, bNoNetworking, recipients)
    self:SetCurrency(amount, uniqueID or "credits", bNoNetworking, recipients)
end

--- Add credits (alias for AddCurrency with "credits").
-- @realm shared
-- @param amount number The amount to add
-- @param bNoNetworking bool Optional flag to disable networking (server only)
-- @param recipients table Optional specific recipients for networking (server only)
-- @return number The new total amount of credits
-- @usage character:AddMoney(500)
function character:AddMoney(amount, uniqueID, bNoNetworking, recipients)
    return self:AddCurrency(amount, uniqueID or "credits", bNoNetworking, recipients)
end

--- Remove credits (alias for TakeCurrency with "credits").
-- @realm shared
-- @param amount number The amount to remove
-- @return bool True if successful, false if insufficient funds
-- @usage if (character:TakeMoney(100)) then
--     print("Purchase successful")
-- end
function character:TakeMoney(amount, uniqueID)
    return self:TakeCurrency(amount, uniqueID or "credits")
end

--- Check if character has credits (alias for HasCurrency with "credits").
-- @realm shared
-- @param amount number The amount to check
-- @return bool True if the character has at least this amount
-- @usage if (character:HasMoney(1000)) then
--     print("Can afford purchase")
-- end
function character:HasMoney(amount, uniqueID)
    return self:HasCurrency(amount, uniqueID or "credits")
end
