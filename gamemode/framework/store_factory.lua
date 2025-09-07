--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

function ax.util:CreateStore(spec)
    local store = {}

    -- Internal state
    store.registry = {}
    store.defaults = {}
    store.values = {}
    store.networkedKeys = {}

    -- Client-side cache for config values (when received from server)
    local CONFIG_CACHE = {}

    -- Server-side per-player cache for options (networked keys only)
    local SERVER_CACHE = {}

    -- Add a new setting
    function store:Add(key, typeId, default, data)
        if ( !isstring(key) or !typeId or default == nil ) then
            ax.util:PrintDebug(spec.name, "Add: Invalid parameters for key", key)
            return false
        end

        data = data or {}

        store.registry[key] = {
            typeId = typeId,
            default = default,
            data = data
        }

        store.defaults[key] = default

        if ( data.bNetworked ) then
            store.networkedKeys[key] = true
        end

        if ( (spec.authority == "client" and CLIENT) or (spec.authority == "server" and SERVER) ) then
            local storedValues = ax.util:ReadJSON(spec.path) or {}
            if ( storedValues[key] != nil ) then
                local coerced, err = ax.type:Sanitise(typeId, storedValues[key])
                if ( coerced != nil ) then
                    store.values[key] = coerced
                else
                    ax.util:PrintDebug(spec.name, "Add: Failed to coerce stored value for", key, ":", err)
                    store.values[key] = default
                end
            else
                store.values[key] = default
            end
        else
            store.values[key] = default
        end

        ax.util:PrintDebug(spec.name, "Added setting:", key, "=", store.values[key])

        return true
    end

    function store:Get(...)
        -- Server-side per-player read for ax.option
        local key, default = select(1, ...), select(2, ...)
        if ( spec.name == "ax.option" and SERVER and IsValid(key) and key:IsPlayer() ) then
            local client, actualKey, fallback = key, default, select(3, ...) or nil
            if ( !ax.util:IsValidPlayer(client) ) then
                ax.util:PrintDebug(spec.name, "Get: Invalid player provided")
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

        if ( CLIENT and spec.name == "ax.config" and CONFIG_CACHE[key] != nil ) then
            return CONFIG_CACHE[key]
        end

        if ( store.values[key] != nil ) then
            return store.values[key]
        end

        return store.defaults[key] or default
    end

    function store:Set(key, value, bNoSave)
        if ( !isstring(key) ) then
            ax.util:PrintDebug(spec.name, "Set: Invalid key")
            return false
        end

        local regEntry = store.registry[key]
        if ( !regEntry ) then
            ax.util:PrintDebug(spec.name, "Set: Unknown key", key)
            return false
        end

        local coerced, err = ax.type:Sanitise(regEntry.typeId, value)
        if ( coerced == nil ) then
            ax.util:PrintDebug(spec.name, "Set: Invalid value for", key, ":", err)
            return false
        end

        if ( regEntry.typeId == ax.type.number ) then
            local data = regEntry.data
            coerced = ax.type:ClampRound(coerced, data.min, data.max, data.decimals)
        end

        if ( regEntry.typeId == ax.type.array and isfunction(regEntry.data.populate) ) then
            local ok, choices = ax.util:SafeCall(regEntry.data.populate)
            if ( ok and istable(choices) and !choices[coerced] ) then
                ax.util:PrintDebug(spec.name, "Set: Invalid choice for", key, ":", coerced)
                return false
            end
        end

        local oldValue = store.values[key]
        if ( oldValue == coerced ) then
            return false
        end

        store.values[key] = coerced

        if ( isfunction(regEntry.data.OnChanged) ) then
            ax.util:SafeCall(regEntry.data.OnChanged, oldValue, coerced, key)
        end

        if ( !bNoSave ) then
            self:Save()
        end

        if ( store.networkedKeys[key] ) then
            if ( spec.name == "ax.config" and SERVER ) then
                net.Start(spec.net.set)
                net.WriteString(key)
                net.WriteType(coerced)
                net.Broadcast()
            elseif ( spec.name == "ax.option" and CLIENT ) then
                net.Start(spec.net.set)
                net.WriteString(key)
                net.WriteType(coerced)
                net.SendToServer()
            end
        end

        ax.util:PrintDebug(spec.name, "Set:", key, "=", coerced)

        return true
    end

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

    function store:GetAllDefinitions()
        local result = {}

        for key, entry in pairs(store.registry) do
            result[key] = { typeId = entry.typeId, default = entry.default, data = table.Copy(entry.data) }
        end

        return result
    end

    function store:GetAllByCategories(bRemoveHidden)
        local result = {}

        for key, entry in pairs(store.registry) do
            local data = entry.data
            local category = data.category or "misc"
            if ( bRemoveHidden and isfunction(data.hidden) ) then
                local ok, isHidden = ax.util:SafeCall(data.hidden)
                if ( ok and isHidden ) then
                    continue
                end
            end

            result[category] = result[category] or {}
            result[category][key] = { typeId = entry.typeId, default = entry.default, data = table.Copy(entry.data), value = store.values[key] }
        end

        return result
    end

    function store:Load()
        if ( !((spec.authority == "server" and SERVER) or (spec.authority == "client" and CLIENT)) ) then
            return false
        end

        local data = ax.util:ReadJSON(spec.path)
        if ( !data ) then
            ax.util:PrintDebug(spec.name, "Load: No data file found at", spec.path)
            return false
        end

        local loaded = 0
        for key, value in pairs(data) do
            local regEntry = store.registry[key]
            if ( regEntry ) then
                local coerced, err = ax.type:Sanitise(regEntry.typeId, value)
                if ( coerced != nil ) then
                    store.values[key] = coerced
                    loaded = loaded + 1
                else
                    ax.util:PrintDebug(spec.name, "Load: Failed to coerce", key, ":", err)
                end
            end
        end

        ax.util:PrintDebug(spec.name, "Loaded", loaded, "settings from", spec.path)

        return true
    end

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
            ax.util:PrintDebug(spec.name, "Saved", table.Count(data), "settings to", spec.path)
        else
            ax.util:PrintDebug(spec.name, "Failed to save settings to", spec.path)
        end

        return success
    end

    function store:Sync(target)
        if ( spec.name == "ax.config" and SERVER ) then
            local recipients = target or player.GetAll()
            if ( !istable(recipients) ) then
                recipients = {recipients}
            end

            local networked = {}
            for key in pairs(store.networkedKeys) do
                networked[key] = store.values[key]
            end

            if ( table.Count(networked) > 0 ) then
                net.Start(spec.net.init)
                    net.WriteTable(networked)
                net.Send(recipients)

                ax.util:PrintDebug(spec.name, "Synced", table.Count(networked), "config keys to clients")
            end
        elseif ( spec.name == "ax.option" and CLIENT ) then
            local networked = {}
            for key in pairs(store.networkedKeys) do
                networked[key] = store.values[key]
            end

            if ( table.Count(networked) > 0 ) then
                net.Start(spec.net.sync)
                    net.WriteTable(networked)
                net.SendToServer()

                ax.util:PrintDebug(spec.name, "Synced", table.Count(networked), "option keys to server")
            end
        end
    end

    function store:_setupNetworking()
        if ( spec.name == "ax.config" ) then
            if ( SERVER ) then
                util.AddNetworkString(spec.net.init)
                util.AddNetworkString(spec.net.set)

                hook.Add("PlayerReady", "ax.config.Init", function(client)
                    store:Sync(client)
                end)
            elseif ( CLIENT ) then
                net.Receive(spec.net.init, function()
                    local data = net.ReadTable()
                    for key, value in pairs(data) do
                        CONFIG_CACHE[key] = value

                        self:HandleConfigChange(store.registry[key], nil, value, key)
                    end

                    ax.util:PrintDebug(spec.name, "Received initial config:", table.Count(data), "keys")
                end)

                net.Receive(spec.net.set, function()
                    local key = net.ReadString()
                    local value = net.ReadType()
                    local oldValue = CONFIG_CACHE[key]
                    CONFIG_CACHE[key] = value

                    self:HandleConfigChange(store.registry[key], oldValue, value, key)

                    ax.util:PrintDebug(spec.name, "Received config update:", key, "=", value)
                end)
            end
        elseif ( spec.name == "ax.option" ) then
            if ( SERVER ) then
                util.AddNetworkString(spec.net.sync)
                util.AddNetworkString(spec.net.set)
                util.AddNetworkString(spec.net.request)

                net.Receive(spec.net.sync, function(len, client)
                    if ( !ax.util:IsValidPlayer(client) ) then return end

                    SERVER_CACHE[client] = SERVER_CACHE[client] or {}

                    local data = net.ReadTable()
                    for key, value in pairs(data) do
                        SERVER_CACHE[client][key] = value
                    end

                    ax.util:PrintDebug(spec.name, "Received option sync from", client:Nick(), ":", table.Count(data), "keys")
                end)

                net.Receive(spec.net.set, function(len, client)
                    if ( !ax.util:IsValidPlayer(client) ) then return end

                    local key = net.ReadString()
                    local value = net.ReadType()

                    SERVER_CACHE[client] = SERVER_CACHE[client] or {}
                    SERVER_CACHE[client][key] = value

                    ax.util:PrintDebug(spec.name, "Received option update from", client:Nick(), ":", key, "=", value)
                end)

                hook.Add("PlayerDisconnected", "ax.option.Cleanup", function(client)
                    SERVER_CACHE[client] = nil
                end)

                local function requestSync(client)
                    if ( ax.util:IsValidPlayer(client) ) then
                        net.Start(spec.net.request)
                        net.Send(client)
                    end
                end

                store.RequestPlayerSync = requestSync
            elseif ( CLIENT ) then
                net.Receive(spec.net.request, function() store:Sync() end)
                hook.Add("InitPostEntity", "ax.option.AutoSync", function()
                    timer.Simple(2, function()
                        store:Sync()
                    end)
                end)
            end
        end
    end

    function store:HandleConfigChange(regEntry, oldValue, newValue, key)
        if ( regEntry and isfunction(regEntry.data.OnChanged) ) then
            ax.util:SafeCall(regEntry.data.OnChanged, oldValue, newValue, key)
        end
    end

    return store
end
