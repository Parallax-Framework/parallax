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

--- Creates and returns a new store instance for managing key/value settings.
-- A store is a self-contained object that handles registration of typed
-- settings, persistence to a JSON file (or `ax.data`), optional networking
-- between server and client, and change callbacks. The framework uses two
-- stores: `ax.config` (server authority, broadcast to clients) and `ax.option`
-- (client authority, synced to server for server-side reads).
-- `spec` fields:
-- - `name` string: identifier used in debug messages (e.g. `"config"`).
-- - `authority` string: `"server"` or `"client"` — only that side persists
--   and loads values from disk.
-- - `path` string|function: `DATA`-relative path to the JSON file, or a
--   function `(spec, store) → string` for dynamic paths.
-- - `net` table: net channel names used for networking:
--   `init` (bulk sync), `set` (single key update), `sync` (option bulk
--   upload), `request` (server asks client to sync).
-- - `data` table (optional): `{ key, options }` for `ax.data`-backed
--   persistence instead of raw JSON.
-- - `legacyPaths` table (optional): array of older paths to migrate data from
--   on first load.
-- When `oldStore` is provided (hot-reload scenario), registry, defaults,
-- values, and networkedKeys are copied from it before the new store is
-- configured, preserving runtime state across live code reloads.
-- @realm shared
-- @param spec table The store specification (see above).
-- @param oldStore table|nil An existing store to migrate state from, used
--   during hot-reload to avoid losing in-memory values.
-- @return table The new store object with all methods attached.
-- @usage local store = ax.util:CreateStore({
--     name = "config",
--     authority = "server",
--     path = ax.util:BuildDataPath("config"),
--     net = { init = "ax.config.init", set = "ax.config.set" }
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
    local PERSISTED_CACHE = nil
    local PERSISTED_CACHE_LOADED = false

    local function ResolvePath(pathSpec)
        if ( isfunction(pathSpec) ) then
            local ok, resolved = pcall(pathSpec, spec, store)
            if ( ok and isstring(resolved) and resolved != "" ) then
                return resolved
            end

            return nil
        end

        if ( isstring(pathSpec) and pathSpec != "" ) then
            return pathSpec
        end

        return nil
    end

    local function GetDataSpec()
        if ( !istable(spec.data) ) then
            return nil, nil
        end

        local dataKey = spec.data.key
        if ( !isstring(dataKey) or dataKey == "" ) then
            return nil, nil
        end

        local dataOptions = {}
        if ( istable(spec.data.options) ) then
            dataOptions = table.Copy(spec.data.options)
        end

        return dataKey, dataOptions
    end

    local function GetPrimaryPath()
        local dataKey, dataOptions = GetDataSpec()
        if ( dataKey ) then
            return ax.util:BuildDataPath(dataKey, dataOptions)
        end

        return ResolvePath(spec.path)
    end

    local function GetLegacyPaths()
        if ( !istable(spec.legacyPaths) ) then
            return {}
        end

        local paths = {}
        for i = 1, #spec.legacyPaths do
            local path = ResolvePath(spec.legacyPaths[i])
            if ( isstring(path) and path != "" ) then
                paths[#paths + 1] = path
            end
        end

        return paths
    end

    local function LoadPersistedData()
        local primaryPath = GetPrimaryPath()
        if ( !primaryPath ) then
            return nil, nil
        end

        local data = nil
        local dataKey, dataOptions = GetDataSpec()
        if ( dataKey and istable(ax.data) and isfunction(ax.data.Get) ) then
            local readOptions = table.Copy(dataOptions or {})
            readOptions.force = true
            data = ax.data:Get(dataKey, nil, readOptions)
        else
            data = ax.util:ReadJSON(primaryPath)
        end

        if ( istable(data) ) then
            return data, primaryPath
        end

        local legacyPaths = GetLegacyPaths()
        for i = 1, #legacyPaths do
            local legacyPath = legacyPaths[i]
            if ( legacyPath == primaryPath ) then continue end

            local legacyData = ax.util:ReadJSON(legacyPath)
            if ( legacyData ) then
                local writeSuccess = false
                if ( dataKey and istable(ax.data) and isfunction(ax.data.Set) ) then
                    writeSuccess = ax.data:Set(dataKey, legacyData, dataOptions or {})
                else
                    writeSuccess = ax.util:WriteJSON(primaryPath, legacyData)
                end

                if ( writeSuccess ) then
                    ax.util:PrintDebug(spec.name, " Migrated store data from ", legacyPath, " to ", primaryPath)
                else
                    ax.util:PrintWarning(spec.name, " Failed to migrate store data from ", legacyPath, " to ", primaryPath)
                end

                return legacyData, primaryPath
            end
        end

        return nil, primaryPath
    end

    local function InvalidatePersistedCache()
        PERSISTED_CACHE = nil
        PERSISTED_CACHE_LOADED = false
    end

    local function GetPersistedDataCached()
        if ( !PERSISTED_CACHE_LOADED ) then
            PERSISTED_CACHE = LoadPersistedData()
            PERSISTED_CACHE_LOADED = true
        end

        return PERSISTED_CACHE
    end

    --- Registers a new key/type/default definition in the store.
    -- After registration, the key is available for `Get` and `Set`. The
    -- initial value is loaded from persisted data (if available and on the
    -- authority side), coerced to the registered type, and stored. If
    -- persisted data is absent or fails coercion, the `default` is used.
    -- Keys are automatically added to `store.networkedKeys` unless
    -- `data.bNoNetworking = true`.
    -- `data` fields:
    -- - `category` string: grouping label for UI (default `"general"`).
    -- - `bNoNetworking` boolean: exclude this key from network sync.
    -- - `min` / `max` number: clamp bounds applied when the type is `ax.type.number`.
    -- - `decimals` number: decimal precision for number clamping.
    -- - `choices` table / `populate` function: valid values for `ax.type.array`.
    --   `populate()` is called to build the choices list dynamically.
    -- - `OnChanged` function: callback `(oldValue, newValue, key)` fired when
    --   the value changes (unless `bNoCallback` is set in `Set`).
    -- Returns false (with a debug message) when any required parameter is nil.
    -- @realm shared
    -- @param key string The unique setting key.
    -- @param type any An `ax.type` constant (e.g. `ax.type.number`, `ax.type.string`).
    -- @param default any The default value used when no persisted value exists.
    -- @param data table|nil Optional metadata table (see field descriptions above).
    -- @return boolean True if registered successfully, false on invalid input.
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
            local storedValues = GetPersistedDataCached() or {}
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

    --- Retrieves a value from the store with optional fallback.
    -- Normal call: `store:Get(key, fallback)` — returns the stored value for
    -- `key`, or `store.defaults[key]`, or `fallback` (in that priority order).
    -- On the client, config values are served from the local CONFIG_CACHE
    -- (populated by server sync) rather than `store.values`.
    -- Special call for `option` stores on the server:
    -- `store:Get(player, key, fallback)` — reads a per-player option value
    -- from SERVER_CACHE (populated when the client sends its preferences). If
    -- no cached value exists for that player, the registered default is used.
    -- @realm shared
    -- @param ... any Either `(key, fallback)` or `(player, key, fallback)`.
    -- @return any The resolved value, or the fallback when no value is found.
    function store:Get(...)
        -- Server-side per-player read for option
        local key, default = select(1, ...), select(2, ...)
        if ( spec.name == "option" and SERVER and ax.util:IsValidPlayer(key) ) then
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

    --- Returns a copy of the metadata table for a registered key.
    -- Returns a deep copy so callers cannot accidentally mutate the registry.
    -- Returns nil when `key` is not a string or is not registered.
    -- @realm shared
    -- @param key string The setting key to look up.
    -- @return table|nil A copy of the `data` table provided when the key was
    --   registered, or nil if the key is unknown.
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


    --- Returns the registered default value for a key.
    -- This is the value passed as `default` to `store:Add`, or subsequently
    -- updated by `store:SetDefault`. Returns nil when `key` is not a string
    -- or is not registered.
    -- @realm shared
    -- @param key string The setting key.
    -- @return any The default value, or nil if the key is unknown.
    function store:GetDefault(key)
        if ( !isstring(key) ) then
            return nil
        end

        return store.defaults[key]
    end

    local function ValidateArrayChoice(key, regEntry, value)
        local data = regEntry.data or {}
        local choices = nil

        if ( istable(data.choices) ) then
            choices = data.choices
        elseif ( isfunction(data.populate) ) then
            local ok, populated = ax.util:SafeCall(data.populate)
            if ( ok and istable(populated) ) then
                choices = populated
            end
        end

        if ( istable(choices) and next(choices) != nil and choices[value] == nil ) then
            return false, "invalid choice"
        end

        return true
    end

    local function CoerceStoreValue(key, regEntry, value)
        local coerced, err = ax.type:Sanitise(regEntry.type, value)
        if ( coerced == nil ) then
            return nil, err
        end

        local data = regEntry.data or {}
        if ( regEntry.type == ax.type.number ) then
            coerced = ax.util:ClampRound(coerced, data.min, data.max, data.decimals)
        elseif ( regEntry.type == ax.type.array ) then
            local validChoice, choiceErr = ValidateArrayChoice(key, regEntry, coerced)
            if ( !validChoice ) then
                return nil, choiceErr
            end
        end

        return coerced
    end

    local function ValuesEqual(oldValue, newValue)
        if ( ax.type:Detect(oldValue) == ax.type.color and ax.type:Detect(newValue) == ax.type.color
        and oldValue.r == newValue.r and oldValue.g == newValue.g and oldValue.b == newValue.b and oldValue.a == newValue.a ) then
            return true
        end

        if ( oldValue == newValue ) then
            return true
        end

        return false
    end

    --- Sets a value in the store, triggering coercion, callbacks, and networking.
    -- The full pipeline when setting a value:
    -- 1. **Coercion**: value is sanitised to the registered type via
    --    `ax.type:Sanitise`. Numbers are additionally clamped and rounded using
    --    `data.min`, `data.max`, and `data.decimals`. Array values are validated
    --    against `data.choices` / `data.populate`.
    -- 2. **Change check**: if the coerced value equals the current value,
    --    returns false immediately (no-op).
    -- 3. **Callbacks** (unless `bNoCallback` is true):
    --    - `regEntry.data.OnChanged(oldValue, newValue, key)` if defined.
    --    - `hook.Run("OnConfigChanged", ...)` or `hook.Run("OnOptionChanged", ...)`.
    -- 4. **Persistence** (unless `bNoSave` is true): calls `store:Save()`.
    -- 5. **Networking** (if the key is in `networkedKeys`): broadcasts the
    --    new value via the appropriate net channel for the store type and realm.
    -- Returns false (silently, with a debug message) for unknown keys or
    -- invalid values. Returns true when the value was actually changed.
    -- @realm shared
    -- @param key string The setting key to update.
    -- @param value any The new value (will be coerced to the registered type).
    -- @param bNoSave boolean|nil When true, skips writing to disk.
    -- @param bNoCallback boolean|nil When true, skips `OnChanged` and hooks.
    -- @return boolean True if the value changed, false otherwise.
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

        local coerced, err = CoerceStoreValue(key, regEntry, value)
        if ( coerced == nil ) then
            ax.util:PrintDebug(spec.name, " Set: Invalid value for ", key, ": ", err)
            return false
        end

        -- For configs on client, check CONFIG_CACHE for current value, not store.values
        local oldValue
        if ( CLIENT and spec.name == "config" ) then
            oldValue = CONFIG_CACHE[key]
            if ( oldValue == nil ) then
                oldValue = store.values[key]
            end
        else
            oldValue = store.values[key]
        end

        if ( ValuesEqual(oldValue, coerced) ) then
            ax.util:PrintDebug(spec.name, " Set: ", key, " = ", coerced, " (no change)")
            return false
        end

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
        end

        if ( !bNoSave ) then
            self:Save()
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

    --- Updates the registered default value for a key without changing the current value.
    -- Modifies both the registry entry's `default` field and `store.defaults[key]`.
    -- The live value in `store.values` is only changed if it is currently nil —
    -- existing values are preserved. Useful for overriding defaults set during
    -- initial registration, e.g. when a gamemode wants to change framework defaults.
    -- Returns false when the key is not registered.
    -- @realm shared
    -- @param key string The setting key whose default should be changed.
    -- @param value any The new default value.
    -- @return boolean True on success, false if the key is unknown.
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

    --- Resets a key's value to its registered default.
    -- Convenience wrapper around `store:Set(key, default)`. Goes through the
    -- full Set pipeline including coercion, callbacks, persistence, and
    -- networking — the reset is treated the same as any other value change.
    -- Returns false when the key is not registered, or when the current value
    -- is already equal to the default (no change).
    -- @realm shared
    -- @param key string The setting key to reset.
    -- @return boolean True if the value was changed, false otherwise.
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

    --- Returns an array of all unique category names in the registry.
    -- Iterates all registered keys and collects their `data.category` field.
    -- Keys without an explicit category are counted under `"general"`.
    -- The returned array contains each category string exactly once, in
    -- arbitrary order. Useful for building category tabs in a settings UI.
    -- @realm shared
    -- @return table An array of unique category name strings.
    function store:GetAllCategories()
        local result = {}

        for key, entry in pairs(store.registry) do
            local category = entry.data.category or "general"
            result[category] = true
        end

        return table.GetKeys(result)
    end

    --- Returns a deep copy of all registered setting definitions.
    -- Each entry in the returned map is a copy of the registry entry (type,
    -- default, data) keyed by the setting key. Modifying the returned table
    -- does not affect the live registry. Useful for introspecting all
    -- available settings, e.g. for building a settings panel or exporting
    -- documentation.
    -- @realm shared
    -- @return table Map of `key → { type, default, data }` for all registered keys.
    function store:GetAllDefinitions()
        local result = {}

        for key, entry in pairs(store.registry) do
            result[key] = table.Copy(entry)
        end

        return result
    end

    --- Returns definitions for all keys whose category matches a filter string.
    -- Matching is performed by `ax.util:FindString` — case-insensitive
    -- substring match. For example, `"gen"` will match `"general"`. Keys with
    -- no category fall under `"misc"` for the purposes of this filter.
    -- The returned map contains deep copies of the matched registry entries.
    -- @realm shared
    -- @param category string The category string to filter by (partial match).
    -- @return table Map of `key → { type, default, data }` for matched keys.
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

    --- Loads persisted values from disk into the store.
    -- Only executes on the authority side (`spec.authority`): server stores
    -- load on `SERVER`, client stores load on `CLIENT`. Calling from the
    -- non-authority side is a no-op that returns false.
    -- Clears the persisted data cache first (`InvalidatePersistedCache`), then
    -- loads from the primary path (or `ax.data` if configured). If the primary
    -- path is absent, falls back to any `spec.legacyPaths` entries and migrates
    -- the data to the primary path on success.
    -- Each loaded key is coerced to its registered type; keys that fail
    -- coercion are skipped (debug message only). After loading, fires either
    -- `hook.Run("OnConfigsLoaded")` or `hook.Run("OnOptionsLoaded")`.
    -- @realm shared
    -- @return boolean True if values were loaded successfully, false if no
    --   data file exists or the store is on the wrong realm.
    function store:Load()
        if ( !((spec.authority == "server" and SERVER) or (spec.authority == "client" and CLIENT)) ) then
            return false
        end

        InvalidatePersistedCache()

        local data, dataPath = LoadPersistedData()
        if ( !data ) then
            ax.util:PrintDebug(spec.name, " Load: No data file found at ", dataPath or "<invalid path>")
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

        ax.util:PrintDebug(spec.name, " Loaded ", loaded, " settings from ", dataPath or "<invalid path>")

        PERSISTED_CACHE = table.Copy(data)
        PERSISTED_CACHE_LOADED = true

        if ( spec.name == "config" ) then
            hook.Run("OnConfigsLoaded")
        elseif ( spec.name == "option" ) then
            hook.Run("OnOptionsLoaded")
        end

        return true
    end

    --- Persists the current store values to disk.
    -- Only executes on the authority side (`spec.authority`). No-op on the
    -- non-authority side. Serialises `store.values` and writes it to the
    -- primary path via `ax.data:Set` (if configured) or `ax.util:WriteJSON`.
    -- On success, updates the persisted cache so subsequent `Add` calls can
    -- read back the correct initial value without re-reading the file.
    -- A warning is printed (but false is returned silently) if the path is
    -- invalid or the write fails. This function is called automatically by
    -- `Set` (unless `bNoSave` is true) and on `ShutDown`.
    -- @realm shared
    -- @return boolean True if values were saved successfully, false otherwise.
    function store:Save()
        if ( !((spec.authority == "server" and SERVER) or (spec.authority == "client" and CLIENT)) ) then
            return false
        end

        local data = {}
        for key, value in pairs(store.values) do
            data[key] = value
        end

        local dataPath = GetPrimaryPath()
        if ( !isstring(dataPath) or dataPath == "" ) then
            ax.util:PrintWarning(spec.name, " Failed to save settings: invalid data path")
            return false
        end

        local success = false
        local dataKey, dataOptions = GetDataSpec()
        if ( dataKey and istable(ax.data) and isfunction(ax.data.Set) ) then
            success = ax.data:Set(dataKey, data, dataOptions or {})
        else
            success = ax.util:WriteJSON(dataPath, data)
        end

        if ( success ) then
            ax.util:PrintDebug(spec.name, " Saved ", table.Count(data), " settings to ", dataPath)
            PERSISTED_CACHE = table.Copy(data)
            PERSISTED_CACHE_LOADED = true
        else
            ax.util:PrintWarning(spec.name, " Failed to save settings to ", dataPath)
        end

        return success
    end

    --- Synchronises networked key values across the network.
    -- Behaviour depends on the store type and current realm:
    -- - **`config` on server**: collects all keys in `store.networkedKeys` and
    --   sends them via `spec.net.init` to `target` (a player or table of
    --   players). When `target` is nil, broadcasts to `player.GetAll()`. This
    --   is called automatically on `PlayerReady` to initialise new clients.
    -- - **`option` on client**: collects all networked option values from
    --   `store.values` and sends them to the server via `spec.net.sync`. This
    --   is called automatically 2 seconds after `InitPostEntity` and when the
    --   server sends a `request` net message.
    -- Does nothing in other realm/store combinations.
    -- @realm shared
    -- @param target Player|table|nil For config syncs: the recipient player(s).
    --   Defaults to all players when nil. Ignored for option syncs.
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

    --- Internal: wires up all net channel receivers and lifecycle hooks.
    -- Called once during store initialisation. If `ax.net` is not yet available,
    -- defers via `timer.Simple(0, ...)` and retries on the next frame.
    -- Registers the following depending on store type and realm:
    -- - **config/server**: `PlayerReady` hook (sends initial values to joining
    --   clients); `spec.net.set` receiver (admin-only remote config changes).
    -- - **config/client**: `spec.net.init` receiver (bulk initial values);
    --   `spec.net.set` receiver (individual key updates from server).
    -- - **option/server**: `spec.net.sync` receiver (bulk preference upload);
    --   `spec.net.set` receiver (single key updates); `PlayerDisconnected`
    --   hook (cleans up SERVER_CACHE); exposes `store.RequestPlayerSync`.
    -- - **option/client**: `spec.net.request` receiver (triggers `Sync`);
    --   `InitPostEntity` hook (auto-syncs after 2 seconds).
    -- Also registers a `ShutDown` hook on the authority side to call `Save`.
    -- This is an internal method — do not call it directly.
    -- @realm shared
    function store:_setupNetworking()
        if ( !istable(spec) ) then
            ax.util:PrintError("Store networking setup failed: missing spec")
            return
        end

        if ( !ax.net or !ax.net.Hook ) then
            timer.Simple(0, function()
                if ( istable(store) and isfunction(store._setupNetworking) ) then
                    store:_setupNetworking()
                end
            end)

            return
        end

        if ( (spec.authority == "server" and SERVER) or (spec.authority == "client" and CLIENT) ) then
            local shutdownHookName = "ax." .. spec.name .. ".PersistOnShutdown"
            hook.Add("ShutDown", shutdownHookName, function()
                store:Save()
            end)
        end

        if ( spec.name == "config" ) then
            if ( SERVER ) then
                hook.Add("PlayerReady", "ax.config.Init", function(client)
                    store:Sync(client)
                end)

                -- Handle config changes from clients (requires admin permission)
                ax.net:Hook(spec.net.set, function(client, key, value)
                    if ( !ax.util:IsValidPlayer(client) or !client:IsAdmin() ) then
                        ax.util:PrintWarning(spec.name, "Unauthorized config change attempt from", ax.util:IsValidPlayer(client) and client:Nick() or "invalid client")
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
                ax.net:Hook(spec.net.sync, function(client, data)
                    if ( !ax.util:IsValidPlayer(client) ) then return end

                    SERVER_CACHE[client] = SERVER_CACHE[client] or {}
                    for key, value in pairs(data) do
                        if ( !store.networkedKeys[key] ) then continue end

                        local regEntry = store.registry[key]
                        if ( !regEntry ) then continue end

                        local coerced, err = CoerceStoreValue(key, regEntry, value)
                        if ( coerced == nil ) then
                            ax.util:PrintDebug(spec.name, " Sync: rejected invalid value from ", client:Nick(), " for ", key, ": ", err)
                            continue
                        end

                        SERVER_CACHE[client][key] = coerced
                    end

                    ax.util:PrintDebug(spec.name, " Received option sync from ", client:Nick(), ": ", table.Count(data), " keys")
                end)

                ax.net:Hook(spec.net.set, function(client, key, value)
                    if ( !ax.util:IsValidPlayer(client) ) then return end

                    if ( !store.networkedKeys[key] ) then return end

                    local regEntry = store.registry[key]
                    if ( !regEntry ) then return end

                    local coerced, err = CoerceStoreValue(key, regEntry, value)
                    if ( coerced == nil ) then
                        ax.util:PrintDebug(spec.name, " Set: rejected invalid value from ", client:Nick(), " for ", key, ": ", err)
                        return
                    end

                    SERVER_CACHE[client] = SERVER_CACHE[client] or {}
                    SERVER_CACHE[client][key] = coerced

                    ax.util:PrintDebug(spec.name, " Received option update from ", client:Nick(), ": ", key, " = ", coerced)
                end)

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

                hook.Add("InitPostEntity", "ax.option.AutoSync", function()
                    timer.Simple(2, function()
                        store:Sync()
                    end)
                end)
            end
        end
    end

    --- Invokes the `OnChanged` callback for a key if one is registered.
    -- Called by the networking layer after a config value arrives from the
    -- server (on the client side). The callback is called via `SafeCall` so
    -- errors in user-defined callbacks do not break the networking flow.
    -- `oldValue` may be nil when this is the initial sync (no prior value).
    -- `regEntry` being nil or having no `OnChanged` function is safe — the
    -- call is silently skipped.
    -- @realm shared
    -- @param regEntry table|nil The registry entry for the key (from
    --   `store.registry[key]`).
    -- @param oldValue any The previous value of the key, or nil on first sync.
    -- @param newValue any The newly received value.
    -- @param key string The setting key that changed.
    function store:HandleConfigChange(regEntry, oldValue, newValue, key)
        if ( regEntry and isfunction(regEntry.data.OnChanged) ) then
            ax.util:SafeCall(regEntry.data.OnChanged, oldValue, newValue, key)
        end
    end

    return store
end
