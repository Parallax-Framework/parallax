--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

properties.Add("ax.Persistence.mark", {
    MenuLabel = "[Parallax] Mark for Persistence",
    Order = -1,
    MenuIcon = "icon16/accept.png",
    Filter = function(self, ent, client)
        if ( !IsValid(ent) or ent:IsPlayer() ) then return false end
        if ( MODULE.PersistentEntities[ent:GetClass()] ) then return false end
        if ( ent:GetRelay("persistent") == true ) then return false end

        return client:IsAdmin()
    end,
    Action = function(self, ent)
        net.Start("ax.persistence.mark")
            net.WriteEntity(ent)
        net.Broadcast()
    end
})

properties.Add("ax.Persistence.unmark", {
    MenuLabel = "[Parallax] Unmark for Persistence",
    Order = -1,
    MenuIcon = "icon16/cross.png",
    Filter = function(self, ent, client)
        if ( !IsValid(ent) or ent:IsPlayer() ) then return false end
        if ( MODULE.PersistentEntities[ent:GetClass()] ) then return false end
        if ( ent:GetRelay("persistent") != true ) then return false end

        return client:IsAdmin()
    end,
    Action = function(self, ent)
        net.Start("ax.persistence.unmark")
            net.WriteEntity(ent)
        net.Broadcast()
    end
})
