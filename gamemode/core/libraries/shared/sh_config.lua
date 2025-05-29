-- Configuration for the gamemode
-- @module ax.config

ax.config = ax.config or {}
ax.config.stored = ax.config.stored or {}
ax.config.instances = ax.config.instances or {}

--- Gets the current value of the specified configuration.
-- @realm shared
-- @param key The key of the configuration.
-- @param default The default value of the configuration.
-- @return The value of the configuration.
-- @usage local color = ax.config.Get("color.schema", Color(0, 100, 150))
-- print(color) -- Prints the color of the schema.
function ax.config:Get(key, fallback)
    local configData = self.stored[key]
    if ( !istable(configData) ) then
        ax.util:PrintError("Config \"" .. key .. "\" does not exist!")
        return fallback
    end

    local instance = self.instances[key] or {}
    local value = instance.Value or instance.Default or configData.Default

    return value or fallback
end

--- Gets the default value of the specified configuration.
-- @realm shared
-- @param key The key of the configuration.
-- @return The default value of the configuration.
-- @usage local defaultColor = ax.config.GetDefault("color.schema")
-- print(defaultColor) -- Prints the default color of the schema.
function ax.config:GetDefault(key)
    local configData = self.stored[key]
    if ( !istable(configData) ) then
        ax.util:PrintError("Config \"" .. key .. "\" does not exist!")
        return nil
    end

    local instance = self.instances[key] or {}
    local defaultValue = instance.Default or configData.Default

    return defaultValue
end

--- Sets the value of the specified configuration.
-- @realm shared
-- @param key The key of the configuration.
-- @param value The value of the configuration.
-- @treturn boolean Whether the configuration was successfully set.
-- @usage ax.config.Set("color.schema", Color(0, 100, 150)) -- Sets the color of the schema.
function ax.config:Set(key, value)
    local stored = self.stored[key]
    if ( !istable(stored) ) then
        ax.util:PrintError("Config \"" .. key .. "\" does not exist!")
        return false
    end

    if ( value == nil ) then
        value = stored.Default
    end

    if ( ax.util:DetectType(value) != stored.Type ) then
        ax.util:PrintError("Attempted to set config \"" .. key .. "\" with invalid type!")
        return false
    end

    local instance = self.instances[key] or {}
    local oldValue = instance.Value or instance.Default or stored.Default
    local bResult = hook.Run("PreConfigChanged", key, value, oldValue)
    if ( bResult == false ) then return false end

    instance.Value = value
    self.instances[key] = instance

    if ( SERVER and stored.NoNetworking != true ) then
        ax.net:Start(nil, "config.set", key, value)
    end

    if ( isfunction(stored.OnChange) ) then
        stored:OnChange(value, oldValue, client)
    end

    if ( SERVER ) then
        self:Save()
    end

    hook.Run("PostConfigChanged", key, value, oldValue)

    return true
end

--- Sets the default value of the specified configuration.
-- @realm shared
-- @param key The key of the configuration.
-- @param value The default value of the configuration.
-- @treturn boolean Whether the default value of the configuration was successfully set.
-- @usage ax.config.SetDefault("color.schema", Color(0, 100, 150)) -- Sets the default color of the schema.
function ax.config:SetDefault(key, value)
    local stored = self.stored[key]
    if ( !istable(stored) ) then
        ax.util:PrintError("Configuration \"" .. key .. "\" does not exist!")
        return false
    end

    local instance = self.instances[key] or {}
    instance.Default = value
    self.instances[key] = instance

    return true
end

--- Registers a new configuration.
-- @realm shared
-- @param key The key of the configuration.
-- @param data The data of the configuration.
-- @field Name The display name of the configuration.
-- @field Description The description of the configuration.
-- @field Type The type of the configuration.
-- @field Default The default value of the configuration.
-- @field OnChange The function that is called when the configuration is changed.
-- @treturn boolean Whether the configuration was successfully registered.
-- @usage ax.config:Register("color.schema", {
--     Name = "Schema Color",
--     Description = "The color of the schema.",
--     Type = ax.types.color,
--     Default = Color(0, 100, 150),
--     OnChange = function(oldValue, newValue)
--         print("Schema color changed from " .. tostring(oldValue) .. " to " .. tostring(newValue))
--     end
-- })

local requiredFields = {
    "Name",
    "Description",
    "Default"
}

function ax.config:Register(key, data)
    if ( !isstring(key) or !istable(data) ) then return false end

    local bResult = hook.Run("PreConfigRegistered", key, data)
    if ( bResult == false ) then return false end

    for _, v in pairs(requiredFields) do
        if ( data[v] == nil ) then
            ax.util:PrintError("Configuration \"" .. key .. "\" is missing required field \"" .. v .. "\"!\n")
            return false
        end
    end

    if ( data.Type == nil ) then
        data.Type = ax.util:DetectType(data.Default)

        if ( data.Type == nil ) then
            ax.util:PrintError("Config \"" .. key .. "\" has an invalid type!")
            return false
        end
    end

    if ( data.Category == nil ) then
        data.Category = "misc"
    end

    if ( data.SubCategory == nil ) then
        data.SubCategory = "other"
    end

    data.UniqueID = key

    self.stored[key] = data
    hook.Run("PostConfigRegistered", key, data)

    return true
end