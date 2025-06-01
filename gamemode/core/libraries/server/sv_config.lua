-- Configuration for the gamemode
-- @module ax.config

ax.config = ax.config or {}
ax.config.stored = ax.config.stored or {}
ax.config.instances = ax.config.instances or {}

--- Loads the configuration from the file.
-- @realm shared
-- @return Whether or not the configuration was loaded.
-- @usage ax.config:Load()
-- @internal
function ax.config:Load()
    local config = ax.data:Get("config", {}, true, false)

    for k, v in pairs(config) do
        local storedData = self.stored[k]
        if ( !istable(storedData) ) then continue end

        storedData.Value = v
    end

    local tableToSend =  self:GetNetworkData()
    ax.net:Start(nil, "config.sync", tableToSend)

    ax.util:Print("Configuration loaded.")
    hook.Run("PostConfigLoad", config, tableToSend)

    return true
end

function ax.config:GetSaveData()
    local saveData = {}
    for k, v in pairs(self.instances) do
        if ( !istable(v) ) then continue end

        if ( v.Value != nil and v.Value != v.Default ) then
            saveData[k] = v.Value
        end
    end

    return saveData
end

function ax.config:GetNetworkData()
    local saveData = self:GetSaveData()
    for k, v in pairs(self.stored) do
        if ( v.NoNetworking ) then
            saveData[k] = nil
            continue
        end
    end

    return saveData
end

--- Saves the configuration to the file.
-- @realm server
-- @return Whether or not the configuration was saved.
-- @usage ax.config:Save() -- Saves the configuration to the file.
-- @internal
function ax.config:Save()
    hook.Run("PreConfigSave")

    local values = self:GetSaveData()

    ax.data:Set("config", values, true, false)

    hook.Run("PostConfigSave", values)
    ax.util:Print("Configuration saved.")

    return true
end

--- Set the config to the default value
-- @realm server
-- @string key The config key to reset
-- @return boolean Returns true if the config was reset successfully, false otherwise
-- @usage ax.config:Reset(key) -- Resets the config to the default value.
function ax.config:Reset(key)
    local configData = self.stored[key]
    if ( !istable(configData) ) then
        ax.util:PrintError("Config \"" .. key .. "\" does not exist!")
        return false
    end

    self:Set(key, configData.Default)

    return true
end

--- Resets the configuration to the default values.
-- @realm server
-- @return Whether or not the configuration was reset.
-- @usage ax.config:ResetAll() -- Resets the configuration to the default values.
function ax.config:ResetAll()
    hook.Run("PreConfigReset")

    for k, v in pairs(self.stored) do
        self:Reset(k)
    end

    ax.net:Start(nil, "config.sync", self:GetNetworkData())

    self:Save()
    hook.Run("PostConfigReset")

    return true
end

--- Synchronizes the configuration with the player.
-- @realm server
-- @param client The player to synchronize the configuration with.
-- @return Whether or not the configuration was synchronized with the player.
-- @usage ax.config:Synchronize(Entity(1)) -- Synchronizes the configuration with the first player.
function ax.config:Synchronize(client)
    local tableToSend = self:GetNetworkData()

    if ( !IsValid(client) ) then
        ax.net:Start(nil, "config.sync", tableToSend)
        hook.Run("PostConfigSync")

        return
    end

    local shouldSend = hook.Run("PreConfigSync", client, tableToSend)
    if ( shouldSend == false ) then return false end

    ax.net:Start(client, "config.sync", tableToSend)
    hook.Run("PostConfigSync", client)

    return true
end