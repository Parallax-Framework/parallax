--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

--- Character library.
-- @module ax.character

ax.character = ax.character or {} -- Character library.
ax.character.meta = ax.character.meta or {} -- All currently registered character meta functions.
ax.character.variables = ax.character.variables or {} -- All currently registered variables.
ax.character.fields = ax.character.fields or {} -- All currently registered fields.
ax.character.stored = ax.character.stored or {} -- All currently stored characters which are in use.
ax.character.pendingDatabaseVars = ax.character.pendingDatabaseVars or {} -- Variables waiting to be registered in the database.

--- Registers a variable for the character.
-- @realm shared
function ax.character:RegisterVariable(key, data)
    data.Index = table.Count(self.variables) + 1

    if ( data.Alias != nil ) then
        if ( isstring(data.Alias) ) then
            data.Alias = { data.Alias }
        end

        for i = 1, #data.Alias do
            local v = data.Alias[i]
            self.meta["Get" .. v] = function(character)
                return self:GetVariable(character:GetID(), key)
            end

            if ( SERVER ) then
                self.meta["Set" .. v] = function(character, value)
                    self:SetVariable(character:GetID(), key, value)
                end

                local field = data.Field or key
                -- Store for later registration when database is ready
                self.pendingDatabaseVars[#self.pendingDatabaseVars + 1] = {
                    table = "ax_characters",
                    field = field,
                    default = data.Default or nil
                }

                -- Debug: track variable registration
                if ( ax.util and ax.util.Print ) then
                    ax.util:Print("Character variable '" .. key .. "' queued for database registration (field: " .. field .. ")")
                end
            end
        end
    else
        local upperKey = string.upper(key:sub(1, 1)) .. key:sub(2)

        self.meta["Get" .. upperKey] = function(character)
            return self:GetVariable(character:GetID(), key)
        end

        if ( SERVER ) then
            self.meta["Set" .. upperKey] = function(character, value)
                self:SetVariable(character:GetID(), key, value)
            end

            local field = data.Field or key
            -- Store for later registration when database is ready
            self.pendingDatabaseVars[#self.pendingDatabaseVars + 1] = {
                table = "ax_characters",
                field = field,
                default = data.Default or nil
            }

            -- Debug: track variable registration
            if ( ax.util and ax.util.Print ) then
                ax.util:Print("Character variable '" .. key .. "' queued for database registration (field: " .. field .. ")")
            end
        end
    end

    self.variables[key] = data
end

--- Registers all pending database variables when the database is ready.
-- This is called after the database tables are loaded.
-- @realm server
function ax.character:RegisterPendingDatabaseVars()
    if ( !SERVER ) then return end

    -- Ensure database is available and properly initialized
    if ( !ax.database or !ax.database.RegisterVar ) then
        ax.util:PrintError("Database not available when trying to register character variables!")
        return
    end

    -- Check if database backend is available
    if ( !ax.database:IsConnected() ) then
        ax.util:PrintError("Database not connected when trying to register character variables!")
        return
    end

    for i = 1, #self.pendingDatabaseVars do
        local varData = self.pendingDatabaseVars[i]
        ax.database:RegisterVar(varData.table, varData.field, varData.default)
    end

    ax.util:Print("Registered " .. #self.pendingDatabaseVars .. " pending character database variables.")

    -- Clear the pending list
    self.pendingDatabaseVars = {}
end

-- Debug hook to track character variable registration
if ( SERVER ) then
    hook.Add("PostDatabaseTablesLoaded", "ax.character.RegisterVars", function()
        ax.util:Print("PostDatabaseTablesLoaded hook called - registering character variables...")
        if ( ax.character and ax.character.RegisterPendingDatabaseVars ) then
            ax.character:RegisterPendingDatabaseVars()
        end
    end)
end

function ax.character:SetVariable(id, key, value)
    if ( !self.variables[key] ) then
        ax.util:PrintError("Attempted to set a variable that does not exist!")
        return false, "Attempted to set a variable that does not exist!"
    end

    local character = self.instances[id]
    if ( !character ) then
        ax.util:PrintError("Attempted to set a variable for a character that does not exist!")
        return false, "Attempted to set a variable for a character that does not exist!"
    end

    local data = self.variables[key]
    if ( data.OnSet ) then
        value = data:OnSet(character, value)
    end

    character[key] = value

    if ( SERVER ) then
        ax.database:Update("ax_characters", { [key] = value }, "id = " .. id)

        if ( data.Field ) then
            local field = data.Field
            if ( field ) then
                ax.database:Update("ax_characters", { [field] = value }, "id = " .. id)
            end
        end

        if ( !data.NoNetworking ) then
            net.Start("ax.character.variable.set")
                net.WriteUInt(id, 16)
                net.WriteString(key)
                net.WriteType(value)
            net.Broadcast()
        end
    end
end

function ax.character:GetVariable(id, key)
    local character = self.instances[id]
    if ( !character ) then
        ax.util:PrintError("Attempted to get a variable for a character that does not exist!")
        return false, "Attempted to get a variable for a character that does not exist!"
    end

    local variable = self.variables[key]
    if ( !variable ) then return end

    local output = ax.util:CoerceType(variable.Type, character[key])
    if ( variable.OnGet ) then
        return variable:OnGet(character, output)
    end

    return output
end

function ax.character:CreateObject(characterID, data, client)
    if ( !characterID or !data ) then
        ax.util:PrintError("Attempted to create a character object with invalid data!")
        return false, "Invalid data provided"
    end

    if ( self.instances[characterID] ) then
        ax.util:PrintWarning("Attempted to create a character object that already exists!")
        return self.instances[characterID], "Character already exists"
    end

    characterID = tonumber(characterID)

    local character = setmetatable({}, self.meta)
    character.ID = characterID
    character.Player = client or NULL
    character.Schema = SCHEMA.Folder
    character.SteamID = client and client:SteamID64() or nil

    if ( istable(data.inventories) ) then
        character.Inventories = data.inventories
    elseif ( isstring(data.inventories) and data.inventories != "" ) then
        character.Inventories = util.JSONToTable(data.inventories) or {}
    else
        character.Inventories = {}
    end

    for k, v in pairs(self.variables) do
        if ( data[k] ) then
            character[k] = data[k]
        elseif ( v.Default ) then
            character[k] = v.Default
        end
    end

    self.instances[characterID] = character

    return character
end

function ax.character:GetPlayerByCharacter(id)
    for _, client in player.Iterator() do
        if ( client:GetCharacterID() == tonumber(id) ) then
            return client
        end
    end

    return false, "Player not found"
end

function ax.character:Get(id)
    return self.instances[id]
end

function ax.character:GetAll()
    return self.instances
end

function ax.character:GetAllVariables()
    return self.variables
end
