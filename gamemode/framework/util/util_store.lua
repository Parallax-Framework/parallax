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

--- Store factory utilities.
-- Provides a canonical pattern for creating configurable stores used by
-- config (server→client broadcast settings) and option (client→server
-- preferences). Stores support registration, defaults, persistence, and
-- optional networking of specific keys.
-- @section store

-- Store library modification time - used to detect when rebuild is needed
local STORE_LIB_TIME = file.Time("gamemodes/parallax/gamemode/framework/util/util_store.lua", "GAME") or 0

--- Create a new store instance.
-- @realm shared
-- @param spec table Store specification with fields:
--  - name (string): identifier, e.g. "config" or "option"
--  - authority (string): "server" or "client" — side that persists values
--  - path (string): JSON file path under DATA for persistence
--  - net (table): net channel names (init, set, sync, request as applicable)
-- @param oldStore table Optional existing store to migrate data from during hot-reload
-- @return table Store object with methods for registration, get/set, IO, and networking
-- @usage
-- local store = ax.util:CreateStore({
--     name = "config",
--     authority = "server",
--     path = ax.util:BuildDataPath("config", { human = true }),
--     net = { init = "config.init", set = "config.set" }
-- })
function ax.util:CreateStore(spec, oldStore)
    local store = {}

    -- Internal state
    store.registry = {}
    store.defaults = {}
    store.values = {}
    store.networkedKeys = {}
    store._libTime = STORE_LIB_TIME

    -- Migrate data from old store if provided
    if ( istable(oldStore) ) then
        if ( istable(oldStore.registry) ) then store.registry = table.Copy(oldStore.registry) end
        if ( istable(oldStore.defaults) ) then store.defaults = table.Copy(oldStore.defaults) end
        if ( istable(oldStore.values) ) then store.values = table.Copy(oldStore.values) end
        if ( istable(oldStore.networkedKeys) ) then store.networkedKeys = table.Copy(oldStore.networkedKeys) end
        ax.util:PrintDebug("Store '" .. spec.name .. "' migrated data from previous instance during hot-reload")
    end

    -- Client-side cache for config values (when received from server)
    local CONFIG_CACHE = {}

    -- Server-side per-player cache for options (networked keys only)
    local SERVER_CACHE = {}

    --- Add a new setting definition to the store.
    -- @realm shared
    -- @param key string Setting key
    -- @param type any ax.type data type (e.g. ax.type.number)
    -- @param default any Default value
    -- @param data table Additional metadata (category, bNoNetworking, min/max/decimals,
    -- populate=function, OnChanged=function)
    -- @return boolean True if added, false on invalid params
    function store:Add(key, type, default, data)
        if ( !isstring(key) or !type or default == nil ) then
            ax.util:PrintDebug(spec.name, " Add: Invalid parameters for key ", key)
            return false
        end

        data = data or {}

        store.registry[key] = {
            type = type,
            default = default,
            data = data
        }

        store.defaults[key] = default

        if ( !data.bNoNetworking ) then
            store.networkedKeys[key] = true
        end

        if ( (spec.authority == "client" and CLIENT) or (spec.authority == "server" and SERVER) ) then
            local storedValues = ax.util:ReadJSON(spec.path) or {}
            if ( storedValues[key] != nil ) then
                local coerced, err = ax.type:Sanitise(type, storedValues[key])
                if ( coerced != nil ) then
                    store.values[key] = coerced
                else
                    ax.util:PrintDebug(spec.name, " Add: Failed to coerce stored value for ", key, ": ", err)
                    store.values[key] = default
                end
            else
                store.values[key] = default
            end
        else
            store.values[key] = default
        end

        ax.util:PrintDebug(spec.name, " Added setting: ", key, " = ", store.values[key])

        return true
    end

    --- Get a value from the store.
    -- For option on server, supports per-player reads when the first arg is a Player.
    -- @realm shared
    -- @param ... any Key and optional default; or (player, key, fallback) for option
    -- @return any Value or default
    function store:Get(...)
        -- Server-side per-player read for option
        local key, default = select(1, ...), select(2, ...)
        if ( spec.name == "option" and SERVER and IsValid(key) and key:IsPlayer() ) then
            local client, actualKey, fallback = key, default, select(3, ...) or nil
            if ( !ax.util:IsValidPlayer(client) ) then
                ax.util:PrintDebug(spec.name, " Get: Invalid player provided")
                return fallback
            end

            if ( !SERVER_CACHE[client] or SERVER_CACHE[client][actualKey] == nil ) then
                return store.defaults[actualKey] or fallback
            end

            return SERVER_CACHE[client][actualKey]
        end

        if ( !isstring(key) ) then
            return default
        end

        if ( CLIENT and spec.name == "config" and CONFIG_CACHE[key] != nil ) then
            return CONFIG_CACHE[key]
        end

        if ( store.values[key] != nil ) then
            return store.values[key]
        end

        return store.defaults[key] or default
    end

    --- Get the metadata table for a registered key.
    -- @realm shared
    -- @param key string Setting key
    -- @return table|nil Copy of data table or nil if unknown
    function store:GetData(key)
        if ( !isstring(key) ) then
            return nil
        end

        local regEntry = store.registry[key]
        if ( !regEntry ) then
            return nil
        end

        return table.Copy(regEntry.data)
    end


    --- Get the default value for a key.
    -- @realm shared
    -- @param key string Setting key
    -- @return any Default value or nil if unknown
    function store:GetDefault(key)
        if ( !isstring(key) ) then
            return nil
        end

        return store.defaults[key]
    end

    --- Set a value in the store.
    -- Coerces to the registered type, clamps numbers, validates array choices,
    -- triggers OnChanged and global hooks, persists, and handles networking.
    -- @realm shared
    -- @param key string Setting key
    -- @param value any New value
    -- @param bNoSave boolean Optional; when true, skip persistence
    -- @param bNoCallback boolean Optional; when true, skip OnChanged and hooks
    -- @return boolean True if the value changed, false otherwise along with a reason
    function store:Set(key, value, bNoSave, bNoCallback)
        if ( !isstring(key) ) then
            ax.util:PrintDebug(spec.name, " Set: Invalid key")
            return false
        end

        local regEntry = store.registry[key]
        if ( !regEntry ) then
            ax.util:PrintDebug(spec.name, " Set: Unknown key ", key)
            return false
        end

        local coerced, err = ax.type:Sanitise(regEntry.type, value)
        if ( coerced == nil ) then
            ax.util:PrintDebug(spec.name, " Set: Invalid value for ", key, ": ", err)
            return false
        end

        if ( regEntry.type == ax.type.number ) then
            local data = regEntry.data
            coerced = ax.util:ClampRound(coerced, data.min, data.max, data.decimals)
        end

        if ( regEntry.type == ax.type.array and isfunction(regEntry.data.populate) ) then
            local ok, choices = ax.util:SafeCall(regEntry.data.populate)
            if ( ok and istable(choices) and !choices[coerced] ) then
                ax.util:PrintDebug(spec.name, "Set: Invalid choice for ", key, ":", coerced)
                return false
            end
        end

        -- For configs on client, check CONFIG_CACHE for current value, not store.values
        local oldValue
        if ( CLIENT and spec.name == "config" ) then
            oldValue = CONFIG_CACHE[key]
        else
            oldValue = store.values[key]
        end

        -- if ( oldValue == coerced ) then
        --     ax.util:PrintDebug(spec.name, " Set: ", key, " = ", coerced, " (no change)")
        --     return false
        -- end

        store.values[key] = coerced

        -- Update CONFIG_CACHE immediately on client for optimistic UI updates
        if ( CLIENT and spec.name == "config" ) then
            CONFIG_CACHE[key] = coerced
        end

        if ( !bNoCallback ) then
            if ( isfunction(regEntry.data.OnChanged) ) then
                ax.util:SafeCall(regEntry.data.OnChanged, oldValue, coerced, key)
            end

            if ( spec.name == "config" ) then
                hook.Run("OnConfigChanged", key, oldValue, coerced)
            elseif ( spec.name == "option" ) then
                hook.Run("OnOptionChanged", key, oldValue, coerced)
            end

            if ( !bNoSave ) then
                self:Save()
            end
        end

        if ( store.networkedKeys[key] ) then
            if ( spec.name == "config" and SERVER ) then
                ax.net:Start(nil, spec.net.set, key, coerced)

                ax.util:PrintDebug(spec.name, " Broadcasted config update: ", key, " = ", coerced)
            elseif ( spec.name == "config" and CLIENT ) then
                ax.net:Start(spec.net.set, key, coerced)

                ax.util:PrintDebug(spec.name, " Sending config update: ", key, " = ", coerced)
            elseif ( spec.name == "option" and CLIENT ) then
                ax.net:Start(spec.net.set, key, coerced)

                ax.util:PrintDebug(spec.name, " Sending option update: ", key, " = ", coerced)
            else
                ax.util:PrintWarning(spec.name, " Unknown network state for option update: ", key, " = ", coerced)
            end
        else
            ax.util:PrintDebug(spec.name, " Set: ", key, " = ", coerced, " (not networked)")
        end

        ax.util:PrintDebug(spec.name, " Set: ", key, " = ", coerced)

        return true
    end

    --- Set the default value for a key.
    -- @realm shared
    -- @param key string Setting key
    -- @param value any Default value
    -- @return boolean True on success
    function store:SetDefault(key, value)
        if ( !isstring(key) ) then
            return false
        end

        local regEntry = store.registry[key]
        if ( !regEntry ) then
            return false
        end

        regEntry.default = value
        store.defaults[key] = value

        if ( store.values[key] == nil ) then
            store.values[key] = value
        end

        return true
    end

    --- Set's a value to its default.
    -- @realm shared
    -- @param key string Setting key
    -- @return boolean True if the value changed, false otherwise
    function store:SetToDefault(key)
        if ( !isstring(key) ) then
            return false
        end

        local regEntry = store.registry[key]
        if ( !regEntry ) then
            return false
        end

        return store:Set(key, regEntry.default)
    end

    --- Get a list of all categories present in the registry.
    -- @realm shared
    -- @return table Array of category names
    function store:GetAllCategories()
        local result = {}

        for key, entry in pairs(store.registry) do
            local category = entry.data.category or "general"
            result[category] = true
        end

        return table.GetKeys(result)
    end

    --- Get a copy of all registered definitions.
    -- @realm shared
    -- @return table Map of key -> definition table
    function store:GetAllDefinitions()
        local result = {}

        for key, entry in pairs(store.registry) do
            result[key] = table.Copy(entry)
        end

        return result
    end

    --- Get all definitions where the category matches the given string.
    -- Case-insensitive partial matching via ax.util:FindString.
    -- @realm shared
    -- @param category string Category filter
    -- @return table Map of key -> definition table
    function store:GetAllByCategory(category)
        local result = {}

        for key, entry in pairs(store.registry) do
            local entryCategory = entry.data.category or "misc"
            if ( ax.util:FindString(entryCategory, category) ) then
                result[key] = table.Copy(entry)
            end
        end

        return result
    end

    --- Load persisted values from disk.
    -- Only runs on the authority side set by spec.authority.
    -- @realm shared
    -- @return boolean True on success, false if no file or invalid
    function store:Load()
        if ( !((spec.authority == "server" and SERVER) or (spec.authority == "client" and CLIENT)) ) then
            return false
        end

        local data = ax.util:ReadJSON(spec.path)
        if ( !data ) then
            ax.util:PrintDebug(spec.name, " Load: No data file found at ", spec.path)
            return false
        end

        local loaded = 0
        for key, value in pairs(data) do
            local regEntry = store.registry[key]
            if ( regEntry ) then
                local coerced, err = ax.type:Sanitise(regEntry.type, value)
                if ( coerced != nil ) then
                    store.values[key] = coerced
                    loaded = loaded + 1
                else
                    ax.util:PrintDebug(spec.name, " Load: Failed to coerce ", key, ": ", err)
                end
            end
        end

        ax.util:PrintDebug(spec.name, " Loaded ", loaded, " settings from ", spec.path)

        if ( spec.name == "config" ) then
            hook.Run("OnConfigsLoaded")
        elseif ( spec.name == "option" ) then
            hook.Run("OnOptionsLoaded")
        end

        return true
    end

    --- Save current values to disk.
    -- Only runs on the authority side set by spec.authority.
    -- @realm shared
    -- @return boolean True on success
    function store:Save()
        if ( !((spec.authority == "server" and SERVER) or (spec.authority == "client" and CLIENT)) ) then
            return false
        end

        local data = {}
        for key, value in pairs(store.values) do
            data[key] = value
        end

        local success = ax.util:WriteJSON(spec.path, data)
        if ( success ) then
            ax.util:PrintDebug(spec.name, " Saved ", table.Count(data), " settings to ", spec.path)
        else
            ax.util:PrintWarning(spec.name, " Failed to save settings to ", spec.path)
        end

        return success
    end

    --- Sync networked keys.
    -- For config on server: sends initial values to clients (or a target).
    -- For option on client: sends local preferences to the server.
    -- @realm shared
    -- @param target any Optional player or table of players (server-side config)
    function store:Sync(target)
        if ( spec.name == "config" and SERVER ) then
            local recipients = target or player.GetAll()
            if ( !istable(recipients) ) then
                recipients = {recipients}
            end

            local networked = {}
            for key in pairs(store.networkedKeys) do
                networked[key] = store.values[key]
            end

            if ( !table.IsEmpty(networked) ) then
                ax.net:Start(recipients, spec.net.init, networked)

                ax.util:PrintDebug(spec.name, " Synced ", table.Count(networked), "config keys to clients")
            end
        elseif ( spec.name == "option" and CLIENT ) then
            local networked = {}
            for key in pairs(store.networkedKeys) do
                networked[key] = store.values[key]
            end

            if ( !table.IsEmpty(networked) ) then
                ax.net:Start(spec.net.sync, networked)

                ax.util:PrintDebug(spec.name, " Synced ", table.Count(networked), "option keys to server")
            end
        end
    end

    --- Internal: register net channels and hooks for networking.
    -- Wires up init/set/sync/request handlers for config and option.
    -- @realm shared
    function store:_setupNetworking()
        if ( !istable(spec) or !istable(spec.net) ) then
            ax.util:PrintError("Store networking setup failed: missing spec.net")
            return
        end

        if ( spec.name == "config" ) then
            if ( SERVER ) then
                util.AddNetworkString(spec.net.init)
                util.AddNetworkString(spec.net.set)

                -- Clean up existing hook to prevent duplicates on reload
                hook.Remove("PlayerReady", "ax.config.Init")

                hook.Add("PlayerReady", "ax.config.Init", function(client)
                    store:Sync(client)
                end)

                -- Handle config changes from clients (requires admin permission)
                ax.net:Hook(spec.net.set, function(client, key, value)
                    if ( !ax.util:IsValidPlayer(client) or !client:IsAdmin() ) then
                        ax.util:PrintWarning(spec.name, "Unauthorized config change attempt from", IsValid(client) and client:Nick() or "invalid client")
                        return
                    end

                    local success = store:Set(key, value)
                    if ( success ) then
                        ax.util:PrintDebug(spec.name, " Config changed by ", client:Nick(), ": ", key, " = ", value)
                    else
                        ax.util:PrintWarning(spec.name, " Failed to set config ", key, " from ", client:Nick())
                    end
                end)
            elseif ( CLIENT ) then
                ax.net:Hook(spec.net.init, function(data)
                    for key, value in pairs(data) do
                        CONFIG_CACHE[key] = value

                        self:HandleConfigChange(store.registry[key], nil, value, key)
                    end

                    ax.util:PrintDebug(spec.name, " Received initial config: ", table.Count(data), " keys")
                end)

                ax.net:Hook(spec.net.set, function(key, value)
                    local oldValue = CONFIG_CACHE[key]
                    CONFIG_CACHE[key] = value

                    self:HandleConfigChange(store.registry[key], oldValue, value, key)

                    ax.util:PrintDebug(spec.name, " Received config update: ", key, " = ", value)
                end)
            end
        elseif ( spec.name == "option" ) then
            if ( SERVER ) then
                util.AddNetworkString(spec.net.sync)
                util.AddNetworkString(spec.net.set)
                util.AddNetworkString(spec.net.request)

                ax.net:Hook(spec.net.sync, function(client, data)
                    if ( !ax.util:IsValidPlayer(client) ) then return end

                    SERVER_CACHE[client] = SERVER_CACHE[client] or {}
                    for key, value in pairs(data) do
                        SERVER_CACHE[client][key] = value
                    end

                    ax.util:PrintDebug(spec.name, " Received option sync from ", client:Nick(), ": ", table.Count(data), " keys")
                end)

                ax.net:Hook(spec.net.set, function(client, key, value)
                    if ( !ax.util:IsValidPlayer(client) ) then return end

                    SERVER_CACHE[client] = SERVER_CACHE[client] or {}
                    SERVER_CACHE[client][key] = value

                    ax.util:PrintDebug(spec.name, " Received option update from ", client:Nick(), ": ", key, " = ", value)
                end)

                -- Clean up existing hook to prevent duplicates on reload
                hook.Remove("PlayerDisconnected", "ax.option.Cleanup")

                hook.Add("PlayerDisconnected", "ax.option.Cleanup", function(client)
                    SERVER_CACHE[client] = nil
                end)

                local function requestSync(client)
                    if ( ax.util:IsValidPlayer(client) ) then
                        ax.net:Start(client, spec.net.request)
                    end
                end

                store.RequestPlayerSync = requestSync
            elseif ( CLIENT ) then
                ax.net:Hook(spec.net.request, function() store:Sync() end)

                -- Clean up existing hook to prevent duplicates on reload
                hook.Remove("InitPostEntity", "ax.option.AutoSync")

                hook.Add("InitPostEntity", "ax.option.AutoSync", function()
                    timer.Simple(2, function()
                        store:Sync()
                    end)
                end)
            end
        end
    end

    --- Invoke a key's OnChanged handler if present.
    -- @realm shared
    -- @param regEntry table Registry entry for the key
    -- @param oldValue any Previous value
    -- @param newValue any New value
    -- @param key string Setting key
    function store:HandleConfigChange(regEntry, oldValue, newValue, key)
        if ( regEntry and isfunction(regEntry.data.OnChanged) ) then
            ax.util:SafeCall(regEntry.data.OnChanged, oldValue, newValue, key)
        end
    end

    return store
end
