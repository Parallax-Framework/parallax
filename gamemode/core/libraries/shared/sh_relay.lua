--- Relay
-- A secure value distribution system using SFS for packing and syncing values.
-- Provides shared (global), user (per-player), and entity (per-entity) scopes.
-- @module ax.relay

ax.relay = ax.relay or {}
ax.relay.shared = ax.relay.shared  or {}
ax.relay.user = ax.relay.user or {}
ax.relay.entity = ax.relay.entity or {}

local playerMeta = FindMetaTable("Player")
local entityMeta = FindMetaTable("Entity")

function ax.relay:SetRelay(key, value, recipient)
    self.shared[key] = value

    if ( SERVER ) then
        ax.net:Start(recipient, "relay.shared", key, value)
    end
end

function ax.relay:GetRelay(key, default)
    local v = self.shared[key]
    return v != nil and v or default
end

if ( CLIENT ) then
    ax.net:Hook("relay.shared", function(key, value)
        if ( value == nil ) then return end

        ax.relay.shared[key] = value
    end)
end

function playerMeta:SetRelay(key, value, recipient)
    if ( SERVER ) then
        local index = self:EntIndex()
        ax.relay.user[index] = ax.relay.user[index] or {}
        ax.relay.user[index][key] = value

        ax.net:Start(recipient, "relay.user", index, key, value)
    end
end

function playerMeta:GetRelay(key, default)
    local index = self:EntIndex()
    local t = ax.relay.user[index]
    if ( t == nil ) then
        return default
    end

    return t[key] == nil and default or t[key]
end

if ( CLIENT ) then
    ax.net:Hook("relay.user", function(index, key, value)
        if ( value == nil ) then return end

        ax.relay.user[index] = ax.relay.user[index] or {}
        ax.relay.user[index][key] = value
    end)
end

function entityMeta:SetRelay(key, value, recipient)
    if ( SERVER ) then
        local index = self:EntIndex()
        ax.relay.entity[index] = ax.relay.entity[index] or {}
        ax.relay.entity[index][key] = value

        ax.net:Start(recipient, "relay.entity", index, key, value)
    end
end

function entityMeta:GetRelay(key, default)
    local index = self:EntIndex()
    local t = ax.relay.entity[index]
    if ( t == nil ) then
        return default
    end

    return t[key] == nil and default or t[key]
end

if ( CLIENT ) then
    ax.net:Hook("relay.entity", function(index, key, value)
        if ( value == nil ) then return end

        ax.relay.entity[index] = ax.relay.entity[index] or {}
        ax.relay.entity[index][key] = value
    end)
end

hook.Add("EntityRemoved", "ax.relay.cleanup.entity", function(entity)
    local index = entity:EntIndex()
    if ( ax.relay.entity[index] ) then
        ax.relay.entity[index] = nil
    end
end)

if ( SERVER ) then
    hook.Add("PlayerDisconnected", "ax.relay.cleanup.user", function(player)
        local index = player:EntIndex()
        if ( ax.relay.user[index] ) then
            ax.relay.user[index] = nil
        end

        ax.net:Start(nil, "relay.cleanup.user", index)
    end)

    hook.Add("SaveData", "ax.relay.cleanup", function()
        for index, _ in pairs(ax.relay.user) do
            if ( !IsValid(Entity(index)) ) then
                ax.relay.user[index] = nil
            end
        end

        for index, _ in pairs(ax.relay.entity) do
            if ( !IsValid(Entity(index)) ) then
                ax.relay.entity[index] = nil
            end
        end
    end)
else
    ax.net:Hook("relay.cleanup.user", function(index)
        if ( ax.relay.user[index] ) then
            ax.relay.user[index] = nil
        end
    end)
end