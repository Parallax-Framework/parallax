--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

Parallax.Net:Hook("persistence.mark", function(client, ent)
    if ( !IsValid(client) or !client:IsAdmin() ) then return end

    if ( ent:GetRelay("persistent") == true ) then
        client:Notify("This entity is already marked for persistence.")
        return
    end

    ent:SetRelay("persistent", true)
    Parallax.log:Send(Parallax.log:Format(client) .. " marked entity " .. tostring(ent) .. " as persistent.")
    client:Notify("Marked entity " .. tostring(ent) .. " as persistent.")

    MODULE:SaveEntities()
end)

Parallax.Net:Hook("persistence.unmark", function(client, ent)
    if ( !IsValid(client) or !client:IsAdmin() ) then return end

    if ( ent:GetRelay("persistent") != true ) then
        client:Notify("This entity is not marked for persistence.")
        return
    end

    ent:SetRelay("persistent", false)
    Parallax.log:Send(Parallax.log:Format(client) .. " unmarked entity " .. tostring(ent) .. " as persistent.")
    client:Notify("Unmarked entity " .. tostring(ent) .. " as persistent.")

    MODULE:SaveEntities()
end)