--- Options library
-- @module ax.option

ax.option = ax.option or {}
ax.option.stored = ax.option.stored or {}
ax.option.clients = ax.option.clients or {}

function ax.option:Set(client, key, value, bNoNetworking)
    local stored = ax.option.stored[key]
    if ( !istable(stored) ) then
        ax.util:PrintError("Option \"" .. key .. "\" does not exist!")
        return false
    end

    if ( ax.util:DetectType(value) != stored.Type ) then
        ax.util:PrintError("Attempted to set option \"" .. key .. "\" with invalid type!")
        return false
    end

    if ( isnumber(value) ) then
        if ( isnumber(stored.Min) and value < stored.Min ) then
            ax.util:PrintError("Option \"" .. key .. "\" is below minimum value!")
            return false
        end

        if ( isnumber(stored.Max) and value > stored.Max ) then
            ax.util:PrintError("Option \"" .. key .. "\" is above maximum value!")
            return false
        end
    end

    if ( stored.NoNetworking != true ) then
        if ( !bNoNetworking ) then
            ax.net:Start(client, "option.set", key, value)
        end

        local index = client:EntIndex()
        if ( ax.option.clients[index] == nil ) then
            ax.option.clients[index] = {}
        end

        ax.option.clients[index][key] = value
    end

    if ( isfunction(stored.OnChange) ) then
        stored:OnChange(value, client)
    end

    return true
end

function ax.option:Get(client, key, default)
    if ( !IsValid(client) ) then return default end

    local stored = ax.option.stored[key]
    if ( !istable(stored) ) then
        ax.util:PrintError("Option \"" .. key .. "\" does not exist!")
        return default
    end

    if ( stored.NoNetworking ) then
        ax.util:PrintWarning("Option \"" .. key .. "\" is not networked!")
        return nil
    end

    local clientStored = ax.option.clients[client:EntIndex()]
    if ( !istable(clientStored) ) then
        return stored.Value or default
    end

    return clientStored[key] != nil and clientStored[key] or stored.Value or default
end