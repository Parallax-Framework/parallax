--- Character library.
-- @module ax.character

ax.character = ax.character or {} -- Character library.
ax.character.meta = ax.character.meta or {} -- All currently registered character meta functions.
ax.character.variables = ax.character.variables or {} -- All currently registered variables.
ax.character.fields = ax.character.fields or {} -- All currently registered fields.
ax.character.stored = ax.character.stored or {} -- All currently stored characters which are in use.

--- Registers a variable for the character.
-- @realm shared
function ax.character:RegisterVariable(key, data)
    data.Index = table.Count(self.variables) + 1

    if ( data.Alias != nil ) then
        if ( isstring(data.Alias) ) then
            data.Alias = { data.Alias }
        end

        for k, v in ipairs(data.Alias) do
            self.meta["Get" .. v] = function(character)
                return self:GetVariable(character:GetID(), key)
            end

            if ( SERVER ) then
                self.meta["Set" .. v] = function(character, value)
                    self:SetVariable(character:GetID(), key, value)
                end

                local field = data.Field
                if ( field ) then
                    ax.database:RegisterVar("ax_characters", key, data.Default or nil)
                    self.fields[key] = field
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

            local field = data.Field
            if ( field ) then
                ax.database:RegisterVar("ax_characters", key, data.Default or nil)
                self.fields[key] = field
            end
        end
    end

    self.variables[key] = data
end

function ax.character:SetVariable(id, key, value)
    if ( !self.variables[key] ) then
        ax.util:PrintError("Attempted to set a variable that does not exist!")
        return false, "Attempted to set a variable that does not exist!"
    end

    local character = self.stored[id]
    if ( !character ) then return end

    local data = self.variables[key]
    local translatedType = ax.util:CoerceType(data.Type, value)
    value = translatedType != nil and translatedType or value

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
            ax.net:Start(nil, "character.variable.set", id, key, value)
        end
    end
end

function ax.character:GetVariable(id, key)
    local character = self.stored[id]
    if ( !character ) then return end

    local variable = self.variables[key]
    if ( !variable ) then return end

    local output = ax.util:CoerceType(variable.Type, character[key])
    if ( variable.OnGet ) then
        return variable:OnGet(character, output)
    end

    return output
end

function ax.character:CreateObject(characterID, data, client)
    if ( !characterID or !data ) then return false, "Invalid ID or data" end
    if ( self.stored[characterID] ) then return self.stored[characterID], "Character already exists" end

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

    self.stored[characterID] = character

    return character
end

function ax.character:GetPlayerByCharacter(id)
    for _, client in player.Iterator() do
        if ( client:GetCharacterID() == id ) then
            return client
        end
    end

    return false, "Player not found"
end

function ax.character:Get(id)
    return self.stored[id]
end

function ax.character:GetAll()
    return self.stored
end

function ax.character:GetAllVariables()
    return self.variables
end