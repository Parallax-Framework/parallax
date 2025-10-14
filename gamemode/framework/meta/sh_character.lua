--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local character = ax.character.meta or {}
character.__index = character

function character:__tostring()
    return string.format("Character [%d][%s]", self.id, self.vars.name or "Unknown")
end

function character:GetID()
    return self.id
end

function character:GetVars()
    return self.vars
end

function character:GetInventory()
    return ax.inventory.instances[self.vars.inventory]
end

character.GetInv = character.GetInventory

function character:GetInventoryID()
    return tonumber(self.vars.inventory) or 0
end

character.GetInvID = character.GetInventoryID

function character:GetData(key)
    if ( !istable(self.vars.data) ) then self.vars.data = {} end

    return self.vars.data[key]
end

function character:SetData(key, value)
    if ( !istable(self.vars.data) ) then self.vars.data = {} end

    self.vars.data[key] = value
end

function character:GetOwner()
    return self.player
end

function character:GetData(key, fallback)
    if ( !istable(self.vars.data) ) then self.vars.data = {} end

    return self.vars.data[key] == nil and fallback or self.vars.data[key]
end

function character:GetFactionData()
    return ax.faction:Get(self.vars.faction)
end

function character:GetClassData()
    return ax.class:Get(self.vars.class)
end

function character:HasFlags(flags)
    local data = self:GetData("flags", "")
    for i = 1, #flags do
        local letter = flags[i]
        if ( !ax.util:FindString(data, letter) ) then
            return false
        end
    end

    return true
end

if ( SERVER ) then
    function character:GiveFlags(flags)
        if ( !isstring(flags) or #flags < 1 ) then return end

        for i = 1, #flags do
            local letter = flags[i]
            local flagData = ax.flag:Get(letter)
            if ( !istable(flagData) ) then continue end

            if ( self:HasFlags(letter) ) then continue end

            self:SetData("flags", self:GetData("flags", "") .. letter)
            self:Save()

            if ( isfunction(flagData.OnGiven) ) then
                flagData:OnGiven(self)
            end

            hook.Run("CharacterFlagGiven", self, letter)
        end
    end

    function character:TakeFlags(flags)
        if ( !isstring(flags) or #flags < 1 ) then return end

        for i = 1, #flags do
            local letter = flags[i]
            local flagData = ax.flag:Get(letter)
            if ( !istable(flagData) ) then continue end

            if ( !self:HasFlags(letter) ) then continue end

            local newFlags = self:GetData("flags", "")
            newFlags = string.Replace(newFlags, letter, "")

            self:SetData("flags", newFlags)
            self:Save()

            if ( isfunction(flagData.OnTaken) ) then
                flagData:OnTaken(self)
            end

            hook.Run("CharacterFlagTaken", self, letter)
        end
    end

    function character:SetFlags(flags)
        if ( !isstring(flags) ) then return end

        local concatenated = table.concat(string.Explode("", flags))

        local current = self:GetData("flags", "")
        for i = 1, #current do
            local letter = current[i]
            if ( ax.util:FindString(concatenated, letter) ) then continue end

            local flagData = ax.flag:Get(letter)
            if ( !istable(flagData) ) then continue end

            if ( isfunction(flagData.OnTaken) ) then
                flagData:OnTaken(self)
            end

            hook.Run("CharacterFlagTaken", self, letter)
        end

        self:SetData("flags", concatenated)
        self:Save()

        for i = 1, #concatenated do
            local letter = concatenated[i]
            local flagData = ax.flag:Get(letter)
            if ( !istable(flagData) ) then continue end

            if ( isfunction(flagData.OnGiven) ) then
                flagData:OnGiven(self)
            end

            hook.Run("CharacterFlagGiven", self, letter)
        end
    end

    function character:SetData(key, value, bNoNetworking, recipients)
        if ( !istable(self.vars.data) ) then self.vars.data = {} end

        self.vars.data[key] = value

        -- Network character data changes to all clients
        if ( !bNoNetworking ) then
            net.Start("ax.character.var")
                net.WriteUInt(self:GetID(), 32)
                net.WriteString(key)
                net.WriteType(value)
            if ( recipients ) then
                net.Send(recipients)
            else
                net.Broadcast()
            end
        end
    end

    function character:Save()
        if ( !istable(self.vars.data) ) then self.vars.data = {} end

        -- Build an update query for the characters table using the registered schema
        local query = mysql:Update("ax_characters")
        query:Where("id", self:GetID())

        -- Ensure the data table exists and always save it as JSON
        query:Update("data", util.TableToJSON(self.vars.data or {}))

        -- Iterate registered vars and persist fields that declare a database column
        for name, meta in pairs(ax.character.vars or {}) do
            if ( istable(meta) and meta.field ) then
                local val = nil

                if ( istable(self.vars) ) then
                    val = self.vars[name]
                end

                -- Fall back to default if not present
                if ( val == nil and meta.default != nil ) then
                    val = meta.default
                end

                -- Serialize tables to JSON for storage
                if ( istable(val) ) then
                    val = util.TableToJSON(val)
                end

                query:Update(meta.field, val)

                ax.util:PrintDebug("Saving character field '" .. meta.field .. "' with value: " .. tostring(val))
            end
        end

        query:Execute()
    end
end

ax.character.meta = character -- Keep, funcs don't define otherwise.
