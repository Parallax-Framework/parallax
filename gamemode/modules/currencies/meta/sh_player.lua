--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local player = ax.player.meta

--- Returns the active character's amount for a currency. Delegates to `Character:GetCurrency`. For backwards compatibility, passing a string as the first argument is treated as `uniqueID`. Returns 0 when the player has no active character.
---@realm shared
---@param amount number|string|nil Ignored amount placeholder, or the currency unique ID when passed as a string.
---@param uniqueID string|nil The unique identifier of the currency. Defaults to the currency module default.
---@return number # The amount of the requested currency.
---@usage local credits = client:GetCurrency("credits")
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

--- Sets the active character's amount for a currency. Delegates to `Character:SetCurrency` and optionally suppresses networking or limits recipients. Prints a warning and returns nil when the player has no active character.
---@realm shared
---@param amount number The amount to set.
---@param uniqueID string|nil The unique identifier of the currency. Defaults to the currency module default.
---@param bNoNetworking boolean|nil When true, suppresses currency networking.
---@param recipients? Player|table|nil Optional networking recipients.
---@usage client:SetCurrency(1000, "default")
function player:SetCurrency(amount, uniqueID, bNoNetworking, recipients)
    local character = self:GetCharacter()
    if ( !character ) then
        ax.util:PrintWarning("Attempted to set currency on player without active character")
        return
    end

    character:SetCurrency(amount, uniqueID, bNoNetworking, recipients)
end

--- Adds currency to the active character. Delegates to `Character:AddCurrency` and returns the new total. Returns 0 when the player has no active character.
---@realm shared
---@param amount number The amount to add.
---@param uniqueID string|nil The unique identifier of the currency. Defaults to the currency module default.
---@param bNoNetworking boolean|nil When true, suppresses currency networking.
---@param recipients? Player|table|nil Optional networking recipients.
---@return number # The new currency total, or 0 when no character is active.
---@usage local newTotal = client:AddCurrency(500, "default")
function player:AddCurrency(amount, uniqueID, bNoNetworking, recipients)
    local character = self:GetCharacter()
    if ( !character ) then
        ax.util:PrintWarning("Attempted to add currency to player without active character")
        return 0
    end

    return character:AddCurrency(amount, uniqueID, bNoNetworking, recipients)
end

--- Attempts to remove currency from the active character. Delegates to `Character:TakeCurrency` and returns whether the removal succeeded. Returns false when the player has no active character or insufficient funds.
---@realm shared
---@param amount number The amount to remove.
---@param uniqueID string|nil The unique identifier of the currency. Defaults to the currency module default.
---@return boolean # True if the currency was removed, false otherwise.
---@usage if ( client:TakeCurrency(100, "default") ) then
---     print("Purchase successful")
--- end
function player:TakeCurrency(amount, uniqueID)
    local character = self:GetCharacter()
    if ( !character ) then
        ax.util:PrintWarning("Attempted to take currency from player without active character")
        return false
    end

    return character:TakeCurrency(amount, uniqueID)
end

--- Returns whether the active character has at least the requested currency amount. Delegates to `Character:HasCurrency`. Returns false when the player has no active character.
---@realm shared
---@param amount number The minimum amount required.
---@param uniqueID string|nil The unique identifier of the currency. Defaults to the currency module default.
---@return boolean # True if the character can afford the amount, false otherwise.
---@usage if ( client:HasCurrency(1000, "default") ) then
---     print("Player can afford this")
--- end
function player:HasCurrency(amount, uniqueID)
    local character = self:GetCharacter()
    if ( !character ) then return false end

    return character:HasCurrency(amount, uniqueID)
end

--- Convenience aliases for the default "default" currency
-- These methods forward to the character's money methods

--- Returns the active character's money amount. Convenience alias that delegates to `Character:GetMoney`.
---@realm shared
---@param uniqueID? string|nil Optional currency unique ID for non-default money aliases.
---@return number # The amount of money, or 0 if no character is active.
---@usage local money = client:GetMoney()
function player:GetMoney(uniqueID)
    local character = self:GetCharacter()
    if ( !character ) then
        return 0
    end

    return character:GetMoney(uniqueID)
end

--- Sets the active character's money amount. Convenience alias that delegates to `Character:SetMoney`.
---@realm shared
---@param amount number The amount to set.
---@param uniqueID? string|nil Optional currency unique ID for non-default money aliases.
---@param bNoNetworking? boolean|nil Optional flag to disable networking.
---@param recipients? Player|table|nil Optional specific recipients for networking.
---@usage client:SetMoney(1000)
function player:SetMoney(amount, uniqueID, bNoNetworking, recipients)
    local character = self:GetCharacter()
    if ( !character ) then
        ax.util:PrintWarning("Attempted to set money on player without active character")
        return
    end

    character:SetMoney(amount, uniqueID, bNoNetworking, recipients)
end

--- Adds money to the active character. Convenience alias that delegates to `Character:AddMoney`.
---@realm shared
---@param amount number The amount to add.
---@param uniqueID? string|nil Optional currency unique ID for non-default money aliases.
---@param bNoNetworking? boolean|nil Optional flag to disable networking.
---@param recipients? Player|table|nil Optional specific recipients for networking.
---@return number # The new total amount of money, or 0 if no character is active.
---@usage local newTotal = client:AddMoney(500)
function player:AddMoney(amount, uniqueID, bNoNetworking, recipients)
    local character = self:GetCharacter()
    if ( !character ) then
        ax.util:PrintWarning("Attempted to add money to player without active character")
        return 0
    end

    return character:AddMoney(amount, uniqueID, bNoNetworking, recipients)
end

--- Attempts to remove money from the active character. Convenience alias that delegates to `Character:TakeMoney`.
---@realm shared
---@param amount number The amount to remove.
---@param uniqueID? string|nil Optional currency unique ID for non-default money aliases.
---@return boolean # True if successful, false if no character or insufficient funds.
---@usage if ( client:TakeMoney(100) ) then
---     print("Purchase successful")
--- end
function player:TakeMoney(amount, uniqueID)
    local character = self:GetCharacter()
    if ( !character ) then
        ax.util:PrintWarning("Attempted to take money from player without active character")
        return false
    end

    return character:TakeMoney(amount, uniqueID)
end

--- Returns whether the active character has at least the requested money amount. Convenience alias that delegates to `Character:HasMoney`.
---@realm shared
---@param amount number The amount to check.
---@param uniqueID? string|nil Optional currency unique ID for non-default money aliases.
---@return boolean # True if the character has at least this amount, false otherwise.
---@usage if ( client:HasMoney(1000) ) then
---     print("Can afford purchase")
--- end
function player:HasMoney(amount, uniqueID)
    local character = self:GetCharacter()
    if ( !character ) then return false end

    return character:HasMoney(amount, uniqueID)
end
