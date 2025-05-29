--- Options library
-- @module ax.option

ax.option = ax.option or {}
ax.option.stored = ax.option.stored or {}

function ax.option:SetDefault(key, default)
    local stored = self.stored[key]
    if ( !istable(stored) ) then
        ax.util:PrintError("Option \"" .. key .. "\" does not exist!")
        return false
    end

    stored.Default = default

    if ( SERVER ) then
        ax.net:Start(nil, "option.sync", self.stored)
    end

    return true
end

if ( CLIENT ) then
    function ax.option:Load()
        hook.Run("PreOptionsLoad")

        for k, v in pairs(ax.data:Get("options", {}, true, false)) do
            if ( istable(self.stored[k]) ) then
                self.stored[k].Value = v
            end
        end

        ax.net:Start("option.sync", self.stored)

        hook.Run("PostOptionsLoad", self.stored)
    end

    function ax.option:GetSaveData()
        local data = {}
        for k, v in pairs(self.stored) do
            if ( v.Value != nil and v.Value != v.Default ) then
                data[k] = v.Value
            end
        end

        return data
    end

    function ax.option:Set(key, value, bNoNetworking)
        local stored = self.stored[key]
        if ( !istable(stored) ) then
            ax.util:PrintError("Option \"" .. key .. "\" does not exist!")
            return false
        end

        if ( value == nil ) then
            value = stored.Default
        end

        local client = ax.client
        local oldValue = stored.Value != nil and stored.Value or stored.Default
        local bResult = hook.Run("PreOptionChanged", client, key, value, oldValue)
        if ( bResult == false ) then return false end

        stored.Value = value

        if ( stored.NoNetworking != true and !bNoNetworking ) then
            ax.net:Start("option.set", key, value)
        end

        if ( isfunction(stored.OnChange) ) then
            stored:OnChange(value, oldValue, client)
        end

        ax.data:Set("options", self:GetSaveData(), true, false)

        hook.Run("PostOptionChanged", client, key, value, oldValue)

        return true
    end

    function ax.option:Get(key, fallback)
        local optionData = self.stored[key]
        if ( !istable(optionData) ) then
            ax.util:PrintError("Option \"" .. key .. "\" does not exist!")
            return fallback
        end

        return optionData.Value == nil and optionData.Default or optionData.Value
    end

    function ax.option:GetDefault(key)
        local optionData = self.stored[key]
        if ( !istable(optionData) ) then
            ax.util:PrintError("Option \"" .. key .. "\" does not exist!")
            return nil
        end

        return optionData.Default
    end

    --- Set the option to the default value
    -- @realm client
    -- @string key The option key to reset
    -- @treturn boolean Returns true if the option was reset successfully, false otherwise
    -- @usage ax.option:Reset(key)
    function ax.option:Reset(key)
        local optionData = self.stored[key]
        if ( !istable(optionData) ) then
            ax.util:PrintError("Option \"" .. key .. "\" does not exist!")
            return false
        end

        self:Set(key, optionData.Default)

        return true
    end

    function ax.option:ResetAll()
        for k, v in pairs(self.stored) do
            v.Value = nil
        end

        ax.data:Set("options", {}, true, false)
        ax.net:Start("option.sync", {})
    end
end

local requiredFields = {
    "Name",
    "Description",
    "Default"
}

function ax.option:Register(key, data)
    local bResult = hook.Run("PreOptionRegistered", key, data)
    if ( bResult == false ) then return false end

    for _, v in pairs(requiredFields) do
        if ( data[v] == nil ) then
            ax.util:PrintError("Option \"" .. key .. "\" is missing required field \"" .. v .. "\"!\n")
            return false
        end
    end

    if ( data.Type == nil ) then
        data.Type = ax.util:DetectType(data.Default)

        if ( data.Type == nil ) then
            ax.util:PrintError("Option \"" .. key .. "\" has an invalid type!")
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
    hook.Run("PostOptionRegistered", key, data)

    return true
end