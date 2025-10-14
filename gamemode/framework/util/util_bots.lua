--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Utility helpers used across the Parallax framework (printing, file handling, text utilities, etc.).
-- @module ax.util

--- Bot utility functions for automatic character creation
-- @section bot_utilities

--- Bot first name components for generating random names
local BOT_FIRST_NAMES = {
    "Alex", "Jordan", "Casey", "Morgan", "Taylor", "Jamie", "Riley", "Avery",
    "Quinn", "Sage", "Cameron", "Rowan", "Blake", "Phoenix", "Reese", "Parker",
    "Drew", "Emery", "Finley", "Hayden", "Logan", "River", "Skyler", "Dakota"
}

--- Bot last name components for generating random names
local BOT_LAST_NAMES = {
    "Anderson", "Baker", "Clark", "Davis", "Evans", "Foster", "Garcia", "Harris",
    "Johnson", "Kelly", "Lewis", "Martin", "Nelson", "Parker", "Quinn", "Rodriguez",
    "Smith", "Taylor", "Walker", "Wilson", "Young", "Brown", "Miller", "Moore"
}

--- Generates a random name for a bot
-- @return string A randomly generated full name
-- @usage local name = ax.util:GenerateBotName()
function ax.util:GenerateBotName()
    local firstName = BOT_FIRST_NAMES[math.random(#BOT_FIRST_NAMES)]
    local lastName = BOT_LAST_NAMES[math.random(#BOT_LAST_NAMES)]
    return firstName .. " " .. lastName
end

--- Gets a random faction that bots can join
-- @return table|nil Random faction table or nil if no valid factions
-- @usage local faction = ax.util:GetRandomBotFaction()
function ax.util:GetRandomBotFaction()
    local factions = ax.faction:GetAll()
    if ( !factions or #factions == 0 ) then
        return nil
    end

    -- Filter factions that bots can join (default factions or ones without whitelist restrictions)
    local validFactions = {}
    for i = 1, #factions do
        local faction = factions[i]
        if ( faction and (faction.isDefault or faction.allowBots != false) ) then
            table.insert(validFactions, faction)
        end
    end

    if ( #validFactions == 0 ) then
        return nil
    end

    return validFactions[math.random(#validFactions)]
end

--- Gets a random model from a faction's model list
-- @param faction table The faction to get a model from
-- @return string|nil Random model path or nil if no models available
-- @usage local model = ax.util:GetRandomFactionModel(faction)
function ax.util:GetRandomFactionModel(faction)
    if ( !faction or !faction.GetModels ) then
        return nil
    end

    local models = faction:GetModels()
    if ( !models or #models == 0 ) then
        return nil
    end

    return models[math.random(#models)]
end

--- Creates a temporary character for a bot with random faction and appearance
-- Bot characters are not stored in the database and exist only in memory
-- @param client Player The bot player object
-- @realm server
-- @usage ax.util:CreateBotCharacter(bot)
function ax.util:CreateBotCharacter(client)
    if ( !IsValid(client) or !client:IsBot() ) then
        return false
    end

    -- Check if bot support is enabled
    if ( !ax.config:Get("botSupport", true) ) then
        ax.util:PrintDebug("Bot support is disabled, skipping character creation for: " .. client:SteamName())
        return false
    end

    local faction = self:GetRandomBotFaction()
    if ( !faction ) then
        ax.util:PrintWarning("No valid factions available for bot: " .. client:SteamName())
        return false
    end

    local model = self:GetRandomFactionModel(faction)
    if ( !model ) then
        ax.util:PrintWarning("No models available for faction " .. faction.name .. " for bot: " .. client:SteamName())
        return false
    end

    local botName = self:GenerateBotName()
    if ( faction.GetDefaultName and isfunction(faction.GetDefaultName) ) then
        local defaultName = faction:GetDefaultName()
        if ( isstring(defaultName) and defaultName != "" ) then
            botName = defaultName
        end
    end

    -- Create temporary character in memory (not saved to database)
    local character = setmetatable({}, ax.character.meta)

    character.id = client:SteamID64() -- Use SteamID64 as unique identifier
    character.vars = {}
    character.isBot = true -- Mark as bot character

    -- Set character variables
    for k, v in pairs(ax.character.vars) do
        character.vars[k] = v.default
    end

    -- Override with bot-specific data
    character.vars.steamID64 = client:SteamID64()
    character.vars.name = botName
    character.vars.faction = faction.index
    character.vars.model = model
    character.vars.description = "An automatically generated character for testing purposes."
    character.vars.creationTime = os.time()
    character.vars.data = {}
    character.vars.inventory = 0 -- No inventory for bots

    -- Add to character instances (but not to database)
    ax.character.instances[character.id] = character

    ax.util:PrintDebug("Creating temporary bot character: " .. botName .. " (Faction: " .. faction.name .. ", Model: " .. model .. ")")

    -- Load the character directly
    ax.character:Load(client, character)

    -- Sync bot character to all clients so they can receive variable updates
    ax.character:SyncBotToClients(character)

    ax.util:PrintSuccess("Bot character created and loaded: " .. botName)

    return true
end
