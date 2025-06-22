--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Options library
-- @module ax.option

ax.option = ax.option or {}
ax.option.stored = ax.option.stored or {}

function ax.option:SetDefault(key, default)
    local stored = self.stored[key]
    if ( !istable(stored) ) then
        ax.util:PrintError("Option \"" .. tostring(key) .. "\" does not exist!")
        return false
    end

    stored.Default = default

    if ( SERVER ) then
        ax.net:Start(nil, "option.sync", self.instances)
    end

    return true
end

if ( CLIENT ) then
    ax.option.instances = ax.option.instances or {}

    function ax.option:Load()
        hook.Run("PreOptionsLoad")

        for k, v in pairs(ax.data:Get("options", {}, true, true)) do
            local stored = self.stored[k]
            if ( !istable(stored) ) then
                ax.util:PrintError("Option \"" .. k .. "\" does not exist!")
                continue
            end

            if ( !istable(self.instances[k]) ) then
                self.instances[k] = nil
            end

            if ( v != nil and v != stored.Default ) then
                if ( ax.util:DetectType(v) != stored.Type ) then
                    ax.util:PrintError("Option \"" .. k .. "\" is not of type \"" .. stored.Type .. "\"!")
                    continue
                end

                self.instances[k] = v
            end
        end

        ax.net:Start("option.sync", self.instances)
        hook.Run("PostOptionsLoad", self.instances)
    end

    function ax.option:GetSaveData()
        local data = {}
        for k, v in pairs(self.instances) do
            if ( v != nil and v != self.stored[k].Default ) then
                data[k] = v
            end
        end

        return data
    end

    function ax.option:Set(key, value, bNoNetworking)
        local stored = self.stored[key]
        if ( !istable(stored) ) then
            ax.util:PrintError("Option \"" .. tostring(key) .. "\" does not exist!")
            return false
        end

        local oldValue = stored.Value != nil and stored.Value or stored.Default
        local bResult = hook.Run("PreOptionChanged", ax.client, key, value, oldValue)
        if ( bResult == false ) then return false end

        if ( !istable(self.instances[key]) ) then
            self.instances[key] = nil
        end

        if ( value != nil and value != stored.Default ) then
            self.instances[key] = value
        end

        if ( stored.NoNetworking != true and !bNoNetworking ) then
            ax.net:Start("option.set", key, value)
        end

        if ( isfunction(stored.OnChange) ) then
            stored:OnChange(value, oldValue, ax.client)
        end

        ax.data:Set("options", self:GetSaveData(), true, true)

        hook.Run("PostOptionChanged", ax.client, key, value, oldValue)

        return true
    end

    function ax.option:Get(key, fallback)
        local optionData = self.stored[key]
        if ( !istable(optionData) ) then
            ax.util:PrintError("Option \"" .. tostring(key) .. "\" does not exist!")
            return fallback
        end

        local instance = self.instances[key]
        if ( instance == nil ) then
            if ( optionData.Default == nil ) then
                ax.util:PrintError("Option \"" .. tostring(key) .. "\" has no value or default set!")
                return fallback
            end

            return optionData.Default
        end

        return instance
    end

    function ax.option:GetDefault(key)
        local optionData = self.stored[key]
        if ( !istable(optionData) ) then
            ax.util:PrintError("Option \"" .. tostring(key) .. "\" does not exist!")
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
            ax.util:PrintError("Option \"" .. tostring(key) .. "\" does not exist!")
            return false
        end

        self:Set(key, optionData.Default)

        return true
    end

    function ax.option:ResetAll()
        self.instances = {}

        ax.data:Set("options", {}, true, true)
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
            ax.util:PrintError("Option \"" .. tostring(key) .. "\" is missing required field \"" .. v .. "\"!\n")
            return false
        end
    end

    if ( data.Type == nil ) then
        data.Type = ax.util:DetectType(data.Default)

        if ( data.Type == nil ) then
            ax.util:PrintError("Option \"" .. tostring(key) .. "\" has an invalid type!")
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