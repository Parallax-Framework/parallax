--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Player meta extensions for currency management.
-- These functions forward calls to the player's active character.
-- @module ax.player.meta

local player = ax.player.meta

-- @param uniqueID string|nil The unique identifier of the currency (defaults to "credits")
function player:GetCurrency(amount, uniqueID)
    if ( isstring(amount) ) then
        uniqueID = amount
        amount = nil
    end

    local character = self:GetCharacter()
    if ( !character ) then
        return 0
    end

    return character:GetCurrency(uniqueID)
end

-- @param uniqueID string The unique identifier of the currency (defaults to "credits")
-- @usage client:SetCurrency(1000, "credits")
function player:SetCurrency(amount, uniqueID, bNoNetworking, recipients)
    local character = self:GetCharacter()
    if ( !character ) then
        ax.util:PrintWarning("Attempted to set currency on player without active character")
        return
    end

    character:SetCurrency(amount, uniqueID, bNoNetworking, recipients)
end

-- @param uniqueID string The unique identifier of the currency (defaults to "credits")
-- @usage client:AddCurrency(500, "credits")
function player:AddCurrency(amount, uniqueID, bNoNetworking, recipients)
    local character = self:GetCharacter()
    if ( !character ) then
        ax.util:PrintWarning("Attempted to add currency to player without active character")
        return 0
    end

    return character:AddCurrency(amount, uniqueID, bNoNetworking, recipients)
end

-- @param uniqueID string The unique identifier of the currency (defaults to "credits")
-- @usage if (client:TakeCurrency(100, "credits")) then
--     print("Purchase successful")
-- end
function player:TakeCurrency(amount, uniqueID)
    local character = self:GetCharacter()
    if ( !character ) then
        ax.util:PrintWarning("Attempted to take currency from player without active character")
        return false
    end

    return character:TakeCurrency(amount, uniqueID)
end

-- @param uniqueID string The unique identifier of the currency (defaults to "credits")
-- @usage if (client:HasCurrency(1000, "credits")) then
--     print("Player can afford this")
-- end
function player:HasCurrency(amount, uniqueID)
    local character = self:GetCharacter()
    if ( !character ) then return false end

    return character:HasCurrency(amount, uniqueID)
end

--- Convenience aliases for the default "credits" currency
-- These methods forward to the character's money methods

--- Get credits amount (alias for GetCurrency with "credits").
-- @realm shared
-- @return number The amount of credits, or 0 if no character
-- @usage local credits = client:GetMoney()
function player:GetMoney(uniqueID)
    local character = self:GetCharacter()
    if ( !character ) then
        return 0
    end

    return character:GetMoney(uniqueID)
end

--- Set credits amount (alias for SetCurrency with "credits").
-- @realm shared
-- @param amount number The amount to set
-- @param bNoNetworking bool Optional flag to disable networking (server only)
-- @param recipients table Optional specific recipients for networking (server only)
-- @usage client:SetMoney(1000)
function player:SetMoney(amount, uniqueID, bNoNetworking, recipients)
    local character = self:GetCharacter()
    if ( !character ) then
        ax.util:PrintWarning("Attempted to set money on player without active character")
        return
    end

    character:SetMoney(amount, uniqueID, bNoNetworking, recipients)
end

--- Add credits (alias for AddCurrency with "credits").
-- @realm shared
-- @param amount number The amount to add
-- @param bNoNetworking bool Optional flag to disable networking (server only)
-- @param recipients table Optional specific recipients for networking (server only)
-- @return number The new total amount of credits, or 0 if no character
-- @usage client:AddMoney(500)
function player:AddMoney(amount, uniqueID, bNoNetworking, recipients)
    local character = self:GetCharacter()
    if ( !character ) then
        ax.util:PrintWarning("Attempted to add money to player without active character")
        return 0
    end

    return character:AddMoney(amount, uniqueID, bNoNetworking, recipients)
end

--- Remove credits (alias for TakeCurrency with "credits").
-- @realm shared
-- @param amount number The amount to remove
-- @return bool True if successful, false if no character or insufficient funds
-- @usage if (client:TakeMoney(100)) then
--     print("Purchase successful")
-- end
function player:TakeMoney(amount, uniqueID)
    local character = self:GetCharacter()
    if ( !character ) then
        ax.util:PrintWarning("Attempted to take money from player without active character")
        return false
    end

    return character:TakeMoney(amount, uniqueID)
end

--- Check if player's character has credits (alias for HasCurrency with "credits").
-- @realm shared
-- @param amount number The amount to check
-- @return bool True if the character has at least this amount, false otherwise
-- @usage if (client:HasMoney(1000)) then
--     print("Can afford purchase")
-- end
function player:HasMoney(amount, uniqueID)
    local character = self:GetCharacter()
    if ( !character ) then return false end

    return character:HasMoney(amount, uniqueID)
end
