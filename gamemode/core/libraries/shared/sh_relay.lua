--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

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
    if ( recipient == nil ) then
        recipient = select(2, player.Iterator())
    end

    self.shared[key] = value

    if ( SERVER ) then
        net.Start("ax.relay.shared")
            net.WriteString(key)
            net.WriteType(value)
        net.Send(recipient)
    end
end

function ax.relay:GetRelay(key, default)
    local v = self.shared[key]
    return v != nil and v or default
end

if ( CLIENT ) then
    net.Receive("ax.relay.shared", function(len, client)
        local key = net.ReadString()
        local value = net.ReadType()

        if ( value == nil ) then return end

        ax.relay.shared[key] = value
    end)
end

function playerMeta:SetRelay(key, value, bNetworked, recipients)
    if ( bNetworked == nil ) then
        bNetworked = true
    end

    if ( bNetworked == false ) then
        recipients = self
    else
        if ( recipients == nil ) then
            recipients = select(2, player.Iterator())
        end
    end

    local index = self:EntIndex()
    ax.relay.user[index] = ax.relay.user[index] or {}
    ax.relay.user[index][key] = value

    if ( SERVER ) then
        net.Start("ax.relay.user")
            net.WriteUInt(index, 16)
            net.WriteString(key)
            net.WriteType(value)
        net.Send(recipients)
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
    net.Receive("ax.relay.user", function(len, client)
        local index = net.ReadUInt(16)
        local key = net.ReadString()
        local value = net.ReadType()

        if ( !IsValid(Entity(index)) ) then return end
        if ( value == nil ) then return end

        ax.relay.user[index] = ax.relay.user[index] or {}
        ax.relay.user[index][key] = value
    end)
end

function entityMeta:SetRelay(key, value, bNetworked, recipients)
    if ( bNetworked == nil ) then
        bNetworked = true
    end

    if ( bNetworked == false ) then
        recipients = self
    else
        if ( recipients == nil ) then
            recipients = select(2, player.Iterator())
        end
    end

    local index = self:EntIndex()
    ax.relay.entity[index] = ax.relay.entity[index] or {}
    ax.relay.entity[index][key] = value

    if ( SERVER ) then
        net.Start("ax.relay.entity")
            net.WriteUInt(index, 16)
            net.WriteString(key)
            net.WriteType(value)
        net.Send(recipients)
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
    net.Receive("ax.relay.entity", function(len, client)
        local index = net.ReadUInt(16)
        local key = net.ReadString()
        local value = net.ReadType()

        if ( !IsValid(Entity(index)) ) then return end
        if ( value == nil ) then return end

        ax.relay.entity[index] = ax.relay.entity[index] or {}
        ax.relay.entity[index][key] = value
    end)
end

hook.Add("EntityRemoved", "ax.relay.cleanup.entity", function(entity)
    local index = entity:EntIndex()
    if ( SERVER ) then
        net.Start("ax.relay.cleanup")
            net.WriteUInt(index, 16)
        net.Broadcast()
    end

    if ( entity:IsPlayer() ) then
        if ( ax.relay.user[index] ) then
            ax.relay.user[index] = nil
        end

        return
    end

    if ( ax.relay.entity[index] ) then
        ax.relay.entity[index] = nil
    end
end)

if ( SERVER ) then
    util.AddNetworkString("ax.relay.cleanup")
    util.AddNetworkString("ax.relay.user")
    util.AddNetworkString("ax.relay.entity")
    util.AddNetworkString("ax.relay.shared")

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
    net.Receive("ax.relay.cleanup", function(len, client)
        local index = net.ReadUInt(16)
        local ent = Entity(index)
        if ( !IsValid(ent) ) then return end

        if ( ent:IsPlayer() ) then
            if ( ax.relay.user[index] ) then
                ax.relay.user[index] = nil
            end

            return
        end

        if ( ax.relay.entity[index] ) then
            ax.relay.entity[index] = nil
        end
    end)
end
