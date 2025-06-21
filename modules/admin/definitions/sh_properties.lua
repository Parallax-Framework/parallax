--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

properties.Add("Parallax.admin.sethealth", {
    MenuLabel = "Set Health",
    Order = 100,
    MenuIcon = "icon16/heart.png",
    Filter = function(self, ent, client)
        if ( !IsValid(ent) or !ent:IsPlayer() ) then return false end
        if ( !hook.Run( "CanProperty", client, "Parallax.admin.sethealth", ent) ) then return false end

        return MODULE:HasPermission(client, "Parallax - Manage Health", nil)
    end,
    Receive = function(self, length, client)
        local target = net.ReadPlayer()
        if ( !self:Filter(target, client) ) then return end

        local health = net.ReadUInt(8)
        if ( health < 1 ) then
            target:Kill()
            return
        end

        target:SetHealth(health)
    end,
    MenuOpen = function(self, option, ent, trace)
        local subMenu, _ = option:AddSubMenu("Set Health")

        for i = 0, 100, 25 do
            local health = i
            subMenu:AddOption(health .. " HP", function()
                if ( !self:Filter(ent, Parallax.Client) ) then return end

                self:MsgStart()
                    net.WritePlayer(ent)
                    net.WriteUInt(health, 8)
                self:MsgEnd("")
            end):SetIcon("icon16/heart.png")
        end
    end
})