--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.relay = ax.relay or {}
ax.relay.data = ax.relay.data or {}

local ENTITY = FindMetaTable("Entity")
function ENTITY:SetRelay(name, value, bNoNetworking, recipients)
    if ( !isstring(name) ) then
        ax.util:PrintError("Invalid 'name' argument provided to method Entity:SetRelay()")
        return
    end

    local index = tostring(self:EntIndex())
    if ( self:IsPlayer() ) then
        index = self:SteamID64()
    end

    ax.relay.data[index] = ax.relay.data[index] or {}
    ax.relay.data[index][name] = value

    if ( !bNoNetworking and SERVER ) then
        net.Start("ax.relay.update")
            net.WriteString(index)
            net.WriteString(name)
            net.WriteType(value)
        if ( recipients ) then
            net.Send( recipients )
        else
            net.Broadcast()
        end
    end
end

function ENTITY:GetRelay(name, fallback)
    if ( !isstring(name) ) then return fallback end

    local index = tostring(self:EntIndex())
    if ( self:IsPlayer() ) then
        index = self:SteamID64()
    end

    ax.relay.data[index] = ax.relay.data[index] or {}

    return ax.relay.data[index][name] != nil and ax.relay.data[index][name] or fallback
end

-- Global variant, similar to SetGlobalVar/GetGlobalVar
function SetRelay(name, value, bNoNetworking, recipients)
    if ( !isstring(name) ) then
        ax.util:PrintError("Invalid 'name' argument provided to function SetRelay()")
        return
    end

    ax.relay.data["global"] = ax.relay.data["global"] or {}
    ax.relay.data["global"][name] = value

    if ( !bNoNetworking and SERVER ) then
        net.Start("ax.relay.update")
            net.WriteString("global")
            net.WriteString(name)
            net.WriteType(value)
        if ( recipients ) then
            net.Send( recipients )
        else
            net.Broadcast()
        end
    end
end

function GetRelay(name, fallback)
    if ( !isstring(name) ) then return fallback end

    ax.relay.data["global"] = ax.relay.data["global"] or {}
    return ax.relay.data["global"][name] != nil and ax.relay.data["global"][name] or fallback
end

hook.Add("EntityRemoved", "ax.relay.cleanup", function(ent, fullUpdate)
    if ( fullUpdate ) then return end

    local index = tostring(ent:EntIndex())
    if ( ent:IsPlayer() ) then
        index = ent:SteamID64()
    end

    ax.relay.data[index] = nil
end)
