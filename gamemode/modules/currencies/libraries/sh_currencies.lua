--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Character-based currency system for managing multiple currencies in roleplay scenarios.
-- This library provides currency registration, formatting, and character-based storage with
-- networking support for synchronized currency values between server and clients.
-- @module ax.currencies

ax.currencies = ax.currencies or {}
ax.currencies.registry = ax.currencies.registry or {}

--- Register a new currency type.
-- Creates a currency definition that can be used for character money management.
-- Automatically registers a character variable for storing the currency value.
-- @realm shared
-- @param uniqueID string The unique identifier for the currency (e.g., "credits", "tokens")
-- @param data table Currency configuration table with the following fields:
--   - name (string): Display name of the currency
--   - symbol (string): Currency symbol (e.g., "$", "¥", "₹")
--   - default (number): Default starting amount (defaults to 0)
--   - singular (string): Singular form of currency name (e.g., "credit")
--   - plural (string): Plural form of currency name (e.g., "credits")
--   - format (function): Optional custom formatting function(amount) -> string
-- @return bool True if registration succeeded, false otherwise
-- @usage ax.currencies:Register("credits", {
--     name = "Credits",
--     symbol = "¢",
--     default = 100,
--     singular = "credit",
--     plural = "credits"
-- })
function ax.currencies:Register(uniqueID, data)
    if ( !isstring(uniqueID) or !istable(data) ) then
        ax.util:PrintError("Invalid arguments provided to ax.currencies:Register()")
        return false
    end

    if ( self.registry[uniqueID] ) then
        ax.util:PrintWarning("Currency '" .. uniqueID .. "' is already registered, overwriting")
    end

    -- Set defaults for missing fields
    data.uniqueID = uniqueID
    data.name = data.name or uniqueID
    data.symbol = data.symbol or "$"
    data.default = tonumber(data.default) or 0
    data.singular = data.singular or data.name
    data.plural = data.plural or (data.name .. "s")

    -- Create default format function if not provided
    if ( !isfunction(data.format) ) then
        data.format = function(amount)
            amount = tonumber(amount) or 0

            local formatted = string.Comma(math.floor(amount))
            if ( amount == 1 ) then
                return formatted .. " " .. data.singular
            else
                return formatted .. " " .. data.plural
            end
        end
    end

    self.registry[uniqueID] = data

    -- Register character variable for this currency
    ax.character:RegisterVar("currency_" .. uniqueID, {
        default = data.default,
        field = "currency_" .. uniqueID,
        fieldType = ax.type.number,
        bNoGetter = true,
        bNoSetter = true
    })

    ax.util:PrintDebug("Registered currency: " .. uniqueID)

    return true
end

--- Get a registered currency by its unique ID.
-- @realm shared
-- @param uniqueID string The unique identifier of the currency
-- @return table|nil The currency data table if found, nil otherwise
-- @usage local credits = ax.currencies:Get("credits")
function ax.currencies:Get(uniqueID)
    if ( !isstring(uniqueID) ) then
        ax.util:PrintError("Invalid currency ID provided to ax.currencies:Get()")
        return nil
    end

    return self.registry[uniqueID]
end

--- Get all registered currencies.
-- @realm shared
-- @return table Table of all registered currencies keyed by their unique IDs
-- @usage for id, currencyData in pairs(ax.currencies:GetAll()) do
--     print(id, currencyData.name)
-- end
function ax.currencies:GetAll()
    return self.registry
end

--- Check if a currency is valid and registered.
-- @realm shared
-- @param uniqueID string The unique identifier to check
-- @return bool True if the currency exists, false otherwise
-- @usage if (ax.currencies:IsValid("credits")) then
--     print("Credits currency is registered")
-- end
function ax.currencies:IsValid(uniqueID)
    return self.registry[uniqueID] != nil
end

--- Format a currency amount using the currency's formatter.
-- Falls back to basic formatting if currency is not found or invalid.
-- @realm shared
-- @param amount number The amount to format
-- @param uniqueID string The unique identifier of the currency
-- @return string Formatted currency string (e.g., "1,234 credits")
-- @usage local formatted = ax.currencies:Format("credits", 1000)
-- -- Returns: "1,000 credits"
function ax.currencies:Format(amount, uniqueID)
    amount = tonumber(amount) or 0
    uniqueID = uniqueID or "credits"

    local currencyData = self:Get(uniqueID)
    if ( !currencyData ) then
        ax.util:PrintWarning("Attempted to format invalid currency: " .. tostring(uniqueID))
        return tostring(amount)
    end

    if ( isfunction(currencyData.format) ) then
        local success, result = pcall(currencyData.format, amount)
        if ( success ) then
            return result
        else
            ax.util:PrintError("Error formatting currency '" .. uniqueID .. "': " .. result)
        end
    end

    -- Fallback formatting
    return string.Comma(math.floor(amount)) .. " " .. currencyData.plural
end

-- Register default currency immediately
--- Spawn a currency entity in the world (server only).
-- Creates a physical entity representing dropped currency that players can pick up.
-- @realm server
-- @param amount number The amount of currency to spawn
-- @param uniqueID string The unique identifier of the currency (defaults to "credits")
-- @param position vector|Player The position to spawn at, or a player (spawns at their drop position)
-- @param angle Angle Optional angle for the entity (defaults to random)
-- @return Entity|nil The spawned currency entity, or nil if invalid parameters
-- @usage local money = ax.currencies:Spawn(500, "credits", player:GetPos() + Vector(0, 0, 32))
function ax.currencies:Spawn(amount, uniqueID, position, angle)
    if ( CLIENT ) then return nil end

    amount = math.abs(tonumber(amount) or 0)
    uniqueID = uniqueID or "credits"

    if ( amount <= 0 ) then
        ax.util:PrintError("Invalid amount for currency spawn: " .. tostring(amount))
        return nil
    end

    if ( !self:IsValid(uniqueID) ) then
        ax.util:PrintError("Invalid currency ID for spawn: " .. tostring(uniqueID))
        return nil
    end

    -- Handle player position
    if ( IsValid(position) and position:IsPlayer() ) then
        position = position:GetPos() + position:GetForward() * 32 + Vector(0, 0, 16)
    end

    if ( !isvector(position) ) then
        ax.util:PrintError("Invalid position for currency spawn")
        return nil
    end

    local entity = ents.Create("ax_currency")
    if ( !IsValid(entity) ) then
        ax.util:PrintError("Failed to create ax_currency entity")
        return nil
    end

    entity:SetPos(position)
    entity:SetAngles(angle or AngleRand())
    entity:SetAmount(amount)
    entity:SetCurrencyID(uniqueID)
    entity:Spawn()
    entity:Activate()

    local physicsObject = entity:GetPhysicsObject()
    if ( IsValid(physicsObject) ) then
        physicsObject:Wake()
    end

    hook.Run("CurrencySpawned", entity, amount, uniqueID, position)

    return entity
end

-- Register default currency on initialization
ax.currencies:Register("credits", {
    name = "Credits",
    symbol = "¢",
    default = 0,
    singular = "credit",
    plural = "credits"
})
