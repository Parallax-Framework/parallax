--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Utility helpers used across the Parallax framework (printing, file handling, text utilities, etc.).
-- @module ax.util

--- Bot utility functions for automatic character creation
-- @section bot_utilities

--- Global utility table storing first names for bot name generation
AX_BOT_FIRST_NAMES = {
    "Alex", "Jordan", "Casey", "Morgan", "Taylor", "Jamie", "Riley", "Avery",
    "Quinn", "Sage", "Cameron", "Rowan", "Blake", "Phoenix", "Reese", "Parker",
    "Drew", "Emery", "Finley", "Hayden", "Logan", "River", "Skyler", "Dakota"
}

--- Global utility table storing last names for bot name generation
AX_BOT_LAST_NAMES = {
    "Anderson", "Baker", "Clark", "Davis", "Evans", "Foster", "Garcia", "Harris",
    "Johnson", "Kelly", "Lewis", "Martin", "Nelson", "Parker", "Quinn", "Rodriguez",
    "Smith", "Taylor", "Walker", "Wilson", "Young", "Brown", "Miller", "Moore"
}

--- Generates a random full name for a bot player.
-- Picks one entry at random from `AX_BOT_FIRST_NAMES` and one from `AX_BOT_LAST_NAMES`, then concatenates them with a space.
-- The name tables are defined as globals at the top of this file and can be extended by other modules before bots are created.
-- @realm shared
-- @return string A randomly generated "Firstname Lastname" string.
-- @usage local name = ax.util:GenerateBotName() -- e.g. "Jordan Walker"
function ax.util:GenerateBotName()
    local firstName = AX_BOT_FIRST_NAMES[math.random(#AX_BOT_FIRST_NAMES)]
    local lastName = AX_BOT_LAST_NAMES[math.random(#AX_BOT_LAST_NAMES)]
    return firstName .. " " .. lastName
end

--- Returns a random faction that bots are allowed to join.
-- Iterates all registered factions and filters to those where either `faction.isDefault` is true, or `faction.allowBots` is not explicitly set to false. Returns nil when no eligible factions exist (e.g. every faction is whitelisted or explicitly bans bots).
-- @realm shared
-- @return table|nil A random eligible faction table, or nil if none qualify.
-- @usage local faction = ax.util:GetRandomBotFaction()
-- if ( faction ) then print(faction.name) end
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
            validFactions[#validFactions + 1] = faction
        end
    end

    if ( #validFactions == 0 ) then
        return nil
    end

    return validFactions[math.random(#validFactions)]
end

--- Returns a random model from a faction's model list.
-- Calls `faction:GetModels()` and picks a random entry. Entries are resolved in this order: if the selected entry is a function it is called and its return value is used; if it is a table whose first element is a string, that string path is used directly. Any other value (plain string or `{model, skin}` table) is returned as-is.
-- Returns nil if the faction has no `GetModels` method or its list is empty.
-- @realm shared
-- @param faction table The faction table to query.
-- @return string|table|nil A model path string, a `{model, skin}` table, or nil when no models are available.
-- @usage local model = ax.util:GetRandomFactionModel(faction)
-- local path = istable(model) and model[1] or model
function ax.util:GetRandomFactionModel(faction)
    if ( !faction or !faction.GetModels ) then
        return nil
    end

    local models = faction:GetModels()
    if ( !models or #models == 0 ) then
        return nil
    end

    local selected = models[math.random(#models)]

    if ( isfunction(selected) ) then
        selected = selected()
    elseif ( istable(selected) and isstring(selected[1]) ) then
        selected = selected[1]
    end

    -- Return as-is (can be string or table {model, skin})
    return selected
end

--- Creates a temporary in-memory character for a bot and loads it immediately.
-- Selects a random eligible faction via `GetRandomBotFaction` and a random model via `GetRandomFactionModel`, then constructs a character metatable instance populated with default variable values. The character is registered in `ax.character.instances` but is never written to the database — it exists only for the lifetime of the server session.
-- If the faction defines a `GetDefaultName` function, that name takes priority over the randomly generated one. A temporary inventory is created via `ax.inventory:CreateTemporary` if available; otherwise the inventory slot is set to 0 with a warning.
-- Returns false (with a printed warning) if the bot is invalid, has no eligible faction, or has no available models.
-- After loading, `ax.character:SyncBotToClients` is called so connected clients receive the new character's variables.
-- @realm server
-- @param client Player The bot player to create a character for.
-- @return boolean True on success, false on any failure.
-- @usage ax.util:CreateBotCharacter(bot)
function ax.util:CreateBotCharacter(client)
    if ( !ax.util:IsValidPlayer(client) or !client:IsBot() ) then return false end

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
        local defaultName = faction:GetDefaultName(client)
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
    local botInventory
    if ( ax.inventory and isfunction(ax.inventory.CreateTemporary) ) then
        botInventory = ax.inventory:CreateTemporary({
            id = character.id
        })
    end

    if ( istable(botInventory) ) then
        character.vars.inventory = botInventory.id
    else
        character.vars.inventory = 0
        ax.util:PrintWarning("Failed to create temporary inventory for bot: " .. botName)
    end

    -- Add to character instances (but not to database)
    ax.character.instances[character.id] = character

    -- Format model for debug output
    local modelStr = istable(model) and model[1] or tostring(model)
    ax.util:PrintDebug("Creating temporary bot character: " .. botName .. " (Faction: " .. faction.name .. ", Model: " .. modelStr .. ")")

    -- Load the character directly
    ax.character:Load(client, character)

    -- Sync bot character to all clients so they can receive variable updates
    ax.character:SyncBotToClients(character)

    ax.util:PrintDebug("Bot character created and loaded: " .. botName)

    return true
end
